; Scratch space to lay out idealized _MakeDirtySprite
;  On input, X register = Sprite Array Index
;Left     equ   tmp1
;Right    equ   tmp2
;Top      equ   tmp3
;Bottom   equ   tmp4

Origin      equ   tmp4
TileTop     equ   tmp5
RowTop      equ   tmp6
AreaIndex   equ   tmp7

TileLeft    equ   tmp8
ColLeft     equ   tmp9

SpriteBit   equ   tmp10     ; set the bit of the value that if the current sprite index
VBuffOrigin equ   tmp11

; Helper function to take a local pixel coordinate [0, ScreenWidth-1],[0, ScreenHeight-1] and return the
; row and column in the tile store that is corresponds to.  This takes into consideration the StartX and
; StartY offsets.
;
; This is more specialized than the code in the _MarkDirtySprite routine below since it does not deal with
; negative or off-screen values.
_OriginToTileStore
        lda   StartYMod208
        lsr
        lsr
        and   #$FFFE                             ; Store the pre-multiplied by 2 for indexing
        tay
        lda   StartXMod164
        lsr
        and   #$FFFE                             ; Same pre-multiply by 2 for later
        tax
        rts

; X = local x-coordinate (0, playfield width)
; Y = local y-coordinate (0, playfield height)
_LocalToTileStore
        clc
        tya
        adc   StartYMod208                       ; Adjust for the scroll offset
        cmp   #208                               ; check if we went too far positive
        bcc   *+5
        sbc   #208
        lsr
        lsr
        and   #$FFFE                             ; Store the pre-multiplied by 2 for indexing
        tay

        clc
        txa
        adc   StartXMod164
        cmp   #164
        bcc   *+5
        sbc   #164
        lsr
        and   #$FFFE                             ; Same pre-multiply by 2 for later
        tax
        rts

; Marks a sprite as dirty.  The work here is mapping from local screen coordinates to the 
; tile store indices.  The first step is to adjust the sprite coordinates based on the current
; code field offsets and then cache variations of this value needed in the rest of the subroutine
;
; The SpriteX is always the MAXIMUM value of the corner coordinates.  We subtract (SpriteX + StartX) mod 4
; to find the coordinate in the sprite cache that matches up with the tile in the play field and 
; then use that to calculate the VBUFF address from which to copy sprite data.
;
; StartX   SpriteX   z = * mod 4   (SpriteX - z)
; ----------------------------------------------
; 0        8         0             8
; 1        8         1             7
; 2        8         2             6
; 3        8         3             5
; 4        9         1             8
; 5        9         2             7
; 6        9         3             6
; 7        9         0             9
; 8        10        2             8
; ...
;
; For the Y-coordinate, we just use "mod 8" instead of "mod 4"
mdsOut  rts
_MarkDirtySprite

        lda   #0
        sta   _Sprites+TILE_STORE_ADDR_1,y       ; Clear this sprite's dirty tile list in case of an early exit
        lda   _SpriteBits,y                      ; Cache its bit flag to mark in the tile slots
        sta   SpriteBit

        lda   _Sprites+IS_OFF_SCREEN,y           ; Check if the sprite is visible in the playfield
        bne   mdsOut

; At this point we know that we have to update the tiles that overlap the sprite's rectangle defined
; by (Top, Left), (Bottom, Right).  

        clc
        lda   _Sprites+SPRITE_CLIP_TOP,y
        adc   StartYMod208                       ; Adjust for the scroll offset (could be a negative number!)
        tax                                      ; Save this value
        and   #$0007                             ; Get (StartY + SpriteY) mod 8
        sta   TileTop                            ; This is the relative offset to the sprite stamp

;        eor   #$FFFF
;        inc
;        clc
;        adc   _Sprites+SPRITE_CLIP_TOP,y         ; subtract from the Y position (possible to go negative here)
;        sta   TileTop                            ; This position will line up with the tile that the sprite overlaps with

        txa                                      ; Get back the position of the sprite top in the code field
        cmp   #208                               ; check if we went too far positive
        bcc   *+5
        sbc   #208
        lsr
        lsr
;        lsr                                      ; This is the row in the Tile Store for top-left corner of the sprite
        and   #$FFFE                              ; Store the pre-multiplied by 2 for indexing in the :mark_R_C routines
        sta   RowTop

        lda   _Sprites+SPRITE_CLIP_BOTTOM,y      ; Figure out how many tiles are needed to cover the sprite's area
        sec
        sbc   _Sprites+SPRITE_CLIP_TOP,y
        clc
        adc   TileTop

        and   #$0018                             ; Clear out the lower bits and stash in bits 4 and 5
        sta   AreaIndex

; Repeat to get the same information for the columns

        clc
        lda   _Sprites+SPRITE_CLIP_LEFT,y
        adc   StartXMod164
        tax
        and   #$0003
        sta   TileLeft

;        eor   #$FFFF
;        inc
;        clc
;        adc   _Sprites+SPRITE_CLIP_LEFT,y
;        sta   TileLeft

        txa
        cmp   #164
        bcc   *+5
        sbc   #164
        lsr
;        lsr
        and   #$FFFE                             ; Same pre-multiply by 2 for later
        sta   ColLeft

; Sneak a pre-calculation here. Calculate the tile-aligned upper-left corner of the sprite in the sprite plane.
; We can reuse this in all of the routines below.  This is not the (x,y) of the sprite itself, but
; the corner of the tile it overlaps with, relative to the sprite's VBUFF_ADDR.

        clc
        lda   TileTop
;        adc   #NUM_BUFF_LINES
        xba
        clc
        adc   TileLeft
        sta   VBuffOrigin                     ; Save once to use later (constant offsets)

; Calculate the number of columns and dispatch

        lda   _Sprites+SPRITE_CLIP_RIGHT,y
        sec
        sbc   _Sprites+SPRITE_CLIP_LEFT,y
        clc
        adc   TileLeft
        and   #$000C
        lsr                                   ; bit 0 is always zero and width stored in bits 1 and 2
        ora   AreaIndex
        tax
        jmp   (:mark,x)
:mark   dw    :mark1x1,:mark1x2,:mark1x3,mdsOut
        dw    :mark2x1,:mark2x2,:mark2x3,mdsOut
        dw    :mark3x1,:mark3x2,:mark3x3,mdsOut
        dw    mdsOut,mdsOut,mdsOut,mdsOut

; Dispatch to the calculated sizing

; Begin a list of subroutines to cover all of the valid sprite size compinations.  This is all unrolled code,
; mainly to be able to do an unrolled fill of the TILE_STORE_ADDR_X values.  Thus, it's important that the clipping
; function does its job properly since it allows us to save a lot of time here.
;
; These functions are a trade off of being composable versus fast.  Having to pay for multiple JSR/RTS invocations
; in the hot sprite path isn't great, but we're at a point of diminishing returns.
;
; There *might* be some speed gained by pushing a list of :mark_R_C addressed onto the stack in the clipping routing
; and dispatching that way, but probably not...
:mark1x1
        jsr   :mark_0_0
        sta   _Sprites+TILE_STORE_ADDR_1,y
        lda   #0
        sta   _Sprites+TILE_STORE_ADDR_2,y
        rts

; NOTE: If we rework the _PushDirtyTile to use the Y register instead of the X register, we can
;       optimize all of these :mark routines as
;
; :mark1x1
;        jsr   :mark_0_0
;        sty   _Sprites+TILE_STORE_ADDR_1,x
;        stz   _Sprites+TILE_STORE_ADDR_2,y
;        rts

:mark1x2
        jsr   :mark_0_0
        sta   _Sprites+TILE_STORE_ADDR_1,y
        jsr   :mark_0_1
        sta   _Sprites+TILE_STORE_ADDR_2,y
        lda   #0
        sta   _Sprites+TILE_STORE_ADDR_3,y
        rts

:mark1x3
        jsr   :mark_0_0
        sta   _Sprites+TILE_STORE_ADDR_1,y
        jsr   :mark_0_1
        sta   _Sprites+TILE_STORE_ADDR_2,y
        jsr   :mark_0_2
        sta   _Sprites+TILE_STORE_ADDR_3,y
        lda   #0
        sta   _Sprites+TILE_STORE_ADDR_4,y
        rts

:mark2x1
        jsr   :mark_0_0
        sta   _Sprites+TILE_STORE_ADDR_1,y
        jsr   :mark_1_0
        sta   _Sprites+TILE_STORE_ADDR_2,y
        lda   #0
        sta   _Sprites+TILE_STORE_ADDR_3,y
        rts

:mark2x2
        jsr   :mark_0_0
        sta   _Sprites+TILE_STORE_ADDR_1,y
        jsr   :mark_0_1
        sta   _Sprites+TILE_STORE_ADDR_2,y
        jsr   :mark_1_0
        sta   _Sprites+TILE_STORE_ADDR_3,y
        jsr   :mark_1_1
        sta   _Sprites+TILE_STORE_ADDR_4,y
        lda   #0
        sta   _Sprites+TILE_STORE_ADDR_5,y
        rts

:mark2x3
        jsr   :mark_0_0
        sta   _Sprites+TILE_STORE_ADDR_1,y
        jsr   :mark_0_1
        sta   _Sprites+TILE_STORE_ADDR_2,y
        jsr   :mark_0_2
        sta   _Sprites+TILE_STORE_ADDR_3,y
        jsr   :mark_1_0
        sta   _Sprites+TILE_STORE_ADDR_4,y
        jsr   :mark_1_1
        sta   _Sprites+TILE_STORE_ADDR_5,y
        jsr   :mark_1_2
        sta   _Sprites+TILE_STORE_ADDR_6,y
        lda   #0
        sta   _Sprites+TILE_STORE_ADDR_7,y
        rts

:mark3x1
        jsr   :mark_0_0
        sta   _Sprites+TILE_STORE_ADDR_1,y
        jsr   :mark_1_0
        sta   _Sprites+TILE_STORE_ADDR_2,y
        jsr   :mark_2_0
        sta   _Sprites+TILE_STORE_ADDR_3,y
        lda   #0
        sta   _Sprites+TILE_STORE_ADDR_4,y
        rts

:mark3x2
        jsr   :mark_0_0
        sta   _Sprites+TILE_STORE_ADDR_1,y
        jsr   :mark_1_0
        sta   _Sprites+TILE_STORE_ADDR_2,y
        jsr   :mark_2_0
        sta   _Sprites+TILE_STORE_ADDR_3,y
        jsr   :mark_0_1
        sta   _Sprites+TILE_STORE_ADDR_4,y
        jsr   :mark_1_1
        sta   _Sprites+TILE_STORE_ADDR_5,y
        jsr   :mark_2_1
        sta   _Sprites+TILE_STORE_ADDR_6,y
        lda   #0
        sta   _Sprites+TILE_STORE_ADDR_7,y
        rts

:mark3x3
        jsr   :mark_0_0
        sta   _Sprites+TILE_STORE_ADDR_1,y
        jsr   :mark_1_0
        sta   _Sprites+TILE_STORE_ADDR_2,y
        jsr   :mark_2_0
        sta   _Sprites+TILE_STORE_ADDR_3,y
        jsr   :mark_0_1
        sta   _Sprites+TILE_STORE_ADDR_4,y
        jsr   :mark_1_1
        sta   _Sprites+TILE_STORE_ADDR_5,y
        jsr   :mark_2_1
        sta   _Sprites+TILE_STORE_ADDR_6,y
        jsr   :mark_0_2
        sta   _Sprites+TILE_STORE_ADDR_7,y
        jsr   :mark_1_2
        sta   _Sprites+TILE_STORE_ADDR_8,y
        jsr   :mark_2_2
        sta   _Sprites+TILE_STORE_ADDR_9,y
        lda   #0
        sta   _Sprites+TILE_STORE_ADDR_10,y
        rts

; Begin List of subroutines to mark each tile offset
;
; If we had a double-sized 2D array to be able to look up the tile store address without
; adding rows and column, we could save ~6 cycles per tile

; If all that is needed is to record the Tile Store offset for the sprite and delay any
; actual calculations, then we just need to do
;
;        lda  TileStore2DArray,x
;        sta  _Sprites+TILE_STORE_ADDR_0,y
;        lda  TileStore2DArray+2,x
;        sta  _Sprites+TILE_STORE_ADDR_1,y
;        lda  TileStore2DArray+41,x
;        sta  _Sprites+TILE_STORE_ADDR_2,y
;        ...

:mark_0_0
        ldx   RowTop
        lda   ColLeft
        clc
        adc   TileStoreYTable,x                 ; Fixed offset to the next row
        tax

        ldal  TileStore+TS_VBUFF_ARRAY_ADDR,x
        sta   tmp0

        lda   VBuffOrigin
        sta   (tmp0),y

;        lda   VBuffOrigin                      ; This is an interesting case.  The mapping between the tile store
;        adc   #{0*4}+{0*256}                  ; and the sprite buffers changes as the StartX, StartY values change
;        stal  TileStore+TS_SPRITE_ADDR,x       ; but don't depend on any sprite information.  However, by setting the
                                               ; value only for the tiles that get added to the dirty tile list, we
                                               ; can avoid recalculating over 1,000 values whenever the screen scrolls
                                               ; (which is common) and just limit it to the number of tiles covered by
                                               ; the sprites.  If the screen is not scrolling and the sprites are not
                                               ; moving and they are being dirtied, then we may do more work, but the
                                               ; odds are in our favor to just take care of it here.

        ; lda   TileStore+TS_SPRITE_FLAG,x
        lda   SpriteBit
        oral  TileStore+TS_SPRITE_FLAG,x
        stal  TileStore+TS_SPRITE_FLAG,x

        jmp   _PushDirtyTileX                   ; Needs X = tile store offset; destroys A,X.  Returns X in A

:mark_1_0
        lda  ColLeft
        ldx  RowTop
        clc
        adc  TileStoreYTable+2,x
        tax

        ldal  TileStore+TS_VBUFF_ARRAY_ADDR,x
        sta   tmp0

        lda   VBuffOrigin
        adc   #{0*4}+{1*8*SPRITE_PLANE_SPAN}
        sta   (tmp0),y

        lda   SpriteBit
        oral  TileStore+TS_SPRITE_FLAG,x
        stal  TileStore+TS_SPRITE_FLAG,x

        jmp   _PushDirtyTileX

:mark_2_0
        lda  ColLeft
        ldx  RowTop
        clc
        adc  TileStoreYTable+4,x
        tax

        ldal  TileStore+TS_VBUFF_ARRAY_ADDR,x
        sta   tmp0

        lda   VBuffOrigin
        adc   #{0*4}+{2*8*SPRITE_PLANE_SPAN}
        sta   (tmp0),y

        lda   SpriteBit
        oral  TileStore+TS_SPRITE_FLAG,x
        stal  TileStore+TS_SPRITE_FLAG,x

        jmp   _PushDirtyTileX

:mark_0_1
        ldx  ColLeft
        lda  NextCol+2,x
        ldx  RowTop
        clc
        adc  TileStoreYTable,x
        tax

        ldal  TileStore+TS_VBUFF_ARRAY_ADDR,x
        sta   tmp0

        lda   VBuffOrigin
        adc   #{1*4}+{0*8*SPRITE_PLANE_SPAN}
        sta   (tmp0),y

        lda   SpriteBit
        oral  TileStore+TS_SPRITE_FLAG,x
        stal  TileStore+TS_SPRITE_FLAG,x

        jmp   _PushDirtyTileX

:mark_1_1
        ldx  ColLeft
        lda  NextCol+2,x
        ldx  RowTop
        clc
        adc  TileStoreYTable+2,x
        tax

        ldal  TileStore+TS_VBUFF_ARRAY_ADDR,x
        sta   tmp0

        lda   VBuffOrigin
        adc   #{1*4}+{1*8*SPRITE_PLANE_SPAN}
        sta   (tmp0),y

        lda   SpriteBit
        oral  TileStore+TS_SPRITE_FLAG,x
        stal  TileStore+TS_SPRITE_FLAG,x

        jmp   _PushDirtyTileX

:mark_2_1
        ldx  ColLeft
        lda  NextCol+2,x
        ldx  RowTop
        clc
        adc  TileStoreYTable+4,x
        tax

        ldal  TileStore+TS_VBUFF_ARRAY_ADDR,x
        sta   tmp0

        lda   VBuffOrigin
        adc   #{1*4}+{2*8*SPRITE_PLANE_SPAN}
        sta   (tmp0),y

        lda   SpriteBit
        oral  TileStore+TS_SPRITE_FLAG,x
        stal  TileStore+TS_SPRITE_FLAG,x

        jmp   _PushDirtyTileX

:mark_0_2
        ldx  ColLeft
        lda  NextCol+4,x
        ldx  RowTop
        clc
        adc  TileStoreYTable,x
        tax

        ldal  TileStore+TS_VBUFF_ARRAY_ADDR,x
        sta   tmp0

        lda   VBuffOrigin
        adc   #{2*4}+{0*8*SPRITE_PLANE_SPAN}
        sta   (tmp0),y

        lda   SpriteBit
        oral  TileStore+TS_SPRITE_FLAG,x
        stal  TileStore+TS_SPRITE_FLAG,x

        jmp   _PushDirtyTileX

:mark_1_2
        ldx  ColLeft
        lda  NextCol+4,x
        ldx  RowTop
        clc
        adc  TileStoreYTable+2,x
        tax

        ldal  TileStore+TS_VBUFF_ARRAY_ADDR,x
        sta   tmp0

        lda   VBuffOrigin
        adc   #{2*4}+{1*8*SPRITE_PLANE_SPAN}
        sta   (tmp0),y

        lda   SpriteBit
        oral  TileStore+TS_SPRITE_FLAG,x
        stal  TileStore+TS_SPRITE_FLAG,x

        jmp   _PushDirtyTileX

:mark_2_2
        ldx  ColLeft
        lda  NextCol+4,x
        ldx  RowTop
        clc
        adc  TileStoreYTable+4,x
        tax

        ldal  TileStore+TS_VBUFF_ARRAY_ADDR,x
        sta   tmp0

        lda   VBuffOrigin
        adc   #{2*4}+{2*8*SPRITE_PLANE_SPAN}
        sta   (tmp0),y

        lda   SpriteBit
        oral  TileStore+TS_SPRITE_FLAG,x
        stal  TileStore+TS_SPRITE_FLAG,x

        jmp   _PushDirtyTileX

; End list of subroutines to mark dirty tiles

; Range-check and clamp the vertical part of the sprite.  When this routine returns we will have valid
; values for the tile-top and row-top.  Also, the accumulator will return the number of rows to render,
; a value of zero means that all of the sprite's rows are off-screen.
;
; This subroutine takes are of calculating the extra tile for unaligned accesses, too.
_SpriteHeight       dw 8,8,16,16
_SpriteHeightMinus1 dw 7,7,15,15
_SpriteRows         dw 1,1,2,2
_SpriteWidth        dw 4,8,4,8
_SpriteWidthMinus1  dw 3,7,3,7
_SpriteCols         dw 1,2,1,2

; Convert sprite index to a bit position
_SpriteBits         dw $0001,$0002,$0004,$0008,$0010,$0020,$0040,$0080,$0100,$0200,$0400,$0800,$1000,$2000,$4000,$8000
_SpriteBitsNot      dw $FFFE,$FFFD,$FFFB,$FFF7,$FFEF,$FFDF,$FFBF,$FF7F,$FEFF,$FDFF,$FBFF,$F7FF,$EFFF,$DFFF,$BFFF,$7FFF

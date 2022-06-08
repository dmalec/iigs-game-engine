; If the engine mode has the second background layer disabled, we take advantage of that to
; be more efficient in our rendering.  Basically, without the second layer, there is no need
; to use the tile mask information.
;
; If there are no sprites, then we copy the tile data into the code field as fast as possible.
; If there are sprites, then the sprite data is flattened and stored into a direct page buffer
; and then copied into the code field
_RenderTileFast
            lda   TileStore+TS_SPRITE_FLAG,x       ; any sprites on this line?
            bne   SpriteDispatch

NoSpriteFast
            lda   TileStore+TS_CODE_ADDR_HIGH,x    ; load the bank of the target code field line
            pha                                    ; and put on the stack for later. Has TileStore bank in high byte.
            ldy   TileStore+TS_CODE_ADDR_LOW,x     ; load the address of the code field
;            lda   TileStore+TS_BASE_TILE_DISP,x    ; go to the tile copy routine (just basics)
;            stal  nsf_patch+1
            lda   TileStore+TS_TILE_ADDR,x         ; load the address of this tile's data (pre-calculated)
            plb                                    ; set the code field bank
            jmp   (K_TS_BASE_TILE_DISP,x)

;nsf_patch   jmp   $0000

; The TS_BASE_TILE_DISP routines will come from this table when ENGINE_MODE_TWO_LAYER and
; ENGINE_MODE_DYN_TILES are both off.
FastTileProcs dw   _TBCopyDataFast,_TBCopyDataFast,_TBCopyDataFast,_TBCopyDataFast

; dw   _TBCopyDataFast,_TBCopyDataFast,_TBCopyDataVFast,_TBCopyDataVFast

; Need to determine if the sprite or tile data is on top, as that will decide whether the
; sprite or tile data is copied into the temporary buffer first.  Also, if TWO_LAYER is set
; then the mask information must be copied as well....This is the last decision point.

SpriteDispatch
            txy
            SpriteBitsToVBuffAddrs OneSpriteFast;TwoSpritesFast;ThreeSpritesFast;FourSpritesFast

; Where there are sprites involved, the first step is to call a routine to copy the
; tile data into a temporary buffer.  Then the sprite data is merged and placed into
; the code field.
;
; A = vbuff address
; Y = tile store address
OneSpriteFast
            sta   sprite_ptr0
            ldx   TileStore+TS_TILE_ADDR,y
            jsr   _CopyTileDataToDP2               ; preserves Y
            lda   TileStore+TS_CODE_ADDR_HIGH,y    ; load the bank of the target code field line
            pha                                    ; and put on the stack for later. Has TileStore bank in high byte.
            ldx   sprite_ptr0                      ; address of sprite vbuff info
            lda   TileStore+TS_CODE_ADDR_LOW,y     ; load the address of the code field
            tay
            plb

_TBApplySpriteData2
]line       equ   0
            lup   8
            lda   tmp_tile_data+{]line*4}
            andl  spritemask+{]line*SPRITE_PLANE_SPAN},x
            oral  spritedata+{]line*SPRITE_PLANE_SPAN},x
            sta:  $0004+{]line*$1000},y

            lda   tmp_tile_data+{]line*4}+2
            andl  spritemask+{]line*SPRITE_PLANE_SPAN}+2,x
            oral  spritedata+{]line*SPRITE_PLANE_SPAN}+2,x
            sta:  $0001+{]line*$1000},y
]line       equ   ]line+1
            --^
            plb
            rts 

TwoSpriteLine mac
;            and   [sprite_ptr1],y
            db    $37,sprite_ptr1
            ora   (sprite_ptr1),y
;            and   [sprite_ptr0],y
            db    $37,sprite_ptr0
            ora   (sprite_ptr0),y
            <<<

TwoSpritesFast
            ldx   TileStore+TS_TILE_ADDR,y
            lda   TileStore+TS_CODE_ADDR_HIGH,y    ; load the bank of the target code field line
            pha                                    ; and put on the stack for later. Has TileStore bank in high byte.
            lda   TileStore+TS_CODE_ADDR_LOW,y     ; load the address of the code field
            pha                                    ; Need to pop it later....

            sep   #$20                             ; set the sprite data bank
            lda   #^spritedata
            pha
            plb
            rep   #$20

]line       equ   0
            lup   8
            ldy   #{]line*SPRITE_PLANE_SPAN}
            ldal  tiledata+{]line*4},x
            TwoSpriteLine
            sta   tmp_tile_data+{]line*4}

            ldy   #{]line*SPRITE_PLANE_SPAN}+2
            ldal  tiledata+{]line*4}+2,x
            TwoSpriteLine
            sta   tmp_tile_data+{]line*4}+2
]line            equ   ]line+1
            --^

            ply                                    ; Pop off CODE_ADDR_LOW
            plb                                    ; Set the CODE_ADDR_HIGH bank

]line       equ   0
            lup   8
            lda   tmp_tile_data+{]line*4}
            sta:  $0004+{]line*$1000},y
            lda   tmp_tile_data+{]line*4}+2
            sta:  $0001+{]line*$1000},y
]line       equ   ]line+1
            --^
            plb                                   ; Reset to the bank in the top byte of CODE_ADDR_HIGH
            rts 

ThreeSpriteLine mac
;            and   [sprite_ptr2],y
            db    $37,sprite_ptr2
            ora   (sprite_ptr2),y
;            and   [sprite_ptr1],y
            db    $37,sprite_ptr1
            ora   (sprite_ptr1),y
;            and   [sprite_ptr0],y
            db    $37,sprite_ptr0
            ora   (sprite_ptr0),y
            <<<

ThreeSpritesFast
            ldx   TileStore+TS_TILE_ADDR,y
            lda   TileStore+TS_CODE_ADDR_HIGH,y    ; load the bank of the target code field line
            pha                                    ; and put on the stack for later. Has TileStore bank in high byte.
            lda   TileStore+TS_CODE_ADDR_LOW,y     ; load the address of the code field
            pha                                    ; Need to pop it later....

            sep   #$20                             ; set the sprite data bank
            lda   #^spritedata
            pha
            plb
            rep   #$20

]line       equ   0
            lup   8
            ldy   #{]line*SPRITE_PLANE_SPAN}
            ldal  tiledata+{]line*4},x
            ThreeSpriteLine
            sta   tmp_tile_data+{]line*4}

            ldy   #{]line*SPRITE_PLANE_SPAN}+2
            ldal  tiledata+{]line*4}+2,x
            ThreeSpriteLine
            sta   tmp_tile_data+{]line*4}+2
]line            equ   ]line+1
            --^

            ply                                    ; Pop off CODE_ADDR_LOW
            plb                                    ; Set the CODE_ADDR_HIGH bank

]line       equ   0
            lup   8
            lda   tmp_tile_data+{]line*4}
            sta:  $0004+{]line*$1000},y
            lda   tmp_tile_data+{]line*4}+2
            sta:  $0001+{]line*$1000},y
]line       equ   ]line+1
            --^
            plb                                   ; Reset to the bank in the top byte of CODE_ADDR_HIGH
            rts

FourSpriteLine mac
;            and   [sprite_ptr3],y
            db    $37,sprite_ptr3
            ora   (sprite_ptr3),y
;            and   [sprite_ptr2],y
            db    $37,sprite_ptr2
            ora   (sprite_ptr2),y
;            and   [sprite_ptr1],y
            db    $37,sprite_ptr1
            ora   (sprite_ptr1),y
;            and   [sprite_ptr0],y
            db    $37,sprite_ptr0
            ora   (sprite_ptr0),y
            <<<

FourSpritesFast
            ldx   TileStore+TS_TILE_ADDR,y
            lda   TileStore+TS_CODE_ADDR_HIGH,y    ; load the bank of the target code field line
            pha                                    ; and put on the stack for later. Has TileStore bank in high byte.
            lda   TileStore+TS_CODE_ADDR_LOW,y     ; load the address of the code field
            pha                                    ; Need to pop it later....

            sep   #$20                             ; set the sprite data bank
            lda   #^spritedata
            pha
            plb
            rep   #$20

]line       equ   0
            lup   8
            ldy   #{]line*SPRITE_PLANE_SPAN}
            ldal  tiledata+{]line*4},x
            FourSpriteLine
            sta   tmp_tile_data+{]line*4}

            ldy   #{]line*SPRITE_PLANE_SPAN}+2
            ldal  tiledata+{]line*4}+2,x
            FourSpriteLine
            sta   tmp_tile_data+{]line*4}+2
]line            equ   ]line+1
            --^

            ply                                    ; Pop off CODE_ADDR_LOW
            plb                                    ; Set the CODE_ADDR_HIGH bank

]line       equ   0
            lup   8
            lda   tmp_tile_data+{]line*4}
            sta:  $0004+{]line*$1000},y
            lda   tmp_tile_data+{]line*4}+2
            sta:  $0001+{]line*$1000},y
]line       equ   ]line+1
            --^
            plb                                   ; Reset to the bank in the top byte of CODE_ADDR_HIGH
            rts
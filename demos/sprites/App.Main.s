; Test driver to exercise graphics routines.

                    REL
                    DSK        MAINSEG

                    use        Locator.Macs.s
                    use        Misc.Macs.s
                    use        EDS.GSOS.MACS.s
                    use        Tool222.Macs.s
                    use        Util.Macs.s
                    use        CORE.MACS.s
                    use        ../../src/GTE.s
                    use        ../../src/Defs.s

                    mx         %00

; Feature flags
NO_INTERRUPTS       equ        0                       ; turn off for crossrunner debugging
NO_MUSIC            equ        1                       ; turn music + tool loading off

; Keycodes
LEFT_ARROW          equ        $08
RIGHT_ARROW         equ        $15
UP_ARROW            equ        $0B
DOWN_ARROW          equ        $0A

; Typical init
                    phk
                    plb

                    jsl        EngineStartUp

                    lda        #^MyPalette               ; Fill Palette #0 with our colors
                    ldx        #MyPalette
                    ldy        #0
                    jsl        SetPalette

                    ldx        #0                        ; Mode 0 is full-screen
                    jsl        SetScreenMode

; Set up our level data
                    jsr        BG0SetUp
;                    jsr        TileAnimInit

; Allocate room to load data
;                    jsr        MovePlayerToOrigin      ; Put the player at the beginning of the map

; Add a player sprite
                    stz        PlayerX
                    lda        #4
                    sta        PlayerY

                    lda        #DIRTY_BIT_BG0_REFRESH  ; Redraw all of the tiles on the next Render
                    tsb        DirtyBits
                    jsl        Render

; Set up a very specific test.  First, we draw a sprite into the sprite plane, and then
; leave it alone.  We are just testing the ability to merge sprite plane data into 
; the play field tiles.
EvtLoop

                    ldx        PlayerX
                    ldy        PlayerY
                    jsl        GetSpriteVBuffAddr
                    tax                                ; put in X
                    ldy        #3*128                  ; draw the 3rd tile as a sprite
                    jsl        DrawTileSprite

; Now the sprite has been drawn. Manually update the 4 top-left tiles. Since we have not scrolled
; the screen, these are the tiles in rows 0 and 1 and columns 0 and 1.  The next step is to mark
; those tiles as intersecting a sprite

                    ldx        #0
                    ldy        #0
                    jsr        MakeDirtyTile

                    ldx        #1
                    ldy        #0
                    jsr        MakeDirtyTile

                    ldx        #0
                    ldy        #1
                    jsr        MakeDirtyTile

                    ldx        #1
                    ldy        #1
                    jsr        MakeDirtyTile

; Let's see what it looks like!

                    jsl        Render

                    lda        PlayerX                 ; Move the player sprite a bit
                    inc
                    and        #$001F
                    sta        PlayerX
;                    tax
;                    ldy        PlayerY
;                    lda        PlayerID
;                    jsl        UpdateSprite

;                    jsl        DoTimers
;                    jsl        Render

                    jsl        ReadControl
                    and        #$007F                  ; Ignore the buttons for now

                    cmp        #'q'
                    bne        :7
                    brl        Exit

:7                  cmp        #LEFT_ARROW
                    bne        :8
                    brl        EvtLoop

:8                  cmp        #RIGHT_ARROW
                    bne        :9
                    brl        EvtLoop

:9
                    brl        EvtLoop

; Exit code
Exit
                    jsl        EngineShutDown

                    _QuitGS    qtRec

                    bcs        Fatal
Fatal               brk        $00

MyPalette           dw         $0000,$0777,$0F31,$0E51,$00A0,$02E3,$0BF1,$0FA4,$0FD7,$0EE6,$0F59,$068F,$01CE,$09B9,$0EDA,$0EEE

PlayerID            ds         2
PlayerX             ds         2
PlayerY             ds         2

; x = column
; y = row
MakeDirtyTile
                    phx
                    phy

                    txa
                    asl
                    asl
                    tax
                    tya
                    asl
                    asl
                    asl
                    tay                    
                    jsl        GetSpriteVBuffAddr

                    ply
                    plx

                    pha

                    jsl        GetTileStoreOffset
                    tax
                    lda        #TILE_SPRITE_BIT
                    stal       TileStore+TS_SPRITE_FLAG,x
                    pla
                    stal       TileStore+TS_SPRITE_ADDR,x
                    txy
                    jsl        RenderTile
                    rts

; Position the screen with the botom-left corner of the tilemap visible
MovePlayerToOrigin
                    lda        #0                      ; Set the player's position
                    jsl        SetBG0XPos

                    lda        TileMapHeight
                    asl
                    asl
                    asl
                    sec
                    sbc        ScreenHeight
                    jsl        SetBG0YPos
                    rts

qtRec               adrl       $0000
                    da         $00

                    PUT        gen/App.TileMapBG0.s
                    PUT        gen/App.TileSetAnim.s

Overlay             ENT
                    rtl

ANGLEBNK            ENT
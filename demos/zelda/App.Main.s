; Test driver to exercise graphics routines.

                    REL
                    DSK        MAINSEG

                    use   Locator.Macs
                    use   Load.Macs
                    use   Mem.Macs
                    use   Misc.Macs
                    use   Tool222.Macs.s
                    use   Util.Macs
                    use   EDS.GSOS.Macs
                    use   GTE.Macs

                    mx         %00

; Feature flags
NO_INTERRUPTS       equ        0                       ; turn off for crossrunner debugging
NO_MUSIC            equ        1                       ; turn music + tool loading off

; Keycodes
LEFT_ARROW          equ        $08
RIGHT_ARROW         equ        $15
UP_ARROW            equ        $0B
DOWN_ARROW          equ        $0A

StartX          equ        4
StartY          equ        6

TSet EXT
; Typical init
                    phk
                    plb

                    stz   StartX
                    stz   StartY


                    sta   MyUserId                ; GS/OS passes the memory manager user ID for the application into the program
                    _MTStartUp                    ; GTE requires the miscellaneous toolset to be running

                    jsr   GTEStartUp              ; Load and install the GTE User Tool

; Load a tileset

                pea   #^TSet
                pea   #TSet
                _GTELoadTileSet


                pea   $0000
                pea   #^MyPalette
                pea   #MyPalette
                _GTESetPalette

                pea   #256
                pea   #176
                _GTESetScreenMode

; Set up our level data
                    jsr        BG0SetUp

; Initialize the sprite's global position (this is tracked outside of the tile engine)
                    lda        #64
                    sta        PlayerX
                    sta        PlayerY
                    stz        MapScreenX
                    stz        MapScreenY

; Add a sprite to the engine and save its sprite
HERO_DOWN_ID        equ        {SPRITE_16X16+1}
HERO_DOWN_VBUFF     equ        VBUFF_SPRITE_START+0*VBUFF_SPRITE_STEP
HERO_SIDE_ID        equ        {SPRITE_16X16+5}
HERO_SIDE_VBUFF     equ        VBUFF_SPRITE_START+1*VBUFF_SPRITE_STEP
HERO_UP_ID          equ        {SPRITE_16X16+9}
HERO_UP_VBUFF       equ        VBUFF_SPRITE_START+2*VBUFF_SPRITE_STEP

HERO_SLOT           equ        0
OKTOROK_ID          equ        {SPRITE_16X16+79}
OKTOROK_VBUFF       equ        VBUFF_SPRITE_START+3*VBUFF_SPRITE_STEP
OKTOROK_SLOT_1      equ        1
OKTOROK_SLOT_2      equ        2
OKTOROK_SLOT_3      equ        3
OKTOROK_SLOT_4      equ        4

; Create the sprite stamps for this scene

                pea   HERO_DOWN_ID                     ; sprint id
                pea   HERO_DOWN_VBUFF                  ; vbuff address
                _GTECreateSpriteStamp

                pea   HERO_SIDE_ID                     ; sprint id
                pea   HERO_SIDE_VBUFF                  ; vbuff address
                _GTECreateSpriteStamp

                pea   HERO_UP_ID                     ; sprint id
                pea   HERO_UP_VBUFF                  ; vbuff address
                _GTECreateSpriteStamp

                pea   OKTOROK_ID                 ; sprint id
                pea   OKTOROK_VBUFF              ; vbuff address
                _GTECreateSpriteStamp

                pea   HERO_DOWN_ID
                lda   PlayerX
                pha
                lda   PlayerY
                pha
                pea   HERO_SLOT
                _GTEAddSprite

                pea   HERO_SLOT
                pea   $0000                       ; with these flags (h/v flip)
                pea   HERO_DOWN_VBUFF             ; and use this stamp
                _GTEUpdateSprite

; Add 4 octoroks 
;                pea   OKTOROK_ID
;                lda   OktorokX
;                pha
;                lda   OktorokY
;                pha
;                pea   OKTOROK_SLOT_1
;                _GTEAddSprite

;                pea   OKTOROK_SLOT_1
;                pea   $0000                       ; with these flags (h/v flip)
;                pea   OKTOROK_VBUFF               ; and use this stamp
;                _GTEUpdateSprite

; Draw the initial screen

                _GTERender

; Set up a very specific test.  First, we draw a sprite into the sprite plane, and then
; leave it alone.  We are just testing the ability to merge sprite plane data into 
; the play field tiles.
EvtLoop
                pha
                _GTEReadControl
                pla

; Check the buttons first
                pha

                bit        #$0100
                beq        :no_sword
:no_sword

; Enable/disable v-sync
                lda        1,s
                bit        #PAD_KEY_DOWN
                beq        :no_key_down
                and        #$007F
                cmp        #'v'
                bne        :not_v
                lda        #$0001
                eor        vsync
                sta        vsync
:not_v
:no_key_down
                pla
                and        #$007F                  ; Ignore the buttons for now

                cmp        #'q'
                bne        :not_q
                brl        Exit
:not_q

                cmp        #'d'
                bne        :not_d
                inc        PlayerX
                lda        PlayerX
                cmp        #128-8
                bcc        *+5
                jsr        TransitionRight

                pea   HERO_SLOT
                pea   $0000                             ; no flags
                pea   HERO_SIDE_VBUFF                   ; and use this stamp
                _GTEUpdateSprite

                    bra        :do_render
:not_d

                    cmp        #'a'
                    bne        :not_a
                    dec        PlayerX
                    bpl        *+5
                    jsr        TransitionLeft

                pea   HERO_SLOT
                pea   SPRITE_HFLIP
                pea   HERO_SIDE_VBUFF
                _GTEUpdateSprite
                    
                    bra        :do_render
:not_a

                    cmp        #'s'
                    bne        :not_s
                    inc        PlayerY

                pea   HERO_SLOT
                pea   $0000
                pea   HERO_DOWN_VBUFF
                _GTEUpdateSprite
                    bra        :do_render
:not_s

                    cmp        #'w'
                    bne        :not_w
                    dec        PlayerY
                pea   HERO_SLOT
                pea   $0000
                pea   HERO_UP_VBUFF
                _GTEUpdateSprite
                    bra        :do_render
:not_w

:do_render
                pea        HERO_SLOT
                lda        PlayerX
                pha
                lda        PlayerY
                pha
                _GTEMoveSprite 

; Based on the frame count, move an oktorok

;                jsr        _GetVBLTicks
;                pha
;                and        #$0003
;                asl
;                tax

;                    pla
;                    and        #$007C
;                    lsr
;                    tay

;                    lda        OktorokX,x
;                    clc
;                    adc        OktorokDelta,y

;                    phx

;                    ldy        OktorokY,x
;                    tax
;                    pla
;                    inc
;                    inc
;                    jsl        MoveSprite


; Let's see what it looks like!

;                    lda        vsync
;                    beq        :no_vsync
;:vsyncloop          jsl        GetVerticalCounter     ; 8-bit value
;                    cmp        ScreenY0
;                    bcc        :vsyncloop
;                    sec
;                    sbc        ScreenY0
;                    cmp        #4
;                    bcs        :vsyncloop             ; Wait until we're within the top 8 scanlines
;                    lda        #1
;                    jsl        SetBorderColor
;:no_vsync
                    _GTERenderDirty
    
;                    lda        vsync
;                    beq        :no_vsync2
;                    lda        #0
;                    jsl        SetBorderColor
:no_vsync2
                    brl        EvtLoop

; Exit code
Exit
                    _GTEShutDown

                    _QuitGS    qtRec

                    bcs        Fatal
Fatal               brk        $00

TransitionRight
                    lda        MapScreenX           ; Only two screens
                    cmp        #1
                    bcs        :done

                    lda        StartX               ; Scroll 128 bytes to the right
                    clc
                    adc        #128
                    sta        TransitionX

:loop               lda        StartX
                    cmp        TransitionX
                    bcs        :out
                    clc
                    adc        #4
                    pha
                    lda        StartY
                    pha
                    _GTESetBG0Origin

                    lda        PlayerX
                    sec
                    sbc        #4
                    bmi        :nosprite
                    sta        PlayerX

                    pea        HERO_SLOT
                    lda        PlayerX
                    pha
                    lda        PlayerY
                    pha
                    _GTEMoveSprite
:nosprite

                    _GTERender                      ; Do full renders since the playfield is scrolling
                    bra        :loop
:out

                    lda        #0                   ; Move the player back to the left edge
                    sta        PlayerX
                    inc        MapScreenX           ; Move the index to the next screen
:done
                    rts


TransitionLeft
                    lda        MapScreenX
                    cmp        #0
                    beq        :done

                    lda        StartX               ; Scroll 128 bytes to the left
                    sec
                    sbc        #128
                    sta        TransitionX

:loop               lda        StartX
                    cmp        TransitionX
                    beq        :out
                    sec
                    sbc        #4
                    pha
                    pei        StartY
                    _GTESetBG0Origin

                    lda        PlayerX
                    clc
                    adc        #4
                    cmp        #128-8+1
                    bcs        :nosprite
                    sta        PlayerX

                    pea        HERO_SLOT
                    lda        PlayerX
                    pha
                    lda        PlayerY
                    pha
                    _GTEMoveSprite
:nosprite

                    _GTERender
                    bra        :loop
:out
;                    lda        #128-8                   ; Move the player back to the right edge
;                    sta        PlayerX
                    dec        MapScreenX           ; Move the index to the next screen
:done
                    rts 

ToolPath        str   '1/Tool160'
MyUserId            ds         2
; Color palette
;MyPalette           dw         $068F,$0EDA,$0000,$0000,$0BF1,$00A0,$0EEE,$0456,$0FA4,$0F59,$0E30,$01CE,$02E3,$0870,$0F93,$0FD7
MyPalette           dw         $0FDA,$08C1,$0C41,$0F93,$0777,$0FDA,$00A0,$0000,$0D20,$0FFF,$023E,$01CE,$02E3,$0870,$0F93,$0FD7

MapScreenX          ds         2
MapScreenY          ds         2

PlayerID            ds         2
PlayerX             ds         2
PlayerY             ds         2

OktorokX            dw         32,32,96,96
OktorokY            dw         48,96,56,72
OktorokDelta        dw         0,1,2,3,4,5,6,7,6,5,4,3,2,1,0,-1,-2,-3,-4,-5,-6,-7,-8,-7,-6,-5,-4,-3,-2,-1,0,0,0
TransitionX         ds         2
TransitionY         ds         2

oldOneSecondCounter  ds    2
frameCount           ds    2

qtRec               adrl       $0000
                    da         $00

vsync               dw         $8000

_GetVBLTicks
                PushLong  #0
                _GetTick
                pla
                plx
                rts

; Load the GTE User Tool and install it
GTEStartUp
                pea   $0000
                _LoaderStatus
                pla

                pea   $0000
                pea   $0000
                pea   $0000
                pea   $0000
                pea   $0000                   ; result space

                lda   MyUserId
                pha

                pea   #^ToolPath
                pea   #ToolPath
                pea   $0001                   ; do not load into special memory
                _InitialLoad
                bcc    :ok1
                brk    $01

:ok1
                ply
                pla                           ; Address of the loaded tool
                plx
                ply
                ply

                pea   $8000                   ; User toolset
                pea   $00A0                   ; Set the tool set number
                phx
                pha                           ; Address of function pointer table
                _SetTSPtr
                bcc    :ok2
                brk    $02

:ok2
                clc                             ; Give GTE a page of direct page memory
                tdc
                adc   #$0100
                pha
                pea   #0                        ; Fast Mode
                lda   MyUserId                  ; Pass the userId for memory allocation
                pha
                _GTEStartUp
                bcc    :ok3
                brk    $03

:ok3
                rts
    
                    PUT        gen/App.TileMapBG0.s

ANGLEBNK            ENT
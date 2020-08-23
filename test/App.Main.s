; Test program for graphics stufff...

                     rel

                     use        Util.Macs.s
                     use        Locator.Macs.s
                     use        Mem.Macs.s
                     use        Misc.Macs.s
                     put        ..\macros\App.Macs.s
                     put        ..\macros\EDS.GSOS.MACS.s

                     mx         %00

SHADOW_REG           equ        $E0C035
NEW_VIDEO_REG        equ        $E0C029
BORDER_REG           equ        $E0C034           ; 0-3 = border 4-7 Text color
VBL_VERT_REG         equ        $E0C02E
VBL_HORZ_REG         equ        $E0C02F

KBD_REG              equ        $E0C000
KBD_STROBE_REG       equ        $E0C010
VBL_STATE_REG        equ        $E0C019

; Typical init

                     phk
                     plb

; Tool startup

                     _TLStartUp                   ; normal tool initialization
                     pha
                     _MMStartUp
                     _Err                         ; should never happen
                     pla
                     sta        MasterId          ; our master handle references the memory allocated to us
                     ora        #$0100            ; set auxID = $01  (valid values $01-0f)
                     sta        UserId            ; any memory we request must use our own id 

                     _MTStartUp

; Install interrupt handlers

                     PushLong   #0
                     pea        $0015             ; Get the existing 1-second interrupt handler and save
                     _GetVector
                     PullLong   OldOneSecVec

                     pea        $0015             ; Set the new handler and enable interrupts
                     PushLong   #OneSecHandler
                     _SetVector

                     pea        $0006
                     _IntSource

                     PushLong   #VBLTASK          ; Also register a Heart Beat Task
                     _SetHeartBeat

; Start up the graphics engine...

                     jsr        MemInit

                     lda        BlitBuff+2        ; Fill in this bank
                     jsr        BuildBank

; Load a picture and copy it into Bank $E1.  Then turn on the screen.

                     jsr        AllocOneBank      ; Alloc 64KB for Load/Unpack
                     sta        BankLoad          ; Store "Bank Pointer"

                     jsr        GrafOn

EvtLoop
                     jsr        WaitForKey
                     cmp        #'q'
                     bne        :1
                     brl        Exit
:1                   cmp        #'l'
                     bne        :2
                     brl        DoLoadPic
:2                   cmp        #'m'
                     beq        DoMessage
                     bra        EvtLoop

HexToChar            dfb        '0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F'
DoMessage
                     sep        #$20
                     ldx        #0
                     lda        BlitBuff+2
                     and        #$F0
                     lsr
                     lsr
                     lsr
                     lsr
                     tax
                     lda        HexToChar,x
                     sta        Hello+1

                     lda        BlitBuff+2
                     and        #$0F
                     tax
                     lda        HexToChar,x
                     sta        Hello+2

                     lda        BlitBuff+1
                     and        #$F0
                     lsr
                     lsr
                     lsr
                     lsr
                     tax
                     lda        HexToChar,x
                     sta        Hello+4

                     lda        BlitBuff+1
                     and        #$0F
                     tax
                     lda        HexToChar,x
                     sta        Hello+5

                     lda        BlitBuff
                     and        #$F0
                     lsr
                     lsr
                     lsr
                     lsr
                     tax
                     lda        HexToChar,x
                     sta        Hello+6

                     lda        BlitBuff
                     and        #$0F
                     tax
                     lda        HexToChar,x
                     sta        Hello+7

                     rep        #$20

                     lda        #Hello
                     ldx        #{60*160+30}
                     ldy        #$7777
                     jsr        DrawString
                     jmp        EvtLoop

DoLoadPic
                     lda        BankLoad
                     ldx        #ImageName        ; Load+Unpack Boot Picture
                     jsr        LoadPicture       ; X=Name, A=Bank to use for loading

                     lda        BankLoad          ; get address of loaded/uncompressed picture
                     clc
                     adc        #$0080            ; skip header? 
                     sta        :copySHR+2        ;  and store that over the 'ldal' address below
                     ldx        #$7FFE            ; copy all image data
:copySHR             ldal       $000000,x         ; load from BankLoad we allocated
                     stal       $E12000,x         ; store to SHR screen
                     dex
                     dex
                     bpl        :copySHR
                     jmp        EvtLoop

Exit
                     pea        $0007             ; disable 1-second interrupts
                     _IntSource

                     PushLong   #VBLTASK          ; Remove our heartbeat task
                     _DelHeartBeat

                     pea        $0015
                     PushLong   OldOneSecVec      ; Reset the interrupt vector
                     _SetVector

                     PushWord   UserId            ; Deallocate all of our memory
                     _DisposeAll

                     _QuitGS    qtRec

                     bcs        Fatal
Fatal                brk        $00

Hello                str        '00/0000'

****************************************
* Fatal Error Handler                  *
****************************************
PgmDeath             tax
                     pla
                     inc
                     phx
                     phk
                     pha
                     bra        ContDeath
PgmDeath0            pha
                     pea        $0000
                     pea        $0000
ContDeath            ldx        #$1503
                     jsl        $E10000

; Interrupt handlers. We install a heartbeat (1/60th second and a 1-second timer)
OneSecHandler        mx         %11
                     phb
                     pha
                     phk
                     plb

                     rep        #$20
                     inc        OneSecondCounter
                     sep        #$20

                     ldal       $E0C032
                     and        #%10111111        ;clear IRQ source
                     stal       $E0C032

                     pla
                     plb
                     clc
                     rtl
                     mx         %00
OneSecondCounter     dw         0
OldOneSecVec         ds         4

VBLTASK              hex        00000000
                     dw         0
                     hex        5AA5


; Graphic screen initialization

GrafInit             ldx        #$7FFE
                     lda        #0000
:loop                stal       $E12000,x
                     dex
                     dex
                     bne        :loop
                     rts

; Return the current border color ($0 - $F) in the accumulator
GetBorderColor       lda        #0000
                     sep        #$20
                     ldal       BORDER_REG
                     and        #$0F
                     rep        #$20
                     rts

; Set the border color to the accumulator value.
SetBorderColor       sep        #$20              ; ACC = $X_Y, REG = $W_Z
                     eorl       BORDER_REG        ; ACC = $(X^Y)_(Y^Z)
                     and        #$0F              ; ACC = $0_(Y^Z)
                     eorl       BORDER_REG        ; ACC = $W_(Y^Z^Z) = $W_Y
                     stal       BORDER_REG
                     rep        #$20
                     rts

; Turn SHR screen On/Off
GrafOn               sep        #$20
                     lda        #$81
                     stal       NEW_VIDEO_REG
                     rep        #$20
                     rts

GrafOff              sep        #$20
                     lda        #$01
                     stal       NEW_VIDEO_REG
                     rep        #$20
                     rts

; Enable/Disable Shadowing.
ShadowOn             sep        #$20
                     ldal       SHADOW_REG
                     and        #$F7
                     stal       SHADOW_REG
                     rep        #$20
                     rts

ShadowOff            sep        #$20
                     ldal       SHADOW_REG
                     ora        #$08
                     stal       SHADOW_REG
                     rep        #$20
                     rts

GetVBL               sep        #$20
                     ldal       VBL_HORZ_REG
                     asl
                     ldal       VBL_VERT_REG
                     rol                          ; put V5 into carry bit, if needed. See TN #39 for details.
                     rep        #$20
                     and        #$00FF
                     rts

WaitForVBL           sep        #$20
:wait1               ldal       VBL_STATE_REG     ; If we are already in VBL, then wait
                     bmi        :wait1
:wait2               ldal       VBL_STATE_REG
                     bpl        :wait2            ; spin until transition into VBL
                     rep        #$20
                     rts

WaitForKey           sep        #$20
                     stal       KBD_STROBE_REG    ; clear the strobe
:WFK                 ldal       KBD_REG
                     bpl        :WFK
                     rep        #$20
                     and        #$007F
                     rts

ClearKeyboardStrobe  sep        #$20
                     stal       KBD_STROBE_REG
                     rep        #$20
                     rts

; Graphics helpers

LoadPicture
                     jsr        LoadFile          ; X=Nom Image, A=Banc de chargement XX/00
                     bcc        :loadOK
                     rts
:loadOK
                     jsr        UnpackPicture     ; A=Packed Size
                     rts


UnpackPicture        sta        UP_PackedSize     ; Size of Packed Data
                     lda        #$8000            ; Size of output Data Buffer
                     sta        UP_UnPackedSize
                     lda        BankLoad          ; Banc de chargement / Decompression
                     sta        UP_Packed+1       ; Packed Data
                     clc
                     adc        #$0080
                     stz        UP_UnPacked       ; On remet a zero car modifie par l'appel
                     stz        UP_UnPacked+2
                     sta        UP_UnPacked+1     ; Unpacked Data buffer

                     PushWord   #0                ; Space for Result : Number of bytes unpacked 
                     PushLong   UP_Packed         ; Pointer to buffer containing the packed data
                     PushWord   UP_PackedSize     ; Size of the Packed Data
                     PushLong   #UP_UnPacked      ; Pointer to Pointer to unpacked buffer
                     PushLong   #UP_UnPackedSize  ; Pointer to a Word containing size of unpacked data
                     _UnPackBytes
                     pla                          ; Number of byte unpacked
                     rts

UP_Packed            hex        00000000          ; Address of Packed Data
UP_PackedSize        hex        0000              ; Size of Packed Data
UP_UnPacked          hex        00000000          ; Address of Unpacked Data Buffer (modified)
UP_UnPackedSize      hex        0000              ; Size of Unpacked Data Buffer (modified)

; Basic I/O function to load files

LoadFile             stx        openRec+4         ; X=File, A=Bank/Page XX/00
                     sta        readRec+5

:openFile            _OpenGS    openRec
                     bcs        :openReadErr
                     lda        openRec+2
                     sta        eofRec+2
                     sta        readRec+2

                     _GetEOFGS  eofRec
                     lda        eofRec+4
                     sta        readRec+8
                     lda        eofRec+6
                     sta        readRec+10

                     _ReadGS    readRec
                     bcs        :openReadErr

:closeFile           _CloseGS   closeRec
                     clc
                     lda        eofRec+4          ; File Size
                     rts

:openReadErr         jsr        :closeFile
                     nop
                     nop

                     PushWord   #0
                     PushLong   #msgLine1
                     PushLong   #msgLine2
                     PushLong   #msgLine3
                     PushLong   #msgLine4
                     _TLTextMountVolume
                     pla
                     cmp        #1
                     bne        :loadFileErr
                     brl        :openFile
:loadFileErr         sec
                     rts

msgLine1             str        'Unable to load File'
msgLine2             str        'Press a key :'
msgLine3             str        ' -> Return to Try Again'
msgLine4             str        ' -> Esc to Quit'

; Data storage
ImageName            strl       '1/test.pic'
MasterId             ds         2
UserId               ds         2
BankLoad             hex        0000

openRec              dw         2                 ; pCount
                     ds         2                 ; refNum
                     adrl       ImageName         ; pathname

eofRec               dw         2                 ; pCount
                     ds         2                 ; refNum
                     ds         4                 ; eof

readRec              dw         4                 ; pCount
                     ds         2                 ; refNum
                     ds         4                 ; dataBuffer
                     ds         4                 ; requestCount
                     ds         4                 ; transferCount

closeRec             dw         1                 ; pCount
                     ds         2                 ; refNum

qtRec                adrl       $0000
                     da         $00

                     put        App.Init.s
                     put        font.s
                     put        blitter/Template.s
                     put        blitter/Tables.s

                     lda        #BG1_ADDR



















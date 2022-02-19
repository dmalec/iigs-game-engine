; Collection of data tables
;

; Col2CodeOffset
;
; Takes a column number (0 - 81) and returns the offset into the blitter code
; template.
;
; This is used for rendering tile data into the code field. For example, is we assume that
; we are filling in the operands for a bunch of PEA values, we could do this
;
;  ldy tileColumn*2
;  lda #DATA
;  ldx Col2CodeOffset,y
;  sta $0001,x 
;
; The table values are pre-reversed so that loop can go in logical order 0, 2, 4, ...
; and the resulting offsets will map to the code instructions in right-to-left order.
;
; Remember, because the data is pushed on to the stack, the last instruction, which is
; in the highest memory location, pushed data that apepars on the left edge of the screen.
PER_TILE_SIZE     equ   3
]step             equ   0

                  dw    CODE_TOP    ; There is a spot where we load Col2CodeOffet-2,x
Col2CodeOffset    lup   82
                  dw    CODE_TOP+{{81-]step}*PER_TILE_SIZE}
]step             equ   ]step+1
                  --^
                  dw    CODE_TOP+{81*PER_TILE_SIZE}

; A parallel table to Col2CodeOffset that holds the offset to the exception handler address for each column
SNIPPET_SIZE      equ   32
]step             equ   0
                  dw    SNIPPET_BASE
JTableOffset      lup   82
                  dw    SNIPPET_BASE+{{81-]step}*SNIPPET_SIZE}
]step             equ   ]step+1
                  --^
                  dw    SNIPPET_BASE+{81*SNIPPET_SIZE}

; Table of BRA instructions that are used to exit the code field.  Separate tables for
; even and odd aligned cases.
;
; The even exit point is closest to the code field. The odd exit point is 3 bytes further
;
; These tables are reversed to be parallel with the JTableOffset and Col2CodeOffset tables above.  The
; physical word index that each instruction is intended to be placed at is in the comment.
CodeFieldEvenBRA
                  bra   *+6         ; 81 -- need to skip over the JMP loop that passed control back
                  bra   *+9         ; 80
                  bra   *+12        ; 79
                  bra   *+15        ; 78
                  bra   *+18        ; 77
                  bra   *+21        ; 76
                  bra   *+24        ; 75
                  bra   *+27        ; 74
                  bra   *+30        ; 73
                  bra   *+33        ; 72
                  bra   *+36        ; 71
                  bra   *+39        ; 70
                  bra   *+42        ; 69
                  bra   *+45        ; 68
                  bra   *+48        ; 67
                  bra   *+51        ; 66
                  bra   *+54        ; 65
                  bra   *+57        ; 64
                  bra   *+60        ; 63
                  bra   *+63        ; 62
                  bra   *+66        ; 61
                  bra   *+69        ; 60
                  bra   *+72        ; 59
                  bra   *+75        ; 58
                  bra   *+78        ; 57
                  bra   *+81        ; 56
                  bra   *+84        ; 55
                  bra   *+87        ; 54
                  bra   *+90        ; 53
                  bra   *+93        ; 52
                  bra   *+96        ; 51
                  bra   *+99        ; 50
                  bra   *+102       ; 49
                  bra   *+105       ; 48
                  bra   *+108       ; 47
                  bra   *+111       ; 46
                  bra   *+114       ; 45
                  bra   *+117       ; 44
                  bra   *+120       ; 43
                  bra   *+123       ; 42
                  bra   *+126       ; 41
                  bra   *-123       ; 40
                  bra   *-120       ; 39
                  bra   *-117       ; 38
                  bra   *-114       ; 37
                  bra   *-111       ; 36
                  bra   *-108       ; 35
                  bra   *-105       ; 34
                  bra   *-102       ; 33
                  bra   *-99        ; 32
                  bra   *-96        ; 31
                  bra   *-93        ; 30
                  bra   *-90        ; 29
                  bra   *-87        ; 28
                  bra   *-84        ; 27
                  bra   *-81        ; 26
                  bra   *-78        ; 25
                  bra   *-75        ; 24
                  bra   *-72        ; 23
                  bra   *-69        ; 22
                  bra   *-66        ; 21
                  bra   *-63        ; 20
                  bra   *-60        ; 19
                  bra   *-57        ; 18
                  bra   *-54        ; 17
                  bra   *-51        ; 16
                  bra   *-48        ; 15
                  bra   *-45        ; 14
                  bra   *-42        ; 13
                  bra   *-39        ; 12
                  bra   *-36        ; 11
                  bra   *-33        ; 10
                  bra   *-30        ; 9
                  bra   *-27        ; 8
                  bra   *-24        ; 7
                  bra   *-21        ; 6
                  bra   *-18        ; 5
                  bra   *-15        ; 4
                  bra   *-12        ; 3
                  bra   *-9         ; 2
                  bra   *-6         ; 1
                  bra   *-3         ; 0

CodeFieldOddBRA
                  bra   *+9         ; 81 -- need to skip over two JMP instructions
                  bra   *+12        ; 80
                  bra   *+15        ; 79
                  bra   *+18        ; 78
                  bra   *+21        ; 77
                  bra   *+24        ; 76
                  bra   *+27        ; 75
                  bra   *+30        ; 74
                  bra   *+33        ; 73
                  bra   *+36        ; 72
                  bra   *+39        ; 71
                  bra   *+42        ; 70
                  bra   *+45        ; 69
                  bra   *+48        ; 68
                  bra   *+51        ; 67
                  bra   *+54        ; 66
                  bra   *+57        ; 65
                  bra   *+60        ; 64
                  bra   *+63        ; 64
                  bra   *+66        ; 62
                  bra   *+69        ; 61
                  bra   *+72        ; 60
                  bra   *+75        ; 59
                  bra   *+78        ; 58
                  bra   *+81        ; 57
                  bra   *+84        ; 56
                  bra   *+87        ; 55
                  bra   *+90        ; 54
                  bra   *+93        ; 53
                  bra   *+96        ; 52
                  bra   *+99        ; 51
                  bra   *+102       ; 50
                  bra   *+105       ; 49
                  bra   *+108       ; 48
                  bra   *+111       ; 47
                  bra   *+114       ; 46
                  bra   *+117       ; 45
                  bra   *+120       ; 44
                  bra   *+123       ; 43
                  bra   *+126       ; 42
                  bra   *+129       ; 41
                  bra   *-126       ; 40
                  bra   *-123       ; 39
                  bra   *-120       ; 38
                  bra   *-117       ; 37
                  bra   *-114       ; 36
                  bra   *-111       ; 35
                  bra   *-108       ; 34
                  bra   *-105       ; 33
                  bra   *-102       ; 32
                  bra   *-99        ; 31
                  bra   *-96        ; 30
                  bra   *-93        ; 29
                  bra   *-90        ; 28
                  bra   *-87        ; 27
                  bra   *-84        ; 26
                  bra   *-81        ; 25
                  bra   *-78        ; 24
                  bra   *-75        ; 23
                  bra   *-72        ; 22
                  bra   *-69        ; 21
                  bra   *-66        ; 20
                  bra   *-63        ; 19
                  bra   *-60        ; 18
                  bra   *-57        ; 17
                  bra   *-54        ; 16
                  bra   *-51        ; 15
                  bra   *-48        ; 14
                  bra   *-45        ; 13
                  bra   *-42        ; 12
                  bra   *-39        ; 11
                  bra   *-36        ; 10
                  bra   *-33        ; 9
                  bra   *-30        ; 8
                  bra   *-27        ; 7
                  bra   *-24        ; 6
                  bra   *-21        ; 5
                  bra   *-18        ; 4
                  bra   *-15        ; 3
                  bra   *-12        ; 2
                  bra   *-9         ; 1
                  bra   *-6         ; 0 -- branch back 6 to skip the JMP even path

]step             equ   $2000
ScreenAddr        ENT
                  lup   200
                  dw    ]step
]step             =     ]step+160
                  --^

; Table of offsets into each row of a Tile Store table.  We currently have two tables defined; one
; that is the backing store for the tiles rendered into the code field, and another that holds 
; backlink information on the sprite entries that overlap various tiles.
;
; This table is double-length to support accessing off the end modulo its legth
TileStoreYTable   ENT
]step             equ   0
                  lup   26
                  dw    ]step
]step             =     ]step+{41*2}
                  --^
]step             equ   0
                  lup   26
                  dw    ]step
]step             =     ]step+{41*2}
                  --^

; Create a table to look up the "next" column with modulo wraparound.  Basically a[i] = i
; and the table is double-length.  Use constant offsets to pick an amount to advance
NextCol
]step             equ   0
                  lup   41
                  dw    ]step
]step             =     ]step+2
                  --^
]step             equ   0
                  lup   41
                  dw    ]step
]step             =     ]step+2
                  --^

; A double-sized table of lookup values.  This is basically the cross-product of TileStoreYTable and
; NextCol.  If is double-width and double-height so that, if we know a tile's address position
; of (X + 41*Y), then any relative tile store address can be looked up by adding a constan value.
;TileStore2DLookup ds    {26*41*2}*4

; This is a double-length table that holds the right-edge adresses of the playfield on the physical
; screen.  At most, it needs to hold 200 addresses for a full height playfield.  It is double-length
; so that code can pick any offset and copy values without needing to check for a wrap-around. If the
; playfield is less than 200 lines tall, then any values after 2 * PLAYFIELD_HEIGHT are undefined.
RTable            ds    400
                  ds    400

; Array of addresses for the banks that hold the blitter. 
BlitBuff          ENT
                  ds    4*13

; The blitter table (BTable) is a double-length table that holds the full 4-byte address of each
; line of the blit fields.  We decompose arrays of pointers into separate high and low words so
; that everything can use the same indexing offsets
BTableHigh        ds    208*2*2
BTableLow         ds    208*2*2

; A shorter table that just holds the blitter row addresses
BRowTableHigh     ds    26*2*2
BRowTableLow      ds    26*2*2

; A double-length table of addresses for the BG1 bank.  The BG1 buffer is 208 rows of 256 bytes each and
; the first row starts $1800 bytes in to center the buffer in the bank
]step             equ   $1800
BG1YTable         lup   208
                  dw    ]step
]step             =     ]step+256
                  --^
]step             equ   256
                  lup   208
                  dw    ]step
]step             =     ]step+256
                  --^

; Repeat
BG1YOffsetTable   lup   26
                  dw    1,1,1,2,2,2,2,2,1,1,1,0,0,0,0,0
                  --^






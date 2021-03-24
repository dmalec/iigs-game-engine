; Initialize the system for fun!
;
; Mostly memory allocation
;
; * 13 banks of memory for the blitter
; *  1 bank of memory for the second background
; *  1 bank of memory for the second background mask
;
; * $01/2000 - $01/9FFF for the shadow screen
; * $00/2000 - $00/9FFF for the fixed background
;
; * 10 pages of direct page in Bank $00
;   - 1 page for scratch space
;   - 1 page for pointer to the second background
;   - 8 pages for the dynamic tiles

               mx        %00

MemInit        PushLong  #0                   ; space for result
               PushLong  #$008000             ; size (32k)
               PushWord  UserId
               PushWord  #%11000000_00010111  ; Fixed location
               PushLong  #$002000
               _NewHandle                     ; returns LONG Handle on stack
               plx                            ; base address of the new handle
               pla                            ; high address 00XX of the new handle (bank)
               _Deref
               stx       Buff00
               sta       Buff00+2

               PushLong  #0                   ; space for result
               PushLong  #$008000             ; size (32k)
               PushWord  UserId
               PushWord  #%11000000_00010111  ; Fixed location
               PushLong  #$012000
               _NewHandle                     ; returns LONG Handle on stack
               plx                            ; base address of the new handle
               pla                            ; high address 00XX of the new handle (bank)
               _Deref
               stx       Buff01
               sta       Buff01+2

               PushLong  #0                   ; space for result
               PushLong  #$000A00             ; size (10 pages)
               PushWord  UserId
               PushWord  #%11000000_00010101  ; Page-aligned, fixed bank
               PushLong  #$000000
               _NewHandle                     ; returns LONG Handle on stack
               plx                            ; base address of the new handle
               pla                            ; high address 00XX of the new handle (bank)
               _Deref
               stx       ZeroPage
               sta       ZeroPage+2

; Allocate the 13 banks of memory we need and store in double-length array
]step          equ       0
               lup       13
               jsr       AllocOneBank2
               sta       BlitBuff+]step+2
               sta       BlitBuffMid+]step+2
               stz       BlitBuff+]step
               stz       BlitBuffMid+]step
]step          equ       ]step+4
               --^

               rts

Buff00         ds        4
Buff01         ds        4
ZeroPage       ds        4

; Array of addressed for the banks that hold the blitter.  This is actually a double-length
; array, which is a pattern that is used a lot in GTE.  Whenever we have a situation where
; we need to wrap around an array, we can to this be doubling the array length and using an
; unrolled loop that starts in the middle instead of doing some kind of "mod N" or loop
; splitting.
BlitBuff       ds        4*13
BlitBuffMid    ds        4*13

; Bank allocator (for one full, fixed bank of memory. Can be immediately deferenced)

AllocOneBank   PushLong  #0
               PushLong  #$10000
               PushWord  UserId
               PushWord  #%11000000_00011100
               PushLong  #0
               _NewHandle                     ; returns LONG Handle on stack
               plx                            ; base address of the new handle
               pla                            ; high address 00XX of the new handle (bank)
               xba                            ; swap accumulator bytes to XX00	
               sta       :bank+2              ; store as bank for next op (overwrite $XX00)
:bank          ldal      $000001,X            ; recover the bank address in A=XX/00	
               rts

; Variation that return pointer in the X/A registers (X = low, A = high)
AllocOneBank2  PushLong  #0
               PushLong  #$10000
               PushWord  UserId
               PushWord  #%11000000_00011100
               PushLong  #0
               _NewHandle
               plx                            ; base address of the new handle
               pla                            ; high address 00XX of the new handle (bank)
               _Deref
               rts

; Set up the interrupts
;
; oldOneVect = GetVector( oneSecHnd );
; SetVector( oneSecHnd, (Pointer) ONEHANDLER );
; IntSource( oSecEnable );
;  SetHeartBeat( VBLTASK );
IntInit        rts


; IntSource( oSecDisable );		/* disable one second interrupts */
; SetVector( oneSecHnd, oldOneVect );   /* reset to the old handler */
ShutDown       rts

































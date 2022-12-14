.SETCPU "65c02"

; Kernal Routines and VERA registers ;

RAM_BANK = $00
ROM_BANK = $01

SETLFS = $FFBA 
SETNAM = $FFBD 
LOAD = $FFD5

OPEN = $FFC0
CHKIN = $FFC6
GETIN = $FFE4
CLOSE = $FFC3

RDTIM = $FFDE

MACPTR = $FF44
ACPTR = $FFA5

VERA_LOADDR = $9F20
VERA_HIADDR = $9F21
VERA_AUTOINC = $9F22 
VERA_DATA = $9F23
VERA_AUDIO_CTRL = $9F3B
VERA_AUDIO_RATE = $9F3C
VERA_AUDIO_DATA = $9F3D

IMAGE_WIDTH = 80
IMAGE_HEIGHT = 60

.SEGMENT "INIT"
.SEGMENT "STARTUP"
.SEGMENT "ONCE"
	jmp setup

audio_filename:
	.byte "apple.raw"
audio_filename_end:

Default_irq_handler:
	.word 0
frame_counter:
	.byte 0
current_color:
	.byte 0

vram_mapstart:
	.byte 0

.macro inc_index
	inc $20
	bne :+
	inc $21
	:
.endmacro

audio_ptr = $18

.macro inc_bank_pointer pointer
	inc pointer
	bne :++
	lda pointer + 1
	inc A
	cmp #$C0 
	bcc :+
	lda #$A0
	inc RAM_BANK
	:
	sta pointer + 1
	:
.endmacro

setup:
	jsr open_audio_file
	
	lda #$40
	sta vram_mapstart
	
	stz $9F25
	
	lda #128
	sta $9F2A 
	sta $9F2B
	
	lda $9F36
	sta $9F2F
	lda $9F34
	sta $9F2D
	
	stz $9F30
	stz $9F31
	stz $9F32
	stz $9F33
	
	stz vram_mapstart
	stz $9F2E
	
	; enable layer 0, disable layer 1
	lda $9F29
	ora #%00010000
	and #%11011111
	sta $9F29
	
	; modify audio registers ;
	stz VERA_AUDIO_RATE
	lda #128
	sta VERA_AUDIO_CTRL
	
	lda #$0F ; max volume ; 8 bit mono ;
	sta VERA_AUDIO_CTRL
	
	
	; clear screen ;
	lda #$00
	sta VERA_LOADDR
	lda #0
	sta VERA_HIADDR 
	lda #$10
	sta VERA_AUTOINC
	ldy #$40 + IMAGE_HEIGHT
	
	:
	ldx #0
	stx VERA_LOADDR 
	ldx #IMAGE_WIDTH
	:
	lda #$20
	sta VERA_DATA 
	lda #$01
	sta VERA_DATA
	dex 
	bne :-
	inc VERA_HIADDR 
	dey 
	bne :--

	lda #16
	sta VERA_AUDIO_RATE
	jsr update_audio
	
	jsr preserve_default_irq
	jsr set_custom_irq_handler
		
	jsr open_video_file
@changed_loop:
	jsr load_video_data
	lda #<video_data_start 
	sta $20
	lda #>video_data_start 
	sta $21
	
@draw_frame:
	jsr frame
	
	lda vram_mapstart
	lsr 
	sta $9F2E
	lda vram_mapstart
	beq :+
	lda #0
	sta vram_mapstart
	jmp :++
	:
	lda #$40
	sta vram_mapstart
	:
	
	lda need_fill_audio
	beq :+
	jsr update_audio
	:
	
	jsr wait_for_vera_interrupt
	jmp @changed_loop

wait_for_vera_interrupt:
	stz vera_interrupt_triggered
	:
	lda vera_interrupt_triggered
	beq :-
	rts
	
vera_interrupt_triggered:
	.byte 0
need_fill_audio:
	.byte 0


	; lda #16 ; 6103.5 Hz 
	; sta VERA_AUDIO_RATE ; start playback of audio

frame:	
	lda #$20
	sta VERA_AUTOINC
	sta current_color

	stz VERA_LOADDR
	ldy vram_mapstart
	sty VERA_HIADDR
outer_loop:	
	lda ( $20 )
	beq done
	cmp #$FF 
	beq end 
	tax
	
	inx
inner_loop:
	dex
	beq done 
	
	lda current_color
	sta VERA_DATA 
	lda VERA_LOADDR 
	cmp #IMAGE_WIDTH * 2
	bcc inner_loop
	
	stz VERA_LOADDR
	lda VERA_HIADDR
	inc A 
	sta VERA_HIADDR
	sec 
	sbc vram_mapstart
	cmp #IMAGE_HEIGHT
	bcs end 
	
	jmp inner_loop
done:
	lda current_color
	eor #$80
	sta current_color

	inc_index
	jmp outer_loop
end:
	inc_index
	
	rts

open_audio_file:
	lda #audio_filename_end - audio_filename
	ldx #<audio_filename
	ldy #>audio_filename
	jsr SETNAM 
	
	lda #0 
	ldx #8
	ldy #2
	jsr SETLFS
	
	lda #0
	ldx #<$A000
	ldy #>$A000
	jsr LOAD
	
	; setup audio ptr to read from ;
	ldx #<$A000
	stx audio_ptr
	ldy #>$A000
	sty audio_ptr + 1
	;stp
	lda #1
	sta RAM_BANK
	
	rts

open_video_file:
	lda #video_combined_filename_end - video_combined_filename
	ldx #<video_combined_filename
	ldy #>video_combined_filename
	jsr SETNAM 

	lda #12
	ldx #8 
	ldy #12
	jsr SETLFS

	jsr OPEN
	
	rts 

video_combined_filename:
	.byte "apple.vid"
video_combined_filename_end:

FRAME_DATASIZE = 442

load_video_data:
	ldx #12
	jsr CHKIN 
	
	jsr ACPTR
	sta @byte_load_first
	sta $02
	
	jsr ACPTR 
	sta @byte_load_second
	sta $04
	
	ldx #<video_data_start
	ldy #>video_data_start
	lda @byte_load_first
	jsr MACPTR
	lda @byte_load_second
	beq :+ ; if 0 don't load
	ldx #<(video_data_start + 255)
	ldy #>(video_data_start + 255)
	jsr MACPTR
	:
	
	rts
@byte_load_first:
	.byte 0
@byte_load_second:
	.byte 0


update_audio:
	lda VERA_AUDIO_CTRL
	and #128
	bne @end_update_audio
	lda (audio_ptr), Y
	sta VERA_AUDIO_DATA
	
	inc_bank_pointer audio_ptr
	jmp update_audio
	
@end_update_audio:
	rts

preserve_default_irq:
    lda $0314
    sta Default_irq_handler
    lda $0315
    sta Default_irq_handler+1
	rts 
	
set_custom_irq_handler:
    sei
    lda #<custom_irq_handler
    sta $0314
    lda #>custom_irq_handler
    sta $0315
    cli
    rts

reset_irq_handler:
	sei
    lda Default_irq_handler
    sta $0314
    lda Default_irq_handler+1
    sta $0315
    cli
	rts

custom_irq_handler:
    lda $9F27
	ora $9F26 ; vsync comes from both
    and #$01
    beq @end_frame
    ; vsync ;
	lda frame_counter
	inc A
	sta frame_counter
	tax 
    and #%00000001
	bne @dec9F27
	; only draw every other frame ;
		
@draw_frame:
	lda #1
	sta vera_interrupt_triggered
@dec9F27:
	lda $9F27 
	ora #1
	sta $9F27
@end_frame:

	lda $9F26 
	ora $9F27 
	and #%00001000
	beq @fifo_done
	
	; fill fifo 
	lda #1
	sta need_fill_audio
	
@fifo_done:
    jmp (Default_irq_handler)



	

video_data_start = $1000
audio_data_start = $2000
AUDIO_END = audio_data_start + $1000

.SETCPU "65c02"

; Kernal Routines and VERA registers ;

SETLFS = $FFBA 
SETNAM = $FFBD 
LOAD = $FFD5

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

filename:
	.literal "OUT2PT/"
filename_numbers:
	.literal "0001.BIN"
filename_end:
audio_filename:
	.literal "SOUND/"
audio_filename_numbers:
	.literal "0001.RAW"
audio_filename_end:

Default_irq_handler:
	.word 0
frame_counter:
	.byte 0
current_color:
	.byte 0

vram_mapstart:
	.byte 0

.macro inc_string numbers
	ldx numbers+3
	inx 
	stx numbers+3
	cpx #$30 + 10 
	bcc :+
	
	ldy #$30
	sty numbers+3
	ldx numbers+2
	inx 
	stx numbers+2
	cpx #$30 + 10 
	bcc :+

	sty numbers+2
	ldx numbers+1
	inx 
	stx numbers+1
	cpx #$30 + 10 
	bcc :+

	sty numbers+1
	inc numbers

	ldx numbers
	cpx #$30 + 7
	bcc :+ 
	jsr reset_irq_handler
	
	:
	rts
.endmacro

setup:
	lda #$40
	sta vram_mapstart
	
	lda #0
	sta $9F25
	lda #128
	sta $9F2A 
	sta $9F2B
	
	lda #<video_data_start
	sta $20 
	lda #>video_data_start
	sta $21
	
	lda #0
	sta VERA_AUDIO_RATE
	lda #128
	sta VERA_AUDIO_CTRL
	
	jsr load_new_audio
	jsr update_audio
	lda #$0F ; max volume ; 8 bit mono ;
	sta VERA_AUDIO_CTRL
	lda #32
	sta VERA_AUDIO_RATE
	
	lda #$00
	sta VERA_LOADDR
	lda #0
	sta VERA_HIADDR 
	lda #$10
	sta VERA_AUTOINC
	ldy #$40 + IMAGE_HEIGHT
@fill_outer_loop:	
	ldx #0
	stx VERA_LOADDR 
	ldx #IMAGE_WIDTH
@fill_inner_loop:
	lda #$20
	sta VERA_DATA 
	lda #$01
	sta VERA_DATA
	dex 
	bne @fill_inner_loop
	inc VERA_HIADDR 
	dey 
	bne @fill_outer_loop

	jsr preserve_default_irq
	jsr set_custom_irq_handler

loop:
	jsr $FFE4 
	cmp #$20 
	beq :+
	lda #<custom_irq_handler
	cmp $0314
	bne :+ 
    lda #>custom_irq_handler
	cmp $0315
	beq loop
	:	
	jsr reset_irq_handler
	rts

frame:	
	lda #$20
	sta VERA_AUTOINC
	sta current_color
	ldy #0
	sty VERA_LOADDR
	ldy vram_mapstart
	sty VERA_HIADDR
outer_loop:	
	ldy #0
	lda ( $20 ), Y
	beq done
	cmp #$FF 
	beq end 
	tax 
inner_loop:
	cpx #0 
	beq done 
	dex 
	
	lda current_color
	sta VERA_DATA 
	lda VERA_LOADDR 
	cmp #IMAGE_WIDTH * 2
	bcc inner_loop
	lda #0
	sta VERA_LOADDR
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

	jsr inc_index
	jmp outer_loop
end:
	jsr inc_index
	rts

inc_index:
	inc $20
	bne :+
	inc $21
	:
	rts 

load_file:
	lda #filename_end - filename
	ldx #<filename
	ldy #>filename
	jsr SETNAM 

	lda #0
	ldx #8 
	ldy #1
	jsr SETLFS

	lda #0
	ldx #<video_data_start
	ldy #>video_data_start
	jsr LOAD
	
	rts 

load_new_audio:
	lda #audio_filename_end - audio_filename
	ldx #<audio_filename
	ldy #>audio_filename
	jsr SETNAM 

	lda #0
	ldx #8 
	ldy #1
	jsr SETLFS

	lda #0
	ldx #<audio_data_start
	stx $30
	ldy #>audio_data_start
	sty $31
	jsr LOAD

	inc_string audio_filename_numbers
	
	rts 
	
update_audio:
	ldy #0
@write:
	lda VERA_AUDIO_CTRL
	and #128
	bne :+
	lda ($30), Y
	sta VERA_AUDIO_DATA
	
	inc $30
	bne @write
	lda $31
	inc A 
	sta $31	
	cmp #$30
	bcc @write
	
	jsr load_new_audio
	
	jmp @write
@end_write:
	rts 

;display_filename_numbers:
;	lda #2
;	sta $9F20 
;	lda #32
;	sta $9F21
;	lda #$20
;	sta $9F22 
;	lda filename_numbers
;	sta $9F23 
;	lda filename_numbers+1
;	sta $9F23 
;	lda filename_numbers+2
;	sta $9F23 
;	lda filename_numbers+3
;	sta $9F23 
;	rts 

inc_framenumberstring:
	inc_string filename_numbers
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
    and #$01
    beq @end_frame
    ; vsync ;
	lda frame_counter
	inc A
	sta frame_counter
	tax 
    and #%00000001
	bne @dec9F27

	jsr load_file
	lda #<video_data_start 
	sta $20
	lda #>video_data_start 
	sta $21
	jsr inc_framenumberstring
	
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
	jsr update_audio
	
@fifo_done:
    jmp (Default_irq_handler)

video_data_start = $1000
audio_data_start = $2000
AUDIO_END = audio_data_start + $1000

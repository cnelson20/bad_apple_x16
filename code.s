.SETCPU "65c02"

; Kernal Routines and VERA registers ;

SETLFS = $FFBA 
SETNAM = $FFBD 
LOAD = $FFD5

VERA_LOADDR = $9F20
VERA_HIADDR = $9F21
VERA_AUTOINC = $9F22 
VERA_DATA = $9F23

IMAGE_WIDTH = 40
IMAGE_HEIGHT = 30

LOAD_AREA = $3000

.SEGMENT "INIT"
.SEGMENT "STARTUP"
.SEGMENT "ONCE"
	jmp setup

filename:
	.literal "OUTPUT/"
filename_numbers:
	.literal "0173.BIN"
filename_end:

Default_irq_handler:
	.word 0
frame_counter:
	.byte 0
current_color:
	.byte 0

setup:
	lda #0
	sta $9F25
	lda #64
	;sta $9F2A 
	;sta $9F2B
	
	ldx #<data_start
	stx $20 
	ldy #>data_start
	stx $21
	
	lda #$00
	sta VERA_LOADDR
	sta VERA_HIADDR 
	lda #$10
	sta VERA_AUTOINC
	ldy #IMAGE_HEIGHT
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
	lda #<custom_irq_handler
	cmp $0314
	bne :+ 
    lda #>custom_irq_handler
	cmp $0315
	beq loop
	:	
	rts

frame:	
	jmp display_image
	
	lda #$00
	sta VERA_LOADDR
	sta VERA_HIADDR 
	lda #$10
	sta VERA_AUTOINC
	ldy #IMAGE_HEIGHT
@fill_outer_loop:	
	ldx #0
	stx VERA_LOADDR 
	ldx #IMAGE_WIDTH
@fill_inner_loop:
	lda #$20
	sta VERA_DATA 
	lda #1
	sta VERA_DATA
	dex 
	bne @fill_inner_loop
	inc VERA_HIADDR 
	dey 
	bne @fill_outer_loop
	
display_image:
	lda #$20
	sta VERA_AUTOINC
	sta current_color
	ldy #0
	sty VERA_LOADDR
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
	cmp #IMAGE_HEIGHT
	bcs end 
	sta VERA_HIADDR
	
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
	bpl :+
	jsr reset_irq_handler
	:
	rts 

load_file:
	lda filename_end - filename
	ldx #<filename
	ldy #>filename
	jsr SETNAM 
	
	lda #0
	ldx #8 
	ldy #$FF 
	jsr SETLFS
	
	lda #0
	ldx #<LOAD_AREA
	ldy #>LOAD_AREA
	jsr LOAD
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
    beq @irq_done
    ; vsync ;
	lda frame_counter
	inc A
	sta frame_counter
    and #%00000001
	bne @dec9F27
		
	jsr frame
	
	@dec9F27:
	lda $9F27 
	and #%11111110
	sta $9F27

    @irq_done:
    jmp (Default_irq_handler)

data_start = data + 2
data:
	.incbin "modified.bin"
; Amegas trainer (unlimited lives, level skip) by StingRay/[S]carab^Scoopex
; 11.05.2021, requested by ZeusDaz
;
; only the PAL version is trained, adding the trainer code to the NTSC version
; is left as an exercise for the reader.
;
; Levels can be skipped by pressing "Help" during game.

	INCDIR	SOURCES:Trainer/Amegas/

START	lea	Disk(pc),a0


	; NTSC version

	; patch the jmp to start game to call patch code
	move.w	#$6000+($180-$126)-2,$126(a0)

	; copy patch code to bootblock
	lea	PatchCode_NTSC(pc),a1
	lea	$180(a0),a2
	moveq	#PatchCodeSize_NTSC/2-1,d7
.loop	move.w	(a1)+,(a2)+
	dbf	d7,.loop



	; PAL version
	
	move.w	#$6000+($180-$178)-2+PatchCodeSize_NTSC,$178(a0)

	lea	PatchCode_PAL(pc),a1
	lea	$180+PatchCodeSize_NTSC(a0),a2
	moveq	#PatchCodeSize_PAL/2-1,d7
.loop2	move.w	(a1)+,(a2)+
	dbf	d7,.loop2

	; calculate new bootblock checksum
	moveq	#0,d0
	moveq	#0,d1
	moveq	#0,d2
	move.l	a0,a1
	clr.l	4(a1)
.checksum
	add.l	(a1)+,d1
	addx.l	d0,d1
	addq.b	#1,d2
	bcc.b	.checksum

	not.l	d1
	move.l	d1,4(a0)

	; return start and end of disk image in a0/a1
	move.l	a0,a1
	add.l	#901120,a1
	rts



PatchCode_NTSC
	lea	TrainerCode_NTSC(pc),a0
	lea	$100.w,a1
	moveq	#TrainerCodeSize_NTSC/2-1,d7
.loop	move.w	(a0)+,(a1)+
	dbf	d7,.loop

	rts

TrainerCode_NTSC
	rts

TrainerCodeSize_NTSC	= *-TrainerCode_NTSC

PatchCodeSize_NTSC	= *-PatchCode_NTSC



PatchCode_PAL
	lea	TrainerCode_PAL(pc),a0
	lea	$100.w,a1
	moveq	#TrainerCodeSize_PAL/2-1,d7
.loop	move.w	(a0)+,(a1)+
	dbf	d7,.loop

	; unlimited lives
	clr.w	$30000+$990+2


	; in-game keys
	lea	$30000,a0
	move.w	#$4eb9,$140e(a0)
	move.l	#$100,$140e+2(a0)
	move.w	#$4e71,$140e+6(a0)

	; start game
	jmp	$40(a0)
	

TrainerCode_PAL
	btst	#3,$dff01e+1		; PORTS irq?
	beq.b	.no_kbd

	move.b	$bfec01,d0
	ror.b	d0
	not.b	d0
	cmp.b	#$5f,d0
	bne.b	.noHelp
	clr.w	$30000+$323c
.noHelp

	move.b	$bfee01,d0
	move.b	d0,d1
	or.b	#1<<6,d0
	move.b	d0,$bfee01		; set  output mode
	clr.b	$bfec01
	move.b	d1,$bfee01		; 

	move.b	$bfed01,d0
	and.b	#$7f,d0
	move.b	d0,$bfed01
	move.b	#$88,$bfed01
	

	move.w	#1<<3,$dff09c
.no_kbd


	move.w	#1<<5,$dff09c	; original code

	rts

TrainerCodeSize_PAL	= *-TrainerCode_PAL

PatchCodeSize_PAL	= *-PatchCode_PAL


Disk	incbin	Amegas.adf

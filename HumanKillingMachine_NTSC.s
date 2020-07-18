; Human Killing Machine NTSC fix for the crack intro/trainer menu
; StingRay, 18.07.2020


START	lea	DISK(pc),a0

; calculate bootblock checksum
	lea	BOOT(pc),a1
	move.l	a1,a5
	moveq	#0,d0
	moveq	#0,d1
	moveq	#0,d2
.crc	add.l	(a5)+,d0
	addx.l	d1,d0
	addq.b	#1,d2
	bcc.b	.crc
	not.l	d0
	move.l	d0,4(a1)

; copy bootblock
	lea	BOOT(pc),a1
	moveq	#0,d0
.loop	move.l	(a1)+,(a0)+
	addq.b	#1,d0
	bcc.b	.loop


	sub.w	#1024,a0
	move.l	a0,a1
	add.l	#901120,a1
	rts




BOOT	dc.l	"DOS"<<8
	DC.L	0		; checksum
	dc.l	"STR!"		; root

	move.w	#2,$1C(a1)
	move.l	#$7800,$24(a1)
	move.l	#$20000,$28(a1)
	move.l	#$D4200,$2C(a1)
	jsr	-$1C8(a6)
	move.w	#9,$1C(a1)
	move.l	#0,$24(a1)
	jsr	-$1C8(a6)

	pea	Patch(pc)
	move.l	(a7)+,$20000+$11a+2	; jmp $50000 -> jmp Patch
	


	movem.l	d0-d7/a0-a6,-(sp)
	jsr	$20000
	movem.l	(sp)+,d0-d7/a0-a6

	move.l	a1,a5
	move.w	#0,$DFF10A
	jmp	$27010




Patch	lea	$50000,a0
	pea	.WaitVBL(pc)
	move.w	#$4ef9,$184(a0)
	move.l	(a7)+,$184+2(a0)
	jmp	(a0)
	

.WaitVBL
.wait	btst	#0,$dff005
	beq.b	.wait

.wait2	btst	#0,$dff005
	bne.b	.wait2
	rts

	ds.b	1024-(*-BOOT)



DISK	INCBIN	SOURCES:GamePatches/HumanKillingMachine/disk.1

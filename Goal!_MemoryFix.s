; Goal! memory fix
; StingRay, 18.06.2023
;
; This fixes a bug in the game which prevented it to run on machines
; with 1 MB chip memory and 0.5 MB fake fast memory.
; This fix has been been applied to the SPS 1817 version of the game.


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	exec/exec.i
	INCLUDE	exec/io.i
	INCLUDE	devices/trackdisk.i


START	lea	BOOT,a0
	lea	Disk(pc),a1
	move.w	#1024/4-1,d7
.copy_bootblock
	move.l	(a0)+,(a1)+
	dbf	d7,.copy_bootblock


	; Disable protection
	lea	Disk(pc),a0
	add.l	#6*512+$20a3e,a0
	lea	Fake_Protection_Check(pc),a1
	moveq	#Fake_Protection_Check_Size/2-1,d7
.copy_protection_removal_code
	move.w	(a1)+,(a0)+
	dbf	d7,.copy_protection_removal_code

	; Calculate bootblock checksum
	lea	Disk(pc),a0
	moveq	#0,d0
	moveq	#0,d1
	moveq	#0,d2
.calculate_checksum
	add.l	(a0)+,d0
	addx.l	d1,d0
	addq.b	#1,d2
	bcc.b	.calculate_checksum
	not.l	d0
	move.l	d0,-1024+(1*4)(a0)	
	rts

Fake_Protection_Check
	move.l	#$16BA3B5B,d6		; also stored at $29970
	move.l	d6,$BC.w
	move.l	#$7765E3B0,d0		; seems to be unused, $100.w
	move.l	d0,$100.w		; is used as MFM buffer in the game
	rts
Fake_Protection_Check_Size = *-Fake_Protection_Check


Disk	incbin	Sources:GamePatches/Goal!_MemoryFix/Disk.1


; ---------------------------------------------------------------------------


BOOT	dc.l	"DOS"<<8
	dc.l	0
	dc.l	"STR!"

	move.w	#20000,d0
lbC000010
	move.w	d0,$DFF180
	subq.w	#1,d0
	bgt.b	lbC000010

	lea	(-$18,sp),sp
	move.l	a1,(sp)
;  allocate memory for file table
	move.l	#$200,d0
	moveq	#MEMF_CHIP,d1
	move.l	(4).W,a6
	jsr	(-$C6,a6)
	tst.l	d0
	bmi.w	Directory_Allocation_Error
	move.l	d0,($14,sp)
	move.l	(sp),a1
;  load file table
	move.l	d0,($28,a1)
	move.l	#$200,($24,a1)
	move.l	#$400,($2C,a1)
	move.l	(4).W,a6
	jsr	(-$1C8,a6)
	move.l	($14,sp),a0
.lbC00005C
	tst.w	(a0)
	bmi.b	.lbC00007C
	move.w	(12,a0),d2
	lsr.w	#4,d2
	move.w	d2,(8,sp)
	move.l	(12,a0),d3
	and.l	#$FFFFF,d3
	move.l	d3,($10,sp)
	beq.b	.next_entry
	bra.b	.Load_File

.lbC00007C
	move.l	(6,a0),d2
	move.w	d2,(8,sp)
	move.l	(10,a0),d3
	move.l	d3,($10,sp)
	bne.b	.Load_File
.next_entry
	lea	($10,a0),a0
	bra.b	.lbC00005C

.Load_File
	subq.l	#1,d3
	and.l	#$FFE00,d3
	add.l	#$200,d3
	move.l	d3,(12,sp)
;  allocate memory for game binary
	move.l	d3,d0
	moveq	#MEMF_CHIP,d1
	move.l	(4).W,a6
	jsr	(-$C6,a6)
	tst.l	d0
	beq.w	Game_Memory_Allocation_Error
	add.l	#$20,(4,sp)
	move.l	d0,(4,sp)
;  load game binary
	move.l	(sp),a1
	move.w	#CMD_READ,($1C,a1)
	move.l	(4,sp),($28,a1)
	move.l	(12,sp),($24,a1)
	move.w	(8,sp),d2
	mulu	#$200,d2
	move.l	d2,($2C,a1)
	move.l	(4).W,a6
	jsr	(-$1C8,a6)
	move.l	(sp),a1
	move.w	#TD_MOTOR,($1C,a1)
	move.l	#0,($24,a1)
	move.l	(4).W,a6
	jsr	(-$1C8,a6)


	move.l	MaxLocMem(a6),d1

	move.w	($DFF01C),d0
	move.w	#$7FFF,($DFF096)
	move.w	#$7FFF,($DFF09A)
	move.w	#15,($DFF180)
	move.l	(4,sp),a4
	cmp.w	#$6001,(a4)
	bne.w	lbC0001A6

	; if more than 0.5 MB chip memory is available, chip memory
	; has priority
	cmp.l	#$80000,d1
	bgt.b	No_Fake_Fast_Memory_Available

	move.w	#$AAAA,($C00000)
	cmp.w	#$AAAA,($C00000)
	bne.b	No_Fake_Fast_Memory_Available
	move.w	#$5555,($C00000)
	cmp.w	#$5555,($C00000)
	bne.b	No_Fake_Fast_Memory_Available
	move.l	(2,a4),a0
	add.l	a4,a0
	lea	(6,a4),a4
	moveq	#$1C,d2
	cmp.w	#$601B,(a0)
	bne.b	lbC000170
	moveq	#$24,d2
	cmp.w	#$601B,(a4)
	beq.b	lbC00017A
	subq.l	#8,(4,sp)
	bra.b	lbC00017A

lbC000170
	cmp.w	#$601B,(a4)
	bne.b	lbC00017A
	addq.l	#8,(4,sp)
lbC00017A
	addq.l	#6,(4,sp)
	move.l	(4,sp),a1
	subq.w	#1,d2
lbC000184
	move.b	(a0)+,(a1)+
	dbra	d2,lbC000184
	move.l	(a0)+,d7
lbC00018C
	move.l	(a0)+,d0
	move.l	d0,d1
	and.w	#$FF,d0
	lsr.l	#8,d1
	move.l	d1,a2
	add.l	a1,a2
	move.b	d0,(a2)
	subq.l	#1,d7
	bgt.b	lbC00018C
	bra.b	lbC0001A6

No_Fake_Fast_Memory_Available
	addq.l	#6,(4,sp)
lbC0001A6
	lea	(lbC000236,pc),a0
	lea	(lbL00030A,pc),a1
	move.l	a1,d1
	sub.l	a0,d1
	lea	($7F000),a1
	move.l	a1,a2
lbC0001BA
	tst.l	d1
	ble.b	lbC0001C4
	move.b	(a0)+,(a1)+
	subq.l	#1,d1
	bra.b	lbC0001BA

lbC0001C4
	move.w	#6,($DFF180)
	move.l	(4,sp),d0
	move.l	($10,sp),d1
	move.l	(4,sp),a4
	cmp.w	#$6001,(a4)
	beq.b	lbC0001EA
	cmp.w	#$601A,(a4)
	beq.b	lbC0001EA
	cmp.w	#$601B,(a4)
	bne.b	lbC00022C
lbC0001EA
	move.l	($10,sp),d3
	lea	($7FFFE),sp
	move.l	(2,a4),d0
	add.l	(6,a4),d0
	add.l	(10,a4),d0
	add.l	#$400,d0
	sub.l	#$80000,d0
	neg.l	d0
	bclr	#0,d0
	move.l	d0,a3
	move.l	a3,a5
	jmp	(a2)

Directory_Allocation_Error
	move.w	#$800,($DFF180)
	bra.b	lbC000234

Game_Memory_Allocation_Error
	move.w	#$F00,($DFF180)
	bra.b	lbC000234

lbC00022C
	move.w	#$F40,($DFF180)
lbC000234
	bra.b	lbC000234

lbC000236
	move.w	#$80,($DFF180)
	bsr.b	Relocate_Binary
	move.w	#$FF,($DFF180)
	move.w	#$8650,($DFF096)
	move.w	#$1AF,($DFF096)
	lea	(lbC000262,pc),a0
	move.l	a0,($80).W
	trap	#0
lbC000262
	lea	($80000),sp
	move.l	a3,a0
	move.l	a5,a1
	move.w	#$F0,($DFF180)
	jmp	(a3)

lbC000276
	move.w	d0,($DFF180)
	addq.w	#1,d0
	bra.b	lbC000276

Relocate_Binary
	movem.l	d0-d7/a0-a2/a4/a6,-(sp)
	movem.l	(2,a4),d4-d7
	move.w	($1A,a4),-(sp)
	ble.b	lbC000296
	move.l	($16,a4),a5
	move.l	a5,a3
lbC000296
	move.l	a5,a6
	moveq	#-1,d0
	cmp.w	#$601A,(a4)
	beq.b	lbC0002AE
	move.w	#$6022,(a4)
	move.l	($1C,a4),d0
	lea	($24,a4),a4
	bra.b	lbC0002B2

lbC0002AE
	lea	($1C,a4),a4
lbC0002B2
	tst.l	d4
	beq.b	lbC0002BC
lbC0002B6
	move.w	(a4)+,(a5)+
	subq.l	#2,d4
	bne.b	lbC0002B6
lbC0002BC
	tst.l	d0
	bmi.b	lbC0002C2
	move.l	d0,a5
lbC0002C2
	tst.l	d5
	beq.b	lbC0002CC
lbC0002C6
	move.w	(a4)+,(a5)+
	subq.l	#2,d5
	bne.b	lbC0002C6
lbC0002CC
	add.l	d7,a4
	move.w	(sp)+,d0
	bne.b	lbC0002FA
	move.l	(a4)+,d0
	lea	(a6,d0.l),a6
	moveq	#0,d1
lbC0002DA
	move.l	(a6),d0
	add.l	a3,d0
	move.l	d0,(a6)
lbC0002E0
	move.b	(a4)+,d1
	beq.b	lbC0002FA
	cmp.w	#1,d1
	bne.b	lbC0002F0
	lea	($FE,a6),a6
	bra.b	lbC0002E0

lbC0002F0
	cmp.w	#2,d1
	blt.b	lbC0002E0
	add.l	d1,a6
	bra.b	lbC0002DA

lbC0002FA
	tst.l	d6
	beq.b	lbC000304
lbC0002FE
	clr.w	(a5)+
	subq.l	#2,d6
	bgt.b	lbC0002FE
lbC000304
	movem.l	(sp)+,d0-d7/a0-a2/a4/a6
	rts

lbL00030A
	dc.b	"Goal! memory fix by StingRay",10
	dc.b	"Game cracked and fixed on 18-Jun-2023",10
	dc.b	"A Scoopex release in June 2023",10


	ds.b	1024-(*-BOOT)


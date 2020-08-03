; World Class Leaderboard patch to fix the "Game returns to title screen"
; problem. Reason is a wrong error code check for Close() on OS versions <36.
; Code patches Close() in dos.library to always return success.
;
; stingray, 02-Aug-2020


	INCLUDE	SOURCES:INCLUDE/LVOs.i

	INCDIR	SOURCES:INCLUDE/
	INCLUDE	exec/exec.i


START	bra.b	.go
	dc.b	"World Class Leaderboard Patch by StingRay/Scarab^Scoopex",10
	dc.b	"Done in August 2020",0
	CNOP	0,2

.go	move.l	$4.w,a6

	; patch is only required and useful on OS versions <36
	cmp.w	#36,$14(a6)
	bge.b	.exit

	; open dos.library
	moveq	#0,d0
	lea	DOSName(pc),a1
	jsr	_LVOOpenLibrary(a6)
	tst.l	d0
	beq.b	.exit
	move.l	d0,a5

	; allocate memory for patch code
	moveq	#ClosePatchSize,d0
	moveq	#0,d1
	jsr	_LVOAllocMem(a6)

	tst.l	d0
	beq.b	.exit
	move.l	d0,a2

	move.l	d0,a0
	lea	NewClose(pc),a1
	moveq	#ClosePatchSize/2-1,d7
.copy	move.w	(a1)+,(a0)+
	dbf	d7,.copy


;.s	move.w	#$f00,$dff180
;	btst	#2,$dff016
;	bne.b	.s

	lea	_LVOClose(a5),a0

	move.w	4(a0),d0		; offset to old Close() (bra.w)
	lea	4(a0,d0.w),a1		; old Close()

	move.l	a1,OldClose-NewClose(a2)

	jsr	_LVOForbid(a6)


	move.w	#$4ef9,(a0)+		; jmp
	move.l	a2,(a0)			; NewClose

	move.l	a5,a1
	bset	#LIBB_CHANGED,LIB_FLAGS(a1)
	jsr	_LVOSumLibrary(a6)


	jsr	_LVOPermit(a6)

	
.exit	rts


NewClose
	moveq	#$5d,d0		; call original Close()
	bsr.b	.old
	

	moveq	#1,d0		; fake return value
	rts


.old	move.l	OldClose(pc),-(a7)
	rts
	
OldClose	dc.l	0


ClosePatchSize	= *-NewClose


DOSName	dc.b	"dos.library",0

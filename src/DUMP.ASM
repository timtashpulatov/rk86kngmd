;	FILE DUMP PROGRAM, READS AN INPUT FILE AND PRINTS IN HEX
;
;	COPYRIGHT (C) 1975, 1976, 1977, 1978
;	DIGITAL RESEARCH
;	BOX 579, PACIFIC GROVE
;	CALIFORNIA, 93950
;

	.binfile DUMP.RK
	.download bin


; Заголовок .rk
	.ORG	0FCH

	DB	01H, 00H
	DB	END>>8, END

	.ORG	100H
BEGIN:

; Вызовы "Монитора"
CHAROUT EQU 	0F809H	; ВЫВОД СИМВОЛА НА ЭКРАН. A - код символа
KEYSTAT EQU 	0F812H	; ОПРОС СОСТОЯНИЯ КЛАВИАТУРЫ. A=00H - не нажата, A=0FFH - нажата
HEXOUT	EQU 	0F815H	; ВЫВВОД БАЙТА НА ЭКРАН В ШЕСТНАДЦАТИРИЧНОМ ВИДЕ. A - выводимый код
STROUT	EQU 	0F818H	; ВЫВОД НА ЭКРАН СООБЩЕНИЯ. HL - адрес начала

; Точка входа РК ДОС
DOS			EQU 	0E001H	; A - подпрограмма ДОС

OPRD		EQU 	0BH		; Подготовка файла к чтению. HL указывает на буфер строки: {диск:} имя (.тип)
							; Подпрограмма загружает в память T/SLIST, возвращает в DE адрес, который указывает на первый трек и сектор файла, 
							; в HL — адрес загрузки файла

OPENR		EQU 	1DH		; Открыть файл для чтения. HL указывает адрес буфера с именем файла
READ		EQU 	20H		; Прочитать 1 байт из файла, открытого п/п OPENR, байт возвращается в аккумуляторе.
							; Регистр: В=0 — байт достоверный, В<>0 — конец данных
CLOSER		EQU 	22H		; Закрыть файл, открытый ранее п/п OPENR, освободить память, использовавшуюся в системной области


; Системные переменные РК-ДОС

DRIVE	EQU 7540H	;1	Номер дисковода (0 или 1)
OPDRV	EQU 7541H	;1	Оперативный номер дисковода (0, 1). Используется подпрограммами чтения и записи сектора. 
						; При выполнении подпрограммы OPFREE или при входе в ДОС по п/п START2 принимает значение DRIVE
TTRK	EQU 7542H	;1	Текущий номер трека, должен быть установлен перед записью или чтением сектора
TSKT	EQU 7543H	;1	Текущий номер сектора, как и TTRK устанавливается перед чтением или записью
BEGS	EQU 7544H	;2	Адрес начала сектора в ОЗУ. Должен быть установлен перед чтением и записью сектора при выполнении п/п WRSKT и RDSKT
LENGTS	EQU 7546H	;2	Длина сектора (1 — 200Н байт), должна быть установлена перед записью сектора. При чтении устанавливается ДОС
KS		EQU 7548H	;2	Контрольная сумма сектора, прочитанная с диска
ERRORS	EQU 754BH	;1	Результат обмена с диском. ERRORS — 0 — ошибок обмена нет, иначе — код ошибки
NWR		EQU 754CH	;1	Количество попыток записи сектора
NRD		EQU 754DH	;1	Количество попыток чтения сектора
TCAT	EQU 754EH	;1	Номер трека каталога с найденным именем (например, п/п КОММ или КОМ2)
SCAT	EQU 754FH	;1	Номер сектора каталога с найденным именем
FLAG	EQU 7550H	;1	Флаг шаблона имени. (FLAG — 0 — запрет использования шаблонов при поиске в каталоге)
BREAK 	EQU 7551H	;2	Адрес выхода по ошибке. При выходе вне ДОС должен быть восстановлен указатель стека SP
ADRNM 	EQU 7553H	;2	Адрес начала найденного имени в прочитанном секторе каталога. Устанавливается п/п КОММ, КОМ2
ADBUF 	EQU 7555H	;2	Адрес имени во входном буфере, по которому производится поиск файла
ENDNAM 	EQU 7557H	;2	Адрес байта, следующего после имени во входном буфере, по которому производится поиск в каталоге 
						; (см. п/п OPRD, OPWR, LOAD, SAVE, OPENR, OPENW, APPEND, DIR)
FLEXT 	EQU 7559H	;1	Флаг расширения. Если при поиске файла во входном буфере в имени был указан тип, принимает значение 2ЕН
SPCDIR 	EQU 755AH	;2	Адрес свободного места в секторе каталога, возникшего в результате удаления файла. 
						; Устанавливается при поиске любого имени (если в каталоге нет удаленных файлов, то принимает значение 0000)
SPCTRK 	EQU 755CH	;1	Номер трека с удаленным именем (см. переменную SPCDIR)
SPCSKT 	EQU 755DH	;1	Номер сектора с удаленным именем (см. переменную SPCDIR)
BOOTA 	EQU 755EH	;2	Адрес начала буфера, выделенного ДОС для чтения и записи сектора каталога и T/SLIST.
						; Устанавливается при операциях обращения к диску по имени файла
BOOTV	EQU	7560H	;2	Адрес начала буфера, выделенного ДОС для чтения и записи карты диска VTOC
RIPERR	EQU 7562H	;1	Вывод сообщения об ошибке, если переменная равна 0 — вывод запрещен, не равна 0 — разрешен
KANALW 	EQU 7564H	;2	Адрес канала вывода байта
OPKANW	EQU 7566H	;2	Адрес временно установленного канала вывода
KANALR	EQU 7568H	;2	Адрес канала ввода байта
OPKANR	EQU 756AH	;2	Адрес временно установленного канала ввода
KSTRT	EQU 758CH	;1	Если при запуске ДОС переменная KSTRT не равна DDH, то произойдет холодный старт 
						; с позиционированием головки на нулевой трек и выполнением AUTOEXEC.BAT
BATF	EQU 758DH	;2	Используется для передачи адреса имени файла типа ВАТ командному процессору
BEGFL	EQU 7590H	;2	Адрес начала файла, загруженного в память
ENDFL	EQU 7592H	;2	Адрес конца файла, загруженного в память


;	NON GRAPHIC CHARACTERS
CR	EQU	0DH	;CARRIAGE RETURN
LF	EQU	0AH	;LINE FEED

;	READ AND PRINT SUCCESSIVE BUFFERS
	CALL	SETUP
	ORA A
	JZ	OPENOK

;	FILE NOT THERE, GIVE ERROR MESSAGE AND RETURN
	LXI		H,OPNMSG
	CALL	STROUT
	RET
;
OPENOK:	;OPEN OPERATION OK, SET BUFFER INDEX TO END

;	HL CONTAINS NEXT ADDRESS TO PRINT
	LXI	H,0	;START WITH 0000
;
GLOOP:
	PUSH	H	;SAVE LINE POSITION
	CALL	GNB
	POP	H	;RECALL LINE POSITION
	JC	FINIS	;CARRY SET BY GNB IF END FILE
	MOV	B,A
;	PRINT HEX VALUES
;	CHECK FOR LINE FOLD
	MOV	A,L
	ANI	0FH	;CHECK LOW 4 BITS
	JNZ	NONUM
;	PRINT LINE NUMBER
	CALL	CRLF
;
;	CHECK FOR KEY
	CALL	KEYSTAT
;	ACCUM LSB = 1 IF CHARACTER READY
	RRC		;INTO CARRY
	JC	FINIS	;DON'T PRINT ANY MORE
;
	MOV	A,H
	CALL	HEXOUT
	MOV	A,L
	CALL	HEXOUT
NONUM:
	INX	H	;TO NEXT LINE NUMBER
	MVI	A,' '
	CALL	CHAROUT
	MOV	A,B
	CALL	HEXOUT
	JMP	GLOOP
;
FINIS:	
	CALL	CRLF
	MVI A, CLOSER
	CALL DOS
	RET
;
;
;	SUBROUTINES
;

;
CRLF:
	MVI	A,CR
	CALL	CHAROUT
	MVI	A,LF
	CALL	CHAROUT
	RET
;
;

;
;
GNB:	;GET NEXT BYTE

	MVI A, READ 	
	CALL DOS 	; B=0 if read OK
	PUSH A
	MOV	A,B
	ORA A
	JZ G0
	POP A
	STC
	RET

G0:
	POP A
	ORA A
	RET

;
SETUP:	;SET UP FILE 
;	OPEN THE FILE FOR INPUT

	LXI	H, (ENDNAM)
	MVI A, OPENR
	CALL DOS
	RET
;
;
;	FIXED MESSAGE AREA
SIGNON:	DB	'FILE DUMP VERSION 1.4',0
OPNMSG:	DB	CR,LF,'NO INPUT FILE PRESENT ON DISK',0


	END
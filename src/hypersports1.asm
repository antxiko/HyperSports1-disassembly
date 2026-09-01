; ==========================================================================
; HYPER SPORTS 1 - Konami - MSX1 - cartucho RC-715 de 16 KB en la pagina 1
; ==========================================================================
; Generado por tools/mkasm.py a partir del trazado de flujo real.
; Los comentarios provienen de tools/../src/*.notes y estan anclados a
; direccion, de modo que sobreviven a un retrazado.
; ==========================================================================

	org 0x04000


; ----------------------------------------------------------------------
; Etiquetas que no caen en ninguna posicion emitida del listado
; (destinos fuera del binario o dentro de una instruccion).
; ----------------------------------------------------------------------
INIT_6367:	equ 0x06367

; ----------------------------------------------------------------------
; DATOS cabecera_cartucho: AB, el puntero INIT (0x4077) y punteros a cero
;   0x4000..0x4010  (16 bytes)
DATA_cabecera_cartucho:
	defb 041h,042h	; 4000
	defw 04077h,00000h,00000h,00000h	; 4002  -> INIT 0x0000 0x0000 0x0000
	defw 00000h,00000h,00000h	; 400a

; ======================================================================
; CODIGO 0x4010..0x4019  (9 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ARRANQUE. La BIOS entra por la cabecera del cartucho (INIT en 0x4077).
; ----------------------------------------------------------------------
SACA_BYTE_VRAM:		; Nucleo del volcado: abre la VRAM y saca A por el puerto
	call FIJA_ESCRITURA		;4010   ; abre la VRAM en la direccion de escritura
	exx			;4013
	out (c),a		;4014
	exx			;4016
	ei			;4017
	ret			;4018

; ----------------------------------------------------------------------
; DATOS nucleo_lee_vram: Variante del nucleo que lee de la VRAM
;   0x4019..0x4022  (9 bytes)
DATA_nucleo_lee_vram:
	defb 0cdh,03bh,044h,0d9h,0edh,078h,0d9h,0fbh,0c9h	; 4019  .;D..x...

; ======================================================================
; CODIGO 0x4022..0x40c2  (160 bytes)
; ======================================================================


HL_MAS_A:		; HL += A, devuelve
	add a,l			;4022
	ld l,a			;4023
	ret nc			;4024
	inc h			;4025
	ret			;4026
DE_MAS_A:		; DE += A, devuelve
	add a,e			;4027
	ld e,a			;4028
	ret nc			;4029
	inc d			;402a
	ret			;402b
INT:		; Rutina de interrupcion: un cuadro de juego
	di			;402c
	call 0013eh		;402d   ; BIOS RDVDP - Reads VDP status register | lee el estado del VDP (limpia la peticion)
	call ACTUALIZA_SONIDO		;4030   ; atiende el sonido
	ld hl,0e005h		;4033   ; candado de reentrada (0xE005)
	bit 0,(hl)		;4036
	jr nz,INT_4047		;4038
	inc (hl)			;403a
	ei			;403b
	call LEE_MANDOS_FLANCO		;403c   ; relee los mandos
	call MAQUINA_ESTADOS		;403f   ; avanza la maquina de estados
	di			;4042
	xor a			;4043
	ld (0e005h),a		;4044
INT_4047:
	ei			;4047
	reti		;4048
SALTA_POR_TABLA:		; Salta a la entrada A de la tabla que sigue al call
	add a,a			;404a
	pop hl			;404b
	call HL_MAS_A		;404c
	ld e,(hl)			;404f
	inc hl			;4050
	ld d,(hl)			;4051
	ex de,hl			;4052
	jp (hl)			;4053   ; salta a la rutina de esa casilla
INTERCAMBIA:		; Intercambia B bytes entre (HL) y (DE)
	ld c,(hl)			;4054   ; lee el byte de destino
	ld a,(de)			;4055
	ld (hl),a			;4056
	ld a,c			;4057
	ld (de),a			;4058
	inc hl			;4059
	inc de			;405a
	djnz INTERCAMBIA		;405b
	ret			;405d
VUELCA_GUION:		; Interprete de guion RLE a la VRAM (mascara c=0)
	ld c,000h		;405e
	jr GUION_DESTINO		;4060
VUELCA_GUION_MASC:		; Igual pero con mascara (c=0xFF)
	ld c,0ffh		;4062
GUION_DESTINO:
	ld e,(hl)			;4064   ; toma el destino de VRAM del guion
	inc hl			;4065
	ld d,(hl)			;4066
	inc hl			;4067
GUION_BYTE:
	ld a,(hl)			;4068   ; lee el byte del guion
	inc hl			;4069   ; avanza el puntero
	ld b,a			;406a   ; pasa la cuenta a B
	inc b			;406b   ; 0xFF cierra el guion, 0xFE abre otro destino
	ret z			;406c
	inc b			;406d
	jr z,GUION_DESTINO		;406e
	and c			;4070
	call SACA_BYTE_VRAM		;4071   ; saca el byte a la VRAM
	inc de			;4074
	jr GUION_BYTE		;4075
INIT:		; Prepara la maquina y engancha la interrupcion
	di			;4077
	im 1		;4078   ; modo de interrupcion 1
	ld a,0c3h		;407a   ; valor 0xC3 (jp) para el gancho
	ld (0fd9ah),a		;407c   ; escribe un jp en H.KEYI apuntando a 0x402C
	ld hl,INT		;407f   ; apunta a la rutina de interrupcion
	ld (0fd9bh),hl		;4082   ; lo escribe en 0xFD9B
	ld sp,0e400h		;4085   ; la pila en 0xE400
	xor a			;4088
	ld hl,0e000h		;4089   ; limpia la RAM de trabajo 0xE000-0xE3FF
	ld de,0e001h		;408c
	ld bc,003ffh		;408f
	ld (hl),a			;4092
	ldir		;4093
	inc a			;4095
	ld (0e005h),a		;4096
	call ARRANCA_VDP		;4099
	xor a			;409c
	ld (0e005h),a		;409d
	call 0013eh		;40a0   ; BIOS RDVDP - Reads VDP status register
	ei			;40a3
BUCLE_MUERTO:
	jr BUCLE_MUERTO		;40a4   ; bucle muerto: el trabajo lo hace la interrupcion
MAQUINA_ESTADOS:		; Reparte segun 0xE000 (estado), con demo (0xE002 bit6)
	ld hl,0e003h		;40a6
	inc (hl)			;40a9
	ld a,(0e002h)		;40aa
	and 040h		;40ad
	ld hl,0430ah		;40af   ; fuera de demo empuja el manejador de juego 0x430A
	jr nz,MAQUINA_ESTADOS_40B7		;40b2
	ld hl,044c9h		;40b4   ; en demo empuja el de demo 0x44C9
MAQUINA_ESTADOS_40B7:
	ld a,(0e000h)		;40b7
	cp 008h		;40ba   ; el estado 8 no lleva manejador de fondo
	jr z,MAQUINA_ESTADOS_40BF		;40bc
	push hl			;40be
MAQUINA_ESTADOS_40BF:
	call SALTA_POR_TABLA		;40bf   ; salta al manejador del estado

; ----------------------------------------------------------------------
; DATOS tabla_estados: Manejadores de estado, indexados por 0xE000
;   0x40c2..0x40da  (24 bytes)
DATA_tabla_estados:
	defw 040dah,040e5h,040f7h,04106h,04108h,0410eh,04117h,04127h,04165h,0411fh,04133h,0614dh	; 40c2

; ======================================================================
; CODIGO 0x40da..0x41cc  (242 bytes)
; ======================================================================


ESTADO_0:		; Prepara y dibuja la pantalla de titulo
	call LIMPIA_NOMBRES		;40da
	call DIBUJA_TITULO		;40dd
	call PREPARA_TITULO		;40e0
	jr AVANZA_ESTADO		;40e3
ESTADO_1:
	ld a,(0e003h)		;40e5   ; solo en la fase impar de la interrupcion
	rra			;40e8
	ret nc			;40e9
	call DESCOMPRIME_A_TERCIOS_4748		;40ea
	ret nz			;40ed
	ld hl,04619h		;40ee
	call VUELCA_GUION_MASC		;40f1
	xor a			;40f4
	jr FIJA_ESPERA		;40f5
ESTADO_2:
	ld hl,0e004h		;40f7   ; espera a que baje el retardo (0xE004)
	dec (hl)			;40fa
	ret nz			;40fb
	ld hl,04619h		;40fc
	call VUELCA_GUION		;40ff
	xor a			;4102
	ld (0e00ah),a		;4103
ESTADO_2B:
	jr AVANZA_ESTADO		;4106
ESTADO_3:
	call PINTA_ROTULO_JUEGO		;4108
	xor a			;410b
	jr FIJA_ESPERA		;410c
ESTADO_4:
	ld hl,0e004h		;410e
	dec (hl)			;4111
	jp nz,DIBUJA_AGUJA		;4112
	jr FIJA_ESPERA		;4115
ESTADO_5:
	call LIMPIA_NOMBRES		;4117
	call PREPARA_EVENTO		;411a
	jr FIJA_ESPERA		;411d
ESTADO_6:
	call LIMPIA_NOMBRES		;411f
	call PREPARA_TABLERO		;4122
	jr FIJA_ESPERA		;4125
ESTADO_7:
	call CUENTA_INTENTOS		;4127
	ret nz			;412a
	ld hl,0e052h		;412b
	inc (hl)			;412e
ESTADO_7_412F:
	xor a			;412f
	jp FIJA_ESTADO		;4130
ESTADO_8:		; Arranca la prueba en curso
	call EVENTO_ACTUAL		;4133
FIJA_ESPERA:		; Guarda A en 0xE004 y avanza el estado
	ld (0e004h),a		;4136
AVANZA_ESTADO:		; inc 0xE000
	ld hl,0e000h		;4139
	inc (hl)			;413c
	ret			;413d
CAMBIA_JUGADOR:		; Intercambia los bloques de los dos jugadores
	ld hl,0e050h		;413e   ; copia el bloque de un jugador al otro
	ld de,0e080h		;4141
	ld b,020h		;4144
	call INTERCAMBIA		;4146
	ld hl,0e002h		;4149
	ld a,(hl)			;414c
	xor 080h		;414d
	ld (hl),a			;414f
	ret			;4150
SALE_DEMO:		; Borra el bit6 de 0xE002
	ld hl,0e002h		;4151
	ld a,(hl)			;4154
	and 0bfh		;4155
	ld (hl),a			;4157
	jp ESTADO_7_412F		;4158
FIJA_ESTADO:		; Escribe A en 0xE000
	ld (0e000h),a		;415b
	ret			;415e
EST_REDIBUJA:
	call INIT_JUGADOR		;415f
	jp FIJA_ESPERA		;4162
ESTADO_ROTULO:		; Ensena un rotulo con sonido y una espera
	ld a,(0e001h)		;4165   ; en el primer subestado prepara el rotulo
	or a			;4168
	jr nz,ROTULO_ESPERA		;4169
	ld a,099h		;416b
	call SUMA_BONUS_7B8F		;416d
	ld a,050h		;4170
	ld (0e004h),a		;4172
ROTULO_PINTA:
	call LIMPIA_NOMBRES		;4175   ; limpia y dibuja el fondo del rotulo
	call DIBUJA_TITULO		;4178
	call PINTA_ROTULO_JUEGO		;417b
	ld hl,0e001h		;417e
	inc (hl)			;4181
	ret			;4182
ROTULO_ESPERA:
	ld hl,0e004h		;4183   ; baja el retardo del rotulo
	dec (hl)			;4186
	jr z,EST_REDIBUJA		;4187
	bit 3,(hl)		;4189
	jp nz,PINTA_ROTULO_JUEGO		;418b
	call CALC_DIR_AGUJA		;418e
	ld bc,0001bh		;4191
	xor a			;4194
	jp RELLENA_VRAM		;4195
DIBUJA_TITULO:		; Pinta el logo y los rotulos de la pantalla de titulo
	call DESCOMPRIME_A_TERCIOS		;4198   ; descomprime el fondo del titulo en los tres tercios
	call LIMPIA_SPRITES		;419b   ; saca los sprites de pantalla
	ld a,070h		;419e   ; tono de relleno del titulo
	ld de,01600h		;41a0   ; destino en la VRAM
	ld bc,00180h		;41a3
	call RELLENA_VRAM		;41a6
	ld hl,0462fh		;41a9   ; vuelca el logo KONAMI VIDEO CARTRIDGE
	call VUELCA_TABLA_VDP		;41ac
	ld de,04600h		;41af
	ld bc,00098h		;41b2
	ld a,0f0h		;41b5
	call RELLENA_VRAM		;41b7
	ld hl,041cch		;41ba
	ld b,011h		;41bd
TITULO_BUCLE:
	push bc			;41bf   ; sube 0x11 filas de adorno a la VRAM
	ld bc,00008h		;41c0
	push hl			;41c3
	call VUELCA_BLOQUE		;41c4
	pop hl			;41c7
	pop bc			;41c8
	djnz TITULO_BUCLE		;41c9
	ret			;41cb

; ----------------------------------------------------------------------
; DATOS tabla_titulo: Patron del adorno del titulo
;   0x41cc..0x41d4  (8 bytes)
DATA_tabla_titulo:
	defb 071h,0f1h	; 41cc
	defb 071h,0f1h	; 41ce
	defb 051h,051h	; 41d0
	defb 041h,041h	; 41d2

; ======================================================================
; CODIGO 0x41d4..0x4211  (61 bytes)
; ======================================================================


INIT_JUGADOR:		; Pone a cero el bloque de estado del jugador
	ld hl,0e04ah		;41d4   ; apunta al bloque del jugador (0xE04A)
	ld bc,002b6h		;41d7   ; tamano del bloque
	ld a,(0e002h)		;41da   ; lee el modo (0xE002)
	and 020h		;41dd   ; bit5 de 0xE002 elige el bloque del jugador 2
	push af			;41df
	jr z,INIT_JUGADOR_41E7		;41e0
	ld l,047h		;41e2
	inc bc			;41e4
	inc bc			;41e5
	inc bc			;41e6
INIT_JUGADOR_41E7:
	ld d,h			;41e7   ; borra el bloque del jugador
	ld e,l			;41e8   ; apunta al segundo byte para el ldir
	inc e			;41e9   ; apunta al segundo byte
	ld (hl),000h		;41ea   ; pone a cero
	ldir		;41ec   ; borra el bloque de un ldir
	ld hl,04211h		;41ee   ; apunta a los valores iniciales
	ld de,0e050h		;41f1
	ld c,003h		;41f4
	ldir		;41f6
	ld a,003h		;41f8
	ld (0e054h),a		;41fa
	ld hl,00720h		;41fd
	ld (0e185h),hl		;4200
	pop af			;4203
	ret z			;4204
	ld hl,0e050h		;4205
	ld de,0e080h		;4208
	ld bc,00020h		;420b
	ldir		;420e
	ret			;4210

; ----------------------------------------------------------------------
; DATOS datos_init_jugador: Valores iniciales del bloque de jugador
;   0x4211..0x4214  (3 bytes)
DATA_datos_init_jugador:
	defb 001h,001h,000h	; 4211

; ======================================================================
; CODIGO 0x4214..0x4335  (289 bytes)
; ======================================================================


PREPARA_EVENTO:		; Monta la pantalla de la prueba en curso
	call PREPARA_TABLERO		;4214
	ld hl,00760h		;4217
	ld (0e185h),hl		;421a
	jp EVENTO_ACTUAL		;421d
CUENTA_INTENTOS:
	ld a,(0e052h)		;4220   ; cuenta segun el evento (0xE052)
	and 003h		;4223
	dec a			;4225
	cp 002h		;4226
	jr nc,CUENTA_INTENTOS_422C		;4228
	ld b,010h		;422a
CUENTA_INTENTOS_422C:
	ld a,r		;422c
	and a			;422e
	jr nz,CUENTA_INTENTOS_4233		;422f
	set 4,b		;4231
CUENTA_INTENTOS_4233:
	ld a,(0e003h)		;4233
	and 003h		;4236
	jr nz,CUENTA_INTENTOS_423C		;4238
	set 3,b		;423a
CUENTA_INTENTOS_423C:
	ld a,b			;423c   ; guarda el numero de intentos
	ld (0e0f1h),a		;423d
	call ARRANCA_PRUEBA		;4240
	ld a,(0e183h)		;4243
	cp 007h		;4246
	ret			;4248
LIMPIA_PANTALLA:		; Borra la tabla de nombres y prepara el fondo
	ld de,03b00h		;4249
	ld bc,00080h		;424c
	xor a			;424f
	jp RELLENA_VRAM		;4250
LIMPIA_PANTALLA_4253:
	ld a,001h		;4253
	ld (0e15dh),a		;4255
LIMPIA_PANTALLA_4258:
	ld a,(0e002h)		;4258   ; bit del modo en 0xE002
	add a,a			;425b
	ret p			;425c
	ld hl,0e04bh		;425d
	jr nc,LIMPIA_PANTALLA_4264		;4260
	ld l,048h		;4262
LIMPIA_PANTALLA_4264:
	ld a,(hl)			;4264   ; lee el estado del tablero
	add a,e			;4265   ; acumula el desplazamiento
	daa			;4266   ; ajuste decimal
	ld (hl),a			;4267   ; guarda el digito
	ld e,a			;4268   ; lo pasa a E
	inc l			;4269
	ld a,(hl)			;426a
	adc a,d			;426b
	daa			;426c
	ld (hl),a			;426d
	ld d,a			;426e
	jr nc,LIMPIA_PANTALLA_427E		;426f
	ld bc,09999h		;4271
	ld (0e044h),bc		;4274
	ld (0e045h),bc		;4278
	jr PREPARA_TABLERO_42C7		;427c
LIMPIA_PANTALLA_427E:
	ld hl,(0e045h)		;427e
	sbc hl,de		;4281
	jr nc,PREPARA_TABLERO_42D0		;4283
	ld (0e045h),de		;4285
	jr PREPARA_TABLERO_42C7		;4289
PREPARA_TABLERO:
	ld hl,0457eh		;428b   ; vuelca el guion base del tablero
	call VUELCA_GUION_MASC		;428e   ; vuelca el guion base con mascara
	ld a,(0e002h)		;4291   ; lee el modo (0xE002)
	bit 5,a		;4294   ; bit5: jugador 2
	jr z,PREPARA_TABLERO_42A6		;4296
	ld hl,04599h		;4298
	call VUELCA_GUION_MASC		;429b
	ld a,(0e002h)		;429e
	xor 080h		;42a1
	call PREPARA_TABLERO_42D3		;42a3
PREPARA_TABLERO_42A6:
	ld a,(0e052h)		;42a6   ; el evento (0xE052) elige el tablero
	and 003h		;42a9   ; lo enmascara a 0..3
	ld hl,04572h		;42ab   ; apunta al otro guion (0x4572)
	push af			;42ae
	cp 002h		;42af   ; compara con 2
	call nz,VUELCA_GUION_MASC		;42b1   ; lo vuelca si no coincide
	pop af			;42b4
	rra			;42b5
	jr c,PREPARA_TABLERO_42C4		;42b6
	ld hl,04568h		;42b8
	rra			;42bb
	jr nc,PREPARA_TABLERO_42C1		;42bc
	ld hl,04560h		;42be
PREPARA_TABLERO_42C1:
	call VUELCA_GUION_MASC		;42c1
PREPARA_TABLERO_42C4:
	call PREPARA_TABLERO_42E5		;42c4
PREPARA_TABLERO_42C7:
	ld hl,0e046h		;42c7
	ld de,0380fh		;42ca
	call PREPARA_TABLERO_42E1		;42cd
PREPARA_TABLERO_42D0:
	ld a,(0e002h)		;42d0
PREPARA_TABLERO_42D3:
	ld de,03805h		;42d3   ; apunta a la fila de la VRAM
	ld hl,0e04ch		;42d6
	add a,a			;42d9
	jr nc,PREPARA_TABLERO_42E1		;42da
	ld e,019h		;42dc
	ld hl,0e049h		;42de
PREPARA_TABLERO_42E1:
	ld b,003h		;42e1
	jr PREPARA_TABLERO_42ED		;42e3
PREPARA_TABLERO_42E5:
	ld de,03848h		;42e5
	ld hl,0e051h		;42e8
	ld b,001h		;42eb
PREPARA_TABLERO_42ED:
	ld a,(hl)			;42ed   ; saca el byte del guion
	push af			;42ee   ; lo guarda mientras escribe
	and 00fh		;42ef   ; aisla el digito
	or 030h		;42f1   ; lo pasa a caracter
	ld c,a			;42f3   ; a C
	pop af			;42f4   ; recupera A
	and 0f0h		;42f5
	rra			;42f7
	rra			;42f8
	rra			;42f9
	rra			;42fa
	or 030h		;42fb
	call SACA_BYTE_VRAM		;42fd
	inc de			;4300
	ld a,c			;4301
	call SACA_BYTE_VRAM		;4302
	dec hl			;4305
	inc de			;4306
	djnz PREPARA_TABLERO_42ED		;4307
	ret			;4309
MARCADOR:		; Pinta el marcador y los rotulos fijos cada cuadro
	ld hl,(0e002h)		;430a
	ld a,01fh		;430d   ; bit5 de 0xE002 elige el bloque del jugador
	and h			;430f
	ret nz			;4310
	ld c,a			;4311
	bit 5,h		;4312
	jr z,MARCADOR_1		;4314
	dec c			;4316
MARCADOR_1:
	bit 7,l		;4317
	ld hl,04593h		;4319   ; el bit7 alterna entre dos guiones del marcador
	jr z,MARCADOR_1_4321		;431c
	ld hl,04599h		;431e
MARCADOR_1_4321:
	jp GUION_DESTINO		;4321
PINTA_ROTULO_JUEGO:		; Vuelca el guion 0x4335 (y otro si toca)
	ld hl,04335h		;4324   ; vuelca el rotulo del juego (0x4335)
	call VUELCA_GUION_MASC		;4327
	push af			;432a
	ld hl,0459fh		;432b
	call z,VUELCA_GUION_MASC		;432e
	pop af			;4331
	cp 034h		;4332
	ret			;4334

; ----------------------------------------------------------------------
; DATOS guion_del_rotulo: El ROTULO DEL JUEGO: 22 x 2 casillas en las filas 5
;   y 6, columnas 6 a 27, con los tiles 0xC0 a 0xE3 del PRIMER tercio.
;   Dibujado desde la ROM se lee HYPER SPORTS 1. Sus patrones son el bloque
;   que 0x41A9 descomprime en la VRAM 0x2600 y sus colores los pone 0x4198:
;   blanco liso arriba (0x41AF) y las rayas de tabla_titulo abajo (0x41BA). No
;   es el marcador: el logotipo que sube en la pantalla anterior es el de
;   Konami, no el del juego.
;   0x4335..0x436c  (55 bytes)
DATA_guion_del_rotulo:
	defb 08bh,038h,000h,000h,0feh,0a6h,038h,0c0h,0c1h,0c2h,0c3h,0c4h,0c5h,0c6h,0c4h,0c7h	; 4335  .8....8.........
	defb 0c8h,0c9h,0c4h,0cah,0cbh,0cch,0c4h,0cdh,0ceh,0cfh,0d0h,0d1h,0d2h,0feh,0c6h,038h	; 4345  ...............8
	defb 0d3h,0d4h,0d5h,0e3h,0d6h,0d7h,0d8h,0d9h,0dah,0dbh,0dch,0d6h,0ddh,0deh,0dfh,0d9h	; 4355  ................
	defb 0dah,0e0h,0e1h,0e2h,0d5h,0e3h,0ffh	; 4365

; ======================================================================
; CODIGO 0x436c..0x443b  (207 bytes)
; ======================================================================


DIBUJA_AGUJA:		; Coloca la aguja/indicador movil en la VRAM
	ld bc,05e5fh		;436c
	bit 3,(hl)		;436f
	jr nz,DIBUJA_AGUJA_4376		;4371
DIBUJA_AGUJA_4373:
	ld bc,00000h		;4373
DIBUJA_AGUJA_4376:
	call CALC_DIR_AGUJA		;4376   ; calcula la direccion de la aguja
	ld a,b			;4379
	call SACA_BYTE_VRAM		;437a
	ld a,c			;437d
	inc de			;437e
	jp SACA_BYTE_VRAM		;437f
CALC_DIR_AGUJA:		; Direccion de VRAM de la aguja desde 0xE042
	ld a,(0e042h)		;4382   ; la posicion sale de 0xE042
	add a,014h		;4385
	rrca			;4387
	rrca			;4388
	ld e,a			;4389
	ld d,07ah		;438a
	ret			;438c
LIMPIA_NOMBRES:		; Rellena la tabla de nombres 0x7800 (0x300 bytes)
	call LIMPIA_PANTALLA		;438d
	ld de,07800h		;4390
	ld bc,00300h		;4393
	xor a			;4396
RELLENA_VRAM:		; Rellena un tramo de VRAM con el valor A
	call FIJA_ESCRITURA		;4397
RELLENA_VRAM_439A:
	ex af,af'			;439a
RELLENA_VRAM_439B:
	ex af,af'			;439b   ; protege registros durante el volcado
	exx			;439c   ; intercambia al banco alterno
	out (c),a		;439d   ; saca el byte por el puerto
	exx			;439f
	ex af,af'			;43a0   ; recupera A
	dec bc			;43a1   ; baja el contador
	ld a,b			;43a2
	or c			;43a3
	jr nz,RELLENA_VRAM_439B		;43a4
	ei			;43a6
	ret			;43a7
RELLENA_VRAM_43A8:
	ld a,(hl)			;43a8
	inc hl			;43a9
	jr RELLENA_VRAM_439A		;43aa
RELLENA_VRAM_43AC:
	ld b,000h		;43ac
RELLENA_VRAM_43AE:
	di			;43ae
	call FIJA_ESCRITURA		;43af
VUELCA_BLOQUE:		; Vuelca un bloque de memoria a la VRAM
	ld a,(hl)			;43b2   ; lee el byte del bloque
	exx			;43b3   ; al banco alterno para el puerto
	out (c),a		;43b4   ; saca el byte por el puerto
	exx			;43b6
	inc hl			;43b7   ; avanza
	dec bc			;43b8   ; baja el contador de 16 bits
	ld a,b			;43b9
	or c			;43ba
	jr nz,VUELCA_BLOQUE		;43bb
	ei			;43bd
	ret			;43be
LIMPIA_SPRITES:		; Saca los sprites de pantalla
	ld hl,(00004h)		;43bf   ; toma la base de la tabla de sprites
	ld bc,00180h		;43c2   ; el tamano de la tabla de atributos
	add hl,bc			;43c5   ; apunta al final para borrarla
	push hl			;43c6   ; guarda el destino
	ld de,02180h		;43c7
	ld bc,00180h		;43ca   ; tamano de la tabla
	call LIMPIA_SPRITES_43F4		;43cd   ; borra el segundo bloque
	ld de,02600h		;43d0
	ld bc,00180h		;43d3
	pop hl			;43d6
	call LIMPIA_SPRITES_43F4		;43d7
	ld hl,0452ah		;43da
	ld de,021d0h		;43dd
	call DIBUJA_MARCO_4849		;43e0
	ld hl,0453ah		;43e3
	push hl			;43e6
	ld de,02760h		;43e7
	call DIBUJA_MARCO_4849		;43ea
	ld de,022e0h		;43ed
	pop hl			;43f0
	jp DIBUJA_MARCO_4849		;43f1
LIMPIA_SPRITES_43F4:
	exx			;43f4
	ld b,003h		;43f5
LIMPIA_SPRITES_43F7:
	push bc			;43f7   ; guarda la cuenta del bucle
	exx			;43f8   ; al banco alterno
	push hl			;43f9
	push bc			;43fa
	call RELLENA_VRAM_43AE		;43fb   ; borra el segundo bloque de sprites
	pop bc			;43fe
	pop hl			;43ff
	ld a,008h		;4400   ; salto de tercio
	add a,d			;4402   ; avanza el destino
	ld d,a			;4403
	exx			;4404
	pop bc			;4405
	djnz LIMPIA_SPRITES_43F7		;4406
	ret			;4408
VUELCA_TABLA_VDP:		; Escribe una tabla de registros del VDP
	ld e,(hl)			;4409
	inc hl			;440a
	ld d,(hl)			;440b
	inc hl			;440c
VUELCA_TABLA_VDP_440D:
	di			;440d
	call FIJA_ESCRITURA		;440e
VUELCA_TABLA_VDP_4411:
	ld a,(hl)			;4411   ; lee el valor del registro
	and 07fh		;4412   ; aisla la cuenta (bits bajos)
	ld c,a			;4414   ; la pasa a C
	ld a,(hl)			;4415   ; relee el byte completo
	inc hl			;4416
	jr nz,VUELCA_TABLA_VDP_441E		;4417
	cp c			;4419
	jr nz,VUELCA_TABLA_VDP		;441a
	ei			;441c
	ret			;441d
VUELCA_TABLA_VDP_441E:
	ld b,000h		;441e   ; limpia B para el bucle
	cp c			;4420
	push af			;4421
	call nz,VUELCA_BLOQUE		;4422
	pop af			;4425
	call z,RELLENA_VRAM_43A8		;4426
	di			;4429
	jr VUELCA_TABLA_VDP_4411		;442a
FIJA_ESCRITURA:		; SETWRT y prepara el puerto de datos del VDP
	ex af,af'			;442c   ; abre la VRAM para escribir en DE
	ex de,hl			;442d   ; intercambia DE y HL
	call 00053h		;442e   ; BIOS SETWRT - Enables VDP to write
	di			;4431
	ex de,hl			;4432   ; los devuelve
	exx			;4433
	ld a,(00006h)		;4434   ; lee el puerto de datos del VDP
	ld c,a			;4437
	exx			;4438
	ex af,af'			;4439
	ret			;443a

; ----------------------------------------------------------------------
; DATOS tabla_registros_vdp: Valores de registro del VDP (SCREEN 2)
;   0x443b..0x4448  (13 bytes)
DATA_tabla_registros_vdp:
	defb 0ebh,0cdh,050h,000h,0f3h,0ebh,0d9h,03ah,007h,000h,04fh,0d9h,0c9h	; 443b  ..P....:..O..

; ======================================================================
; CODIGO 0x4448..0x446d  (37 bytes)
; ======================================================================


ARRANCA_VDP:		; Carga los registros del VDP y borra la VRAM
	ld a,0b8h		;4448   ; arranca los ocho registros del VDP
	call FIJA_MEZCLADOR		;444a
	ld a,09ch		;444d
	call SUMA_BONUS_7B8F		;444f
	ld de,00000h		;4452
	ld bc,04000h		;4455
	xor a			;4458
	call RELLENA_VRAM		;4459
PREPARA_TITULO:
	ld hl,0446dh		;445c
	ld d,008h		;445f
	ld c,000h		;4461
PREPARA_TITULO_4463:
	ld b,(hl)			;4463
	call 00047h		;4464   ; BIOS WRTVDP - Writes data in the VDP-register
	inc hl			;4467
	inc c			;4468
	dec d			;4469
	jr nz,PREPARA_TITULO_4463		;446a
	ret			;446c

; ----------------------------------------------------------------------
; DATOS tabla_vdp_2: Cabecera de la carga de VDP
;   0x446d..0x4475  (8 bytes)
DATA_tabla_vdp_2:
	defb 002h,0e2h,00eh,07fh,007h,076h,003h,0e1h	; 446d  .....v..

; ======================================================================
; CODIGO 0x4475..0x4526  (177 bytes)
; ======================================================================


LEE_MANDOS:		; Junta joystick (PSG) y teclado (filas 7 y 8) en un byte
	ld e,08fh		;4475
	ld hl,0e002h		;4477
	bit 7,(hl)		;447a
	jr z,LEE_MANDOS_PSG		;447c
	set 6,e		;447e
LEE_MANDOS_PSG:
	ld a,00fh		;4480
	call 00093h		;4482   ; BIOS WRTPSG - Writes data to PSG-register
	ld a,00eh		;4485
	call 00096h		;4487   ; BIOS RDPSG - Reads value from PSG-register
	cpl			;448a
	and 03fh		;448b
	ret			;448d
LEE_MANDOS_FLANCO:
	call LEE_MANDOS		;448e   ; lee los mandos y detecta los flancos
	bit 4,(hl)		;4491   ; guarda las teclas recien pulsadas (0xE0F1)
	call nz,LEE_TECLADO		;4493   ; lee el teclado si toca
	ld hl,0e009h		;4496   ; apunta a los mandos (0xE009)
	ld c,(hl)			;4499   ; lee el estado anterior
	ld (hl),a			;449a
	dec hl			;449b
	ld (hl),c			;449c
	ld b,a			;449d
	xor c			;449e
	and b			;449f
	ld (0e0f1h),a		;44a0
	ret			;44a3
LEE_TECLADO:
	ld a,007h		;44a4   ; fila 7 del teclado
	call 00141h		;44a6   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix
	cpl			;44a9   ; invierte los bits del joystick
	rrca			;44aa   ; los rota
	and 020h		;44ab   ; aisla el bit de arriba
	ld e,a			;44ad   ; lo pasa a E
	ld a,008h		;44ae   ; fila 8 del teclado
	call 00141h		;44b0   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix
	cpl			;44b3   ; invierte los bits
	rrca			;44b4   ; los rota
	rrca			;44b5
	ld b,a			;44b6
	and 004h		;44b7
	or e			;44b9
	ld c,a			;44ba
	ld a,b			;44bb
	rrca			;44bc
	rrca			;44bd
	ld b,a			;44be
	and 018h		;44bf
	or c			;44c1
	ld c,a			;44c2
	ld a,b			;44c3
	rrca			;44c4
	and 003h		;44c5
	or c			;44c7
	ret			;44c8
MANEJADOR_DEMO:
	ld e,08fh		;44c9   ; el manejador de demo dibuja su pantalla
	call LEE_MANDOS_PSG		;44cb   ; dibuja el bloque de demo
	ld d,a			;44ce   ; guarda el destino
	ld e,0cfh		;44cf   ; siguiente tramo de la demo
	call LEE_MANDOS_PSG		;44d1   ; lee el registro del PSG del joystick
	or d			;44d4   ; mezcla con el teclado
	ld d,a			;44d5   ; lo guarda
	call LEE_TECLADO		;44d6   ; lee la fila de flechas
	or d			;44d9   ; mezcla joystick y teclado
	ld hl,0e040h		;44da   ; apunta a los records (0xE040)
	ld c,(hl)			;44dd   ; lee el estado
	ld (hl),a			;44de
	inc hl			;44df
	ld (hl),c			;44e0
	ld b,a			;44e1
	xor c			;44e2
	and b			;44e3
	ret z			;44e4
	ld b,a			;44e5
	ld a,000h		;44e6
	ld (0e004h),a		;44e8
	ld a,005h		;44eb
	ld hl,0e000h		;44ed
	cp (hl)			;44f0
	jr nz,MANEJADOR_DEMO_450C		;44f1
	ld a,b			;44f3
	cp 010h		;44f4
	jr c,MANEJADOR_DEMO_4510		;44f6
	ld hl,04526h		;44f8
	ld a,(0e042h)		;44fb
	call HL_MAS_A		;44fe
	ld a,(hl)			;4501
	ld (0e002h),a		;4502
	ld hl,00008h		;4505
	ld (0e000h),hl		;4508
	ret			;450b
MANEJADOR_DEMO_450C:
	ld (hl),a			;450c
	jp ROTULO_PINTA		;450d
MANEJADOR_DEMO_4510:
	push bc			;4510   ; guarda la cuenta del tercio
	call DIBUJA_AGUJA_4373		;4511
	pop af			;4514
	ld hl,0e042h		;4515
	ld b,(hl)			;4518
	rra			;4519
	jr nc,MANEJADOR_DEMO_451D		;451a
	dec b			;451c
MANEJADOR_DEMO_451D:
	rra			;451d
	jr nc,MANEJADOR_DEMO_4521		;451e
	inc b			;4520
MANEJADOR_DEMO_4521:
	ld a,b			;4521
	and 003h		;4522
	ld (hl),a			;4524
	ret			;4525

; ----------------------------------------------------------------------
; DATOS rotulos_y_logo: Guiones de rotulos (TIME, HEIGHT, STAGE, PLAY SELECT)
;   y el logo KONAMI VIDEO CARTRIDGE
;   0x4526..0x4717  (497 bytes)
DATA_rotulos_y_logo:
	defb 040h,060h,050h,070h,088h,03ch,042h,099h,0a1h,0a1h,099h,042h,03ch,003h,000h,081h	; 4526  @`Pp.<B....B<...
	defb 0fch,004h,000h,000h,093h,000h,000h,002h,000h,08ah,0aah,0aah,0dah,000h,000h,008h	; 4536  ................
	defb 048h,0eeh,04ah,04ah,06ah,000h,00fh,01fh,004h,0ffh,089h,00fh,000h,000h,0feh,0e0h	; 4546  H.JJj...........
	defb 0e0h,0c0h,0c0h,080h,000h,051h,038h,055h,050h,0ffh,04ch,038h,054h,049h,04dh,045h	; 4556  .....Q8UP.L8TIME
	defb 03bh,0feh,054h,038h,048h,045h,049h,047h,048h,054h,03bh,0ffh,02ch,038h,032h,04eh	; 4566  ;.T8HEIGHT;.,82N
	defb 044h,0feh,036h,038h,033h,052h,044h,0ffh,00ch,038h,048h,049h,03bh,0feh,022h,038h	; 4576  D.683RD..8HI;."8
	defb 031h,053h,054h,0feh,042h,038h,053h,054h,041h,047h,045h,03bh,0feh,002h,038h,031h	; 4586  1ST.B8STAGE;..81
	defb 050h,03bh,0ffh,016h,038h,032h,050h,03bh,0ffh,0abh,039h,050h,04ch,041h,059h,000h	; 4596  P;..82P;..9PLAY.
	defb 053h,045h,04ch,045h,043h,054h,0feh,007h,03ah,0c1h,0e0h,0dch,0d1h,0e9h,0d5h,0e2h	; 45a6  SELECT..:.......
	defb 000h,000h,0ech,0edh,000h,0dah,0dfh,0e9h,0e3h,0e4h,0d9h,0d3h,0dbh,0feh,047h,03ah	; 45b6  ..............G:
	defb 0c2h,0e0h,0dch,0d1h,0e9h,0d5h,0e2h,0e3h,000h,0ech,0edh,000h,0dah,0dfh,0e9h,0e3h	; 45c6  ................
	defb 0e4h,0d9h,0d3h,0dbh,0feh,087h,03ah,0c1h,0e0h,0dch,0d1h,0e9h,0d5h,0e2h,000h,000h	; 45d6  ......:.........
	defb 0ech,0edh,000h,0dbh,0d5h,0e9h,0d2h,0dfh,0d1h,0e2h,0d4h,0feh,0c7h,03ah,0c2h,0e0h	; 45e6  .............:..
	defb 0dch,0d1h,0e9h,0d5h,0e2h,0e3h,000h,0ech,0edh,000h,0dbh,0d5h,0e9h,0d2h,0dfh,0d1h	; 45f6  ................
	defb 0e2h,0d4h,0feh,00ah,039h,03ah,000h,04bh,04fh,04eh,041h,04dh,049h,000h,031h,039h	; 4606  ....9:.KONAMI.19
	defb 038h,034h,0ffh,066h,039h,03bh,000h,056h,049h,044h,045h,04fh,000h,043h,041h,052h	; 4616  84.f9;.VIDEO.CAR
	defb 054h,052h,049h,044h,047h,045h,000h,03bh,0ffh,000h,066h,006h,03eh,002h,03fh,006h	; 4626  TRIDGE.;..f.>.?.
	defb 00fh,002h,0ffh,09bh,078h,038h,03ch,01ch,01eh,00fh,00fh,007h,01eh,01ch,03ch,038h	; 4636  ....x8<.......<8
	defb 078h,0f0h,0f0h,0e0h,0ffh,0ffh,0ffh,0f1h,0f0h,0f0h,0f1h,0ffh,087h,0e7h,0e7h,004h	; 4646  x...............
	defb 0f7h,081h,0e7h,003h,0feh,003h,080h,083h,0feh,0feh,080h,002h,0e0h,004h,0f0h,083h	; 4656  ................
	defb 0e0h,001h,007h,005h,00fh,0a4h,007h,0f0h,0fch,0fch,09ch,004h,080h,0e0h,0f8h,080h	; 4666  ................
	defb 0e0h,0e1h,0f3h,0f3h,0f7h,0f7h,0e7h,03fh,0ffh,0ffh,0f1h,0c0h,0c0h,080h,080h,080h	; 4676  .......?........
	defb 0e0h,0f0h,0f8h,078h,07ch,03ch,03ch,087h,0e7h,0e7h,004h,0f0h,081h,0e0h,003h,0ffh	; 4686  ...x|<<.........
	defb 005h,078h,094h,087h,09fh,0bfh,03eh,03ch,03eh,03fh,01fh,0c0h,0f0h,0f0h,070h,010h	; 4696  .x....><>?....p.
	defb 000h,080h,0e0h,003h,007h,00fh,00fh,004h,003h,008h,0c0h,081h,03fh,007h,03ch,081h	; 46a6  ............?.<.
	defb 0ffh,007h,00fh,008h,003h,002h,0ffh,006h,0f0h,082h,0e7h,087h,006h,007h,081h,0feh	; 46b6  ................
	defb 004h,080h,003h,0feh,002h,0ffh,002h,0f1h,004h,0f0h,002h,0c0h,002h,0e0h,002h,0f0h	; 46c6  ................
	defb 082h,078h,07ch,0a8h,001h,000h,000h,008h,00eh,00fh,00fh,007h,0fch,03eh,01eh,01eh	; 46d6  .x|..........>..
	defb 03eh,0feh,0fch,0f0h,0e7h,087h,007h,003h,003h,001h,000h,000h,080h,080h,0c0h,0c0h	; 46e6  >...............
	defb 0f1h,0ffh,0ffh,03fh,03ch,03ch,07ch,078h,0f8h,0f0h,0e0h,080h,008h,078h,08fh,007h	; 46f6  ...?<<|x.....x..
	defb 000h,000h,020h,038h,03fh,03fh,01fh,0f0h,0f8h,078h,078h,0f8h,0f8h,0f0h,009h,0c0h	; 4706  .. 8??...xx.....
	defb 000h	; 4716

; ======================================================================
; CODIGO 0x4717..0x4783  (108 bytes)
; ======================================================================


DESCOMPRIME_A_TERCIOS:		; Descomprime el mismo guion en los tres tercios
	ld a,011h		;4717   ; arranca el contador de filas (0xE00A)
	ld (0e00ah),a		;4719   ; lo guarda
	ld hl,00000h		;471c   ; arranca el puntero a 0
	ld (0e00eh),hl		;471f   ; lo guarda (0xE00E)
	ld hl,04783h		;4722   ; apunta a los graficos (0x4783)
	ld de,06300h		;4725
	call DIBUJA_MARCO_4849		;4728
	ld de,00180h		;472b
	ld bc,00280h		;472e
	ld a,0f0h		;4731
	exx			;4733
	ld b,003h		;4734
DESCOMPRIME_A_TERCIOS_4736:
	push bc			;4736   ; guarda la cuenta del tercio
	exx			;4737   ; al banco alterno
	push af			;4738
	push bc			;4739
	call RELLENA_VRAM		;473a   ; rellena un tercio
	pop bc			;473d
	ld a,008h		;473e   ; salto de tercio
	add a,d			;4740   ; avanza el destino
	ld d,a			;4741
	pop af			;4742
	exx			;4743
	pop bc			;4744
	djnz DESCOMPRIME_A_TERCIOS_4736		;4745
	ret			;4747
DESCOMPRIME_A_TERCIOS_4748:
	ld hl,(0e00eh)		;4748   ; sube el puntero de VRAM una fila
	ld de,00020h		;474b   ; resta 0x20 (una fila de nombres)
	add hl,de			;474e   ; avanza a la fila anterior
	ld (0e00eh),hl		;474f   ; guarda el puntero (0xE00E)
	ex de,hl			;4752   ; lo pasa a HL
	or a			;4753   ; limpia el acarreo
	ld hl,03aaah		;4754   ; destino en la VRAM
	sbc hl,de		;4757
	ex de,hl			;4759
	ld a,060h		;475a
	ld b,003h		;475c
	call DESCOMPRIME_A_TERCIOS_4774		;475e
	ld bc,00b0ch		;4761
	call DESCOMPRIME_A_TERCIOS_4774		;4764
	ld b,c			;4767
	call DESCOMPRIME_A_TERCIOS_4774		;4768
	xor a			;476b
	call RELLENA_VRAM		;476c
	ld hl,0e00ah		;476f
	dec (hl)			;4772
	ret			;4773
DESCOMPRIME_A_TERCIOS_4774:
	push de			;4774
DESCOMPRIME_A_TERCIOS_4775:
	call SACA_BYTE_VRAM		;4775   ; saca el byte por el puerto
	inc de			;4778
	inc a			;4779
	djnz DESCOMPRIME_A_TERCIOS_4775		;477a
	pop de			;477c
	ld hl,00020h		;477d
	add hl,de			;4780
	ex de,hl			;4781
	ret			;4782

; ----------------------------------------------------------------------
; DATOS graficos_titulo: Graficos comprimidos de la pantalla de titulo
;   0x4783..0x4816  (147 bytes)
DATA_graficos_titulo:
	defb 00eh,000h,082h,007h,00fh,006h,000h,082h,0f8h,0f0h,004h,03eh,004h,03fh,090h,01fh	; 4783  ...........>.?..
	defb 03fh,07fh,0ffh,0feh,0fch,0f8h,0f0h,0e0h,0c0h,080h,000h,000h,000h,03eh,03eh,005h	; 4793  ?............>>.
	defb 000h,083h,01fh,07fh,0fbh,005h,000h,083h,00fh,0cfh,0efh,005h,000h,083h,078h,0fch	; 47a3  ..............x.
	defb 0bch,005h,000h,083h,03fh,07fh,0f3h,005h,000h,083h,087h,0c7h,0c7h,005h,000h,083h	; 47b3  ....?...........
	defb 0bch,0feh,0dfh,005h,000h,08dh,078h,0fch,0bch,060h,0f0h,0f0h,060h,000h,0f0h,0f0h	; 47c3  ......x..`..`...
	defb 0f0h,03fh,03fh,006h,03eh,090h,0f8h,0fch,0feh,07fh,03fh,01fh,00fh,007h,03eh,03eh	; 47d3  .??.>.....?...>>
	defb 03eh,07eh,0fch,0fch,0f8h,0e0h,005h,0f1h,083h,0fbh,07fh,01fh,006h,0efh,082h,0cfh	; 47e3  >~..............
	defb 00fh,008h,01eh,088h,0e1h,003h,03fh,0f1h,0e1h,0f3h,07fh,01eh,008h,0e7h,008h,08fh	; 47f3  ......?.........
	defb 008h,01eh,082h,0f1h,0f2h,004h,0f5h,08ah,0f2h,0f1h,0e0h,010h,0c8h,068h,0c8h,028h	; 4803  .............h.(
	defb 010h,0e0h,000h	; 4813

; ======================================================================
; CODIGO 0x4816..0x4859  (67 bytes)
; ======================================================================


DIBUJA_MARCO:		; Monta el marco de la pantalla de prueba
	ld a,(0e052h)		;4816   ; el evento (0xE052) elige el marco
	and 003h		;4819   ; lo enmascara a 0..3
	add a,a			;481b   ; lo dobla
	ld hl,04859h		;481c   ; apunta a la tabla de marcos (0x4859)
	call HL_MAS_A		;481f
	ld e,(hl)			;4822
	inc hl			;4823
	ld d,(hl)			;4824
	ex de,hl			;4825
	ld b,004h		;4826
DIBUJA_MARCO_4828:
	push bc			;4828   ; guarda la cuenta
	ld e,(hl)			;4829   ; lee el destino del guion
	inc hl			;482a   ; avanza el puntero
	ld d,(hl)			;482b   ; lee el destino
	inc hl			;482c   ; avanza
	ld a,(hl)			;482d   ; lee el byte
	inc hl			;482e
	push hl			;482f
	ld h,(hl)			;4830
	ld l,a			;4831
	call DIBUJA_MARCO_4849		;4832
	pop hl			;4835
	inc hl			;4836
	pop bc			;4837
	djnz DIBUJA_MARCO_4828		;4838
	ld de,02008h		;483a
	ld hl,04891h		;483d
	call DIBUJA_MARCO_4849		;4840
	ld de,00008h		;4843
	ld hl,04ef8h		;4846
DIBUJA_MARCO_4849:
	ld b,003h		;4849
DIBUJA_MARCO_484B:
	push bc			;484b   ; guarda la cuenta del bucle
	push hl			;484c
	call VUELCA_TABLA_VDP_440D		;484d   ; descomprime un tercio
	ld a,008h		;4850   ; salto de tercio
	add a,d			;4852   ; avanza el destino
	ld d,a			;4853
	pop hl			;4854
	pop bc			;4855
	djnz DIBUJA_MARCO_484B		;4856
	ret			;4858

; ----------------------------------------------------------------------
; DATOS graficos_eventos: Tabla de punteros y graficos comprimidos de las
;   cuatro pruebas
;   0x4859..0x614d  (6388 bytes)
DATA_graficos_eventos:
	defb 061h,048h,079h,048h,069h,048h,081h,048h,040h,025h,076h,04ah,040h,005h,04ch,050h	; 4859  aHyHiH.H@%vJ@.LP
	defb 000h,023h,0a5h,049h,000h,003h,044h,04fh,040h,025h,00ch,04bh,040h,005h,0c2h,050h	; 4869  .#.I..DO@%.K@..P
	defb 000h,025h,0ach,04ch,000h,005h,023h,052h,050h,024h,067h,04ah,050h,004h,004h,050h	; 4879  .%.L..#RP$gJP..P
	defb 000h,025h,0d4h,04dh,000h,005h,033h,053h,024h,000h,08ch,071h,073h,077h,07fh,000h	; 4889  .%.M..3S$..qsw..
	defb 000h,000h,0f8h,0f0h,0e0h,0c0h,080h,005h,000h,094h,0c0h,0c0h,000h,07fh,07fh,077h	; 4899  ...............w
	defb 073h,071h,070h,000h,000h,01ch,09dh,0ddh,0fdh,0fdh,0f8h,000h,000h,0f9h,004h,0ddh	; 48a9  sqp.............
	defb 094h,0f9h,000h,000h,0b0h,0f9h,098h,09bh,09bh,099h,000h,000h,0f1h,019h,0f9h,019h	; 48b9  ................
	defb 0f9h,0ddh,000h,000h,0fch,005h,0b6h,002h,000h,006h,0c0h,008h,000h,002h,003h,002h	; 48c9  ................
	defb 000h,004h,03ch,002h,0ffh,006h,000h,002h,0c0h,002h,003h,006h,000h,002h,0ffh,004h	; 48d9  ..<.............
	defb 03ch,002h,000h,002h,0c0h,00eh,000h,003h,0ffh,082h,0c3h,081h,005h,000h,082h,081h	; 48e9  <...............
	defb 0c3h,004h,0ffh,090h,0ffh,0bbh,0eeh,0bbh,0eeh,0bbh,0eeh,0bbh,0e0h,0a0h,0e0h,0a0h	; 48f9  ................
	defb 0e0h,0a0h,0e0h,0a0h,008h,000h,088h,03eh,07fh,02ah,03eh,01ch,036h,07fh,077h,018h	; 4909  .......>.*>.6.w.
	defb 000h,005h,0ffh,0d5h,0cfh,0cfh,0ffh,000h,01ch,022h,063h,063h,063h,022h,01ch,000h	; 4919  ........."ccc"..
	defb 00ch,01ch,00ch,00ch,00ch,00ch,03fh,000h,03eh,063h,003h,00eh,03ch,070h,07fh,000h	; 4929  ......?.>c..<p..
	defb 03eh,063h,003h,00eh,003h,063h,03eh,000h,00eh,01eh,036h,066h,066h,07fh,006h,000h	; 4939  >c...c>...6ff...
	defb 07fh,060h,07eh,063h,003h,063h,03eh,000h,03eh,063h,060h,07eh,063h,063h,03eh,000h	; 4949  .`~c.c>.>c`~cc>.
	defb 07fh,063h,006h,00ch,018h,018h,018h,000h,03eh,063h,063h,03eh,063h,063h,03eh,000h	; 4959  .c......>cc>cc>.
	defb 03eh,063h,063h,03fh,003h,063h,03eh,000h,066h,005h,029h,081h,076h,08ch,000h,000h	; 4969  >cc?.c>.f.).v...
	defb 063h,063h,063h,000h,0c6h,0c6h,0c6h,05bh,05bh,000h,005h,036h,081h,000h,003h,063h	; 4979  ccc....[[..6...c
	defb 083h,029h,029h,000h,000h,002h,000h,003h,036h,087h,000h,06ch,06ch,06ch,04ah,04ah	; 4989  .)).....6..lllJJ
	defb 000h,005h,063h,081h,000h,003h,036h,002h,06dh,081h,000h,000h,02eh,000h,002h,03ch	; 4999  ..c...6.m......<
	defb 002h,000h,004h,003h,002h,000h,002h,0c3h,004h,000h,002h,0c3h,002h,000h,004h,0c0h	; 49a9  ................
	defb 00ah,000h,002h,03ch,00ah,000h,084h,03eh,07fh,02ah,03eh,00fh,000h,082h,03ch,081h	; 49b9  ...<...>.*>...<.
	defb 005h,000h,082h,081h,0c3h,015h,000h,083h,044h,011h,044h,004h,000h,084h,0e0h,0a0h	; 49c9  ........D.D.....
	defb 0e0h,0a0h,008h,000h,084h,011h,044h,011h,044h,004h,000h,085h,0e0h,0a0h,0e0h,0a0h	; 49d9  ......D.D.......
	defb 0e0h,013h,000h,084h,01ch,036h,07fh,077h,01ch,000h,007h,000h,091h,0f8h,08eh,08ch	; 49e9  .....6.w........
	defb 088h,080h,080h,080h,088h,08ch,0f0h,0e0h,0c0h,080h,01ch,09dh,0ddh,0fdh,004h,000h	; 49f9  ................
	defb 081h,0f9h,003h,0ddh,004h,000h,084h,0b0h,0f9h,098h,09bh,004h,000h,084h,0f1h,019h	; 4a09  ................
	defb 0f9h,019h,004h,000h,088h,0fch,0b6h,0b6h,0b6h,000h,0c0h,0c0h,000h,004h,0c0h,082h	; 4a19  ................
	defb 071h,070h,006h,000h,082h,0fdh,0f8h,006h,000h,082h,0ddh,0f9h,006h,000h,082h,09bh	; 4a29  qp..............
	defb 099h,006h,000h,082h,0f9h,0ddh,006h,000h,082h,0b6h,0b6h,006h,000h,002h,0c0h,006h	; 4a39  ................
	defb 000h,030h,000h,060h,000h,006h,000h,003h,063h,087h,000h,0c6h,0c6h,0c6h,05bh,05bh	; 4a49  .0.`....c.....[[
	defb 000h,005h,036h,081h,000h,003h,063h,002h,029h,005h,000h,008h,000h,000h,038h,00fh	; 4a59  ..6...c.).....8.
	defb 008h,000h,008h,00fh,008h,000h,008h,00fh,018h,000h,008h,00fh,000h,010h,000h,08bh	; 4a69  ................
	defb 0fch,0f0h,0c0h,000h,0fch,0f0h,0c0h,000h,0fch,0f0h,0c0h,005h,000h,004h,000h,08ch	; 4a79  ................
	defb 003h,00fh,03fh,0ffh,0fch,0f0h,0c0h,000h,0fch,0f0h,0c0h,000h,004h,000h,083h,0fch	; 4a89  ..?.............
	defb 0f0h,0c0h,041h,000h,083h,003h,00fh,03fh,003h,0ffh,00ah,000h,086h,003h,00fh,03fh	; 4a99  ..A....?.......?
	defb 0fch,0f0h,0c0h,00eh,000h,088h,003h,00fh,03fh,0ffh,0ffh,0ffh,000h,000h,018h,000h	; 4aa9  ........?.......
	defb 086h,003h,00fh,03fh,0fch,0f0h,0c0h,021h,000h,086h,003h,00fh,03fh,0fch,0f0h,0c0h	; 4ab9  ...?...!....?...
	defb 047h,000h,004h,0ffh,085h,0fch,0ffh,003h,000h,0c0h,004h,0ffh,085h,0fch,0ffh,003h	; 4ac9  G...............
	defb 000h,0c0h,004h,0ffh,081h,00fh,004h,000h,081h,0fch,004h,0ffh,004h,000h,081h,0f0h	; 4ad9  ................
	defb 003h,0ffh,006h,000h,083h,0e0h,0fch,00fh,007h,000h,083h,0ffh,0ffh,003h,005h,000h	; 4ae9  ................
	defb 08fh,0ffh,03fh,00fh,0c0h,0f0h,0ffh,0ffh,0ffh,000h,003h,00fh,03fh,0fch,0f0h,0c0h	; 4af9  ..?.........?...
	defb 009h,000h,000h,08ah,0feh,0fch,0fch,0f8h,0f8h,0f0h,0f0h,0e0h,03fh,0dfh,003h,0e0h	; 4b09  ............?...
	defb 003h,0c0h,083h,0ffh,0ffh,081h,00dh,0ffh,082h,0fch,0fbh,003h,0f8h,003h,0fch,093h	; 4b19  ................
	defb 07fh,03fh,03fh,01fh,01fh,00fh,00fh,007h,01fh,03fh,03fh,07fh,078h,038h,0bfh,0ffh	; 4b29  .??......??.x8..
	defb 03fh,07fh,081h,007h,0ffh,081h,081h,00dh,0ffh,083h,003h,001h,081h,005h,0ffh,088h	; 4b39  ?...............
	defb 007h,003h,003h,001h,01eh,01ch,002h,0ffh,008h,0feh,0a0h,0ffh,0feh,0feh,0fch,0fdh	; 4b49  ................
	defb 0f9h,0fbh,0f2h,067h,047h,0cfh,08fh,09fh,01fh,03fh,03fh,0e6h,0e2h,0f3h,0f1h,0f9h	; 4b59  ...gG....??.....
	defb 0f8h,0fch,0fch,0ffh,07fh,07fh,03fh,0bfh,09fh,0dfh,04fh,008h,000h,088h,0feh,0fch	; 4b69  ......?...O.....
	defb 0fch,0f8h,0f8h,0f0h,0f0h,0e0h,008h,000h,088h,0f6h,0f4h,0f4h,0e8h,0e9h,0d1h,0d3h	; 4b79  ................
	defb 0c3h,002h,07fh,00eh,0ffh,002h,0feh,006h,0ffh,088h,06fh,02fh,02fh,017h,097h,08bh	; 4b89  ..........o//...
	defb 0cbh,0c3h,008h,000h,090h,07fh,03fh,03fh,01fh,01fh,00fh,00fh,007h,0e0h,0e0h,0c0h	; 4b99  ......??........
	defb 0c0h,080h,080h,000h,000h,008h,000h,090h,087h,087h,08fh,00fh,01fh,01fh,03fh,03fh	; 4ba9  ..............??
	defb 0e1h,0e1h,0f1h,0f0h,0f8h,0f8h,0fch,0fch,008h,000h,085h,0f8h,0fch,0fch,0feh,0feh	; 4bb9  ................
	defb 003h,0ffh,004h,000h,084h,001h,003h,003h,007h,004h,0ffh,084h,03fh,0dfh,01fh,01fh	; 4bc9  ............?...
	defb 006h,0ffh,081h,081h,008h,000h,005h,0ffh,084h,0fch,0fah,0f8h,0f8h,004h,000h,08dh	; 4bd9  ................
	defb 080h,0c0h,0c0h,0e0h,0f8h,0f0h,0f0h,0e0h,0e0h,0c0h,0c0h,080h,01fh,004h,03fh,083h	; 4be9  ..............?.
	defb 07fh,07fh,0ffh,006h,0ffh,081h,081h,009h,0ffh,081h,0f8h,004h,0fch,002h,0feh,08ch	; 4bf9  ................
	defb 0ffh,0e0h,0f0h,0f0h,0f8h,0f8h,0fch,0fch,0feh,087h,038h,040h,00dh,0ffh,005h,000h	; 4c09  ..........8@....
	defb 083h,001h,001h,003h,004h,000h,084h,098h,0b8h,030h,070h,010h,000h,004h,000h,084h	; 4c19  .........0p.....
	defb 019h,01dh,00ch,00eh,005h,000h,083h,080h,080h,0c0h,008h,000h,083h,0e1h,01ch,002h	; 4c29  ................
	defb 005h,000h,004h,0ffh,084h,0feh,0fch,0fch,0f8h,008h,000h,08eh,0fdh,0f9h,0fbh,0f2h	; 4c39  ................
	defb 0f6h,0f4h,0f4h,0e8h,09fh,01fh,03fh,03fh,07fh,07fh,00ah,0ffh,090h,0f9h,0f8h,0fch	; 4c49  ......??........
	defb 0fch,0feh,0feh,0ffh,0ffh,0bfh,09fh,0dfh,04fh,06fh,02fh,02fh,017h,00ch,0ffh,08ch	; 4c59  ........Oo//....
	defb 07fh,03fh,03fh,01fh,0f8h,0f0h,0f0h,0e0h,0e0h,0c0h,0c0h,080h,008h,0ffh,099h,0e9h	; 4c69  .??.............
	defb 0d1h,0d3h,0c3h,087h,087h,08fh,08fh,097h,08bh,0cbh,0c3h,0e1h,0e1h,0f1h,0f1h,0e0h	; 4c79  ................
	defb 0f0h,0f0h,0f8h,0f8h,0fch,0fch,0feh,080h,00fh,000h,002h,0e0h,002h,0c0h,00ch,000h	; 4c89  ................
	defb 002h,007h,002h,003h,00ch,000h,081h,001h,02fh,000h,004h,00fh,00ch,000h,004h,000h	; 4c99  ......../.......
	defb 004h,0ffh,000h,007h,000h,081h,003h,003h,000h,083h,003h,00fh,03fh,005h,0ffh,004h	; 4ca9  ............?...
	defb 000h,081h,0ffh,007h,000h,082h,0ffh,000h,003h,0ffh,096h,0fch,0f0h,0c0h,000h,000h	; 4cb9  ................
	defb 0f0h,0c0h,000h,000h,003h,00ch,030h,000h,0fch,0f0h,0cch,03ch,0fch,0f0h,0c0h,0f0h	; 4cc9  ......0....<....
	defb 0c0h,016h,000h,086h,0c0h,003h,00fh,03fh,0ffh,0ffh,007h,000h,083h,003h,00fh,03fh	; 4cd9  .......?.......?
	defb 003h,0ffh,081h,0c0h,003h,000h,084h,00fh,0ffh,0ffh,0f0h,004h,000h,083h,0ffh,0ffh	; 4ce9  ................
	defb 0f0h,004h,000h,095h,003h,0ffh,000h,0ffh,0fch,0f0h,0c0h,000h,000h,003h,0ffh,000h	; 4cf9  ................
	defb 000h,003h,00ch,030h,0c0h,003h,000h,0c0h,000h,003h,0c0h,003h,000h,083h,003h,00fh	; 4d09  ...0............
	defb 00fh,004h,000h,002h,00fh,006h,000h,081h,00fh,007h,000h,084h,003h,00fh,000h,003h	; 4d19  ................
	defb 004h,000h,082h,0f0h,0c0h,006h,000h,085h,0fch,0f0h,0c0h,080h,080h,00fh,000h,086h	; 4d29  ................
	defb 0fch,0feh,0ffh,0ffh,003h,001h,00eh,000h,008h,007h,008h,0ffh,084h,001h,003h,00fh	; 4d39  ................
	defb 03fh,004h,000h,008h,007h,00eh,0ffh,087h,0fch,0f0h,0ffh,0ffh,0fch,0f0h,0c0h,003h	; 4d49  ?...............
	defb 000h,008h,007h,008h,000h,002h,0ffh,00ch,000h,08bh,003h,00fh,0ffh,0ffh,000h,00fh	; 4d59  ................
	defb 03fh,0fch,0f0h,0c0h,0c0h,00fh,000h,084h,0c0h,0fch,0f0h,0c0h,006h,000h,087h,003h	; 4d69  ?...............
	defb 007h,0f8h,0f0h,0f0h,0f0h,0c0h,00bh,000h,086h,0c0h,0e0h,0f0h,0f0h,0c0h,0e0h,006h	; 4d79  ................
	defb 0f0h,003h,00fh,081h,00fh,008h,000h,004h,070h,00bh,00fh,081h,0fch,004h,000h,084h	; 4d89  ........p.......
	defb 0e0h,0c0h,000h,0ffh,004h,000h,010h,070h,004h,000h,087h,003h,00fh,03fh,0ffh,0ffh	; 4d99  .......p.....?..
	defb 0ffh,0c0h,005h,000h,008h,070h,008h,000h,091h,0ffh,0ffh,000h,000h,003h,00fh,03fh	; 4da9  .....p.........?
	defb 0fch,000h,000h,0f0h,0f0h,0f0h,0c0h,000h,000h,003h,003h,00fh,004h,000h,084h,003h	; 4db9  ................
	defb 00fh,000h,003h,004h,000h,082h,0f0h,0c0h,006h,000h,000h,004h,0ffh,089h,0e4h,0e3h	; 4dc9  ................
	defb 0e7h,0e7h,0ffh,0ffh,0f8h,087h,07fh,003h,0ffh,082h,0e7h,007h,019h,0e7h,003h,0c3h	; 4dd9  ................
	defb 082h,081h,042h,003h,0e7h,003h,0c3h,08ah,081h,042h,0feh,0fdh,0fbh,0f7h,0efh,0dfh	; 4de9  ..B......B......
	defb 0bfh,07fh,008h,0c3h,08ah,07fh,0bfh,0dfh,0efh,0f7h,0fbh,0fdh,0feh,0c2h,0c1h,004h	; 4df9  ................
	defb 0c3h,08ah,083h,043h,0feh,0fdh,0fbh,0f7h,0efh,0dfh,0bfh,07fh,008h,0c3h,082h,043h	; 4e09  ...C...........C
	defb 083h,004h,0c3h,092h,0c1h,0c2h,07fh,0bfh,0dfh,0efh,0f7h,0fbh,0fdh,0feh,0feh,0fdh	; 4e19  ................
	defb 0fbh,0f7h,0efh,0dfh,0bfh,07fh,008h,0c3h,088h,07fh,0bfh,0dfh,0efh,0f7h,0fbh,0fdh	; 4e29  ................
	defb 0feh,004h,0ffh,004h,0feh,003h,0ffh,089h,0f8h,047h,03fh,07fh,07fh,0feh,0f0h,08eh	; 4e39  .........G?.....
	defb 07eh,004h,0feh,008h,07fh,010h,0feh,008h,07fh,003h,0feh,003h,0fch,082h,0f8h,0f4h	; 4e49  ~...............
	defb 003h,07fh,003h,03fh,082h,01fh,02fh,003h,0feh,003h,0fch,082h,0f8h,0f4h,003h,07fh	; 4e59  ...?../.........
	defb 089h,03fh,03eh,03dh,01bh,027h,0ech,0dch,0bch,07ch,004h,0fch,084h,037h,03bh,03dh	; 4e69  .?>=.'...|...7;=
	defb 03eh,004h,03fh,004h,0ffh,084h,07fh,0bfh,0dfh,0efh,004h,0ffh,090h,0feh,0fdh,0fbh	; 4e79  >.?.............
	defb 0f7h,0ech,0dch,0bch,07ch,0fch,0fch,0f8h,0f4h,027h,01bh,03dh,03eh,004h,03fh,004h	; 4e89  ....|....'.=>.?.
	defb 0fch,084h,07ch,0bch,0dch,0ech,008h,03fh,084h,0f7h,0fbh,0fdh,0feh,008h,0ffh,090h	; 4e99  ..|....?........
	defb 0feh,0fdh,0fbh,0f7h,0efh,0dfh,0bfh,07fh,0feh,0fdh,0fbh,0f7h,0ech,0dch,0bch,07ch	; 4ea9  ...............|
	defb 004h,0fch,008h,03fh,082h,0f4h,0f8h,006h,0fch,006h,03fh,086h,01fh,02fh,0f7h,0fbh	; 4eb9  ...?......?../..
	defb 0fdh,0feh,008h,0ffh,084h,07fh,0bfh,0dfh,0efh,004h,0ffh,088h,0feh,0fdh,0fbh,0f7h	; 4ec9  ................
	defb 0efh,0dfh,0bfh,07fh,004h,0ffh,008h,0fch,008h,03fh,084h,0f7h,0fbh,0fdh,0feh,008h	; 4ed9  .........?......
	defb 0ffh,088h,07fh,0bfh,0dfh,0efh,0efh,0dfh,0bfh,07fh,004h,0ffh,008h,0fch,000h,010h	; 4ee9  ................
	defb 00eh,008h,00ch,008h,002h,050h,04eh,030h,0f6h,008h,00fh,010h,0f6h,008h,04fh,090h	; 4ef9  .....PN0......O.
	defb 046h,04fh,046h,04fh,046h,04fh,046h,04fh,046h,04fh,046h,04fh,046h,04fh,046h,04fh	; 4f09  FOFOFOFOFOFOFOFO
	defb 002h,0f2h,003h,0b2h,003h,042h,008h,007h,008h,006h,008h,005h,060h,01fh,098h,001h	; 4f19  .....B......`...
	defb 00ah,012h,062h,072h,00eh,012h,0b2h,0b2h,058h,085h,00eh,012h,0f2h,0f2h,062h,062h	; 4f29  ..br....X.....bb
	defb 00eh,012h,0b2h,0b2h,0d7h,07dh,011h,000h,018h,0ach,000h,005h,001h,007h,00eh,008h	; 4f39  .....}..........
	defb 00ch,00ch,002h,004h,00eh,004h,006h,004h,00eh,00ch,0f6h,008h,06fh,008h,0f6h,004h	; 4f49  ............o...
	defb 006h,004h,002h,004h,0f6h,004h,002h,004h,00ch,084h,0f2h,0f2h,0b2h,0b2h,004h,00eh	; 4f59  ................
	defb 004h,00fh,004h,00eh,004h,06fh,008h,0f6h,004h,00fh,00ch,002h,004h,00eh,004h,0f4h	; 4f69  .....o..........
	defb 004h,00eh,084h,046h,04fh,046h,04fh,004h,00eh,084h,006h,00fh,006h,00fh,004h,0f4h	; 4f79  ...FOFO.........
	defb 090h,006h,00fh,006h,00fh,046h,04fh,046h,04fh,066h,04fh,046h,04fh,006h,00fh,006h	; 4f89  .....FOFOfOFO...
	defb 00fh,00ch,002h,081h,0b2h,003h,042h,004h,00fh,018h,000h,005h,001h,083h,00eh,00eh	; 4f99  ......B.........
	defb 04eh,008h,0e4h,034h,04eh,004h,00ch,004h,04eh,004h,00ch,004h,04eh,004h,00ch,004h	; 4fa9  N..4N...N...N...
	defb 04eh,004h,00ch,004h,04eh,004h,00ch,004h,04eh,004h,00ch,004h,04eh,004h,00ch,004h	; 4fb9  N...N...N...N...
	defb 00eh,004h,007h,004h,00eh,004h,00fh,004h,00eh,004h,006h,004h,007h,004h,002h,004h	; 4fc9  ................
	defb 00fh,00ch,002h,060h,000h,004h,005h,097h,001h,00ah,012h,062h,072h,00eh,012h,0b2h	; 4fd9  ...`.......br...
	defb 0b2h,058h,085h,00eh,012h,0f2h,0f2h,062h,062h,00eh,012h,0b2h,0b2h,0d7h,07dh,005h	; 4fe9  .X.....bb.....}.
	defb 001h,088h,008h,007h,008h,007h,008h,007h,007h,008h,000h,020h,07ch,008h,0f7h,008h	; 4ff9  ........... |...
	defb 08fh,008h,0c8h,002h,00eh,006h,005h,002h,0efh,006h,05fh,006h,005h,002h,001h,006h	; 5009  .........._.....
	defb 05fh,002h,011h,088h,006h,009h,006h,009h,006h,009h,009h,006h,084h,009h,009h,009h	; 5019  _...............
	defb 006h,004h,009h,006h,00eh,002h,004h,008h,05fh,008h,0f5h,004h,005h,084h,00fh,00fh	; 5029  ........_.......
	defb 0f1h,0f1h,004h,005h,084h,00fh,00fh,001h,001h,004h,005h,084h,00fh,00fh,0f1h,0f1h	; 5039  ................
	defb 008h,005h,000h,008h,004h,003h,00fh,005h,00eh,004h,0feh,00ch,0e4h,00ch,07fh,004h	; 5049  ................
	defb 0feh,003h,007h,081h,008h,004h,07fh,040h,000h,004h,09fh,004h,08fh,004h,009h,084h	; 5059  .......@........
	defb 008h,008h,005h,005h,003h,069h,005h,065h,010h,09fh,002h,088h,006h,0ffh,004h,055h	; 5069  .....i.e.......U
	defb 004h,099h,002h,088h,006h,055h,004h,055h,003h,069h,009h,065h,005h,009h,083h,008h	; 5079  .....U.U.i.e....
	defb 008h,005h,081h,005h,004h,009h,083h,008h,008h,005h,081h,005h,005h,009h,002h,008h	; 5089  ................
	defb 002h,005h,004h,069h,002h,065h,048h,065h,004h,090h,002h,089h,002h,085h,005h,095h	; 5099  ...i.eHe........
	defb 083h,089h,089h,085h,006h,095h,002h,098h,028h,095h,003h,098h,005h,058h,004h,069h	; 50a9  ........(....X.i
	defb 004h,065h,003h,007h,081h,008h,004h,007h,000h,084h,0c1h,0c6h,0c6h,0a6h,004h,0c6h	; 50b9  .e..............
	defb 084h,061h,081h,061h,06eh,004h,06fh,084h,060h,080h,0e1h,0e1h,004h,0f0h,008h,000h	; 50c9  .a.an.o.`.......
	defb 084h,061h,081h,016h,0e6h,004h,0f6h,084h,0c1h,0c6h,0c6h,0a6h,004h,0c6h,004h,06ch	; 50d9  .a.............l
	defb 084h,081h,019h,0f1h,060h,088h,0f6h,0f6h,01eh,060h,088h,099h,0ffh,066h,088h,0f0h	; 50e9  ....`....`...f..
	defb 0f0h,01eh,060h,080h,090h,0f0h,060h,008h,000h,088h,06fh,06fh,01eh,066h,088h,099h	; 50f9  ..`...`...oo.f..
	defb 0ffh,066h,004h,0c6h,084h,081h,019h,01fh,066h,008h,000h,084h,0cch,0ceh,0ceh,0aeh	; 5109  .f......f.......
	defb 007h,0ceh,081h,0aeh,007h,0ceh,081h,0aeh,004h,0ceh,084h,0cch,0ceh,0ceh,0aeh,004h	; 5119  ................
	defb 0ceh,008h,000h,008h,0c1h,038h,01eh,010h,0c1h,020h,01eh,008h,01ch,005h,01ch,083h	; 5129  .....8... ......
	defb 06ch,06ch,06ah,004h,0c0h,084h,061h,081h,016h,0e6h,004h,0c0h,084h,060h,080h,0e1h	; 5139  llj...a......`..
	defb 0eeh,008h,000h,004h,0c0h,084h,061h,081h,016h,0e6h,005h,01ch,083h,06ch,06ch,06ah	; 5149  ......a......llj
	defb 008h,0c6h,006h,0f6h,082h,0e6h,060h,006h,0f0h,082h,01eh,060h,008h,000h,006h,0f6h	; 5159  ......`....`....
	defb 082h,0e6h,060h,008h,06ch,088h,018h,019h,01fh,066h,0cch,0cch,0cch,0aah,008h,000h	; 5169  ..`.l....f......
	defb 098h,0c8h,0c9h,0cfh,0c6h,0cch,0ech,0ech,0eah,008h,009h,00fh,006h,0ech,0ech,0ech	; 5179  ................
	defb 0eah,008h,009h,00fh,006h,00ch,00ch,00ch,00ah,008h,000h,090h,008h,009h,00fh,006h	; 5189  ................
	defb 0ech,0ech,0ech,0eah,0c8h,0c9h,0cfh,0c6h,0cch,0ech,0ech,0eah,008h,000h,088h,018h	; 5199  ................
	defb 019h,01fh,016h,00ch,00ch,00ch,00ah,010h,0c1h,004h,0ceh,004h,01eh,004h,0ceh,004h	; 51a9  ................
	defb 01eh,004h,0c0h,004h,010h,004h,0ceh,004h,01eh,004h,0ceh,00ch,01eh,010h,0c1h,008h	; 51b9  ................
	defb 010h,010h,01eh,008h,01ch,004h,0c1h,003h,00ch,081h,00ah,008h,000h,004h,0e1h,003h	; 51c9  ................
	defb 00ch,081h,00ah,004h,001h,003h,00ch,081h,00ah,004h,0e1h,003h,00ch,081h,00ah,008h	; 51d9  ................
	defb 000h,004h,0c1h,003h,00ch,081h,00ah,088h,00ah,00ch,00ah,00ch,00ah,00ch,00ch,00ah	; 51e9  ................
	defb 003h,00ch,081h,00ah,004h,00ch,004h,002h,084h,00ah,00ch,00ah,00ch,004h,00fh,08ch	; 51f9  ................
	defb 00ah,00ch,00ah,00ch,00ah,00ch,00ch,00ah,00ch,00ch,00ch,00ah,004h,0ceh,084h,00ah	; 5209  ................
	defb 00ch,00ah,00ch,007h,00ch,081h,00ah,008h,0f2h,000h,008h,08eh,008h,08eh,007h,0e8h	; 5219  ................
	defb 081h,06eh,002h,06eh,006h,068h,004h,08eh,004h,086h,081h,08eh,004h,086h,003h,0e6h	; 5229  .n.n.h..........
	defb 008h,06eh,099h,0e8h,0e6h,0e6h,0e6h,00eh,00eh,004h,004h,006h,001h,006h,006h,00eh	; 5239  .n..............
	defb 00eh,004h,004h,001h,001h,006h,006h,00eh,00eh,004h,004h,016h,005h,0e6h,002h,004h	; 5249  ................
	defb 008h,08eh,007h,0e8h,081h,068h,007h,0e8h,081h,06eh,006h,0e8h,002h,068h,002h,08eh	; 5259  .....h...n...h..
	defb 005h,086h,081h,0e6h,008h,0e6h,008h,06eh,006h,06eh,002h,004h,098h,068h,016h,006h	; 5269  .......n.n...h..
	defb 006h,00eh,00eh,004h,004h,016h,001h,006h,006h,00eh,00eh,004h,004h,061h,061h,006h	; 5279  .............aa.
	defb 0e6h,00eh,00eh,004h,004h,006h,06eh,082h,004h,004h,003h,09fh,082h,06fh,09ah,003h	; 5289  ......n......o..
	defb 00ah,004h,00fh,004h,00ah,008h,0afh,008h,09fh,004h,00ah,004h,009h,004h,0aah,004h	; 5299  ................
	defb 0f9h,004h,0aah,004h,099h,003h,09fh,081h,06fh,004h,009h,006h,01eh,00ah,014h,010h	; 52a9  ........o.......
	defb 0e8h,002h,01eh,00eh,018h,008h,0e8h,002h,0eeh,006h,068h,003h,0e8h,002h,068h,003h	; 52b9  ..........h...h.
	defb 06eh,091h,0e8h,008h,006h,006h,00eh,00eh,004h,004h,008h,008h,006h,006h,00eh,00eh	; 52c9  n...............
	defb 004h,004h,086h,005h,06eh,086h,004h,004h,009h,009h,0f9h,0f6h,004h,09ah,081h,09fh	; 52d9  ....n...........
	defb 003h,0ffh,004h,0aah,008h,0afh,003h,0f9h,081h,0f6h,004h,0f9h,003h,0a9h,081h,0a6h	; 52e9  ................
	defb 004h,0a9h,004h,0aah,00ch,0f9h,003h,0fah,081h,0a6h,004h,009h,002h,0f9h,006h,069h	; 52f9  ...............i
	defb 006h,01eh,00ah,014h,008h,08eh,008h,0e8h,002h,01eh,00eh,018h,004h,0e8h,003h,068h	; 5309  ...............h
	defb 081h,06eh,003h,08eh,005h,06eh,002h,08eh,004h,06eh,002h,004h,088h,068h,068h,006h	; 5319  .n...n...n...hh.
	defb 0e6h,00eh,00eh,004h,004h,006h,06eh,002h,004h,000h,020h,021h,094h,061h,091h,061h	; 5329  ......n... !.a.a
	defb 091h,061h,091h,091h,061h,061h,091h,061h,09fh,061h,091h,091h,061h,091h,091h,091h	; 5339  .a..aa.a.a..a...
	defb 06fh,007h,091h,081h,061h,007h,091h,081h,061h,007h,091h,081h,061h,007h,091h,081h	; 5349  o...a...a...a...
	defb 061h,004h,091h,006h,0e1h,002h,041h,006h,0e1h,002h,041h,006h,0e1h,002h,041h,006h	; 5359  a.....A...A...A.
	defb 0e1h,002h,041h,018h,0e1h,028h,021h,0a4h,061h,091h,061h,091h,061h,091h,091h,061h	; 5369  ..A..(!.a.a.a..a
	defb 061h,091h,061h,091h,061h,091h,091h,061h,061h,091h,061h,09fh,061h,091h,091h,061h	; 5379  a.a.a..aa.a.a..a
	defb 061h,091h,061h,09fh,061h,091h,091h,061h,091h,091h,091h,06fh,007h,091h,081h,06fh	; 5389  a.a.a..a...o...o
	defb 007h,091h,081h,061h,007h,091h,081h,061h,004h,091h,003h,099h,081h,066h,004h,091h	; 5399  ...a...a.....f..
	defb 003h,099h,081h,066h,007h,091h,081h,061h,007h,091h,081h,061h,007h,091h,081h,061h	; 53a9  ...f...a...a...a
	defb 007h,091h,081h,061h,007h,091h,081h,061h,004h,099h,006h,0e1h,002h,041h,006h,0e1h	; 53b9  ...a...a.....A..
	defb 002h,041h,006h,0e1h,002h,041h,006h,0e1h,002h,041h,006h,0e1h,002h,041h,006h,0e1h	; 53c9  .A...A...A...A..
	defb 002h,041h,006h,0e1h,002h,044h,006h,0e1h,002h,041h,036h,0e1h,002h,044h,006h,0e1h	; 53d9  .A...D...A6..D..
	defb 002h,041h,000h,08bh,007h,00fh,01eh,01ch,018h,018h,01ch,00ch,000h,007h,009h,004h	; 53e9  .A..............
	defb 008h,086h,000h,0c0h,0f0h,030h,000h,040h,004h,000h,081h,0c0h,006h,0e0h,084h,0c6h	; 53f9  .....0.@........
	defb 0c2h,0e2h,07ch,008h,000h,084h,078h,038h,03ch,03fh,010h,000h,08ah,000h,000h,01ch	; 5409  ..|...x8<?......
	defb 03eh,07ah,07fh,03eh,03ch,038h,07ch,006h,0feh,010h,000h,084h,038h,03ch,01ch,000h	; 5419  >z.><8|.....8<..
	defb 004h,07ch,088h,03ch,07ch,078h,078h,078h,038h,03ch,03fh,010h,000h,000h,002h,000h	; 5429  .|.<|xxx8<?.....
	defb 005h,001h,003h,000h,095h,002h,003h,001h,011h,03fh,000h,0ech,0ffh,0e3h,0c0h,084h	; 5439  .........?......
	defb 080h,0c0h,040h,030h,030h,070h,0f0h,0f0h,0e0h,0c0h,004h,000h,003h,03fh,087h,01eh	; 5449  ..@00p.......?..
	defb 004h,000h,000h,000h,001h,003h,003h,007h,003h,000h,002h,080h,006h,000h,085h,080h	; 5459  ................
	defb 0e0h,0c0h,080h,0e0h,007h,000h,081h,00fh,003h,01fh,002h,00fh,082h,01fh,03fh,003h	; 5469  ..............?.
	defb 000h,086h,01ch,03eh,07ah,07fh,03eh,0bch,005h,0f0h,08ch,0e0h,0c0h,000h,000h,000h	; 5479  ...>z.>.........
	defb 001h,003h,001h,000h,000h,001h,003h,003h,007h,004h,000h,08ch,040h,0e0h,0f0h,0f8h	; 5489  ............@...
	defb 0f8h,078h,0f8h,0f0h,0e0h,0c0h,080h,0e0h,004h,000h,000h,099h,001h,003h,007h,007h	; 5499  .x..............
	defb 006h,006h,007h,003h,007h,00eh,01eh,03eh,07fh,0ffh,0ffh,000h,0f0h,0fch,08ch,000h	; 54a9  .......>........
	defb 010h,000h,000h,000h,0c0h,004h,000h,081h,080h,005h,000h,085h,0feh,0feh,0fch,078h	; 54b9  ...............x
	defb 010h,003h,000h,085h,006h,00fh,01fh,01eh,01fh,00ch,000h,084h,080h,000h,000h,080h	; 54c9  ................
	defb 004h,000h,002h,001h,002h,000h,0a4h,007h,00fh,01fh,03fh,07fh,0ffh,0ffh,000h,000h	; 54d9  ..........?.....
	defb 000h,070h,0f8h,0e8h,0fch,0f8h,0f0h,0c7h,0c7h,0efh,0feh,0fch,0f8h,000h,000h,001h	; 54e9  .p..............
	defb 003h,007h,00fh,007h,001h,003h,007h,00fh,01fh,01eh,01fh,005h,000h,082h,080h,0c0h	; 54f9  ................
	defb 004h,0e0h,085h,0c0h,080h,000h,000h,080h,004h,000h,000h,089h,007h,00fh,01eh,01ch	; 5509  ................
	defb 018h,018h,01ch,00ch,007h,005h,00fh,087h,007h,000h,0c0h,0f0h,030h,000h,040h,005h	; 5519  ............0.@.
	defb 000h,081h,080h,004h,0e0h,084h,000h,00fh,00fh,007h,007h,000h,089h,020h,030h,078h	; 5529  ............. 0x
	defb 078h,07ch,01eh,0e0h,0e0h,0c0h,00fh,000h,087h,001h,003h,007h,007h,003h,003h,007h	; 5539  x|..............
	defb 005h,00fh,08ch,007h,000h,00eh,00eh,0c6h,0e6h,0aeh,0feh,0feh,0fch,0f8h,0f0h,005h	; 5549  ................
	defb 0e0h,004h,000h,005h,007h,088h,00fh,01fh,03eh,03ch,078h,078h,07ch,01eh,003h,000h	; 5559  ........><xx|...
	defb 005h,0c0h,081h,080h,016h,000h,081h,00fh,00fh,000h,081h,0e0h,000h,083h,004h,00ch	; 5569  ................
	defb 01ch,004h,018h,082h,008h,000h,005h,00fh,08bh,007h,000h,0c0h,0f0h,030h,000h,040h	; 5579  .............0.@
	defb 000h,000h,000h,0c0h,006h,0e0h,008h,000h,002h,00fh,087h,01eh,03eh,03ch,01ch,00ch	; 5589  ............><..
	defb 00ch,008h,010h,000h,085h,07ah,07fh,07eh,07ch,07ch,005h,0feh,081h,07eh,004h,000h	; 5599  .....z.~||...~..
	defb 081h,07ch,010h,000h,005h,007h,004h,00fh,087h,01eh,03eh,03ch,01ch,00ch,00ch,008h	; 55a9  .|........><....
	defb 004h,0c0h,002h,080h,010h,000h,002h,003h,081h,007h,006h,003h,081h,007h,00eh,000h	; 55b9  ................
	defb 082h,0c0h,0e0h,00bh,000h,003h,0feh,081h,07ch,011h,000h,000h,002h,000h,005h,001h	; 55c9  ........|.......
	defb 003h,000h,09bh,003h,007h,007h,00fh,00fh,007h,07ch,0ffh,0e3h,0c0h,084h,080h,0c0h	; 55d9  .........|......
	defb 060h,030h,078h,0f8h,0f8h,0f0h,0f0h,0f0h,0e0h,00fh,00fh,00fh,007h,002h,004h,000h	; 55e9  `0x.............
	defb 08ah,001h,003h,007h,007h,007h,003h,001h,0e0h,0e0h,0c0h,006h,000h,087h,080h,0e0h	; 55f9  ................
	defb 0c0h,080h,080h,080h,0c0h,004h,000h,002h,001h,003h,000h,097h,001h,003h,007h,007h	; 5609  ................
	defb 007h,003h,001h,000h,000h,030h,0f0h,0f8h,0fch,0fch,07ch,0f8h,0f0h,0e0h,0c0h,080h	; 5619  .....0....|.....
	defb 080h,080h,0c0h,007h,000h,099h,01fh,07fh,0ffh,0f3h,0e7h,0f7h,07fh,00fh,007h,000h	; 5629  ................
	defb 000h,01ch,03eh,07ah,07fh,03eh,0fch,0f0h,0f8h,0f8h,0f8h,0f0h,0f0h,0f0h,0e0h,020h	; 5639  ..>z.>......... 
	defb 000h,000h,099h,000h,003h,007h,00fh,00eh,00ch,00ch,006h,01fh,03ch,07ch,0feh,0ffh	; 5649  ............<|..
	defb 0ffh,0ffh,0fch,000h,0e0h,0f8h,018h,000h,020h,000h,000h,0c0h,007h,000h,086h,006h	; 5659  ........ .......
	defb 0feh,0fch,07ch,03ch,01ch,00ah,000h,086h,001h,005h,00fh,00fh,00eh,00ch,00eh,000h	; 5669  ..|<............
	defb 087h,001h,003h,003h,001h,01fh,03fh,07fh,004h,0ffh,093h,0fch,000h,000h,000h,0e0h	; 5679  ......?.........
	defb 0f0h,0d0h,0f8h,0f0h,0e0h,0c0h,0e0h,0f8h,0fch,03ch,07eh,0feh,0f9h,001h,004h,003h	; 5689  .........<~.....
	defb 00ah,000h,086h,0fdh,0fdh,0efh,0cfh,08eh,00ch,00ah,000h,000h,005h,000h,088h,01fh	; 5699  ................
	defb 07fh,0ffh,0ffh,0ffh,07fh,03fh,01fh,006h,000h,088h,00fh,01fh,033h,0e1h,0c0h,0c0h	; 56a9  .....?......3...
	defb 022h,010h,007h,000h,087h,030h,038h,03ch,03fh,03fh,01ch,008h,00ch,000h,081h,080h	; 56b9  "....08<??......
	defb 005h,000h,084h,039h,03fh,03eh,038h,00ah,000h,087h,01fh,07fh,0ffh,0ffh,0ffh,07fh	; 56c9  ...9?>8.........
	defb 03fh,009h,000h,08dh,00ch,0deh,0ffh,0ffh,0fdh,0ffh,0e2h,01fh,000h,007h,01fh,03fh	; 56d9  ?..............?
	defb 01fh,005h,001h,005h,000h,081h,0e0h,004h,0f0h,086h,0e0h,0c0h,0c8h,0f8h,0f0h,0c0h	; 56e9  ................
	defb 009h,000h,087h,080h,0c0h,0c0h,0c0h,0e0h,0e0h,040h,015h,000h,000h,08ah,0f8h,0fch	; 56f9  .........@......
	defb 0feh,0ffh,0ffh,0ffh,079h,071h,001h,001h,00ah,000h,089h,078h,0fch,09eh,00eh,006h	; 5709  ....yq.....x....
	defb 006h,026h,00ch,00ch,013h,000h,087h,006h,00eh,01eh,03eh,03eh,03fh,003h,005h,000h	; 5719  .&........>>?...
	defb 093h,03ch,03eh,01ch,00fh,0f8h,0fch,0feh,0ffh,0ffh,0ffh,07fh,07fh,09fh,0dfh,0fdh	; 5729  .<>.............
	defb 0f8h,0f8h,0f0h,0c0h,007h,000h,087h,060h,0f0h,0f8h,0f8h,0d8h,0f0h,040h,019h,000h	; 5739  .......`.....@..
	defb 08ah,03ch,03fh,01fh,00fh,007h,003h,03fh,03fh,01ch,00fh,000h,083h,003h,007h,00fh	; 5749  .<?....??.......
	defb 005h,01fh,08bh,001h,001h,002h,004h,000h,000h,002h,000h,080h,0c0h,0c0h,005h,0e0h	; 5759  ................
	defb 088h,0c0h,0c0h,060h,030h,018h,018h,038h,078h,004h,000h,081h,001h,005h,000h,003h	; 5769  ...`0..8x.......
	defb 078h,08ch,030h,030h,018h,000h,000h,07ch,0fch,0f8h,0f0h,060h,060h,020h,00eh,000h	; 5779  x.00...|...`` ..
	defb 003h,007h,083h,003h,003h,001h,005h,000h,091h,010h,039h,039h,03dh,03dh,07dh,0ffh	; 5789  ..........99==}.
	defb 0ffh,03fh,01eh,080h,000h,000h,000h,038h,07ch,0fch,005h,0feh,088h,0fch,0fch,0f8h	; 5799  .?.....8|.......
	defb 07ch,07eh,07eh,0dch,078h,010h,000h,083h,003h,007h,003h,00dh,000h,082h,0f0h,0e0h	; 57a9  |~~.x...........
	defb 00eh,000h,000h,007h,000h,098h,003h,000h,000h,004h,000h,018h,01fh,007h,000h,03fh	; 57b9  ...............?
	defb 0ffh,0ffh,0ffh,07fh,03eh,03ch,0f8h,060h,030h,030h,070h,0f0h,0e0h,0c0h,00bh,000h	; 57c9  ....><.`00p.....
	defb 086h,030h,070h,0f0h,0f0h,0a0h,080h,00ah,000h,086h,038h,03ch,03eh,03fh,07fh,060h	; 57d9  .0p.......8<>?.`
	defb 00ah,000h,086h,030h,071h,0f3h,0f7h,0bfh,0bfh,00ah,000h,004h,0c0h,002h,080h,091h	; 57e9  ...0q...........
	defb 07fh,07eh,03ch,03fh,01fh,007h,003h,007h,00fh,01fh,00bh,00fh,007h,000h,000h,000h	; 57f9  .~<?............
	defb 03fh,004h,0ffh,087h,0feh,0fch,0f8h,080h,0c0h,0c0h,080h,004h,000h,000h,085h,000h	; 5809  ?...............
	defb 01ch,07ch,0fch,09ch,005h,000h,081h,001h,00ch,000h,087h,010h,038h,0fch,0fch,03ch	; 5819  .|..........8..<
	defb 01ch,00ch,007h,000h,088h,008h,044h,003h,003h,087h,0cch,0f8h,0f0h,006h,000h,088h	; 5829  ......D.........
	defb 0f8h,0fch,0feh,0ffh,0ffh,0ffh,0feh,0f8h,00ah,000h,08bh,003h,00fh,01fh,013h,003h	; 5839  ................
	defb 007h,00fh,00fh,00fh,00fh,007h,005h,000h,005h,080h,08dh,0f8h,0fch,0f8h,0e0h,000h	; 5849  ................
	defb 0f8h,047h,0ffh,0bfh,0ffh,0ffh,07bh,030h,009h,000h,087h,0fch,0feh,0ffh,0ffh,0ffh	; 5859  .G....{0........
	defb 0feh,0f8h,01eh,000h,087h,002h,007h,007h,003h,003h,003h,001h,004h,000h,000h,08ch	; 5869  ................
	defb 000h,000h,000h,030h,030h,064h,060h,060h,070h,079h,03fh,01eh,00ah,000h,08eh,080h	; 5879  ...00d``py?.....
	defb 080h,08eh,09eh,0ffh,0ffh,0ffh,07fh,03fh,01fh,0f0h,038h,07ch,03ch,005h,000h,087h	; 5889  .......?..8|<...
	defb 0c0h,0fch,07ch,07ch,078h,070h,060h,013h,000h,087h,002h,00fh,01bh,01fh,01fh,00fh	; 5899  ..||xp`.........
	defb 006h,007h,000h,087h,001h,00fh,01fh,01fh,0bfh,0fbh,0f9h,002h,0feh,003h,0ffh,08dh	; 58a9  ................
	defb 07fh,03fh,01fh,0f0h,038h,0fch,0fch,0c0h,0e0h,0f0h,0f8h,0fch,03ch,016h,000h,000h	; 58b9  .?..8.......<...
	defb 007h,000h,08fh,004h,006h,006h,00fh,01fh,03fh,03eh,000h,000h,018h,00ch,00ch,01eh	; 58c9  ........?>......
	defb 01eh,01eh,005h,000h,081h,080h,004h,000h,088h,01eh,01ch,018h,018h,00ch,006h,003h	; 58d9  ................
	defb 003h,005h,007h,08bh,003h,003h,001h,000h,040h,000h,000h,020h,040h,080h,080h,005h	; 58e9  ........@.. @...
	defb 0f8h,083h,0f0h,0e0h,0c0h,010h,000h,088h,01eh,03bh,07eh,07eh,03eh,01fh,03fh,03fh	; 58f9  .........;~~>.??
	defb 005h,07fh,091h,03fh,03eh,01ch,000h,000h,000h,001h,078h,0fch,0ffh,0ffh,0bfh,0bch	; 5909  ...?>.....x.....
	defb 0bch,09ch,09ch,008h,005h,000h,083h,080h,0c0h,0c0h,003h,0e0h,015h,000h,082h,007h	; 5919  ................
	defb 00fh,00dh,000h,083h,0c0h,0e0h,0c0h,000h,083h,000h,000h,001h,004h,000h,092h,008h	; 5929  ................
	defb 007h,003h,001h,021h,003h,0c7h,0ffh,03eh,000h,000h,0e0h,078h,03eh,03ch,078h,0f0h	; 5939  ...!...>...x><x.
	defb 0e0h,005h,080h,006h,000h,085h,007h,001h,003h,007h,001h,00bh,000h,003h,0e0h,089h	; 5949  ................
	defb 0c0h,080h,000h,018h,01ch,03eh,07eh,01eh,006h,008h,000h,085h,007h,001h,003h,007h	; 5959  .....>~.........
	defb 00fh,003h,01fh,008h,000h,0a1h,0e0h,0e0h,0e0h,0c0h,080h,000h,0e0h,0e0h,00fh,007h	; 5969  ................
	defb 001h,03fh,0ffh,0ffh,0e7h,00fh,03fh,07ch,0ffh,05eh,07ch,038h,000h,000h,0c0h,080h	; 5979  .?....?|.^|8....
	defb 0e0h,0f8h,0feh,0fch,0f8h,0f0h,0e0h,007h,000h,000h,083h,000h,000h,001h,004h,000h	; 5989  ................
	defb 09dh,003h,000h,000h,000h,008h,000h,031h,03fh,00fh,000h,0ffh,0ffh,0feh,07ch,078h	; 5999  .......1?.....|x
	defb 070h,0e0h,0c0h,0e0h,060h,060h,0e0h,0e0h,0c0h,080h,001h,000h,000h,001h,00ch,000h	; 59a9  p...``..........
	defb 08dh,0f8h,078h,0f8h,0f0h,060h,000h,000h,000h,008h,01eh,03fh,07fh,07fh,007h,000h	; 59b9  ..x..`.....?....
	defb 085h,001h,000h,000h,001h,003h,004h,007h,082h,003h,001h,005h,000h,0a8h,0f8h,078h	; 59c9  ...............x
	defb 0f8h,0f0h,0e0h,0c0h,080h,0e0h,0f0h,0e0h,0c0h,080h,000h,000h,01fh,03fh,07fh,0f7h	; 59d9  .............?..
	defb 0e3h,0e3h,00fh,01fh,03fh,017h,01fh,00eh,000h,000h,080h,0ffh,0ffh,0feh,0fch,0f8h	; 59e9  ....?...........
	defb 0f0h,0e0h,000h,000h,080h,080h,004h,000h,000h,081h,000h,004h,007h,081h,001h,005h	; 59f9  ................
	defb 000h,087h,002h,000h,00ch,00fh,003h,000h,0e0h,005h,0f0h,089h,0e0h,030h,038h,018h	; 5a09  .............08.
	defb 018h,038h,078h,0f0h,0e0h,00dh,000h,089h,003h,007h,007h,078h,03eh,01eh,01eh,00ch	; 5a19  .8x........x>...
	defb 004h,007h,000h,083h,0e0h,0f0h,0f0h,007h,000h,081h,001h,005h,003h,003h,000h,088h	; 5a29  ................
	defb 078h,03eh,01eh,01eh,03ch,07ch,0f8h,0f0h,005h,0e0h,004h,000h,005h,007h,08ch,00fh	; 5a39  x>..<|..........
	defb 01fh,03fh,07fh,07fh,075h,067h,063h,070h,070h,000h,0e0h,005h,0f0h,08ah,0e0h,0c0h	; 5a49  .?..ugcpp.......
	defb 0c0h,0e0h,0e0h,0c0h,080h,000h,000h,007h,00fh,000h,081h,0f0h,00fh,000h,000h,081h	; 5a59  ................
	defb 000h,006h,007h,08bh,003h,000h,000h,000h,002h,000h,00ch,00fh,003h,000h,0e0h,004h	; 5a69  ................
	defb 0f0h,083h,030h,000h,010h,004h,018h,083h,038h,030h,020h,000h,010h,000h,089h,010h	; 5a79  ..0.....80 .....
	defb 030h,030h,038h,03ch,07ch,078h,0f0h,0f0h,007h,000h,081h,003h,004h,000h,006h,007h	; 5a89  008<|x..........
	defb 086h,003h,003h,007h,00fh,005h,0e0h,004h,000h,081h,0e0h,005h,0f0h,005h,0e0h,00ah	; 5a99  ................
	defb 000h,002h,001h,004h,003h,087h,010h,030h,030h,038h,03ch,07ch,078h,004h,0f0h,005h	; 5aa9  .......008<|x...
	defb 0e0h,082h,007h,003h,00eh,000h,081h,0e0h,006h,0c0h,083h,0e0h,0c0h,0c0h,006h,000h	; 5ab9  ................
	defb 000h,082h,000h,003h,003h,007h,00ch,000h,081h,0e0h,003h,0f0h,00bh,000h,000h,082h	; 5ac9  ................
	defb 007h,00fh,005h,01fh,082h,00fh,007h,003h,00fh,004h,01fh,083h,0c0h,0f0h,0f0h,004h	; 5ad9  ................
	defb 0e0h,082h,0c0h,080h,007h,0c0h,000h,0a0h,000h,000h,001h,003h,007h,007h,003h,003h	; 5ae9  ................
	defb 000h,001h,013h,033h,023h,021h,001h,000h,000h,000h,0c0h,0e0h,0a0h,0f0h,0e0h,0c0h	; 5af9  ...3#!..........
	defb 000h,080h,080h,080h,0dch,0fch,0fch,070h,000h,08eh,01ch,03eh,07ah,07fh,03eh,03ch	; 5b09  .......p...>z.><
	defb 000h,070h,0f0h,0e0h,0eeh,0feh,07eh,038h,012h,000h,000h,0a0h,000h,000h,001h,003h	; 5b19  .p....~8........
	defb 007h,007h,003h,003h,000h,01ch,03ch,078h,077h,07fh,03fh,01ch,000h,000h,0c0h,0e0h	; 5b29  ......<xw.?.....
	defb 0a0h,0f0h,0e0h,0c0h,000h,000h,000h,018h,038h,038h,030h,000h,000h,0a0h,000h,000h	; 5b39  ........880.....
	defb 001h,003h,007h,007h,003h,003h,01ch,03ch,078h,0f0h,0ech,0fch,07ch,038h,000h,000h	; 5b49  .......<x...|8..
	defb 0c0h,0e0h,0a0h,0f0h,0e0h,0c0h,000h,000h,01ch,01ch,03ch,038h,030h,000h,000h,0a0h	; 5b59  ..........<80...
	defb 000h,000h,001h,003h,007h,007h,003h,003h,03ch,07ch,0f8h,0e0h,0e0h,0f0h,070h,070h	; 5b69  ........<|....pp
	defb 000h,000h,0c0h,0e0h,0a0h,0f0h,0e0h,0c0h,000h,00eh,00eh,03eh,03ch,038h,030h,000h	; 5b79  ...........><80.
	defb 000h,0a0h,000h,000h,001h,003h,007h,007h,003h,003h,000h,001h,013h,033h,063h,061h	; 5b89  .............3ca
	defb 020h,000h,000h,000h,0c0h,0e0h,0a0h,0f0h,0e0h,0c0h,000h,000h,09ch,0dch,0fch,0f8h	; 5b99   ...............
	defb 0f0h,000h,000h,0a0h,000h,000h,001h,003h,007h,007h,003h,003h,000h,011h,073h,0f3h	; 5ba9  ..............s.
	defb 0e3h,061h,020h,000h,000h,000h,0c0h,0e0h,0a0h,0f0h,0e0h,0c0h,000h,00eh,08eh,0deh	; 5bb9  .a .............
	defb 0fch,0f8h,0f0h,000h,000h,087h,000h,000h,020h,070h,0fbh,0f3h,0e3h,003h,003h,002h	; 5bc9  ........ p......
	defb 007h,007h,000h,007h,0c0h,081h,080h,005h,000h,086h,001h,01bh,039h,078h,0f0h,090h	; 5bd9  ............9x..
	defb 008h,000h,002h,001h,003h,0fch,081h,0e0h,008h,000h,084h,0f0h,0e0h,0f0h,0fch,000h	; 5be9  ................
	defb 08ah,006h,00eh,0feh,0feh,0feh,07ch,07ch,0f8h,070h,020h,016h,000h,003h,01fh,08fh	; 5bf9  ......||.p .....
	defb 07eh,0e0h,0e0h,0c0h,080h,000h,000h,030h,078h,0f8h,0f0h,038h,01ch,0c0h,0c0h,00eh	; 5c09  ~......0x..8....
	defb 000h,000h,08bh,000h,000h,000h,00ch,01fh,01fh,03eh,03ch,07ch,0f8h,030h,006h,000h	; 5c19  .........><|.0..
	defb 086h,018h,03ch,07eh,03fh,01fh,00eh,009h,000h,003h,003h,007h,000h,092h,070h,0f8h	; 5c29  ..<~?.........p.
	defb 0f0h,0f0h,038h,01ch,0fch,0f8h,0f0h,0e0h,000h,000h,004h,00fh,01eh,01eh,006h,003h	; 5c39  ..8.............
	defb 004h,000h,000h,08ah,000h,000h,000h,018h,03fh,07eh,0fch,0f8h,0f0h,060h,006h,000h	; 5c49  ........?~...`..
	defb 086h,03ch,03eh,07fh,0ffh,00fh,00eh,00ah,000h,084h,00fh,01fh,01fh,007h,005h,000h	; 5c59  .<>.............
	defb 002h,080h,005h,000h,08ah,0c0h,0c0h,080h,000h,000h,000h,01eh,03ch,03eh,00fh,01dh	; 5c69  ............<>..
	defb 000h,082h,001h,007h,003h,00fh,003h,006h,081h,003h,000h,084h,000h,000h,000h,006h	; 5c79  ................
	defb 004h,007h,009h,000h,087h,020h,070h,0f8h,0fch,0f0h,0c0h,080h,008h,000h,088h,030h	; 5c89  ..... p........0
	defb 038h,07eh,0ffh,03fh,00fh,007h,003h,00dh,000h,002h,080h,00bh,000h,086h,030h,078h	; 5c99  8~.?..........0x
	defb 0f8h,0f8h,0c8h,080h,008h,000h,084h,01fh,01fh,00fh,007h,00ch,000h,083h,0c0h,0c0h	; 5ca9  ................
	defb 080h,005h,000h,081h,001h,00dh,000h,085h,048h,0f8h,0f0h,0e0h,0c0h,005h,000h,000h	; 5cb9  ........H.......
	defb 088h,000h,000h,020h,078h,0feh,0fch,0f8h,070h,009h,000h,089h,020h,070h,0f8h,0f8h	; 5cc9  ... x...p... p..
	defb 07ch,03eh,01eh,01eh,00eh,008h,000h,086h,003h,007h,007h,00fh,00ch,008h,008h,000h	; 5cd9  |>..............
	defb 003h,01fh,081h,087h,00ch,000h,083h,0c0h,0c0h,080h,007h,000h,085h,00eh,00fh,00fh	; 5ce9  ................
	defb 00fh,006h,00bh,000h,003h,080h,003h,000h,000h,002h,000h,003h,001h,00bh,000h,09ah	; 5cf9  ................
	defb 07ch,0ffh,0e3h,0c0h,084h,080h,040h,000h,018h,01ch,03eh,0feh,0feh,07eh,07eh,07eh	; 5d09  |.....@...>..~~~
	defb 0c0h,070h,038h,01ch,01eh,00fh,00fh,007h,003h,001h,008h,000h,089h,01ch,03eh,07ah	; 5d19  .p8...........>z
	defb 07fh,0beh,0fch,0e0h,0e0h,0c0h,00eh,000h,003h,001h,008h,000h,003h,07ch,085h,0f8h	; 5d29  .............|..
	defb 0f0h,0f0h,0e0h,0c0h,010h,000h,081h,001h,003h,003h,003h,0feh,081h,07ch,008h,000h	; 5d39  .............|..
	defb 084h,0c0h,0c0h,0e0h,0f8h,000h,089h,026h,067h,0e1h,0c0h,0c2h,0c0h,0c0h,040h,006h	; 5d49  .......&g.....@.
	defb 005h,07fh,081h,03fh,002h,000h,002h,080h,00dh,000h,083h,01ch,074h,03ch,004h,078h	; 5d59  ...?........t<.x
	defb 089h,060h,060h,078h,0fch,0f4h,0feh,0fch,0f8h,0e0h,010h,000h,005h,07ch,083h,078h	; 5d69  .``x.........|.x
	defb 0b8h,0d0h,022h,000h,003h,0feh,081h,07ch,019h,000h,089h,00eh,00fh,01eh,03eh,03ch	; 5d79  .."....|......><
	defb 01ch,00ch,00ch,008h,010h,000h,000h,083h,004h,00ch,01ch,004h,018h,08eh,008h,000h	; 5d89  ................
	defb 00ch,00fh,00fh,00fh,007h,007h,003h,0c0h,0f0h,030h,000h,040h,003h,000h,002h,0e0h	; 5d99  .........0.@....
	defb 004h,0f0h,086h,0e0h,080h,000h,00eh,03ah,01eh,004h,03ch,088h,030h,030h,03ch,07eh	; 5da9  .......:..<.00<~
	defb 07ah,07fh,07eh,07ch,00fh,000h,083h,018h,070h,030h,00eh,000h,089h,03ch,07eh,07fh	; 5db9  z.~|....p0...<~.
	defb 0ffh,0f7h,073h,070h,030h,010h,00ch,000h,087h,008h,018h,07ch,0feh,0ffh,07eh,03ch	; 5dc9  ..sp0......|..~<
	defb 006h,000h,087h,002h,006h,00eh,00eh,01eh,00eh,006h,007h,000h,000h,089h,000h,001h	; 5dd9  ................
	defb 000h,008h,008h,00ch,00ch,006h,003h,007h,000h,09dh,060h,0f0h,0e0h,000h,020h,000h	; 5de9  ..........`... .
	defb 000h,01ch,00fh,09fh,0ffh,07fh,03fh,01fh,00fh,007h,000h,00eh,03ah,01eh,03fh,01fh	; 5df9  ......?.....:.?.
	defb 00eh,00fh,007h,007h,003h,003h,001h,008h,000h,099h,080h,000h,000h,0f1h,0d9h,0f1h	; 5e09  ................
	defb 0f1h,0e0h,0f0h,060h,000h,000h,010h,078h,0fch,0f8h,0f0h,0f0h,0f8h,0fch,0fch,07eh	; 5e19  ...`...x.......~
	defb 03eh,01eh,006h,014h,000h,085h,01ch,00eh,00fh,00fh,007h,007h,000h,082h,080h,0c0h	; 5e29  >...............
	defb 005h,000h,002h,080h,009h,000h,085h,0e0h,0f8h,0fch,0f8h,0f0h,01bh,000h,000h,08dh	; 5e39  ................
	defb 000h,000h,01eh,03eh,018h,002h,000h,040h,060h,070h,038h,00fh,001h,00bh,000h,088h	; 5e49  ...>...@`p8.....
	defb 0f0h,0fch,0feh,0ffh,0feh,0fch,078h,010h,003h,000h,08ah,01ch,074h,03eh,07eh,03ch	; 5e59  ......x.....t>~<
	defb 01eh,00fh,007h,003h,001h,00bh,000h,087h,070h,0d8h,0f8h,0f8h,0f0h,0f0h,070h,004h	; 5e69  ........p.....p.
	defb 000h,083h,010h,038h,078h,003h,0fch,002h,07eh,003h,03eh,002h,01eh,019h,000h,087h	; 5e79  ...8x...~.>.....
	defb 00ch,01eh,03fh,07eh,0fch,078h,030h,028h,000h,088h,03ch,07ch,07ch,078h,038h,01ch	; 5e89  ..?~.x0(..<||x8.
	defb 00eh,000h,000h,007h,000h,089h,060h,060h,0c8h,0c0h,000h,000h,0e0h,07fh,03eh,008h	; 5e99  ......``......>.
	defb 000h,087h,07eh,0feh,0feh,03eh,03eh,07eh,07ch,00ah,000h,084h,038h,0ech,07fh,0ffh	; 5ea9  ..~..>>~|...8...
	defb 00ah,000h,087h,010h,078h,0dch,0fch,0ffh,0ffh,07eh,008h,000h,081h,018h,004h,01fh	; 5eb9  ....x....~......
	defb 082h,00fh,001h,00bh,000h,087h,0c0h,0e0h,0f0h,0f8h,0fch,078h,030h,019h,000h,081h	; 5ec9  ...........x0...
	defb 01ch,005h,01eh,081h,01ch,003h,000h,083h,003h,001h,001h,00bh,000h,086h,040h,0e0h	; 5ed9  ..............@.
	defb 0e0h,0f0h,0f8h,03ch,00ah,000h,000h,009h,000h,096h,034h,030h,038h,038h,010h,001h	; 5ee9  ...<......4088..
	defb 000h,010h,038h,07ch,07eh,0ffh,0feh,0feh,0fch,018h,010h,010h,030h,060h,0e0h,0c0h	; 5ef9  ..8|~.......0`..
	defb 008h,000h,086h,003h,00fh,01fh,00fh,007h,003h,009h,000h,087h,07fh,0ffh,0ffh,0ffh	; 5f09  ................
	defb 0fch,0e0h,080h,006h,000h,08ch,007h,00fh,00bh,00fh,007h,007h,00fh,01eh,03fh,0feh	; 5f19  ..............?.
	defb 03ch,0e0h,005h,000h,003h,0e0h,082h,0c0h,080h,01ch,000h,088h,020h,070h,0f8h,0fch	; 5f29  <........... p..
	defb 07eh,03eh,01ch,008h,014h,000h,086h,002h,0e6h,0feh,0fch,0f8h,070h,009h,000h,000h	; 5f39  ~>..........p...
	defb 005h,000h,002h,001h,003h,003h,002h,007h,005h,000h,087h,010h,038h,07ch,0fch,0f8h	; 5f49  ............8|..
	defb 0f0h,0f0h,003h,0e0h,081h,0c0h,004h,000h,088h,001h,001h,007h,00fh,01fh,00bh,00fh	; 5f59  ................
	defb 007h,005h,001h,084h,003h,001h,003h,080h,006h,0c0h,083h,080h,080h,0a0h,005h,0e0h	; 5f69  ................
	defb 081h,080h,011h,000h,088h,004h,00ch,01ch,07ch,0f8h,078h,038h,020h,007h,000h,000h	; 5f79  ........|.x8 ...
	defb 088h,008h,01eh,03fh,07fh,0ffh,07fh,03fh,00fh,00bh,000h,08bh,080h,0f0h,01ch,00eh	; 5f89  ...?...?........
	defb 006h,002h,000h,040h,018h,07ch,078h,002h,000h,002h,03ch,003h,03eh,002h,03fh,003h	; 5f99  ...@.|x...<.>.?.
	defb 01fh,083h,00fh,00eh,004h,00ah,000h,003h,080h,007h,000h,087h,01ch,01eh,01fh,03fh	; 5fa9  ...............?
	defb 03fh,037h,01ch,00ch,000h,088h,0a0h,0f0h,0f8h,0fch,07fh,03fh,00fh,01ch,005h,000h	; 5fb9  ?7.........?....
	defb 087h,070h,038h,01ch,01eh,03eh,03eh,03ch,01bh,000h,085h,001h,003h,007h,003h,001h	; 5fc9  .p8..>><........
	defb 009h,000h,087h,060h,0f0h,0f8h,0f0h,0e0h,0c0h,080h,008h,000h,000h,088h,000h,03eh	; 5fd9  ...`...........>
	defb 07eh,07eh,07eh,07fh,07fh,07eh,008h,000h,087h,07ch,0feh,007h,000h,000h,001h,010h	; 5fe9  ~~~..~...|......
	defb 00ah,000h,087h,00ch,01eh,03fh,01fh,00fh,007h,003h,00bh,000h,082h,080h,0f0h,004h	; 5ff9  .....?..........
	defb 0f8h,081h,018h,008h,000h,087h,0fch,0ffh,0ffh,07ch,074h,03ch,010h,009h,000h,084h	; 6009  .........|t<....
	defb 07fh,0ffh,0f3h,00eh,014h,000h,086h,03ch,01fh,00fh,007h,007h,002h,00bh,000h,083h	; 6019  .......<........
	defb 080h,080h,0c0h,003h,000h,081h,038h,005h,078h,081h,038h,018h,000h,000h,097h,000h	; 6029  ......8.x.8.....
	defb 002h,006h,006h,00ch,008h,008h,018h,03eh,07eh,07eh,0feh,07eh,03eh,01ch,008h,000h	; 6039  .......>~~.~>...
	defb 000h,008h,01ch,01ch,00ch,02ch,010h,000h,087h,001h,007h,03fh,0ffh,0ffh,0ffh,0feh	; 6049  .....,.....?....
	defb 009h,000h,086h,0c0h,0e0h,0f0h,0f8h,0f0h,0c0h,007h,000h,089h,003h,007h,007h,006h	; 6059  ................
	defb 026h,067h,065h,067h,006h,003h,000h,087h,00eh,07ah,09eh,078h,0f0h,0e0h,040h,022h	; 6069  &geg.....z.x..@"
	defb 000h,086h,00eh,01fh,03fh,07fh,063h,040h,014h,000h,088h,010h,038h,07ch,07eh,03fh	; 6079  ....?.c@....8|~?
	defb 01fh,00eh,004h,005h,000h,000h,08ah,03ch,07eh,0c3h,0a5h,000h,03ch,018h,000h,07eh	; 6089  .......<~...<..~
	defb 07eh,006h,0ffh,010h,000h,000h,08ah,03ch,07eh,0c3h,0a5h,000h,018h,018h,000h,07eh	; 6099  ~......<~......~
	defb 07eh,006h,0ffh,010h,000h,000h,0a0h,000h,000h,003h,005h,00fh,0ech,0e6h,0e3h,0dfh	; 60a9  ~...............
	defb 0ffh,0ffh,07fh,03fh,00fh,00fh,00fh,000h,000h,0c0h,0a0h,0f0h,037h,067h,0c7h,0fbh	; 60b9  ...?........7g..
	defb 0ffh,0ffh,0feh,0fch,0f0h,0f0h,0f0h,000h,08dh,070h,070h,070h,0e0h,0e3h,0e5h,0efh	; 60c9  .........ppp....
	defb 0ech,0f6h,07bh,07fh,03fh,01fh,003h,00fh,003h,00eh,08dh,007h,0c7h,0a7h,0f7h,037h	; 60d9  ..{.?..........7
	defb 06fh,0deh,0feh,0fch,0f8h,0f0h,0f0h,0f0h,000h,09ch,000h,000h,003h,005h,00fh,00eh	; 60e9  o...............
	defb 006h,003h,01fh,03fh,07fh,0ffh,0efh,0ffh,07fh,03fh,01ch,01ch,0ceh,0afh,0f7h,077h	; 60f9  ...?.....?.....w
	defb 067h,0cfh,0ffh,0feh,0fch,0f8h,004h,0f0h,000h,09ch,000h,000h,003h,005h,00fh,00eh	; 6109  g...............
	defb 006h,003h,01fh,03fh,07fh,0ffh,0efh,0ffh,07fh,03fh,000h,000h,0cch,0ach,0feh,07fh	; 6119  ...?.....?......
	defb 067h,0c7h,0ffh,0ffh,0feh,0f8h,004h,0f0h,000h,018h,000h,008h,07eh,003h,00fh,081h	; 6129  g...........~...
	defb 007h,008h,000h,088h,007h,007h,01fh,03fh,0f0h,0f0h,0f0h,0e0h,008h,000h,084h,0e0h	; 6139  .......?........
	defb 0e0h,0f8h,0fch,000h	; 6149

; ======================================================================
; CODIGO 0x614d..0x6157  (10 bytes)
; ======================================================================


ARRANCA_PRUEBA:		; Prepara la prueba segun el evento (0xE052)
	ld hl,063e8h		;614d
	push hl			;6150
	ld a,(0e183h)		;6151
	call SALTA_POR_TABLA		;6154

; ----------------------------------------------------------------------
; DATOS tabla_pruebas: Rutina de arranque por evento
;   0x6157..0x6167  (16 bytes)
DATA_tabla_pruebas:
	defw 06167h,061f6h,062a9h,062c4h,0753bh,062e4h,07abeh,0633bh	; 6157

; ======================================================================
; CODIGO 0x6167..0x61f1  (138 bytes)
; ======================================================================


ACTUALIZA_PRUEBA:		; Un cuadro del motor de la prueba en curso
	ld hl,0e182h		;6167   ; apunta al estado de la prueba (0xE182)
	ld a,(hl)			;616a   ; lee el estado
	and a			;616b   ; comprueba el estado
	jp nz,ACTUALIZA_PRUEBA_61E6		;616c   ; si no es cero, otro camino
	inc (hl)			;616f   ; lo sube
	ld hl,061f1h		;6170
	call VUELCA_TABLA_VDP		;6173
	call PREPARA_TABLERO		;6176
	xor a			;6179
	ld (0e031h),a		;617a
	ld hl,0e100h		;617d
	ld de,0e101h		;6180
	ld bc,00080h		;6183
	ld (hl),a			;6186
	ldir		;6187
	ld hl,0e0d2h		;6189
	ld b,007h		;618c
ACTUALIZA_PRUEBA_618E:
	ld (hl),a			;618e   ; guarda el nuevo valor
	add a,004h		;618f   ; lo desplaza a la casilla de VRAM
	inc hl			;6191   ; avanza el puntero
	inc hl			;6192   ; (tres bytes)
	inc hl			;6193   ; al siguiente sprite
	inc hl			;6194
	djnz ACTUALIZA_PRUEBA_618E		;6195
	ld hl,039cah		;6197
	ld (0e164h),hl		;619a
	ld a,(0e052h)		;619d
	ld b,0c3h		;61a0
	and 003h		;61a2
	jr nz,ACTUALIZA_PRUEBA_61A8		;61a4
	ld b,0a0h		;61a6
ACTUALIZA_PRUEBA_61A8:
	cp 002h		;61a8
	jr nz,ACTUALIZA_PRUEBA_61AE		;61aa
	ld b,098h		;61ac
ACTUALIZA_PRUEBA_61AE:
	ld a,b			;61ae
	ld c,002h		;61af
	ld de,03b00h		;61b1
ACTUALIZA_PRUEBA_61B4:
	ld b,005h		;61b4
ACTUALIZA_PRUEBA_61B6:
	call SACA_BYTE_VRAM		;61b6   ; saca el sprite por el puerto
	inc de			;61b9   ; avanza el destino
	inc de			;61ba   ; avanza el destino
	inc de			;61bb   ; (tres coordenadas)
	inc de			;61bc   ; al siguiente
	djnz ACTUALIZA_PRUEBA_61B6		;61bd
	add a,010h		;61bf
	dec c			;61c1
	jr nz,ACTUALIZA_PRUEBA_61B4		;61c2
	ld a,040h		;61c4
	ld (0e15bh),a		;61c6
	ld a,(0e052h)		;61c9
	rra			;61cc
	ld a,010h		;61cd
	jr nc,ACTUALIZA_PRUEBA_61D3		;61cf
	ld a,004h		;61d1
ACTUALIZA_PRUEBA_61D3:
	ld (0e143h),a		;61d3   ; guarda la coordenada calculada
	ld a,020h		;61d6
	ld (0e109h),a		;61d8
	ld a,030h		;61db
	ld (0e137h),a		;61dd
	call AVANZA_POSTURA		;61e0
	call MUEVE_BANDERA_7A82		;61e3
ACTUALIZA_PRUEBA_61E6:
	call MIDE_MARCA		;61e6   ; comprueba el resultado del intento
	ld hl,0e182h		;61e9
	ld a,(hl)			;61ec
	and a			;61ed
	ret nz			;61ee
	jr $+98		;61ef

; ----------------------------------------------------------------------
; DATOS tabla_motor: Cabecera del motor
;   0x61f1..0x61f6  (5 bytes)
DATA_tabla_motor:
	defb 023h,038h,01dh,000h,000h	; 61f1

; ======================================================================
; CODIGO 0x61f6..0x6432  (572 bytes)
; ======================================================================


MOTOR_ATLETA:		; Fisica y postura del atleta
	ld a,(0e052h)		;61f6   ; el evento elige el motor
	ld c,a			;61f9   ; lo copia a C
	and 003h		;61fa   ; lo enmascara a 0..3
	jr nz,MOTOR_ATLETA_6256		;61fc   ; si no es este caso, otro
	ld a,(0e126h)		;61fe   ; lee la bandera (0xE126)
	and a			;6201   ; la comprueba
	jr nz,MOTOR_ATLETA_622E		;6202   ; salta si esta puesta
	ld a,c			;6204   ; lo pasa a A
	and 01fh		;6205   ; aisla los cinco bits
	rra			;6207   ; lo rota
	and 07eh		;6208
	neg		;620a
	sub 003h		;620c
	ld h,a			;620e
	ld l,090h		;620f
	ld (0e124h),hl		;6211
	ld a,003h		;6214
	ld (0e12ah),a		;6216
	ld a,001h		;6219
	ld (0e126h),a		;621b
	ld a,040h		;621e
	ld (0e109h),a		;6220
	ld hl,06432h		;6223
	ld de,01900h		;6226
	ld c,020h		;6229
	jp RELLENA_VRAM_43AC		;622b
MOTOR_ATLETA_622E:
	ld hl,0e106h		;622e   ; apunta a la posicion del atleta
	ld a,(hl)			;6231
	sub 010h		;6232
	ld (hl),a			;6234
	ld e,a			;6235
	inc hl			;6236
	jr nc,MOTOR_ATLETA_623A		;6237
	dec (hl)			;6239
MOTOR_ATLETA_623A:
	ld d,(hl)			;623a
	ld hl,(0e124h)		;623b
	and a			;623e
	sbc hl,de		;623f
	ret c			;6241
MOTOR_ATLETA_6242:
	ld a,003h		;6242
	ld (0e102h),a		;6244
MOTOR_ATLETA_6247:
	ld a,001h		;6247
	ld (0e131h),a		;6249
	ld a,091h		;624c
	call SUMA_BONUS		;624e
MOTOR_ATLETA_6251:
	ld hl,0e183h		;6251
	inc (hl)			;6254
	ret			;6255
MOTOR_ATLETA_6256:
	dec a			;6256   ; decrementa el selector
	jr nz,MOTOR_ATLETA_6282		;6257   ; si no es cero, otro caso
	ld hl,0e126h		;6259   ; apunta a la bandera (0xE126)
	ld a,(hl)			;625c   ; la lee
	and a			;625d   ; la comprueba
	jr nz,MOTOR_ATLETA_626C		;625e
	inc (hl)			;6260
	ld hl,0ffe5h		;6261
	ld (0e106h),hl		;6264
	ld a,001h		;6267
	ld (0e12ah),a		;6269
MOTOR_ATLETA_626C:
	ld hl,(0e109h)		;626c   ; lee la coordenada (0xE109)
	dec hl			;626f   ; la baja
	dec hl			;6270   ; retrocede el puntero
	dec hl			;6271   ; (tres bytes)
	dec hl			;6272   ; al campo anterior
	ld (0e109h),hl		;6273
	ld a,h			;6276
	and a			;6277
	ret p			;6278
	ld de,001b8h		;6279
	add hl,de			;627c
	jr nc,MOTOR_ATLETA_6280		;627d
	ret			;627f
MOTOR_ATLETA_6280:
	jr MOTOR_ATLETA_6247		;6280
MOTOR_ATLETA_6282:
	dec a			;6282   ; decrementa el selector
	jr nz,MOTOR_ATLETA_6292		;6283
	ld hl,0ffd7h		;6285
	ld (0e106h),hl		;6288
	ld a,074h		;628b
	ld (0e109h),a		;628d
	jr MOTOR_ATLETA_6242		;6290
MOTOR_ATLETA_6292:
	ld hl,0ffd2h		;6292   ; desplazamiento negativo
	ld (0e106h),hl		;6295
	ld a,075h		;6298
	ld (0e109h),a		;629a
	ld a,021h		;629d
	ld (0e10bh),a		;629f
	ld a,001h		;62a2
	ld (0e16fh),a		;62a4
	jr MOTOR_ATLETA_6247		;62a7
MOTOR_ATLETA_62A9:
	ld a,(0e0f1h)		;62a9   ; lee la bandera del atleta (0xE0F1)
	and 010h		;62ac
	jr z,MOTOR_ATLETA_62B7		;62ae
	ld a,010h		;62b0
	ld (0e128h),a		;62b2
	jr MOTOR_ATLETA_6251		;62b5
MOTOR_ATLETA_62B7:
	ld a,(0e003h)		;62b7   ; la fase de la interrupcion
	rra			;62ba
	ret nc			;62bb
	ld hl,0e160h		;62bc
	dec (hl)			;62bf
	ret nz			;62c0
	jp MOTOR_ATLETA_6251		;62c1
MOTOR_ATLETA_62C4:
	call MOTOR_ATLETA_6251		;62c4   ; llama al paso de fisica
	ld a,(0e052h)		;62c7
	rra			;62ca
	jr c,MOTOR_ATLETA_62D3		;62cb
	call EVENTO_ACTUAL_6507		;62cd
	jp ELIGE_EVENTO_6F5A		;62d0
MOTOR_ATLETA_62D3:
	rra			;62d3
	jr c,MOTOR_ATLETA_62DB		;62d4
	ld a,00ch		;62d6
	ld (0e128h),a		;62d8
MOTOR_ATLETA_62DB:
	ld a,010h		;62db   ; carga el tope de la cuenta
	ld hl,0e150h		;62dd
	ld (hl),a			;62e0
	inc hl			;62e1
	ld (hl),a			;62e2
	ret			;62e3
MOTOR_ATLETA_62E4:
	call DESPACHA_JUEZ		;62e4   ; salta a la fase de puntuacion
	ld hl,(0e147h)		;62e7   ; lee el contador (0xE147)
	ld de,(0e185h)		;62ea   ; lee el puntero de trabajo (0xE185)
	ld a,h			;62ee   ; la parte alta
	inc a			;62ef   ; la sube
	ld a,080h		;62f0
	jr z,MOTOR_ATLETA_62FF		;62f2
	and a			;62f4
	sbc hl,de		;62f5
	jr c,MOTOR_ATLETA_62FF		;62f7
	ld a,001h		;62f9
	ld (0e15fh),a		;62fb
	xor a			;62fe
MOTOR_ATLETA_62FF:
	ld (0e160h),a		;62ff
	jp MOTOR_ATLETA_6251		;6302
MOTOR_ATLETA_6305:
	ld a,(hl)			;6305
	bit 3,a		;6306
	ld a,02ah		;6308
	jr nz,MOTOR_ATLETA_630D		;630a
	dec a			;630c
MOTOR_ATLETA_630D:
	ld (0e10bh),a		;630d
	ret			;6310
MOTOR_ATLETA_6311:
	dec (hl)			;6311   ; baja el contador
	jr z,MOTOR_ATLETA_634C		;6312   ; al llegar a cero, cierra
	ld a,(hl)			;6314   ; lee el estado
	push af			;6315
	inc a			;6316   ; lo sube
	ld a,002h		;6317   ; valor de reinicio
	call z,SUMA_BONUS		;6319
	pop af			;631c
	push af			;631d
	bit 4,a		;631e
	ld a,02bh		;6320
	jr nz,MOTOR_ATLETA_6325		;6322
	inc a			;6324
MOTOR_ATLETA_6325:
	ld (0e10bh),a		;6325   ; guarda el estado
	pop af			;6328
	bit 2,a		;6329
	ld hl,04f27h		;632b
	jr z,MOTOR_ATLETA_6333		;632e
	ld hl,04f41h		;6330
MOTOR_ATLETA_6333:
	ld de,00158h		;6333
	ld b,002h		;6336
	jp DIBUJA_MARCO_484B		;6338
MOTOR_ATLETA_633B:
	ld a,001h		;633b   ; marca la bandera
	ld (0e131h),a		;633d
	ld a,(0e15fh)		;6340
	and a			;6343
	ld hl,0e160h		;6344
	jr nz,MOTOR_ATLETA_6311		;6347
	dec (hl)			;6349
	jr nz,MOTOR_ATLETA_6305		;634a
MOTOR_ATLETA_634C:
	xor a			;634c   ; pone a cero
	ld (0e131h),a		;634d   ; limpia la casilla (0xE131)
	ld a,(0e122h)		;6350   ; lee la coordenada (0xE122)
	inc (hl)			;6353   ; sube el campo
	ld hl,0e054h		;6354   ; apunta a los intentos (0xE054)
	dec (hl)			;6357
	jr nz,MOTOR_ATLETA_63C2		;6358
	ld hl,0e055h		;635a
	ld e,(hl)			;635d
	inc hl			;635e
	ld d,(hl)			;635f
	ld a,e			;6360
	inc a			;6361
	jp nz,INIT_6367		;6362
	ld de,00000h		;6365
	inc hl			;6368
	ld b,002h		;6369
MOTOR_ATLETA_636B:
	ld a,e			;636b   ; resta para comparar
	sub (hl)			;636c   ; resta para comparar
	inc hl			;636d   ; avanza en la tabla
	ld a,d			;636e   ; pasa D a A
	sbc a,(hl)			;636f
	jr nc,MOTOR_ATLETA_637A		;6370
	ld a,(hl)			;6372   ; si la casilla vale 0xFF, la salta
	inc a			;6373
	jr z,MOTOR_ATLETA_637A		;6374
	ld d,(hl)			;6376
	dec hl			;6377
	ld e,(hl)			;6378
	inc hl			;6379
MOTOR_ATLETA_637A:
	inc hl			;637a   ; avanza en la tabla
	djnz MOTOR_ATLETA_636B		;637b   ; repite la comparacion
	push de			;637d
	ld a,(0e15dh)		;637e   ; lee la bandera (0xE15D)
	and a			;6381   ; la comprueba
	jr nz,MOTOR_ATLETA_6393		;6382   ; si esta puesta, salta
	ex de,hl			;6384
	xor a			;6385
	add hl,hl			;6386
	rla			;6387
	add hl,hl			;6388
	rla			;6389
	add hl,hl			;638a
	rla			;638b
	add hl,hl			;638c
	rla			;638d
	ld e,h			;638e
	ld d,a			;638f
	call LIMPIA_PANTALLA_4253		;6390
MOTOR_ATLETA_6393:
	pop de			;6393   ; recupera el destino
	ld hl,(0e185h)		;6394   ; puntero de trabajo (0xE185)
	ex de,hl			;6397   ; pasa a HL
	and a			;6398   ; limpia el acarreo
	sbc hl,de		;6399   ; resta para comparar
	jr nc,MOTOR_ATLETA_63B4		;639b
	call MIDE_MARCA_6EAD		;639d
	ld a,(0e122h)		;63a0
	ld hl,0e054h		;63a3
	inc (hl)			;63a6
	and a			;63a7
	ret nz			;63a8
	dec (hl)			;63a9
	ld (0e050h),a		;63aa
	ld a,(0e080h)		;63ad
	and a			;63b0
	jp z,SALE_DEMO		;63b1
MOTOR_ATLETA_63B4:
	ld a,(0e084h)		;63b4
	and a			;63b7
	jr z,MOTOR_ATLETA_63CA		;63b8
MOTOR_ATLETA_63BA:
	call CAMBIA_JUGADOR		;63ba
MOTOR_ATLETA_63BD:
	xor a			;63bd
	ld (0e183h),a		;63be
	ret			;63c1
MOTOR_ATLETA_63C2:
	ld a,(0e080h)		;63c2
	and a			;63c5
	jr nz,MOTOR_ATLETA_63BA		;63c6
	jr MOTOR_ATLETA_63BD		;63c8
MOTOR_ATLETA_63CA:
	ld a,(0e080h)		;63ca   ; lee el estado del jugador 2 (0xE080)
	and a			;63cd   ; mira si esta activo
	call nz,CAMBIA_JUGADOR		;63ce   ; cambia de jugador si toca
	ld a,093h		;63d1   ; numero del sonido
	call SUMA_BONUS		;63d3   ; suma el bonus
	ld hl,0e052h		;63d6
	inc (hl)			;63d9
	ld hl,0e051h		;63da
	ld a,001h		;63dd
	add a,(hl)			;63df
	daa			;63e0
	ld (hl),a			;63e1
	ld a,009h		;63e2
	ld (0e000h),a		;63e4
	ret			;63e7
MOTOR_ATLETA_63E8:
	call EVENTO_ACTUAL_657A		;63e8   ; recorre el buffer de sprites
	ld a,(0e052h)		;63eb   ; lee el evento
	and 003h		;63ee   ; aisla los dos bits
	jr nz,MOTOR_ATLETA_640F		;63f0   ; si no toca, salta
	ld b,008h		;63f2   ; ocho iteraciones
	ld hl,0e0d0h		;63f4
	ld de,0e0d8h		;63f7
	call INTERCAMBIA		;63fa
	ld hl,0e0d2h		;63fd
	ld b,004h		;6400
	ld a,008h		;6402
MOTOR_ATLETA_6404:
	and 00fh		;6404   ; lo enmascara
	ld (hl),a			;6406
	inc hl			;6407
	inc hl			;6408
	inc hl			;6409
	inc hl			;640a
	add a,004h		;640b
	djnz MOTOR_ATLETA_6404		;640d
MOTOR_ATLETA_640F:
	ld de,03b28h		;640f   ; destino de sprites en la VRAM (0x3B28)
	ld hl,0e0d0h		;6412   ; apunta al buffer (0xE0D0)
	ld c,01ch		;6415   ; la cuenta
	call RELLENA_VRAM_43AC		;6417   ; lo rellena
	ld a,(0e131h)		;641a
	and a			;641d
	jr nz,MOTOR_ATLETA_6428		;641e
	ld de,03b28h		;6420
	ld a,0d0h		;6423
	call SACA_BYTE_VRAM		;6425
MOTOR_ATLETA_6428:
	ld a,(0e052h)		;6428
	rra			;642b
	jp nc,DIBUJA_ATLETA		;642c
	jp MOTOR_TRAMPOLIN_71F0		;642f

; ----------------------------------------------------------------------
; DATOS tabla_evento: Parametros del evento por prueba
;   0x6432..0x6452  (32 bytes)
DATA_tabla_evento:
	defb 000h,003h	; 6432
	defb 003h,000h	; 6434
	defb 010h,002h	; 6436
	defb 000h,004h	; 6438
	defb 0c0h,072h	; 643a
	defb 03ah,00fh	; 643c
	defb 0e7h,03dh	; 643e
	defb 062h,004h	; 6440
	defb 000h,000h	; 6442
	defb 000h,004h	; 6444
	defb 000h,060h	; 6446
	defb 060h,000h	; 6448
	defb 093h,02eh	; 644a
	defb 05ch,0f0h	; 644c
	defb 0e7h,0bch	; 644e
	defb 046h,020h	; 6450

; ======================================================================
; CODIGO 0x6452..0x65f6  (420 bytes)
; ======================================================================


EVENTO_ACTUAL:		; Ejecuta el evento en curso (mide el intento)
	call DIBUJA_MARCO		;6452   ; monta el marco del evento
	ld hl,(0e185h)		;6455   ; lee el puntero de trabajo (0xE185)
	ld de,00040h		;6458   ; salto de fila
	ld a,(0e052h)		;645b   ; lee el evento
	and 003h		;645e
	push af			;6460
	call z,JUEZ_NOTA_796E		;6461
	cp 00ah		;6464
	jr c,EVENTO_ACTUAL_646B		;6466
	ld hl,00960h		;6468
EVENTO_ACTUAL_646B:
	ld (0e185h),hl		;646b
	xor a			;646e
	ld b,006h		;646f
	ld hl,0e055h		;6471
EVENTO_ACTUAL_6474:
	ld (hl),a			;6474   ; guarda el valor
	inc hl			;6475   ; avanza el puntero
	djnz EVENTO_ACTUAL_6474		;6476   ; repite el borrado
	ld (0e182h),a		;6478   ; guarda el estado (0xE182)
	ld (0e183h),a		;647b   ; y el segundo campo
	ld (0e181h),a		;647e
	pop af			;6481
	cp 002h		;6482
	ld a,003h		;6484
	jr nz,EVENTO_ACTUAL_648A		;6486
	ld a,001h		;6488
EVENTO_ACTUAL_648A:
	ld (0e054h),a		;648a   ; fija los intentos (0xE054)
	ld a,(0e080h)		;648d
	and a			;6490
	ret z			;6491
	ld hl,0e051h		;6492
	ld de,0e081h		;6495
	ld bc,0002fh		;6498
	ldir		;649b
	ret			;649d
EVENTO_ACTUAL_649E:
	ld a,(0e128h)		;649e   ; lee la bandera del atleta (0xE128)
	and 020h		;64a1   ; aisla el bit de salto
	ret z			;64a3
	ld hl,0e10bh		;64a4   ; apunta a la postura (0xE10B)
	ld a,005h		;64a7   ; umbral 5
	cp (hl)			;64a9   ; lo compara
	jr c,EVENTO_ACTUAL_64B6		;64aa
	ld a,(0e102h)		;64ac
	add a,a			;64af
	ld a,004h		;64b0
	jr c,EVENTO_ACTUAL_64B5		;64b2
	inc a			;64b4
EVENTO_ACTUAL_64B5:
	ld (hl),a			;64b5
EVENTO_ACTUAL_64B6:
	ld hl,0e102h		;64b6
	bit 7,(hl)		;64b9
	jr nz,EVENTO_ACTUAL_64C2		;64bb
	ld a,002h		;64bd
	ld (0e031h),a		;64bf
EVENTO_ACTUAL_64C2:
	dec hl			;64c2   ; retrocede el puntero
	ld a,(0e143h)		;64c3   ; lee la coordenada guardada
	add a,(hl)			;64c6   ; suma el desplazamiento
	ld (hl),a			;64c7   ; lo guarda
	ret nc			;64c8
	inc hl			;64c9   ; avanza
	inc (hl)			;64ca
	ld a,(hl)			;64cb
	add a,020h		;64cc
	cp 026h		;64ce
	ret c			;64d0
	ld (hl),005h		;64d1
	dec hl			;64d3
	ld (hl),0ffh		;64d4
	ret			;64d6
EVENTO_ACTUAL_64D7:
	ld a,(0e128h)		;64d7   ; relee la bandera
	and 008h		;64da
	ret z			;64dc
	ld hl,0e101h		;64dd
	ld de,0e105h		;64e0
	ld b,002h		;64e3
EVENTO_ACTUAL_64E5:
	ld a,(de)			;64e5   ; suma el desplazamiento
	add a,(hl)			;64e6   ; al valor de la tabla
	ld (de),a			;64e7   ; escribe la coordenada
	inc hl			;64e8   ; avanza el origen
	inc de			;64e9   ; y el destino
	ld a,(de)			;64ea
	adc a,(hl)			;64eb
	ld (de),a			;64ec
	inc de			;64ed
	ld a,000h		;64ee
	jr nc,EVENTO_ACTUAL_64F3		;64f0
	inc a			;64f2
EVENTO_ACTUAL_64F3:
	bit 7,(hl)		;64f3
	jr z,EVENTO_ACTUAL_64F8		;64f5
	dec a			;64f7
EVENTO_ACTUAL_64F8:
	ex de,hl			;64f8   ; intercambia origen y destino
	add a,(hl)			;64f9
	ld (hl),a			;64fa
	ex de,hl			;64fb
	inc hl			;64fc
	inc de			;64fd
	djnz EVENTO_ACTUAL_64E5		;64fe
	ret			;6500
EVENTO_ACTUAL_6501:
	ld a,(0e128h)		;6501
	bit 4,a		;6504
	ret nz			;6506
EVENTO_ACTUAL_6507:
	ld a,(0e10bh)		;6507   ; lee la postura (0xE10B)
	ld (0e14bh),a		;650a   ; la guarda
	ld hl,(0e101h)		;650d   ; lee el estado (0xE101)
	ld a,h			;6510   ; la parte alta
	and a			;6511   ; la comprueba
	ret m			;6512
	ld a,(0e137h)		;6513
	and a			;6516
	jr nz,EVENTO_ACTUAL_651D		;6517
	inc a			;6519
	ld (0e15ch),a		;651a
EVENTO_ACTUAL_651D:
	ld de,00040h		;651d   ; salto de fila en la VRAM
	add hl,de			;6520
	ld a,h			;6521
	cp 006h		;6522
	jr c,EVENTO_ACTUAL_6528		;6524
	ld a,005h		;6526
EVENTO_ACTUAL_6528:
	ld hl,0e12bh		;6528   ; apunta a la casilla de sprite
	ld (hl),a			;652b   ; la escribe
	inc hl			;652c   ; avanza
	ld (hl),000h		;652d   ; pone a cero
	ld hl,0e106h		;652f   ; apunta a la marca (0xE106)
	ld a,0f8h		;6532
	and (hl)			;6534
	ld (hl),a			;6535
	ld a,090h		;6536
	ld (0e128h),a		;6538
	ld hl,0e10bh		;653b
	ld a,(hl)			;653e
	cp 009h		;653f
	jr c,EVENTO_ACTUAL_6547		;6541
	cp 00dh		;6543
	jr nz,EVENTO_ACTUAL_6554		;6545
EVENTO_ACTUAL_6547:
	ld (hl),001h		;6547
EVENTO_ACTUAL_6549:
	ld a,(0e183h)		;6549
	cp 005h		;654c
	ret nc			;654e
	ld a,00bh		;654f
	jp SUMA_BONUS		;6551
EVENTO_ACTUAL_6554:
	ld a,(0e137h)		;6554   ; lee el fotograma (0xE137)
	and a			;6557
	jr z,EVENTO_ACTUAL_6549		;6558
	ld hl,0e159h		;655a
	inc (hl)			;655d
	jr EVENTO_ACTUAL_6549		;655e
EVENTO_ACTUAL_6560:
	ld b,000h		;6560   ; limpia B
	ld c,l			;6562
	ld de,0ff40h		;6563
	and a			;6566
	sbc hl,de		;6567
	jr c,EVENTO_ACTUAL_656C		;6569
	inc b			;656b
EVENTO_ACTUAL_656C:
	ld a,(0e183h)		;656c
	cp 004h		;656f
	jr nz,EVENTO_ACTUAL_6577		;6571
	ld a,b			;6573
	ld (0e131h),a		;6574
EVENTO_ACTUAL_6577:
	ld a,c			;6577
	jr EVENTO_ACTUAL_658F		;6578
EVENTO_ACTUAL_657A:
	ld c,020h		;657a   ; ancho del sprite del atleta
	ld d,07fh		;657c   ; limite de columna
	ld hl,(0e106h)		;657e   ; lee la marca (0xE106)
	dec hl			;6581   ; la baja
	ld a,(0e052h)		;6582   ; lee el evento
	rra			;6585
	jr c,EVENTO_ACTUAL_6560		;6586
	inc h			;6588
	jr nz,EVENTO_ACTUAL_6592		;6589
	ld a,l			;658b
	cp d			;658c
	jr c,EVENTO_ACTUAL_6592		;658d
EVENTO_ACTUAL_658F:
	sub 05fh		;658f
	ld c,a			;6591
EVENTO_ACTUAL_6592:
	ld hl,(0e109h)		;6592   ; lee la coordenada (0xE109)
	ld a,h			;6595
	and a			;6596
	ld b,020h		;6597
	jr z,EVENTO_ACTUAL_65A2		;6599
	jp m,EVENTO_ACTUAL_65AD		;659b
	ld b,0d0h		;659e
	jr EVENTO_ACTUAL_65AD		;65a0
EVENTO_ACTUAL_65A2:
	ld a,l			;65a2   ; el byte bajo
	sub b			;65a3
	jr c,EVENTO_ACTUAL_65AD		;65a4
	ld b,l			;65a6
	cp 0b0h		;65a7
	jr c,EVENTO_ACTUAL_65AD		;65a9
	ld b,0d0h		;65ab
EVENTO_ACTUAL_65AD:
	ld a,(0e10bh)		;65ad   ; lee la postura
	add a,a			;65b0
	ld hl,065f6h		;65b1
	call HL_MAS_A		;65b4
	ld e,(hl)			;65b7
	inc hl			;65b8
	ld d,(hl)			;65b9
	ex de,hl			;65ba
	ld de,0e0d0h		;65bb
EVENTO_ACTUAL_65BE:
	ld a,(hl)			;65be   ; aisla el nibble alto
	and 0f0h		;65bf   ; el patron base
	cp 080h		;65c1   ; 0x80 marca fin
	jr z,EVENTO_ACTUAL_65D6		;65c3   ; salta si es fin
	ld a,(hl)			;65c5   ; lee el byte
	add a,c			;65c6   ; suma C
	ld (de),a			;65c7
	inc hl			;65c8
	inc de			;65c9
	ld a,(hl)			;65ca
	add a,b			;65cb
	ld (de),a			;65cc
	inc hl			;65cd
	inc de			;65ce
	inc de			;65cf
	ld a,(hl)			;65d0
	ld (de),a			;65d1
	inc hl			;65d2
	inc de			;65d3
	jr EVENTO_ACTUAL_65BE		;65d4
EVENTO_ACTUAL_65D6:
	ld a,0d0h		;65d6   ; valor por defecto de la Y
	ld (de),a			;65d8
	ld de,05800h		;65d9
	di			;65dc
	call FIJA_ESCRITURA		;65dd
	ld a,(hl)			;65e0
	and 00fh		;65e1
	ld b,a			;65e3
	inc hl			;65e4
EVENTO_ACTUAL_65E5:
	ld e,(hl)			;65e5   ; lee el destino del sprite
	inc hl			;65e6   ; avanza
	ld d,(hl)			;65e7   ; lee el destino del sprite
	inc hl			;65e8   ; avanza
	push bc			;65e9
	push hl			;65ea
	ld b,001h		;65eb   ; arranca B a 1
	ex de,hl			;65ed
	call DIBUJA_ATLETA_69F9		;65ee
	pop hl			;65f1
	pop bc			;65f2
	djnz EVENTO_ACTUAL_65E5		;65f3
	ret			;65f5

; ----------------------------------------------------------------------
; DATOS graficos_prueba: Graficos y guiones de las posturas del atleta
;   0x65f6..0x6990  (922 bytes)
DATA_graficos_prueba:
	defb 050h,066h,05fh,066h,06eh,066h,07dh,066h,08fh,066h,0a4h,066h,0b6h,066h,0c5h,066h	; 65f6  Pf_fnf}f.f.f.f.f
	defb 0d7h,066h,0e6h,066h,0f8h,066h,007h,067h,019h,067h,028h,067h,03ah,067h,049h,067h	; 6606  .f.f.f.g.g(g:gIg
	defb 058h,067h,06ah,067h,083h,067h,096h,067h,0ach,067h,0c5h,067h,0dbh,067h,0eeh,067h	; 6616  Xgjg.g.g.g.g.g.g
	defb 001h,068h,014h,068h,02ah,068h,043h,068h,059h,068h,0eeh,067h,06ch,068h,08dh,068h	; 6626  .h.h*hChYh.glh.h
	defb 09ch,068h,07bh,068h,0aeh,068h,0c0h,068h,0d2h,068h,0e4h,068h,0fah,068h,00ch,069h	; 6636  .h{h.h.h.h.h.h.i
	defb 01eh,069h,030h,069h,048h,069h,060h,069h,078h,069h,000h,000h,006h,010h,004h,00fh	; 6646  .i0iHi`ixi......
	defb 000h,004h,00bh,010h,004h,00bh,081h,0ech,053h,009h,000h,006h,015h,000h,00fh,009h	; 6656  ........S.......
	defb 000h,00bh,019h,000h,00bh,081h,037h,054h,00ah,000h,006h,016h,000h,00fh,00ah,000h	; 6666  ......7T........
	defb 00bh,01ah,000h,00bh,081h,0a4h,054h,000h,000h,006h,010h,000h,00fh,000h,000h,00bh	; 6676  ......T.........
	defb 010h,000h,00bh,000h,000h,00fh,081h,014h,055h,000h,000h,006h,014h,000h,00fh,004h	; 6686  ........U.......
	defb 004h,00bh,014h,000h,00bh,0f4h,000h,00bh,004h,004h,00fh,081h,076h,055h,000h,000h	; 6696  ............vU..
	defb 006h,010h,000h,00fh,010h,000h,00bh,000h,000h,00bh,000h,000h,00fh,081h,0d5h,055h	; 66a6  ...............U
	defb 00bh,000h,006h,01ah,001h,00fh,00bh,000h,00bh,01ah,001h,00bh,081h,04bh,056h,00ch	; 66b6  .............KV.
	defb 000h,006h,014h,0fdh,00fh,008h,000h,00bh,018h,000h,00bh,00ch,010h,006h,081h,0a5h	; 66c6  ................
	defb 056h,010h,000h,006h,011h,0f1h,00fh,010h,000h,00bh,011h,0f1h,00bh,081h,006h,057h	; 66d6  V..............W
	defb 010h,000h,006h,00dh,0f8h,00fh,010h,0f4h,00bh,010h,004h,00bh,020h,000h,006h,081h	; 66e6  ............ ...
	defb 055h,057h,014h,000h,006h,005h,0ffh,00fh,005h,0ffh,00bh,014h,000h,00bh,081h,0bch	; 66f6  UW..............
	defb 057h,00ch,003h,00fh,014h,000h,006h,008h,000h,00bh,018h,000h,00bh,014h,0f0h,006h	; 6706  W...............
	defb 081h,017h,058h,010h,0fch,006h,00fh,00bh,00fh,010h,0fch,00bh,00fh,00bh,00bh,081h	; 6716  ..X.............
	defb 078h,058h,014h,004h,00fh,011h,0fch,006h,011h,0f8h,00bh,011h,008h,00bh,001h,0fch	; 6726  xX..............
	defb 006h,081h,0c9h,058h,008h,000h,006h,0fch,000h,00fh,0f8h,000h,00bh,008h,000h,00bh	; 6736  ...X............
	defb 081h,031h,059h,00ch,000h,006h,000h,000h,00fh,0fch,000h,00bh,00ch,000h,00bh,081h	; 6746  .1Y.............
	defb 093h,059h,010h,000h,006h,000h,000h,00fh,000h,000h,00bh,010h,000h,00bh,010h,000h	; 6756  .Y..............
	defb 00fh,081h,002h,05ah,010h,000h,006h,0fch,000h,00fh,00ch,000h,00bh,0fch,000h,00bh	; 6766  ...Z............
	defb 01ch,000h,00bh,00ch,000h,00fh,083h,068h,05ah,085h,05ah,0cah,05ah,000h,000h,00bh	; 6776  .......hZ.Z.Z...
	defb 010h,0ffh,00bh,010h,0fdh,00fh,000h,000h,006h,083h,024h,05bh,01bh,05ch,0d8h,05ah	; 6786  ..........$[.\.Z
	defb 0ffh,000h,00bh,00fh,000h,00bh,00fh,000h,00fh,00fh,0f0h,00fh,0ffh,000h,006h,083h	; 6796  ................
	defb 046h,05bh,04ch,05ch,0d8h,05ah,0feh,000h,00bh,00eh,0f8h,00bh,00eh,008h,00bh,00eh	; 67a6  F[L\.Z..........
	defb 0f8h,00fh,00eh,008h,00fh,0feh,000h,006h,083h,068h,05bh,084h,05ch,0d8h,05ah,0ffh	; 67b6  .........h[.\.Z.
	defb 000h,00bh,00fh,000h,00bh,00fh,0f8h,00fh,00fh,008h,00fh,0ffh,000h,006h,083h,046h	; 67c6  ...............F
	defb 05bh,0c9h,05ch,0d8h,05ah,000h,000h,00bh,010h,000h,00bh,010h,0fch,00fh,000h,000h	; 67d6  [.\.Z...........
	defb 006h,083h,024h,05bh,0ceh,05bh,0d8h,05ah,002h,004h,00bh,012h,003h,00bh,010h,000h	; 67e6  ..$[.[.Z........
	defb 00fh,000h,000h,006h,083h,012h,05bh,0f9h,05bh,0d8h,05ah,000h,000h,00bh,010h,0ffh	; 67f6  ......[.[.Z.....
	defb 00bh,010h,0fdh,00fh,000h,000h,006h,083h,0f0h,05ah,01bh,05ch,0d8h,05ah,0ffh,000h	; 6806  .........Z.\.Z..
	defb 00bh,00fh,000h,00bh,00fh,000h,00fh,00fh,0f0h,00fh,0ffh,000h,006h,083h,08ah,05bh	; 6816  ...............[
	defb 04ch,05ch,0d8h,05ah,0feh,000h,00bh,00eh,0f8h,00bh,00eh,008h,00bh,00eh,0f8h,00fh	; 6826  L\.Z............
	defb 00eh,008h,00fh,0feh,000h,006h,083h,0ach,05bh,084h,05ch,0d8h,05ah,0ffh,000h,00bh	; 6836  ........[.\.Z...
	defb 00fh,000h,00bh,00fh,0f8h,00fh,00fh,008h,00fh,0ffh,000h,006h,083h,08ah,05bh,0c9h	; 6846  ..............[.
	defb 05ch,0d8h,05ah,000h,000h,00bh,010h,000h,00bh,010h,0fch,00fh,000h,000h,006h,083h	; 6856  \.Z.............
	defb 0f0h,05ah,0ceh,05bh,0d8h,05ah,000h,000h,006h,000h,000h,00bh,010h,000h,00bh,010h	; 6866  .Z.[.Z..........
	defb 000h,00fh,081h,002h,05dh,005h,0fah,006h,0feh,0fch,00bh,018h,0fbh,00bh,00ah,0fbh	; 6876  ....]...........
	defb 00fh,019h,0f7h,00fh,081h,04fh,05dh,005h,0f7h,006h,0fdh,0fbh,00bh,00dh,0fbh,00bh	; 6886  .....O].........
	defb 00dh,0ffh,00fh,081h,090h,05dh,002h,0fbh,006h,0fdh,0fbh,00bh,001h,00bh,00bh,0fdh	; 6896  .....]..........
	defb 00bh,00fh,00dh,00bh,00fh,081h,0e6h,05dh,0ffh,000h,006h,0fbh,0fch,00bh,00bh,00fh	; 68a6  .......]........
	defb 00bh,002h,00bh,00fh,013h,008h,00fh,081h,048h,05eh,0f5h,003h,006h,0f5h,0fdh,00bh	; 68b6  ........H^......
	defb 0f8h,013h,00bh,0f5h,007h,00fh,005h,017h,00fh,081h,09ch,05eh,0efh,0fch,006h,0e3h	; 68c6  ...........^....
	defb 008h,00bh,0f3h,0fch,00bh,0e7h,000h,00fh,0e7h,010h,00fh,081h,0f0h,05eh,0ech,0f6h	; 68d6  .............^..
	defb 006h,0ddh,0f7h,00bh,0f2h,0f7h,00bh,0d9h,0fbh,00fh,0e8h,0f6h,00fh,083h,068h,05ah	; 68e6  ..............hZ
	defb 049h,05fh,0cah,05ah,0f2h,0edh,006h,0e6h,0e5h,00bh,0f6h,0f2h,00bh,0deh,0e5h,00fh	; 68f6  I_.Z............
	defb 0eeh,0e5h,00fh,081h,089h,05fh,0fch,0e9h,006h,0f9h,0d9h,00bh,0fch,0f0h,00bh,0ech	; 6906  ....._..........
	defb 0d5h,00fh,0fch,0e5h,00fh,081h,0e6h,05fh,002h,0efh,006h,00ah,0e3h,00bh,0feh,0f3h	; 6916  ......._........
	defb 00bh,00ah,0d3h,00fh,00ah,0e3h,00fh,081h,037h,060h,000h,000h,000h,000h,004h,006h	; 6926  ........7`......
	defb 000h,000h,00bh,00ch,0fch,00bh,010h,000h,00fh,084h,09fh,060h,09fh,060h,0f2h,060h	; 6936  ...........`.`.`
	defb 032h,061h,000h,000h,000h,000h,004h,006h,000h,000h,00bh,00ch,0fch,00bh,010h,000h	; 6946  2a..............
	defb 00fh,084h,09fh,060h,09fh,060h,012h,061h,032h,061h,000h,000h,000h,000h,004h,006h	; 6956  ...`.`.a2a......
	defb 000h,000h,00bh,00ch,0fch,00bh,010h,000h,00fh,084h,08fh,060h,08fh,060h,0afh,060h	; 6966  ...........`.`.`
	defb 032h,061h,000h,000h,000h,000h,004h,006h,0feh,000h,00bh,00ch,0fch,00bh,010h,000h	; 6976  2a..............
	defb 00fh,084h,08fh,060h,08fh,060h,0d1h,060h,032h,061h	; 6986  ...`.`.`2a

; ======================================================================
; CODIGO 0x6990..0x6a88  (248 bytes)
; ======================================================================


DIBUJA_ATLETA:		; Monta la figura del atleta y la sube a la VRAM
	call PUNTOS_A_BCD		;6990   ; convierte la marca a BCD para el marcador
	ld hl,(0e106h)		;6993
	ld b,h			;6996
	ld c,l			;6997
	ld de,0fee3h		;6998
	ld a,(0e052h)		;699b
	and 003h		;699e
	jr nz,DIBUJA_ATLETA_69A4		;69a0
	ld e,0e8h		;69a2
DIBUJA_ATLETA_69A4:
	sbc hl,de		;69a4   ; resta para comparar con la de paso
	jp c,DIBUJA_ATLETA_6A30		;69a6
	ld de,000a0h		;69a9
	sbc hl,de		;69ac
	jr c,DIBUJA_ATLETA_69B9		;69ae
	ld de,00011h		;69b0
	sbc hl,de		;69b3
	ret nc			;69b5
DIBUJA_ATLETA_69B6:
	ld bc,0ff80h		;69b6
DIBUJA_ATLETA_69B9:
	ld h,b			;69b9   ; pasa el resultado a HL
	ld a,c			;69ba   ; el byte bajo
	and 0f8h		;69bb   ; aisla los bits altos
	ld l,a			;69bd   ; pasa a L
	add hl,hl			;69be   ; dobla dos veces
	add hl,hl			;69bf   ; (por cuatro)
	ld de,03680h		;69c0   ; destino en la VRAM (0x3680)
	ex de,hl			;69c3
	and a			;69c4
	sbc hl,de		;69c5
	ex de,hl			;69c7
	rr b		;69c8
	rra			;69ca
	rr b		;69cb
	rra			;69cd
	rr b		;69ce
	rra			;69d0
	add a,024h		;69d1
	ld b,a			;69d3
	ld a,(0e052h)		;69d4
	and 003h		;69d7
	jr nz,DIBUJA_ATLETA_69E1		;69d9
	rra			;69db
	ld hl,06b64h		;69dc
	jr DIBUJA_ATLETA_69F3		;69df
DIBUJA_ATLETA_69E1:
	ld hl,06c39h		;69e1   ; apunta a la tabla de posturas (0x6C39)
	bit 2,c		;69e4   ; mira el bit del salto
	jr z,DIBUJA_ATLETA_69F3		;69e6   ; si no, salta
	ld hl,06cfah		;69e8   ; apunta a otra tabla (0x6CFA)
	inc b			;69eb
	ld a,e			;69ec
	sub 020h		;69ed
	ld e,a			;69ef
	jr nc,DIBUJA_ATLETA_69F3		;69f0
	dec d			;69f2
DIBUJA_ATLETA_69F3:
	dec b			;69f3
	inc b			;69f4
	ret z			;69f5
	call FIJA_ESCRITURA		;69f6
DIBUJA_ATLETA_69F9:
	ld d,b			;69f9
	exx			;69fa
	ld a,c			;69fb
	exx			;69fc
	ld c,a			;69fd
DIBUJA_ATLETA_69FE:
	ld a,(hl)			;69fe   ; lee la postura
	inc hl			;69ff
	and a			;6a00
	jr z,DIBUJA_ATLETA_6A1B		;6a01
	jp p,DIBUJA_ATLETA_6A11		;6a03
	and 07fh		;6a06
	ld b,a			;6a08
DIBUJA_ATLETA_6A09:
	ld a,(hl)			;6a09
	inc hl			;6a0a
	out (c),a		;6a0b
	djnz DIBUJA_ATLETA_6A09		;6a0d
	jr DIBUJA_ATLETA_69FE		;6a0f
DIBUJA_ATLETA_6A11:
	ld b,a			;6a11
	ld a,(hl)			;6a12
	inc hl			;6a13
DIBUJA_ATLETA_6A14:
	out (c),a		;6a14
	nop			;6a16
	djnz DIBUJA_ATLETA_6A14		;6a17
	jr DIBUJA_ATLETA_69FE		;6a19
DIBUJA_ATLETA_6A1B:
	dec d			;6a1b
	jr nz,DIBUJA_ATLETA_69FE		;6a1c
	ei			;6a1e
	ret			;6a1f
DIBUJA_ATLETA_6A20:
	ld a,l			;6a20   ; el byte bajo del puntero
	and 007h		;6a21
	cp 004h		;6a23
	ld hl,06aceh		;6a25
	jr c,DIBUJA_ATLETA_6A2D		;6a28
	ld hl,06aefh		;6a2a
DIBUJA_ATLETA_6A2D:
	jp VUELCA_GUION_MASC		;6a2d
DIBUJA_ATLETA_6A30:
	inc b			;6a30   ; sube el contador
	ret p			;6a31   ; sale si es positivo
	ld a,(0e052h)		;6a32   ; lee el evento
	and 003h		;6a35   ; aisla los dos bits
	ret nz			;6a37   ; sale si no toca
	ld hl,(0e106h)		;6a38   ; lee la marca (0xE106)
	bit 0,h		;6a3b   ; mira su bit bajo
	ret z			;6a3d
	ld a,(0e128h)		;6a3e   ; lee la bandera (0xE128)
	and 010h		;6a41   ; aisla el bit del resultado
	jr nz,DIBUJA_ATLETA_6A20		;6a43   ; si esta puesto, salta
	ld a,l			;6a45
	neg		;6a46
	ld c,a			;6a48
	and 0f8h		;6a49
	ld hl,00dc0h		;6a4b
	call HL_MAS_A		;6a4e
	add hl,hl			;6a51
	add hl,hl			;6a52
	inc hl			;6a53
	inc hl			;6a54
	ex de,hl			;6a55
	ld hl,06a88h		;6a56
	bit 2,c		;6a59
	jr z,DIBUJA_ATLETA_6A60		;6a5b
	ld hl,06aa4h		;6a5d
DIBUJA_ATLETA_6A60:
	exx			;6a60
	ld b,006h		;6a61
	ld d,007h		;6a63
DIBUJA_ATLETA_6A65:
	exx			;6a65   ; al banco alterno
	ld a,d			;6a66   ; lee la parte alta
	cp 03bh		;6a67   ; compara con 0x3B
	ret nc			;6a69
	ld a,038h		;6a6a   ; valor tope
	cp d			;6a6c   ; lo compara con D
	jr nz,DIBUJA_ATLETA_6A7C		;6a6d
	ld a,e			;6a6f
	cp 060h		;6a70
	jr nc,DIBUJA_ATLETA_6A7C		;6a72
	exx			;6a74
	ld a,d			;6a75
	exx			;6a76
	call HL_MAS_A		;6a77
	jr DIBUJA_ATLETA_6A7F		;6a7a
DIBUJA_ATLETA_6A7C:
	call VUELCA_TABLA_VDP_440D		;6a7c
DIBUJA_ATLETA_6A7F:
	ld a,020h		;6a7f
	call DE_MAS_A		;6a81
	exx			;6a84
	djnz DIBUJA_ATLETA_6A65		;6a85
	ret			;6a87

; ----------------------------------------------------------------------
; DATOS tabla_posturas: Punteros de las posturas del atleta
;   0x6a88..0x6b10  (136 bytes)
DATA_tabla_posturas:
	defb 081h,015h	; 6a88
	defb 005h,01eh	; 6a8a
	defb 002h,01eh	; 6a8c
	defb 000h,081h	; 6a8e
	defb 015h,005h	; 6a90
	defb 01eh,002h	; 6a92
	defb 01eh,000h	; 6a94
	defb 081h,0b7h	; 6a96
	defb 006h,0b8h	; 6a98
	defb 081h,0b9h	; 6a9a
	defb 000h,081h	; 6a9c
	defb 015h,005h	; 6a9e
	defb 01eh,002h	; 6aa0
	defb 01eh,000h	; 6aa2
	defb 081h,015h	; 6aa4
	defb 005h,01eh	; 6aa6
	defb 002h,01eh	; 6aa8
	defb 000h,081h	; 6aaa
	defb 015h,005h	; 6aac
	defb 01eh,002h	; 6aae
	defb 01eh,000h	; 6ab0
	defb 081h,0bbh	; 6ab2
	defb 006h,0bdh	; 6ab4
	defb 081h,0bfh	; 6ab6
	defb 000h,081h	; 6ab8
	defb 0bch,006h	; 6aba
	defb 0beh,081h	; 6abc
	defb 0c0h,000h	; 6abe
	defb 081h,015h	; 6ac0
	defb 005h,01eh	; 6ac2
	defb 002h,01eh	; 6ac4
	defb 000h,081h	; 6ac6
	defb 015h,005h	; 6ac8
	defb 01eh,002h	; 6aca
	defb 01eh,000h	; 6acc
	defb 002h,039h	; 6ace
	defb 0b7h,0b8h	; 6ad0
	defb 0b8h,0b8h	; 6ad2
	defb 0c1h,0c2h	; 6ad4
	defb 0c3h,0c4h	; 6ad6
	defb 0feh,022h	; 6ad8
	defb 039h,015h	; 6ada
	defb 01eh,01eh	; 6adc
	defb 01eh,01eh	; 6ade
	defb 01eh,01eh	; 6ae0
	defb 0c5h,0feh	; 6ae2
	defb 042h,039h	; 6ae4
	defb 015h,01eh	; 6ae6
	defb 01eh,01eh	; 6ae8
	defb 01eh,01eh	; 6aea
	defb 01eh,01eh	; 6aec
	defb 0ffh,002h	; 6aee
	defb 039h,0b7h	; 6af0
	defb 0b8h,0ceh	; 6af2
	defb 0cfh,0d0h	; 6af4
	defb 0d1h,0d2h	; 6af6
	defb 0d3h,0feh	; 6af8
	defb 022h,039h	; 6afa
	defb 015h,01eh	; 6afc
	defb 01eh,01eh	; 6afe
	defb 0d4h,0d5h	; 6b00
	defb 0d6h,0d7h	; 6b02
	defb 0feh,042h	; 6b04
	defb 039h,015h	; 6b06
	defb 01eh,01eh	; 6b08
	defb 01eh,01eh	; 6b0a
	defb 01eh,01eh	; 6b0c
	defb 01eh,0ffh	; 6b0e

; ======================================================================
; CODIGO 0x6b10..0x6b3c  (44 bytes)
; ======================================================================


AVANZA_POSTURA:		; Pasa al siguiente fotograma de la animacion
	ld a,(0e052h)		;6b10   ; el evento elige la animacion
	rra			;6b13
	jr c,AVANZA_POSTURA_6B28		;6b14
	ld hl,06b58h		;6b16
	rra			;6b19
	jr nc,AVANZA_POSTURA_6B1F		;6b1a
	ld hl,06b60h		;6b1c
AVANZA_POSTURA_6B1F:
	ld de,07860h		;6b1f
	call VUELCA_TABLA_VDP_440D		;6b22
	jp DIBUJA_ATLETA_69B6		;6b25
AVANZA_POSTURA_6B28:
	ld hl,06b3ch		;6b28   ; apunta a los dibujos de las posturas (0x6B3C)
	call VUELCA_TABLA_VDP		;6b2b
	ld b,008h		;6b2e
	ld de,038c0h		;6b30
	ld hl,06c3fh		;6b33
	call DIBUJA_ATLETA_69F3		;6b36
	jp CONTROL_MANDOS		;6b39

; ----------------------------------------------------------------------
; DATOS graficos_posturas: Dibujos de las posturas del atleta por prueba
;   0x6b3c..0x6dec  (688 bytes)
DATA_graficos_posturas:
	defb 060h,038h,020h,091h,020h,01eh,020h,093h,080h,0c0h,039h,040h,004h,020h,095h,040h	; 6b3c  `8 . . ...9@. .@
	defb 096h,020h,097h,020h,002h,020h,097h,020h,002h,020h,096h,000h,083h,002h,002h,015h	; 6b4c  . . . . . ......
	defb 01dh,01eh,000h,000h,020h,01eh,000h,000h,083h,002h,002h,015h,01dh,01eh,000h,083h	; 6b5c  .... ...........
	defb 002h,002h,015h,01dh,01eh,000h,083h,002h,002h,015h,01dh,02bh,000h,083h,002h,002h	; 6b6c  ...........+....
	defb 015h,01dh,02ch,000h,083h,002h,002h,015h,01dh,02dh,000h,083h,002h,002h,015h,01dh	; 6b7c  ..,......-......
	defb 000h,000h,083h,002h,002h,015h,00ah,001h,082h,005h,006h,004h,001h,081h,007h,00ch	; 6b8c  ................
	defb 001h,000h,083h,002h,002h,015h,00ah,002h,087h,008h,009h,00ah,00bh,00ch,00dh,00eh	; 6b9c  ................
	defb 00ch,002h,000h,083h,002h,002h,015h,003h,003h,083h,00fh,010h,011h,00eh,003h,089h	; 6bac  ................
	defb 015h,016h,015h,003h,018h,019h,01ah,003h,003h,000h,083h,002h,002h,015h,003h,003h	; 6bbc  ................
	defb 083h,012h,013h,014h,00eh,003h,089h,015h,017h,015h,003h,01ah,01ah,01ah,003h,003h	; 6bcc  ................
	defb 000h,083h,002h,002h,015h,008h,004h,089h,01bh,004h,01bh,004h,01bh,004h,01bh,004h	; 6bdc  ................
	defb 01bh,00ch,004h,000h,083h,002h,002h,015h,008h,004h,009h,015h,00ch,004h,000h,083h	; 6bec  ................
	defb 002h,002h,015h,01dh,0a1h,000h,083h,002h,002h,015h,01dh,0d8h,000h,088h,002h,002h	; 6bfc  ................
	defb 015h,0d8h,0d8h,0d8h,0aeh,0adh,018h,0a9h,000h,088h,002h,002h,0ach,0d8h,0aeh,0adh	; 6c0c  ................
	defb 0aah,0abh,018h,0a8h,000h,086h,0d8h,0d8h,0aeh,0adh,0aah,0abh,01ah,0a8h,000h,084h	; 6c1c  ................
	defb 0aeh,0adh,0aah,0abh,01ch,0a8h,000h,020h,0a9h,000h,020h,0d8h,000h,020h,01eh,000h	; 6c2c  ....... .. .. ..
	defb 020h,01eh,000h,020h,02bh,000h,020h,02ch,000h,020h,02dh,000h,020h,000h,000h,00dh	; 6c3c   .. +. ,. -. ...
	defb 001h,082h,005h,006h,004h,001h,081h,007h,00ch,001h,000h,00dh,002h,087h,008h,009h	; 6c4c  ................
	defb 00ah,00bh,00ch,00dh,00eh,00ch,002h,000h,086h,003h,003h,01ch,015h,01dh,003h,083h	; 6c5c  ................
	defb 00fh,010h,011h,00eh,003h,089h,015h,016h,015h,003h,018h,019h,01ah,003h,003h,000h	; 6c6c  ................
	defb 086h,003h,003h,01ch,015h,01dh,003h,083h,012h,013h,014h,00eh,003h,089h,015h,017h	; 6c7c  ................
	defb 015h,003h,01ah,01ah,01ah,003h,003h,000h,00bh,004h,089h,01bh,004h,01bh,004h,01bh	; 6c8c  ................
	defb 004h,01bh,004h,01bh,00ch,004h,000h,00bh,004h,009h,015h,00ch,004h,000h,020h,0f4h	; 6c9c  .............. .
	defb 000h,020h,0f5h,000h,009h,0f5h,082h,0a8h,0a9h,009h,0aah,082h,0ach,0adh,00ah,0f5h	; 6cac  . ..............
	defb 000h,009h,003h,082h,0aeh,0afh,009h,0b0h,082h,0b2h,0b3h,00ah,003h,000h,00bh,0f5h	; 6cbc  ................
	defb 082h,0b5h,0b6h,005h,0f5h,082h,0b7h,0b8h,00ch,0f5h,000h,009h,003h,084h,0bah,0beh	; 6ccc  ................
	defb 0bch,0bdh,005h,0beh,084h,0bfh,0c0h,0beh,0c2h,00ah,003h,000h,009h,003h,083h,0c3h	; 6cdc  ................
	defb 0beh,0c5h,007h,0beh,083h,0c6h,0beh,0c8h,00ah,003h,000h,020h,0f5h,000h,020h,01eh	; 6cec  ........... .. .
	defb 000h,020h,01eh,000h,020h,09dh,000h,020h,09eh,000h,020h,09fh,000h,020h,0a0h,000h	; 6cfc  . .. .. .. .. ..
	defb 00eh,060h,081h,07ch,011h,060h,000h,00dh,002h,087h,07dh,07eh,07fh,080h,081h,082h	; 6d0c  .`.|.`....}~....
	defb 083h,00ch,002h,000h,089h,061h,061h,08bh,08ch,08dh,061h,064h,065h,064h,004h,061h	; 6d1c  .....aa...aded.a
	defb 087h,084h,085h,086h,087h,088h,089h,08ah,003h,061h,089h,06ch,06dh,06ch,061h,071h	; 6d2c  .........a.lmlaq
	defb 072h,073h,061h,061h,000h,089h,003h,003h,01ch,015h,01dh,003h,066h,067h,068h,00eh	; 6d3c  rsaa........fgh.
	defb 003h,089h,015h,06eh,015h,003h,074h,075h,01ah,003h,003h,000h,094h,062h,062h,08eh	; 6d4c  ...n..tu.....bb.
	defb 08fh,069h,062h,069h,06ah,069h,062h,062h,06bh,062h,06bh,062h,06bh,062h,06bh,062h	; 6d5c  .ibijibbkbkbkbkb
	defb 06bh,003h,062h,084h,06fh,06fh,06fh,062h,003h,076h,002h,062h,000h,00bh,004h,089h	; 6d6c  k.b.ooob.v.b....
	defb 078h,0fbh,078h,0fbh,078h,0fbh,078h,0fbh,078h,00ch,004h,000h,00bh,0f6h,009h,0f7h	; 6d7c  x.x.x.x.x.......
	defb 00ch,0f6h,000h,020h,0f8h,000h,009h,0fah,082h,0c9h,0cah,009h,0cbh,082h,0cdh,0ceh	; 6d8c  ... ............
	defb 00ah,0fah,000h,009h,003h,082h,0cfh,0d0h,009h,0d1h,082h,0d3h,0d4h,00ah,003h,000h	; 6d9c  ................
	defb 009h,0fah,084h,0d5h,0d9h,0d7h,0d8h,005h,0d9h,084h,0dbh,0dch,0d9h,0deh,00ah,0fah	; 6dac  ................
	defb 000h,009h,003h,084h,0dfh,0e3h,0e1h,0e2h,005h,0e3h,084h,0e4h,0e5h,0e3h,0e7h,00ah	; 6dbc  ................
	defb 003h,000h,009h,003h,083h,0e8h,0e9h,0eah,007h,000h,083h,0ebh,0e9h,0ech,00ah,003h	; 6dcc  ................
	defb 000h,009h,0fah,083h,0edh,0f0h,0efh,007h,0f0h,083h,0f1h,0f0h,0f3h,00ah,0fah,000h	; 6ddc  ................

; ======================================================================
; CODIGO 0x6dec..0x6eeb  (255 bytes)
; ======================================================================


PUNTOS_A_BCD:		; Convierte la marca a BCD y la deja en el marcador
	ld hl,(0e106h)		;6dec   ; toma la marca de 0xE106
	ld a,l			;6def   ; el byte bajo
	sra h		;6df0   ; desplaza la marca a la derecha
	rra			;6df2   ; arrastrando el bit
	sra h		;6df3   ; y otra vez
	rra			;6df5   ; (dividida entre 16)
	sra h		;6df6
	rra			;6df8
	sra h		;6df9
	rra			;6dfb
	cpl			;6dfc
	ld l,a			;6dfd
	ld a,h			;6dfe
	cpl			;6dff
	ld h,a			;6e00
	inc hl			;6e01
	ld de,0fffeh		;6e02
	add hl,de			;6e05
	jr c,PUNTOS_A_BCD_6E0B		;6e06
	ld hl,00000h		;6e08
PUNTOS_A_BCD_6E0B:
	ld b,010h		;6e0b
	ld de,00000h		;6e0d
PUNTOS_A_BCD_6E10:
	add hl,hl			;6e10   ; dobla el acumulador
	ld a,e			;6e11   ; suma con acarreo decimal
	adc a,a			;6e12   ; suma con acarreo
	daa			;6e13   ; ajuste decimal
	ld e,a			;6e14   ; lo guarda
	ld a,d			;6e15
	adc a,a			;6e16
	daa			;6e17
	ld d,a			;6e18
	djnz PUNTOS_A_BCD_6E10		;6e19
	ld hl,0e138h		;6e1b
	ld (hl),e			;6e1e
	inc hl			;6e1f
	ld (hl),d			;6e20
	ld de,0385bh		;6e21
	ld b,002h		;6e24
	jp PREPARA_TABLERO_42ED		;6e26
MIDE_MARCA:		; Comprueba el resultado del intento
	ld a,(0e14eh)		;6e29   ; lee el estado del intento (0xE14E)
	dec a			;6e2c   ; lo decrementa
	jp m,MIDE_MARCA_6E73		;6e2d   ; si es negativo, otro camino
	jr nz,MIDE_MARCA_6E52		;6e30   ; si no es este caso, otro
	ld a,(0e181h)		;6e32   ; lee la bandera (0xE181)
	and a			;6e35   ; la comprueba
	jr nz,MIDE_MARCA_6E73		;6e36   ; salta si esta puesta
	ld hl,06f00h		;6e38
	ld a,(0e052h)		;6e3b
	and 003h		;6e3e
	add a,a			;6e40
	call HL_MAS_A		;6e41
	ld e,(hl)			;6e44
	inc hl			;6e45
	ld d,(hl)			;6e46
	ex de,hl			;6e47
	call MIDE_MARCA_6E6B		;6e48
	ret nz			;6e4b
	ld a,001h		;6e4c
	ld (0e181h),a		;6e4e
	ret			;6e51
MIDE_MARCA_6E52:
	dec a			;6e52   ; decrementa el selector
	jr nz,MIDE_MARCA_6E87		;6e53
	ld a,(0e002h)		;6e55
	bit 5,a		;6e58
	jr z,MIDE_MARCA_6E73		;6e5a
	add a,a			;6e5c
	ld a,031h		;6e5d
	jr nc,MIDE_MARCA_6E62		;6e5f
	inc a			;6e61
MIDE_MARCA_6E62:
	ld de,07934h		;6e62
	call SACA_BYTE_VRAM		;6e65
	ld hl,06f3ch		;6e68
MIDE_MARCA_6E6B:
	call VUELCA_GUION_MASC		;6e6b
	ld hl,0e122h		;6e6e
	dec (hl)			;6e71
	ret nz			;6e72
MIDE_MARCA_6E73:
	ld a,080h		;6e73   ; valor por defecto
	ld (0e122h),a		;6e75
	ld hl,0e14eh		;6e78
	inc (hl)			;6e7b
	ld hl,061f3h		;6e7c
	ld de,07923h		;6e7f
	call VUELCA_TABLA_VDP_440D		;6e82
	xor a			;6e85
	ret			;6e86
MIDE_MARCA_6E87:
	dec a			;6e87   ; baja el contador
	jr nz,MIDE_MARCA_6EA5		;6e88
	ld hl,06f45h		;6e8a
	call MIDE_MARCA_6E6B		;6e8d
	ret z			;6e90
	inc de			;6e91
	ld hl,0e186h		;6e92
MIDE_MARCA_6E95:
	ld b,001h		;6e95   ; arranca B a 1
	call PREPARA_TABLERO_42ED		;6e97
	ld a,01fh		;6e9a
	call SACA_BYTE_VRAM		;6e9c
	inc de			;6e9f
	ld b,001h		;6ea0
	jp PREPARA_TABLERO_42ED		;6ea2
MIDE_MARCA_6EA5:
	xor a			;6ea5
	ld (0e182h),a		;6ea6
	ld (0e14eh),a		;6ea9
	ret			;6eac
MIDE_MARCA_6EAD:
	ld a,(0e003h)		;6ead
	bit 3,a		;6eb0
	ld a,02ah		;6eb2
	jr nz,MIDE_MARCA_6EB7		;6eb4
	dec a			;6eb6
MIDE_MARCA_6EB7:
	ld (0e10bh),a		;6eb7   ; guarda la postura (0xE10B)
	ld (0e131h),a		;6eba   ; y la casilla (0xE131)
	ld hl,0e122h		;6ebd   ; apunta a la coordenada (0xE122)
	ld a,(hl)			;6ec0   ; la lee
	cp 001h		;6ec1   ; compara con 1
	jr z,MIDE_MARCA_6EE2		;6ec3
	ld hl,06eebh		;6ec5
	call MIDE_MARCA_6E6B		;6ec8
	ld a,(hl)			;6ecb
	cp 07fh		;6ecc
	ld a,096h		;6ece
	call z,SUMA_BONUS		;6ed0
	ld de,0792eh		;6ed3
	ld a,(0e002h)		;6ed6
	add a,a			;6ed9
	ld a,031h		;6eda
	jr nc,MIDE_MARCA_6EDF		;6edc
	inc a			;6ede
MIDE_MARCA_6EDF:
	jp SACA_BYTE_VRAM		;6edf
MIDE_MARCA_6EE2:
	inc a			;6ee2   ; sube el contador
	ld (hl),a			;6ee3
	ld a,(0e012h)		;6ee4
	and a			;6ee7
	ret nz			;6ee8
	ld (hl),a			;6ee9
	ret			;6eea

; ----------------------------------------------------------------------
; DATOS rotulos_eventos: Rotulos PLAYER, DIVING, TRAMPOLINE, HORSE,
;   HORIZONTAL, QUALIFY
;   0x6eeb..0x6f4f  (100 bytes)
DATA_rotulos_eventos:
	defb 027h,079h,050h,04ch,041h,059h,045h,052h,000h,000h,000h,047h,041h,04dh,045h,000h	; 6eeb  'yPLAYER...GAME.
	defb 04fh,056h,045h,052h,0ffh,008h,06fh,01eh,06fh,011h,06fh,02bh,06fh,02eh,079h,044h	; 6efb  OVER..o.o.o+o.yD
	defb 049h,056h,049h,04eh,047h,0ffh,02bh,079h,054h,052h,041h,04dh,050h,04fh,04ch,049h	; 6f0b  IVING.+yTRAMPOLI
	defb 04eh,045h,0ffh,02ah,079h,04ch,04fh,04eh,047h,000h,048h,04fh,052h,053h,045h,0ffh	; 6f1b  NE.*yLONG.HORSE.
	defb 02ah,079h,048h,04fh,052h,049h,05ah,04fh,04eh,054h,041h,04ch,000h,042h,041h,052h	; 6f2b  *yHORIZONTAL.BAR
	defb 0ffh,02dh,079h,050h,04ch,041h,059h,045h,052h,0ffh,02ah,079h,051h,055h,041h,04ch	; 6f3b  .-yPLAYER.*yQUAL
	defb 049h,046h,059h,0ffh	; 6f4b

; ======================================================================
; CODIGO 0x6f4f..0x6f9c  (77 bytes)
; ======================================================================


ELIGE_EVENTO:		; Escribe el rotulo del evento en curso
	ld a,(0e128h)		;6f4f   ; lee la bandera del evento (0xE128)
	add a,a			;6f52
	ret nc			;6f53
	ld a,(0e0f1h)		;6f54
	and 010h		;6f57
	ret z			;6f59
ELIGE_EVENTO_6F5A:
	ld hl,0e128h		;6f5a   ; apunta a la bandera
	res 7,(hl)		;6f5d   ; borra su bit alto
	ld a,(0e106h)		;6f5f   ; lee la marca (0xE106)
	and 007h		;6f62   ; la enmascara
	add a,a			;6f64   ; la dobla
	ld hl,06f9ch		;6f65   ; apunta a la tabla de rotulos (0x6F9C)
	call HL_MAS_A		;6f68
	ld e,(hl)			;6f6b
	inc hl			;6f6c
	ld d,(hl)			;6f6d
	ld a,(0e12dh)		;6f6e
	and a			;6f71
	jr z,ELIGE_EVENTO_6F83		;6f72
	sra d		;6f74
	rr e		;6f76
	sub 003h		;6f78
	cp 004h		;6f7a
	jr nc,ELIGE_EVENTO_6F83		;6f7c
	ld de,0ff80h		;6f7e
	jr ELIGE_EVENTO_6F87		;6f81
ELIGE_EVENTO_6F83:
	xor a			;6f83
	ld (0e12dh),a		;6f84
ELIGE_EVENTO_6F87:
	ld hl,0e101h		;6f87   ; apunta al estado (0xE101)
	ld a,(hl)			;6f8a   ; lo lee
	add a,e			;6f8b   ; suma el desplazamiento
	cpl			;6f8c   ; lo niega
	ld (hl),a			;6f8d   ; lo guarda
	inc hl			;6f8e
	ld a,(hl)			;6f8f
	adc a,d			;6f90
	cpl			;6f91
	jr nz,ELIGE_EVENTO_6F96		;6f92
	ld a,0ffh		;6f94
ELIGE_EVENTO_6F96:
	ld (hl),a			;6f96
	ret nz			;6f97
	dec hl			;6f98
	ld (hl),000h		;6f99
	ret			;6f9b

; ----------------------------------------------------------------------
; DATOS tabla_evento_rotulo: Punteros de los rotulos de evento
;   0x6f9c..0x6fac  (16 bytes)
DATA_tabla_evento_rotulo:
	defw 0ff60h,00088h,000a8h,000c8h,000f8h,00118h,00128h,00158h	; 6f9c

; ======================================================================
; CODIGO 0x6fac..0x7020  (116 bytes)
; ======================================================================


DIBUJA_RESULTADO:		; Pinta la marca conseguida y compara con la de paso
	ld a,(0e128h)		;6fac   ; lee la bandera (0xE128)
	and 010h		;6faf   ; aisla el bit del resultado
	ret z			;6fb1
	ld hl,0e10bh		;6fb2   ; apunta a la postura (0xE10B)
	ld a,(hl)			;6fb5   ; la lee
	ld c,a			;6fb6   ; la pasa a C
	cp 006h		;6fb7
	jr nc,DIBUJA_RESULTADO_6FCB		;6fb9
	ld a,(0e12ch)		;6fbb
	cp 00ah		;6fbe
	jr nz,DIBUJA_RESULTADO_6FC4		;6fc0
	ld c,002h		;6fc2
DIBUJA_RESULTADO_6FC4:
	cp 00dh		;6fc4
	jr nz,DIBUJA_RESULTADO_6FCA		;6fc6
	ld c,003h		;6fc8
DIBUJA_RESULTADO_6FCA:
	ld (hl),c			;6fca
DIBUJA_RESULTADO_6FCB:
	ld a,(0e12bh)		;6fcb   ; lee la casilla (0xE12B)
	ld hl,07020h		;6fce   ; apunta a la tabla de resultados (0x7020)
	add a,a			;6fd1   ; dobla el indice
	call HL_MAS_A		;6fd2   ; indexa la tabla de resultados
	ld e,(hl)			;6fd5   ; lee el puntero
	inc hl			;6fd6   ; avanza
	ld d,(hl)			;6fd7   ; la parte alta
	ld hl,0e12ch		;6fd8
	ld a,(hl)			;6fdb
	inc (hl)			;6fdc
	and a			;6fdd
	rra			;6fde
	call DE_MAS_A		;6fdf
	ld a,(de)			;6fe2
	ld c,a			;6fe3
	inc a			;6fe4
	jr z,DIBUJA_RESULTADO_6FF0		;6fe5
	ld hl,0e106h		;6fe7
	ld a,(hl)			;6fea
	and 0f8h		;6feb
	or c			;6fed
	ld (hl),a			;6fee
	ret			;6fef
DIBUJA_RESULTADO_6FF0:
	call SALTO_ALTURA_70E7		;6ff0   ; dibuja el resultado
	ld hl,0e14bh		;6ff3
	ld a,(0e10bh)		;6ff6
	cp (hl)			;6ff9
	jr nz,DIBUJA_RESULTADO_6FFE		;6ffa
	inc hl			;6ffc
	inc (hl)			;6ffd
DIBUJA_RESULTADO_6FFE:
	ld a,(0e128h)		;6ffe   ; relee la bandera
	add a,a			;7001   ; dobla
	call c,ELIGE_EVENTO_6F5A		;7002   ; elige el rotulo si toca
	ld hl,0e128h		;7005   ; apunta a la bandera (0xE128)
	ld (hl),068h		;7008   ; le pone el valor 0x68
	ld hl,0e12ah		;700a
	ld a,(0e137h)		;700d
	and a			;7010
	ret z			;7011
	dec (hl)			;7012
	ret nz			;7013
	ld a,(0e052h)		;7014
	and 003h		;7017
	ret nz			;7019
	ld a,0ffh		;701a
	ld (0e103h),a		;701c
	ret			;701f

; ----------------------------------------------------------------------
; DATOS tabla_resultado: Punteros de los rotulos del resultado
;   0x7020..0x7063  (67 bytes)
DATA_tabla_resultado:
	defw 0702ch,07033h,0703bh,07044h,0704eh,07059h,00101h,00202h	; 7020
	defw 00001h,001ffh,00201h,00203h,00001h,001ffh,00302h,00304h	; 7030
	defw 00102h,0ff00h,00201h,00403h,00304h,00102h,0ff00h,00201h	; 7040
	defw 00403h,00506h,00304h,00001h,002ffh,00504h,00706h,00305h	; 7050
	defw 00001h	; 7060
	defb 0ffh	; 7062

; ======================================================================
; CODIGO 0x7063..0x70f5  (146 bytes)
; ======================================================================


SALTO_ALTURA:		; Motor del salto (impulso, angulo, altura)
	ld de,0e141h		;7063   ; apunta a la altura (0xE141)
	ld a,(de)			;7066   ; la lee
	inc a			;7067   ; sube en uno
	ret z			;7068   ; sale si desborda
	ld hl,(0e109h)		;7069   ; lee la coordenada (0xE109)
	ld bc,0001ah		;706c   ; desplazamiento de 0x1A
	add hl,bc			;706f   ; lo suma
	ld a,h			;7070   ; la parte alta
	and a			;7071   ; limpia el acarreo
	ret m			;7072
	ld bc,00024h		;7073   ; desplazamiento de 0x24
	and a			;7076   ; limpia el acarreo
	sbc hl,bc		;7077
	jp nc,SALTO_ALTURA_709F		;7079
	ld a,(de)			;707c
	and a			;707d
	jr nz,SALTO_ALTURA_70A7		;707e
	add hl,bc			;7080
	ld c,l			;7081
	ld hl,0e128h		;7082
	res 2,(hl)		;7085
	ld a,(0e0f1h)		;7087
	and 010h		;708a
	ret z			;708c
	xor a			;708d
	ld (hl),a			;708e
	inc a			;708f
	ld (de),a			;7090
	ld a,c			;7091
	add a,004h		;7092
	rra			;7094
	and 01ch		;7095
	ld (0e163h),a		;7097
	ld a,049h		;709a
	jp SUMA_BONUS		;709c
SALTO_ALTURA_709F:
	ld a,014h		;709f
	ld (0e109h),a		;70a1
	jp JUEZ		;70a4
SALTO_ALTURA_70A7:
	ex de,hl			;70a7   ; intercambia a HL
	inc (hl)			;70a8   ; sube la casilla
	ld a,(hl)			;70a9   ; la lee
	sra a		;70aa   ; divide entre cuatro
	sra a		;70ac   ; con signo
	add a,001h		;70ae   ; suma uno
	push af			;70b0   ; lo guarda
	ld (0e10bh),a		;70b1   ; guarda la postura (0xE10B)
	dec a			;70b4   ; la baja
	ex de,hl			;70b5   ; la pasa a HL
	ld hl,070f5h		;70b6
	call HL_MAS_A		;70b9
	ld a,(hl)			;70bc
	ld hl,0e106h		;70bd
	ld (hl),a			;70c0
	pop af			;70c1
	cp 004h		;70c2
	ret c			;70c4
	ex de,hl			;70c5
	ld a,0ffh		;70c6
	ld (hl),a			;70c8
	ld a,028h		;70c9
	ld (0e128h),a		;70cb
	ld a,(0e163h)		;70ce
	ld hl,070f9h		;70d1
	call HL_MAS_A		;70d4
	ld de,0e101h		;70d7
	ld b,004h		;70da
SALTO_ALTURA_70DC:
	ld a,(hl)			;70dc   ; lee el valor
	inc hl			;70dd
	ld (de),a			;70de
	inc de			;70df
	djnz SALTO_ALTURA_70DC		;70e0
	ld a,001h		;70e2
	ld (0e142h),a		;70e4
SALTO_ALTURA_70E7:
	ld hl,0e031h		;70e7   ; apunta al canal de sonido (0xE031)
	ld a,(hl)			;70ea
	ld (hl),000h		;70eb
	cp 002h		;70ed
	ret z			;70ef
	ld a,001h		;70f0
	jp SUMA_BONUS		;70f2

; ----------------------------------------------------------------------
; DATOS tabla_salto: Curva del salto
;   0x70f5..0x7115  (32 bytes)
DATA_tabla_salto:
	defb 0dfh,0dch	; 70f5
	defb 0deh,0cfh	; 70f7
	defb 0d0h,0feh	; 70f9
	defb 0f0h,000h	; 70fb
	defb 0f0h,0feh	; 70fd
	defb 000h,001h	; 70ff
	defb 010h,0ffh	; 7101
	defb 020h,001h	; 7103
	defb 020h,0ffh	; 7105
	defb 040h,001h	; 7107
	defb 030h,0ffh	; 7109
	defb 060h,001h	; 710b
	defb 040h,0ffh	; 710d
	defb 080h,001h	; 710f
	defb 040h,0ffh	; 7111
	defb 080h,001h	; 7113

; ======================================================================
; CODIGO 0x7115..0x715e  (73 bytes)
; ======================================================================


DIBUJA_SALPICADURA:		; Dibuja la entrada al agua o el aterrizaje
	ld a,(0e128h)		;7115
	and 004h		;7118
	ret z			;711a
DIBUJA_SALPICADURA_711B:
	ld hl,(0e103h)		;711b   ; lee la coordenada (0xE103)
	inc hl			;711e
	inc hl			;711f
	ld b,h			;7120
	ld c,l			;7121
	ld de,001ffh		;7122
	sbc hl,de		;7125
	jr c,DIBUJA_SALPICADURA_712C		;7127
	ld bc,001ffh		;7129
DIBUJA_SALPICADURA_712C:
	ld (0e103h),bc		;712c   ; guarda la nueva
	ld hl,(0e103h)		;7130   ; la relee
	ld a,l			;7133   ; el byte bajo
	rr h		;7134   ; desplaza con signo
	rra			;7136   ; arrastra el bit
	rr h		;7137
	rra			;7139
	ld hl,0e13bh		;713a
	add a,(hl)			;713d
	ld (hl),a			;713e
	inc hl			;713f
	ret nc			;7140
	inc (hl)			;7141
	ld a,(hl)			;7142
	cp 00ch		;7143
	jr c,DIBUJA_SALPICADURA_7149		;7145
	xor a			;7147
	ld (hl),a			;7148
DIBUJA_SALPICADURA_7149:
	add a,012h		;7149   ; suma el desplazamiento
	ld hl,0e10bh		;714b   ; apunta a la postura (0xE10B)
	ld b,(hl)			;714e   ; la lee a B
	ld (hl),a			;714f   ; guarda la nueva
	cp b			;7150
	ret z			;7151
	cp 014h		;7152
	jr z,DIBUJA_SALPICADURA_7159		;7154
	cp 01ah		;7156
	ret nz			;7158
DIBUJA_SALPICADURA_7159:
	ld a,045h		;7159
	jp SUMA_BONUS		;715b

; ----------------------------------------------------------------------
; DATOS byte_suelto: Un byte de relleno entre dos rutinas
;   0x715e..0x715f  (1 bytes)
DATA_byte_suelto:
	defb 077h	; 715e

; ======================================================================
; CODIGO 0x715f..0x72a8  (329 bytes)
; ======================================================================


MOTOR_TRAMPOLIN:		; Rebote y giros del trampolin
	ld a,(0e128h)		;715f   ; lee la bandera del evento (0xE128)
	add a,a			;7162   ; la dobla
	ret p			;7163
	ld a,(0e0f1h)		;7164   ; lee los mandos (0xE0F1)
	and 008h		;7167   ; aisla el bit del boton
	ret z			;7169
	ld hl,0e145h		;716a   ; apunta al campo (0xE145)
	inc (hl)			;716d
	jr nz,MOTOR_TRAMPOLIN_7172		;716e
	inc hl			;7170
	inc (hl)			;7171
MOTOR_TRAMPOLIN_7172:
	ld hl,0e12dh		;7172   ; apunta a la casilla (0xE12D)
	ld a,(0e16fh)		;7175
	and a			;7178
	ld a,001h		;7179
	jr z,MOTOR_TRAMPOLIN_717F		;717b
	ld a,0ffh		;717d
MOTOR_TRAMPOLIN_717F:
	add a,(hl)			;717f   ; suma la casilla
	and 007h		;7180
	ld (hl),a			;7182
	add a,006h		;7183
	ld hl,0e10bh		;7185
	ld (hl),a			;7188
	ret			;7189
MOTOR_TRAMPOLIN_718A:
	ld a,(0e12ah)		;718a   ; lee la bandera (0xE12A)
	and a			;718d   ; la comprueba
	ret nz			;718e
	ld a,(0e13ah)		;718f   ; lee la bandera (0xE13A)
	and a			;7192   ; la comprueba
	jr nz,MOTOR_TRAMPOLIN_71A6		;7193   ; si esta puesta, salta
	ld a,(0e0f1h)		;7195
	and 010h		;7198
	ret z			;719a
	ld a,001h		;719b
	ld (0e13ah),a		;719d
	ld hl,0e128h		;71a0
	res 6,(hl)		;71a3
	ret			;71a5
MOTOR_TRAMPOLIN_71A6:
	ld a,(0e003h)		;71a6   ; la fase de la interrupcion
	and 003h		;71a9   ; la enmascara
	ret nz			;71ab
	ld hl,0e10bh		;71ac   ; apunta a la postura (0xE10B)
	ld a,(hl)			;71af   ; la lee
	cp 00ah		;71b0   ; compara con 0x0A
	jr z,MOTOR_TRAMPOLIN_71BE		;71b2
	cp 00eh		;71b4
	jr c,MOTOR_TRAMPOLIN_7172		;71b6
	inc a			;71b8
	cp 012h		;71b9
	ret nc			;71bb
	ld (hl),a			;71bc
	ret			;71bd
MOTOR_TRAMPOLIN_71BE:
	ld a,00eh		;71be
	ld (hl),a			;71c0
	ret			;71c1
MOTOR_TRAMPOLIN_71C2:
	ld hl,0733eh		;71c2   ; apunta a una tabla (0x733E)
	ld de,073a6h		;71c5
	ld bc,0080dh		;71c8
	exx			;71cb
	ld hl,039c0h		;71cc
	ld a,0fdh		;71cf
	jr MOTOR_TRAMPOLIN_7225		;71d1
MOTOR_TRAMPOLIN_71D3:
	ex af,af'			;71d3
	or a			;71d4
	ex af,af'			;71d5
	jr MOTOR_TRAMPOLIN_724F		;71d6
MOTOR_TRAMPOLIN_71D8:
	ld hl,0740eh		;71d8   ; a otra tabla (0x740E)
	ld d,h			;71db   ; copia H a D
	ld e,l			;71dc   ; pasa L a E
	ld bc,0020bh		;71dd   ; cuenta y ancho del sprite
	exx			;71e0
	ld hl,039c0h		;71e1   ; destino en la VRAM (0x39C0)
	ld a,0dah		;71e4
	call MOTOR_TRAMPOLIN_7225		;71e6
	ld hl,(0e153h)		;71e9
	ld (0e164h),hl		;71ec
	ret			;71ef
MOTOR_TRAMPOLIN_71F0:
	ld a,(0e167h)		;71f0   ; lee la bandera (0xE167)
	and a			;71f3   ; la comprueba
	ret nz			;71f4   ; sale si esta puesta
	call CONTROL_MANDOS		;71f5   ; lee los mandos
	ld a,(0e052h)		;71f8   ; lee el evento
	push af			;71fb   ; lo protege
	call MOTOR_TRAMPOLIN_71D8		;71fc   ; dibuja la figura
	pop af			;71ff
	and 002h		;7200
	jr nz,MOTOR_TRAMPOLIN_71C2		;7202
	ld hl,072a8h		;7204
	ld de,072bch		;7207
	ld bc,0020ah		;720a
	exx			;720d
	ld hl,03a80h		;720e
	ld a,00ah		;7211
	call MOTOR_TRAMPOLIN_7225		;7213
	ld hl,072d0h		;7216
	ld de,07307h		;7219
	ld bc,0050bh		;721c
	exx			;721f
	ld hl,03a20h		;7220
	ld a,0fah		;7223
MOTOR_TRAMPOLIN_7225:
	ld (0e157h),hl		;7225   ; guarda el puntero (0xE157)
	ld (0e159h),a		;7228   ; y el valor (0xE159)
	ld hl,(0e109h)		;722b   ; lee la coordenada (0xE109)
	sra h		;722e   ; desplaza con signo
	rr l		;7230   ; arrastra el bit
	sra h		;7232
	rr l		;7234
	sra h		;7236
	rr l		;7238
	ex af,af'			;723a
	ld a,l			;723b
	sub 004h		;723c
	jp p,MOTOR_TRAMPOLIN_7246		;723e
	ld a,008h		;7241
	sub l			;7243
	jr MOTOR_TRAMPOLIN_724F		;7244
MOTOR_TRAMPOLIN_7246:
	cp 016h		;7246
	ld a,004h		;7248
	jr c,MOTOR_TRAMPOLIN_71D3		;724a
	add a,01ah		;724c
	sub l			;724e
MOTOR_TRAMPOLIN_724F:
	ld hl,0e159h		;724f   ; apunta al contador (0xE159)
	sub (hl)			;7252
	ex af,af'			;7253
	exx			;7254
	jr nc,MOTOR_TRAMPOLIN_7258		;7255
	ex de,hl			;7257
MOTOR_TRAMPOLIN_7258:
	ex af,af'			;7258   ; protege A
	ld de,(0e157h)		;7259   ; lee el puntero (0xE157)
	ld (0e13dh),bc		;725d   ; guarda el par (0xE13D)
	ld b,a			;7261   ; pasa A a B
	and a			;7262   ; lo comprueba
	jp p,MOTOR_TRAMPOLIN_7272		;7263
	add a,c			;7266
	ret nc			;7267
	ret z			;7268
	ld b,a			;7269
	ld a,c			;726a
	sub b			;726b
	call HL_MAS_A		;726c
	ld c,b			;726f
	jr MOTOR_TRAMPOLIN_7288		;7270
MOTOR_TRAMPOLIN_7272:
	cp 020h		;7272   ; compara con 0x20
	ret nc			;7274
	add a,c			;7275
	sub 020h		;7276
	jr nc,MOTOR_TRAMPOLIN_7280		;7278
	ld a,b			;727a
	call DE_MAS_A		;727b
	jr MOTOR_TRAMPOLIN_7288		;727e
MOTOR_TRAMPOLIN_7280:
	sub c			;7280
	neg		;7281
	ld c,a			;7283
	ld a,b			;7284
	call DE_MAS_A		;7285
MOTOR_TRAMPOLIN_7288:
	ld (0e153h),de		;7288
MOTOR_TRAMPOLIN_728C:
	ld (0e13fh),hl		;728c   ; guarda el puntero (0xE13F)
	push bc			;728f   ; guarda la cuenta
	call RELLENA_VRAM_43AC		;7290   ; rellena la VRAM
	pop bc			;7293
	ld hl,0e13eh		;7294   ; apunta al contador (0xE13E)
	dec (hl)			;7297   ; lo baja
	ret z			;7298
	dec hl			;7299
	ld a,(hl)			;729a
	ld hl,(0e13fh)		;729b
	call HL_MAS_A		;729e
	ld a,020h		;72a1
	call DE_MAS_A		;72a3
	jr MOTOR_TRAMPOLIN_728C		;72a6

; ----------------------------------------------------------------------
; DATOS graficos_trampolin: Graficos y tablas del trampolin y el caballo
;   0x72a8..0x7424  (380 bytes)
DATA_graficos_trampolin:
	defb 002h,002h,0a0h,0a1h,0a2h,0a3h,0a4h,0a5h,0a6h,002h,097h,097h,0a7h,0a8h,0a9h,0a9h	; 72a8  ................
	defb 0a9h,0aah,097h,097h,002h,002h,0abh,0ach,0adh,0aeh,0afh,0b0h,0b1h,002h,097h,0b2h	; 72b8  ................
	defb 0b3h,0b4h,0a9h,0a9h,0b5h,0b6h,097h,097h,096h,096h,096h,0b7h,0b8h,0b8h,0b8h,0b9h	; 72c8  ................
	defb 0bah,096h,096h,096h,096h,096h,0bbh,0bch,0bbh,0bch,0bbh,0beh,096h,096h,097h,097h	; 72d8  ................
	defb 097h,097h,0bfh,097h,0bfh,097h,097h,097h,097h,002h,002h,0c1h,0c2h,0c3h,0c5h,0c3h	; 72e8  ................
	defb 0c5h,0c6h,0c7h,002h,097h,097h,0c8h,0c9h,0c9h,0c9h,0c9h,0c9h,0cah,097h,097h,096h	; 72f8  ................
	defb 096h,0cbh,0cch,0b8h,0b8h,0b8h,0cdh,0ceh,096h,096h,096h,096h,0cfh,0bbh,0d0h,0bbh	; 7308  ................
	defb 0d0h,0d2h,0d3h,096h,096h,097h,097h,097h,097h,0d4h,097h,0d4h,097h,097h,097h,097h	; 7318  ................
	defb 002h,002h,0d6h,0d7h,0d8h,0c5h,0d8h,0c5h,0dah,0dbh,002h,097h,0dch,0c9h,0c9h,0c9h	; 7328  ................
	defb 0c9h,0c9h,0ddh,0deh,097h,097h,004h,004h,004h,004h,004h,004h,0a0h,0a1h,0a2h,004h	; 7338  ................
	defb 004h,004h,004h,004h,004h,004h,004h,004h,004h,0a3h,004h,0a3h,004h,004h,004h,004h	; 7348  ................
	defb 095h,095h,095h,095h,095h,095h,0a4h,095h,0a5h,095h,095h,095h,095h,096h,096h,096h	; 7358  ................
	defb 096h,096h,096h,0a6h,0a7h,0a8h,0a9h,096h,096h,096h,096h,096h,096h,096h,096h,0a7h	; 7368  ................
	defb 0aah,0a9h,0a8h,096h,0a9h,096h,096h,097h,097h,097h,097h,0abh,0abh,0ach,097h,0adh	; 7378  ................
	defb 097h,097h,0aeh,097h,002h,002h,002h,0afh,002h,002h,0b0h,002h,002h,0b1h,002h,002h	; 7388  ................
	defb 002h,097h,097h,0abh,097h,097h,097h,0ach,097h,097h,097h,0aeh,097h,097h,004h,004h	; 7398  ................
	defb 004h,004h,004h,0b2h,0b3h,0b4h,0b5h,004h,004h,004h,004h,004h,004h,004h,004h,004h	; 73a8  ................
	defb 0b6h,0b5h,0b6h,0b5h,004h,004h,004h,004h,095h,095h,095h,095h,095h,0b7h,0b8h,0b9h	; 73b8  ................
	defb 0bah,095h,095h,095h,095h,096h,096h,096h,096h,096h,0bbh,0bch,0bdh,0beh,0bfh,096h	; 73c8  ................
	defb 096h,096h,096h,096h,096h,096h,0c0h,0c1h,0c2h,0c3h,0c4h,0c5h,0bfh,096h,096h,097h	; 73d8  ................
	defb 097h,097h,0c6h,0c7h,0c8h,0c9h,0cah,0cbh,097h,0cch,0cdh,097h,002h,002h,0ceh,0cfh	; 73e8  ................
	defb 002h,0d0h,0d1h,002h,0d2h,0d3h,002h,002h,002h,097h,0c6h,0d4h,097h,097h,0d5h,0c9h	; 73f8  ................
	defb 097h,097h,0cch,0cdh,097h,097h,004h,01bh,004h,01bh,004h,01bh,004h,01bh,004h,01bh	; 7408  ................
	defb 004h,004h,015h,015h,015h,015h,015h,015h,015h,015h,015h,004h	; 7418  ............

; ======================================================================
; CODIGO 0x7424..0x74bf  (155 bytes)
; ======================================================================


CONTROL_MANDOS:		; Lee los mandos y ajusta el impulso
	call CONTROL_MANDOS_748D		;7424
	ld hl,074bfh		;7427
	exx			;742a
	ld b,006h		;742b
CONTROL_MANDOS_742D:
	exx			;742d   ; al banco alterno
	ld c,(hl)			;742e   ; lee el byte
	inc hl			;742f   ; avanza el puntero
	ld b,(hl)			;7430   ; lee el ancho a B
	inc hl			;7431   ; avanza
	ld a,(0e14fh)		;7432
	add a,(hl)			;7435
	inc hl			;7436
	and 01fh		;7437
	ld e,(hl)			;7439
	inc hl			;743a
	ld d,(hl)			;743b
	inc hl			;743c
CONTROL_MANDOS_743D:
	call DE_MAS_A		;743d   ; indexa la tabla de mandos
	push bc			;7440   ; guarda la cuenta
	push de			;7441   ; y el destino
	call CONTROL_MANDOS_7472		;7442   ; llama al lector de mandos
	pop de			;7445   ; recupera el destino
	pop bc			;7446   ; y la cuenta
	ld a,020h		;7447   ; valor de columna
	dec c			;7449
	jr nz,CONTROL_MANDOS_743D		;744a
	exx			;744c
	djnz CONTROL_MANDOS_742D		;744d
	ld hl,(0e109h)		;744f
	ld a,l			;7452
	ld de,00020h		;7453
	and a			;7456
	sbc hl,de		;7457
	ld de,000b0h		;7459
	and a			;745c
	sbc hl,de		;745d
	ret c			;745f
	ld hl,04976h		;7460
	bit 3,a		;7463
	jr z,CONTROL_MANDOS_746A		;7465
	ld hl,0498eh		;7467
CONTROL_MANDOS_746A:
	ld b,002h		;746a
	ld de,02158h		;746c
	jp DIBUJA_MARCO_484B		;746f
CONTROL_MANDOS_7472:
	call FIJA_ESCRITURA		;7472
	exx			;7475
	ld a,c			;7476
	exx			;7477
	ld c,a			;7478
CONTROL_MANDOS_7479:
	ld a,(hl)			;7479   ; lee el byte de la tabla
	inc hl			;747a   ; avanza
	out (c),a		;747b   ; saca el byte por el puerto
	inc e			;747d   ; avanza la columna
	ld a,e			;747e   ; la pasa a A
	and 01fh		;747f
	jr nz,CONTROL_MANDOS_748A		;7481
	ld a,e			;7483
	sub 020h		;7484
	ld e,a			;7486
	call FIJA_ESCRITURA		;7487
CONTROL_MANDOS_748A:
	djnz CONTROL_MANDOS_7479		;748a
	ret			;748c
CONTROL_MANDOS_748D:
	ld b,001h		;748d   ; arranca B a 1
	ld hl,(0e109h)		;748f
	ld a,l			;7492
	rra			;7493
	rra			;7494
	rra			;7495
	jr nc,CONTROL_MANDOS_7499		;7496
	dec b			;7498
CONTROL_MANDOS_7499:
	and 01fh		;7499   ; aisla los cinco bits
	ld c,a			;749b
	ld a,h			;749c
	add a,a			;749d
	jr c,CONTROL_MANDOS_74AF		;749e
	jr z,CONTROL_MANDOS_74B2		;74a0
	ld a,c			;74a2
CONTROL_MANDOS_74A3:
	sub 016h		;74a3
	and 01fh		;74a5
CONTROL_MANDOS_74A7:
	sub 01fh		;74a7
	neg		;74a9
	ld (0e14fh),a		;74ab
	ret			;74ae
CONTROL_MANDOS_74AF:
	ld a,c			;74af
	jr CONTROL_MANDOS_74A7		;74b0
CONTROL_MANDOS_74B2:
	ld a,c			;74b2   ; recupera la cuenta
	cp 004h		;74b3
	jr c,CONTROL_MANDOS_74A7		;74b5
	cp 01ah		;74b7
	jr nc,CONTROL_MANDOS_74A3		;74b9
	ld a,004h		;74bb
	jr CONTROL_MANDOS_74A7		;74bd

; ----------------------------------------------------------------------
; DATOS tabla_mandos: Tablas de respuesta de los mandos
;   0x74bf..0x753b  (124 bytes)
DATA_tabla_mandos:
	defb 003h,004h,005h,060h,038h,091h,000h,092h,091h,01eh,000h,098h,01eh,093h,000h,094h	; 74bf  ...`8...........
	defb 093h,003h,004h,00eh,060h,038h,091h,000h,092h,091h,01eh,000h,098h,01eh,093h,000h	; 74cf  ....`8..........
	defb 094h,093h,003h,004h,017h,060h,038h,091h,000h,092h,091h,01eh,000h,098h,01eh,093h	; 74df  .....`8.........
	defb 000h,094h,093h,002h,009h,010h,040h,039h,001h,005h,006h,001h,001h,001h,001h,007h	; 74ef  ......@9........
	defb 001h,002h,008h,009h,00ah,00bh,00ch,00dh,00eh,002h,002h,00ah,006h,080h,039h,003h	; 74ff  ..............9.
	defb 01ch,015h,01dh,003h,00fh,010h,011h,003h,003h,003h,01ch,015h,01dh,003h,012h,013h	; 750f  ................
	defb 014h,003h,003h,002h,00ah,01ah,080h,039h,003h,015h,016h,015h,003h,018h,019h,01ah	; 751f  .......9........
	defb 003h,003h,003h,015h,017h,015h,003h,01ah,01ah,01ah,003h,003h	; 752f  ............

; ======================================================================
; CODIGO 0x753b..0x7543  (8 bytes)
; ======================================================================


DESPACHA_ANIM:		; Salta a la animacion segun el estado
	ld a,(0e052h)		;753b
	and 003h		;753e
	call SALTA_POR_TABLA		;7540

; ----------------------------------------------------------------------
; DATOS tabla_anim: Rutina de animacion por estado
;   0x7543..0x754b  (8 bytes)
DATA_tabla_anim:
	defw 0754bh,07632h,075d3h,0768bh	; 7543  -> ANIMA_FIGURA MOTOR_BARRA_7632 MOTOR_BARRA MOTOR_BARRA_768B

; ======================================================================
; CODIGO 0x754b..0x75cf  (132 bytes)
; ======================================================================


ANIMA_FIGURA:		; Avanza y dibuja un fotograma de la figura
	call MOTOR_TRAMPOLIN		;754b   ; avanza la fisica de la figura
	call DIBUJA_RESULTADO		;754e   ; dibuja el resultado
	call ELIGE_EVENTO		;7551   ; elige el evento
	call EVENTO_ACTUAL_649E		;7554   ; lee la bandera de salto
	call MOTOR_TRAMPOLIN_718A		;7557   ; avanza la fisica
	call EVENTO_ACTUAL_64D7		;755a
	ld hl,0e106h		;755d
	ld a,(hl)			;7560
	inc hl			;7561
	sub 08eh		;7562
	ld a,(0e12ah)		;7564
	jr c,ANIMA_FIGURA_7571		;7567
	bit 0,(hl)		;7569
	jr z,ANIMA_FIGURA_7571		;756b
	and a			;756d
	call nz,EVENTO_ACTUAL_6501		;756e
ANIMA_FIGURA_7571:
	and a			;7571
	jr z,ANIMA_FIGURA_7579		;7572
	ld hl,0e128h		;7574
	res 6,(hl)		;7577
ANIMA_FIGURA_7579:
	ld hl,0e103h		;7579
	ld a,(hl)			;757c
	and a			;757d
	jr z,ANIMA_FIGURA_7581		;757e
	dec (hl)			;7580
ANIMA_FIGURA_7581:
	ld hl,0e107h		;7581   ; apunta al estado (0xE107)
	bit 7,(hl)		;7584   ; mira su bit alto
	ret nz			;7586   ; sale si esta puesto
	xor a			;7587   ; pone a cero
	ld (hl),a			;7588   ; borra la casilla
	dec hl			;7589   ; retrocede
	ld (hl),a			;758a   ; y la anterior
	ld (0e131h),a		;758b   ; guarda la casilla (0xE131)
	ld hl,0e15bh		;758e   ; apunta al contador (0xE15B)
	dec (hl)			;7591   ; lo baja
	jr z,ANIMA_FIGURA_75B7		;7592
	ld a,(hl)			;7594
	cp 03eh		;7595
	jr z,ANIMA_FIGURA_75CA		;7597
	cp 03fh		;7599
	ret nz			;759b
	call MOTOR_BARRA_76DD		;759c
	ld a,(0e10bh)		;759f
	ld (0e15ah),a		;75a2
	ld hl,075cfh		;75a5
	ld de,03b00h		;75a8
	ld c,004h		;75ab
	call RELLENA_VRAM_43AC		;75ad
	ld a,(0e0d1h)		;75b0
	inc de			;75b3
	jp SACA_BYTE_VRAM		;75b4
ANIMA_FIGURA_75B7:
	ld hl,0fff6h		;75b7   ; desplazamiento negativo (-10)
	ld (0e106h),hl		;75ba
	xor a			;75bd
	ld de,03b00h		;75be
	ld bc,00004h		;75c1
	call RELLENA_VRAM		;75c4
	jp MOTOR_ATLETA_6251		;75c7
ANIMA_FIGURA_75CA:
	ld a,04fh		;75ca
	jp SUMA_BONUS		;75cc

; ----------------------------------------------------------------------
; DATOS tabla_figura: Cabecera de la figura
;   0x75cf..0x75d3  (4 bytes)
DATA_tabla_figura:
	defb 093h,0c0h	; 75cf
	defb 020h,00fh	; 75d1

; ======================================================================
; CODIGO 0x75d3..0x7821  (590 bytes)
; ======================================================================


MOTOR_BARRA:		; Giros y sueltas de la barra horizontal
	ld hl,0e137h		;75d3   ; apunta al fotograma (0xE137)
	push hl			;75d6   ; lo guarda
	call MOTOR_BARRA_762A		;75d7   ; avanza el motor
	pop hl			;75da
	ld a,(hl)			;75db   ; lee el byte
	and a			;75dc   ; lo comprueba
	jr z,MOTOR_BARRA_760D		;75dd
	ld a,(0e003h)		;75df
	and 03fh		;75e2
	jr nz,MOTOR_BARRA_75F2		;75e4
	ld a,(hl)			;75e6
	sub 001h		;75e7
	daa			;75e9
	ld (hl),a			;75ea
	cp 005h		;75eb
	ld a,00ch		;75ed
	call z,SUMA_BONUS		;75ef
MOTOR_BARRA_75F2:
	call MOTOR_TRAMPOLIN		;75f2   ; avanza la fisica
	call EVENTO_ACTUAL_649E		;75f5   ; lee la bandera de salto
	call DIBUJA_RESULTADO		;75f8   ; dibuja el resultado
	call ELIGE_EVENTO		;75fb   ; elige el evento
	call EVENTO_ACTUAL_64D7		;75fe   ; lee la bandera
	ld hl,(0e106h)		;7601
	inc h			;7604
	ret nz			;7605
	ld a,l			;7606
	cp 0d8h		;7607
	jp nc,EVENTO_ACTUAL_6501		;7609
	ret			;760c
MOTOR_BARRA_760D:
	ld hl,0455bh		;760d   ; apunta a un guion (0x455B)
	call VUELCA_GUION_MASC		;7610   ; lo vuelca con mascara
	xor a			;7613   ; pone a cero
	ld (0e0f1h),a		;7614   ; borra los mandos (0xE0F1)
	call MOTOR_BARRA_75F2		;7617   ; avanza la fisica
	ld a,(0e15ch)		;761a
	and a			;761d
	ret z			;761e
	ld a,0d7h		;761f
	ld (0e106h),a		;7621
	call MOTOR_BARRA_76DD		;7624
	jp MOTOR_ATLETA_6251		;7627
MOTOR_BARRA_762A:
	ld de,03851h		;762a
	ld b,001h		;762d
	jp PREPARA_TABLERO_42ED		;762f
MOTOR_BARRA_7632:
	call MOTOR_TRAMPOLIN		;7632   ; avanza la fisica
	call EVENTO_ACTUAL_649E		;7635   ; lee la bandera de salto
	call EVENTO_ACTUAL_64D7		;7638   ; lee la bandera
	call SALTO_ALTURA		;763b   ; sube la altura
	call DIBUJA_SALPICADURA		;763e   ; dibuja la salpicadura
	call JUEZ_7871		;7641
	call JUEZ_788C		;7644
	ld hl,(0e106h)		;7647
	ld de,0ffe8h		;764a
	and a			;764d
	sbc hl,de		;764e
	ret c			;7650
	ld (0e106h),de		;7651
	jr MOTOR_BARRA_76A5		;7655
MOTOR_BARRA_7657:
	ld a,(0e10bh)		;7657   ; lee la postura (0xE10B)
	cp 00eh		;765a   ; compara con 0x0E
	ret nc			;765c
	inc (hl)			;765d   ; sube la casilla
	ld a,(0e003h)		;765e   ; lee la fase (0xE003)
	and 003h		;7661   ; la enmascara
	ret nz			;7663
	ld hl,(0e109h)		;7664
	ld de,00002h		;7667
	ld a,(0e16fh)		;766a
	and a			;766d
	jr z,MOTOR_BARRA_7673		;766e
	ld de,0fffch		;7670
MOTOR_BARRA_7673:
	add hl,de			;7673   ; suma el desplazamiento
	ld (0e109h),hl		;7674   ; guarda la coordenada (0xE109)
	call MOTOR_TRAMPOLIN_7172		;7677   ; avanza la figura
	ld hl,0e16eh		;767a   ; apunta al contador (0xE16E)
	inc (hl)			;767d   ; lo sube
	cp 006h		;767e
	ret nz			;7680
	ld a,(hl)			;7681
	cp 008h		;7682
	ret c			;7684
	ld a,001h		;7685
	ld (0e15bh),a		;7687
	ret			;768a
MOTOR_BARRA_768B:
	call MOTOR_TRAMPOLIN		;768b   ; avanza la fisica
	call EVENTO_ACTUAL_649E		;768e   ; lee la bandera
	call EVENTO_ACTUAL_64D7		;7691   ; relee la bandera
	call MOTOR_BARRA_7719		;7694   ; avanza el bloque
	ld hl,(0e106h)		;7697
	ld de,0ffe8h		;769a
	and a			;769d
	sbc hl,de		;769e
	ret c			;76a0
	ld (0e106h),de		;76a1
MOTOR_BARRA_76A5:
	ld hl,0e15bh		;76a5   ; apunta al contador (0xE15B)
	dec (hl)			;76a8   ; lo baja
	jr z,MOTOR_BARRA_76FF		;76a9   ; si es cero, salta
	ld a,(hl)			;76ab   ; lee el byte
	sub 03eh		;76ac   ; resta 0x3E
	jr z,MOTOR_BARRA_76E2		;76ae   ; salta si coincide
	dec a			;76b0
	jr nz,MOTOR_BARRA_7657		;76b1
	ld hl,(0e109h)		;76b3
	ld (0e16ch),hl		;76b6
	ld de,00300h		;76b9
	add hl,de			;76bc
	ld de,00376h		;76bd
	xor a			;76c0
	sbc hl,de		;76c1
	ld h,a			;76c3
	ld l,a			;76c4
	jr nc,MOTOR_BARRA_76CB		;76c5
	inc a			;76c7
	ld (0e15eh),a		;76c8
MOTOR_BARRA_76CB:
	ld (0e13bh),hl		;76cb   ; guarda el puntero (0xE13B)
	ld a,(0e104h)		;76ce
	rlca			;76d1
	and 001h		;76d2
	ld (0e16fh),a		;76d4
	ld (0e101h),hl		;76d7
	ld (0e103h),hl		;76da
MOTOR_BARRA_76DD:
	ld a,09ch		;76dd
	jp SUMA_BONUS		;76df
MOTOR_BARRA_76E2:
	xor a			;76e2   ; pone a cero
	ld (0e128h),a		;76e3   ; guarda la bandera (0xE128)
	ld hl,0e10bh		;76e6   ; apunta a la postura (0xE10B)
	ld a,(hl)			;76e9   ; la lee
	ld (0e15ah),a		;76ea
	sub 009h		;76ed
	cp 004h		;76ef
	jr nc,MOTOR_BARRA_76F8		;76f1
	ld a,04ah		;76f3
	jp SUMA_BONUS		;76f5
MOTOR_BARRA_76F8:
	ld (hl),01eh		;76f8
	ld a,04dh		;76fa
	jp SUMA_BONUS		;76fc
MOTOR_BARRA_76FF:
	ld a,(0e15eh)		;76ff   ; lee la bandera (0xE15E)
	and a			;7702   ; la comprueba
	jp nz,JUEZ		;7703   ; salta al juez si toca
	inc (hl)			;7706   ; sube la postura
	ld hl,(0e109h)		;7707   ; lee la coordenada (0xE109)
	ld de,0fe60h		;770a
	add hl,de			;770d
	jp c,MOTOR_ATLETA_6251		;770e
	ld a,00ch		;7711
	ld (0e128h),a		;7713
	jp DIBUJA_SALPICADURA_711B		;7716
MOTOR_BARRA_7719:
	ld hl,0e150h		;7719   ; apunta al bloque (0xE150)
	ld a,(hl)			;771c
	and a			;771d
	ret z			;771e
	cp 004h		;771f
	jr nc,MOTOR_BARRA_7725		;7721
	ld (hl),004h		;7723
MOTOR_BARRA_7725:
	ld a,(0e0f1h)		;7725   ; lee la bandera (0xE0F1)
	and 010h		;7728
	jr nz,MOTOR_BARRA_775E		;772a
	ld a,(0e003h)		;772c
	and 03fh		;772f
	jr nz,MOTOR_BARRA_7734		;7731
	dec (hl)			;7733
MOTOR_BARRA_7734:
	ld a,(hl)			;7734   ; lee el byte
	inc hl			;7735   ; avanza
	dec (hl)			;7736   ; baja la casilla
	ret nz			;7737
	ld (hl),a			;7738   ; la guarda
	inc hl			;7739   ; avanza
	inc (hl)			;773a
	ld a,(hl)			;773b
	cp 009h		;773c
	jr nc,MOTOR_BARRA_774B		;773e
	ld hl,07850h		;7740
	call HL_MAS_A		;7743
	ld a,(hl)			;7746
	ld (0e10bh),a		;7747
	ret			;774a
MOTOR_BARRA_774B:
	cp 080h		;774b   ; compara con 0x80
	jr z,MOTOR_BARRA_775E		;774d   ; si es cero, salta
	ld hl,0e10bh		;774f   ; apunta a la postura (0xE10B)
	inc (hl)			;7752   ; la sube
	ld a,(hl)			;7753
	cp 029h		;7754
	ret c			;7756
	ld (hl),021h		;7757
	ld a,048h		;7759
	jp SUMA_BONUS		;775b
MOTOR_BARRA_775E:
	ld a,(0e152h)		;775e   ; lee la casilla (0xE152)
	cp 009h		;7761
	jr nc,MOTOR_BARRA_776B		;7763
	xor a			;7765
	ld (0e0f1h),a		;7766
	jr MOTOR_BARRA_7719		;7769
MOTOR_BARRA_776B:
	ld hl,0e150h		;776b   ; apunta al bloque (0xE150)
	ld a,(hl)			;776e   ; lo lee
	ld c,a			;776f   ; pasa A a C
	inc hl			;7770   ; avanza
	sub (hl)			;7771   ; resta la casilla
	ld b,a			;7772
	ld a,c			;7773
	rra			;7774
	rra			;7775
	and 007h		;7776
	inc a			;7778
	ld c,a			;7779
	ld a,b			;777a
	ld b,0ffh		;777b
MOTOR_BARRA_777D:
	sub c			;777d   ; resta C
	inc b			;777e   ; sube el contador
	jr nc,MOTOR_BARRA_777D		;777f   ; repite mientras no haya acarreo
	ld a,(0e10bh)		;7781   ; lee la postura (0xE10B)
	sub 021h		;7784   ; resta 0x21
	push af			;7786   ; la protege
	and 001h		;7787   ; aisla el bit bajo
	add a,a			;7789
	add a,a			;778a
	add a,b			;778b
	add a,a			;778c
	ld hl,07821h		;778d
	call HL_MAS_A		;7790
	ld e,(hl)			;7793
	inc hl			;7794
	ld d,(hl)			;7795
	pop af			;7796
	rra			;7797
	rra			;7798
	jr nc,MOTOR_BARRA_779E		;7799
	ld a,e			;779b
	ld e,d			;779c
	ld d,a			;779d
MOTOR_BARRA_779E:
	ld a,(0e150h)		;779e   ; lee la posicion (0xE150)
	sub 010h		;77a1   ; resta 0x10
	neg		;77a3   ; la niega
	and 00fh		;77a5   ; aisla el nibble
	ld h,a			;77a7   ; lo pasa a H
	push de			;77a8   ; guarda el destino
	push hl			;77a9   ; y el valor
	call MOTOR_BARRA_7815		;77aa   ; dibuja el tramo
	ld (0e153h),hl		;77ad   ; guarda el puntero (0xE153)
	pop hl			;77b0   ; recupera el destino
	pop de			;77b1   ; y el valor
	ld e,d			;77b2   ; pasa D a E
	call MOTOR_BARRA_7815		;77b3   ; dibuja el tramo
	ld (0e155h),hl		;77b6   ; guarda el puntero (0xE155)
	ld a,(0e10bh)		;77b9   ; lee la postura (0xE10B)
	sub 021h		;77bc
	and 006h		;77be
	ld hl,07831h		;77c0
	call HL_MAS_A		;77c3
	ld e,(hl)			;77c6
	inc hl			;77c7
	ld d,(hl)			;77c8
	ld hl,0e153h		;77c9
	ld bc,0e101h		;77cc
	ld a,(hl)			;77cf
	xor e			;77d0
	ld (bc),a			;77d1
	inc hl			;77d2
	inc bc			;77d3
	ld a,(hl)			;77d4
	xor e			;77d5
	ld (bc),a			;77d6
	inc hl			;77d7
	inc bc			;77d8
	ld a,(hl)			;77d9
	xor d			;77da
	ld (bc),a			;77db
	inc hl			;77dc
	inc bc			;77dd
	ld a,(hl)			;77de
	xor d			;77df
	ld (bc),a			;77e0
	xor a			;77e1
	ld (0e150h),a		;77e2
	dec a			;77e5
	ld (0e128h),a		;77e6
	ld hl,0e10bh		;77e9
	ld a,(hl)			;77ec
	sub 021h		;77ed
	ld b,a			;77ef
	add a,a			;77f0
	add a,b			;77f1
	ld de,07839h		;77f2
	ex de,hl			;77f5
	call HL_MAS_A		;77f6
	ld a,(hl)			;77f9
	inc hl			;77fa
	ld c,(hl)			;77fb
	inc hl			;77fc
	ld b,(hl)			;77fd
	ld (de),a			;77fe
	sub 006h		;77ff
	and 007h		;7801
	ld (0e12dh),a		;7803
	ld hl,0e106h		;7806
	ld a,(hl)			;7809
	add a,c			;780a
	ld (hl),a			;780b
	inc hl			;780c
	inc hl			;780d
	inc hl			;780e
	ld a,(hl)			;780f
	add a,b			;7810
	ld (hl),a			;7811
	jp SALTO_ALTURA_70E7		;7812
MOTOR_BARRA_7815:
	ld d,000h		;7815
	ld l,d			;7817
	ld b,008h		;7818
MOTOR_BARRA_781A:
	add hl,hl			;781a
	jr nc,MOTOR_BARRA_781E		;781b
	add hl,de			;781d
MOTOR_BARRA_781E:
	djnz MOTOR_BARRA_781A		;781e
	ret			;7820

; ----------------------------------------------------------------------
; DATOS graficos_barra: Graficos de la barra horizontal
;   0x7821..0x7859  (56 bytes)
DATA_graficos_barra:
	defb 000h,030h,009h,02fh,012h,02ch,01ah,027h,021h,021h,027h,01ah,02ch,012h,02fh,009h	; 7821  .0./.,.'!!'.,./.
	defb 0ffh,000h,0ffh,0ffh,000h,0ffh,000h,000h,006h,0feh,0f8h,00dh,0f0h,008h,00ch,0e0h	; 7831  ................
	defb 00eh,00bh,0e0h,005h,00ah,0d8h,0f8h,009h,0e0h,0e8h,008h,0f0h,0f0h,007h,0fch,0f8h	; 7841  ................
	defb 021h,01fh,020h,023h,022h,021h,028h,027h	; 7851  !. #"!('

; ======================================================================
; CODIGO 0x7859..0x7908  (175 bytes)
; ======================================================================


JUEZ:		; Puntua el intento y decide si clasifica
	ld a,09ch		;7859   ; arranca el sonido del juez
	call SUMA_BONUS		;785b
	ld a,001h		;785e
	ld (0e15eh),a		;7860
	ld hl,07ab0h		;7863
	ld de,0792eh		;7866
	ld c,0ffh		;7869
	call GUION_BYTE		;786b
	jp MOTOR_ATLETA_6251		;786e
JUEZ_7871:
	ld a,(0e142h)		;7871   ; lee la nota (0xE142)
	and a			;7874   ; la comprueba
	ret z			;7875
	ld a,(0e109h)		;7876   ; lee la coordenada (0xE109)
	add a,020h		;7879   ; suma 0x20
	rlca			;787b   ; la rota
	rlca			;787c
	rlca			;787d
	and 007h		;787e
	add a,007h		;7880
	cp 00bh		;7882
	jr c,JUEZ_7888		;7884
	add a,004h		;7886
JUEZ_7888:
	ld (0e10bh),a		;7888
	ret			;788b
JUEZ_788C:
	ld hl,0e144h		;788c   ; apunta a la nota (0xE144)
	ld a,(hl)			;788f   ; la lee
	and a			;7890   ; la comprueba
	jr z,JUEZ_78D1		;7891   ; si es cero, otra fase
	jp m,JUEZ_7900		;7893   ; si es negativo, fin
	cp 020h		;7896   ; compara con 0x20
	jr z,JUEZ_78C9		;7898   ; salta si coincide
	inc (hl)			;789a   ; sube el contador
	ex af,af'			;789b   ; protege A
	ld a,(0e0f1h)		;789c   ; lee los mandos (0xE0F1)
	and 010h		;789f
	ret z			;78a1
	ex af,af'			;78a2
	rra			;78a3
	and 00eh		;78a4
	ld hl,07908h		;78a6
	call HL_MAS_A		;78a9
	ld e,(hl)			;78ac
	inc hl			;78ad
	ld d,(hl)			;78ae
	ld (0e101h),de		;78af
	ld a,068h		;78b3
	ld (0e128h),a		;78b5
	ld a,0fch		;78b8
	ld (0e144h),a		;78ba
	ld hl,0e12ah		;78bd
	dec (hl)			;78c0
	ld a,00ah		;78c1
	ld (0e10bh),a		;78c3
	jp SALTO_ALTURA_70E7		;78c6
JUEZ_78C9:
	ld a,0c9h		;78c9
	ld (0e106h),a		;78cb
	jp JUEZ		;78ce
JUEZ_78D1:
	ld a,(0e12ah)		;78d1   ; lee la bandera (0xE12A)
	and a			;78d4   ; la comprueba
	ret z			;78d5   ; sale si es cero
	ld a,(0e102h)		;78d6   ; lee el estado (0xE102)
	add a,a			;78d9   ; lo dobla
	ret c			;78da   ; sale si desborda
	ld hl,(0e106h)		;78db   ; lee la marca (0xE106)
	inc h			;78de
	ret nz			;78df
	ld a,l			;78e0
	sub 0c6h		;78e1
	cp 008h		;78e3
	ret nc			;78e5
	ld a,011h		;78e6
	ld (0e10bh),a		;78e8
	xor a			;78eb
	ld (0e128h),a		;78ec
	ld (0e142h),a		;78ef
	inc a			;78f2
	ld (0e144h),a		;78f3
	ld a,004h		;78f6
	ld (0e12dh),a		;78f8
	ld a,049h		;78fb
	jp SUMA_BONUS		;78fd
JUEZ_7900:
	inc (hl)			;7900
	ret nz			;7901
	ld a,00ah		;7902
	ld (0e10bh),a		;7904
	ret			;7907

; ----------------------------------------------------------------------
; DATOS tabla_juez: Umbrales de puntuacion
;   0x7908..0x7918  (16 bytes)
DATA_tabla_juez:
	defb 028h,0feh	; 7908
	defb 030h,0feh	; 790a
	defb 040h,0feh	; 790c
	defb 050h,0feh	; 790e
	defb 060h,0feh	; 7910
	defb 070h,0feh	; 7912
	defb 080h,0feh	; 7914
	defb 0b0h,0feh	; 7916

; ======================================================================
; CODIGO 0x7918..0x792a  (18 bytes)
; ======================================================================


DESPACHA_JUEZ:		; Salta a la fase de puntuacion
	ld hl,07a57h		;7918   ; fija el destino del salto (0x7A57)
	ld a,(0e15eh)		;791b
	and a			;791e
	jr nz,$+19		;791f
	ld a,(0e052h)		;7921
	and 003h		;7924
	push hl			;7926
	call SALTA_POR_TABLA		;7927

; ----------------------------------------------------------------------
; DATOS tabla_despacho_juez: Rutina de puntuacion por fase
;   0x792a..0x7932  (8 bytes)
DATA_tabla_despacho_juez:
	defw 0793ah,079edh,079a3h,079edh	; 792a  -> JUEZ_NOTA DIBUJA_NOTA_79ED DIBUJA_NOTA DIBUJA_NOTA_79ED

; ======================================================================
; CODIGO 0x7932..0x7996  (100 bytes)
; ======================================================================


JUEZ_SALTO:
	ld de,0ffffh		;7932
	ld (0e147h),de		;7935
	jp (hl)			;7939
JUEZ_NOTA:		; Elige la nota segun la marca
	ld a,(0e052h)		;793a   ; el evento elige la nota
	rra			;793d   ; la desplaza
	rra			;793e   ; dos veces
	and 00fh		;793f   ; aisla el nibble
	ld hl,07ab6h		;7941   ; apunta a la tabla de notas (0x7AB6)
	call HL_MAS_A		;7944   ; la indexa
	ld e,(hl)			;7947   ; lee la entrada
	ld d,007h		;7948
	call JUEZ_NOTA_7977		;794a
	ex de,hl			;794d
	ld a,(0e15ah)		;794e
	sub 005h		;7951
	ld hl,07996h		;7953
	call HL_MAS_A		;7956
	ld l,(hl)			;7959
	ld h,000h		;795a
	add hl,hl			;795c
	add hl,hl			;795d
	add hl,hl			;795e
	add hl,hl			;795f
	call JUEZ_NOTA_796E		;7960
	cp 010h		;7963
	jr c,JUEZ_NOTA_796A		;7965
	ld hl,01000h		;7967
JUEZ_NOTA_796A:
	ld (0e147h),hl		;796a
	ret			;796d
JUEZ_NOTA_796E:
	ld a,l			;796e   ; el byte bajo
	add a,e			;796f
	daa			;7970
	ld l,a			;7971
	ld a,h			;7972
	adc a,d			;7973
	daa			;7974
	ld h,a			;7975
	ret			;7976
JUEZ_NOTA_7977:
	ld bc,(0e145h)		;7977
JUEZ_NOTA_797B:
	ld hl,00000h		;797b
	inc bc			;797e
JUEZ_NOTA_797F:
	ld a,l			;797f   ; el byte bajo
	add a,e			;7980   ; suma el desplazamiento
	daa			;7981   ; ajuste decimal
	ld l,a			;7982   ; lo pasa a L
	ld a,h			;7983   ; la parte alta
	adc a,000h		;7984
	daa			;7986
	jr c,JUEZ_NOTA_798F		;7987
	ld h,a			;7989
	dec bc			;798a
	ld a,b			;798b
	or c			;798c
	jr nz,JUEZ_NOTA_797F		;798d
JUEZ_NOTA_798F:
	ld a,h			;798f   ; la parte alta
	cp d			;7990
	ret c			;7991
	ld h,d			;7992
	ld l,000h		;7993
	ret			;7995

; ----------------------------------------------------------------------
; DATOS tabla_notas: Notas posibles del juez
;   0x7996..0x79a3  (13 bytes)
DATA_tabla_notas:
	defb 000h,001h,004h,006h,008h,010h,008h,006h,004h,024h,026h,028h,030h	; 7996  .........$&(0

; ======================================================================
; CODIGO 0x79a3..0x7a47  (164 bytes)
; ======================================================================


DIBUJA_NOTA:		; Pinta la nota conseguida
	ld e,003h		;79a3   ; tres digitos de la nota
	ld d,007h		;79a5
	call JUEZ_NOTA_7977		;79a7
	ld a,(0e159h)		;79aa
	ld b,a			;79ad
	ld de,09960h		;79ae
	and a			;79b1
	jr z,DIBUJA_NOTA_79C0		;79b2
DIBUJA_NOTA_79B4:
	call JUEZ_NOTA_796E		;79b4
	djnz DIBUJA_NOTA_79B4		;79b7
	cp 011h		;79b9
	jr c,DIBUJA_NOTA_79C0		;79bb
	ld hl,00000h		;79bd
DIBUJA_NOTA_79C0:
	push hl			;79c0   ; guarda el puntero
	ld a,(0e12ah)		;79c1
	add a,00ah		;79c4
	ld hl,00300h		;79c6
	jr c,DIBUJA_NOTA_79DE		;79c9
	neg		;79cb
	ld b,a			;79cd
	inc b			;79ce
	ld de,09980h		;79cf
DIBUJA_NOTA_79D2:
	call JUEZ_NOTA_796E		;79d2
	djnz DIBUJA_NOTA_79D2		;79d5
	cp 003h		;79d7
	jr c,DIBUJA_NOTA_79DE		;79d9
	ld hl,00000h		;79db
DIBUJA_NOTA_79DE:
	pop de			;79de
	call JUEZ_NOTA_796E		;79df
	cp 010h		;79e2
	jr c,DIBUJA_NOTA_79E9		;79e4
	ld hl,01000h		;79e6
DIBUJA_NOTA_79E9:
	ld (0e147h),hl		;79e9
	ret			;79ec
DIBUJA_NOTA_79ED:
	ld a,(0e052h)		;79ed
	and 002h		;79f0
	ld e,015h		;79f2
	jr z,DIBUJA_NOTA_79F8		;79f4
	ld e,011h		;79f6
DIBUJA_NOTA_79F8:
	ld d,004h		;79f8
	ld hl,(0e16ch)		;79fa
	ld bc,0fef0h		;79fd
	jr z,DIBUJA_NOTA_7A05		;7a00
	ld bc,0ff90h		;7a02
DIBUJA_NOTA_7A05:
	add hl,bc			;7a05   ; suma el desplazamiento
	ld a,l			;7a06   ; el byte bajo
	srl h		;7a07   ; desplaza H
	rra			;7a09   ; y arrastra el bit
	srl h		;7a0a   ; desplaza H
	rra			;7a0c   ; arrastra el bit
	srl h		;7a0d   ; y otra vez
	rra			;7a0f   ; el segundo digito
	ld b,h			;7a10   ; pasa la parte alta a B
	ld c,a			;7a11   ; y el byte bajo a C
	call JUEZ_NOTA_797B		;7a12   ; escribe los digitos
	push hl			;7a15
	ld e,006h		;7a16
	ld d,003h		;7a18
	call JUEZ_NOTA_7977		;7a1a
	ex de,hl			;7a1d
	ld a,(0e15ah)		;7a1e
	sub 006h		;7a21
	add a,a			;7a23
	ld hl,07a47h		;7a24
	call HL_MAS_A		;7a27
	ld a,(hl)			;7a2a
	inc hl			;7a2b
	ld h,(hl)			;7a2c
	ld l,a			;7a2d
	call JUEZ_NOTA_796E		;7a2e
	pop de			;7a31
	call JUEZ_NOTA_796E		;7a32
	cp 010h		;7a35
	jr c,DIBUJA_NOTA_7A3C		;7a37
	ld hl,01000h		;7a39
DIBUJA_NOTA_7A3C:
	dec a			;7a3c
	jp p,DIBUJA_NOTA_7A43		;7a3d
	ld hl,00100h		;7a40
DIBUJA_NOTA_7A43:
	ld (0e147h),hl		;7a43
	ret			;7a46

; ----------------------------------------------------------------------
; DATOS tabla_bandera: Posiciones de las banderas del juez
;   0x7a47..0x7a57  (16 bytes)
DATA_tabla_bandera:
	defb 080h,002h,000h,003h,080h,002h,000h,098h,000h,097h,000h,098h,000h,000h,060h,002h	; 7a47  ..............`.

; ======================================================================
; CODIGO 0x7a57..0x7ab0  (89 bytes)
; ======================================================================


MUEVE_BANDERA:		; Anima las banderas de puntuacion
	ld hl,(0e147h)		;7a57   ; lee el contador (0xE147)
	ld a,h			;7a5a   ; la parte alta
	inc a			;7a5b   ; sube el contador
	jr z,MUEVE_BANDERA_7A6F		;7a5c   ; si desborda, salta
	ld de,00010h		;7a5e   ; paso de 0x10
	call JUEZ_NOTA_796E		;7a61
	ld a,l			;7a64
	and 0e0h		;7a65
	ld l,a			;7a67
	ld a,h			;7a68
	and a			;7a69
	jr nz,MUEVE_BANDERA_7A6F		;7a6a
	ld hl,00100h		;7a6c
MUEVE_BANDERA_7A6F:
	ld (0e147h),hl		;7a6f   ; guarda el contador
	ld a,(0e054h)		;7a72   ; lee los intentos (0xE054)
	dec a			;7a75   ; baja el contador
	add a,a			;7a76   ; lo dobla
	ex de,hl			;7a77   ; lo pasa a HL
	ld hl,0e055h		;7a78
	call HL_MAS_A		;7a7b
	ld (hl),e			;7a7e
	inc hl			;7a7f
	ld (hl),d			;7a80
	ret			;7a81
MUEVE_BANDERA_7A82:
	ld de,03826h		;7a82
	ld hl,0e05ah		;7a85
	ld b,003h		;7a88
MUEVE_BANDERA_7A8A:
	push bc			;7a8a   ; guarda la cuenta
	ld a,(hl)			;7a8b   ; lee el byte
	dec hl			;7a8c   ; retrocede el puntero
	or (hl)			;7a8d   ; combina
	jr z,MUEVE_BANDERA_7AAD		;7a8e   ; si es cero, salta
	inc a			;7a90
	jr z,MUEVE_BANDERA_7A9F		;7a91
	inc hl			;7a93
	call MIDE_MARCA_6E95		;7a94
	ld a,005h		;7a97
	add a,e			;7a99
	ld e,a			;7a9a
MUEVE_BANDERA_7A9B:
	pop bc			;7a9b
	djnz MUEVE_BANDERA_7A8A		;7a9c
	ret			;7a9e
MUEVE_BANDERA_7A9F:
	push hl			;7a9f   ; guarda el puntero
	ld c,005h		;7aa0
	ld hl,07ab0h		;7aa2
	call RELLENA_VRAM_43AC		;7aa5
	pop hl			;7aa8
	ld a,00ah		;7aa9
	add a,e			;7aab
	ld e,a			;7aac
MUEVE_BANDERA_7AAD:
	dec hl			;7aad
	jr MUEVE_BANDERA_7A9B		;7aae

; ----------------------------------------------------------------------
; DATOS tabla_bandera_2: Cabecera de las banderas
;   0x7ab0..0x7abe  (14 bytes)
DATA_tabla_bandera_2:
	defb 000h,046h	; 7ab0
	defb 04fh,055h	; 7ab2
	defb 04ch,0ffh	; 7ab4
	defb 019h,011h	; 7ab6
	defb 009h,008h	; 7ab8
	defb 007h,006h	; 7aba
	defb 005h,005h	; 7abc

; ======================================================================
; CODIGO 0x7abe..0x7b57  (153 bytes)
; ======================================================================


BONIFICACION:		; Calcula y muestra el bonus de la prueba
	ld a,(0e15eh)		;7abe   ; lee la bandera (0xE15E)
	and a			;7ac1   ; la comprueba
	push af			;7ac2   ; la protege
	call nz,MUEVE_BANDERA_7A82		;7ac3   ; mueve la bandera si toca
	pop af			;7ac6   ; recupera A
	jp nz,MOTOR_ATLETA_6251		;7ac7   ; salta a la fisica si no
	ld hl,0e164h		;7aca   ; apunta al bloque (0xE164)
	ld e,(hl)			;7acd
	inc hl			;7ace
	ld d,(hl)			;7acf
	inc hl			;7ad0
	ld a,(hl)			;7ad1
	and a			;7ad2
	jr nz,BONIFICACION_7B17		;7ad3
	inc (hl)			;7ad5
	inc hl			;7ad6
	ld bc,(0e147h)		;7ad7
	ld a,b			;7adb
	cp 010h		;7adc
	jr nz,BONIFICACION_7AE2		;7ade
	ld b,00ah		;7ae0
BONIFICACION_7AE2:
	ld a,c			;7ae2   ; lee C
	rlca			;7ae3   ; lo rota
	rlca			;7ae4   ; rota el valor
	rlca			;7ae5   ; dos veces
	ld c,a			;7ae6   ; lo pasa a C
	add a,a			;7ae7
	add a,a			;7ae8
	add a,c			;7ae9
	ld de,07b57h		;7aea
	call DE_MAS_A		;7aed
	ld c,005h		;7af0
	push hl			;7af2
BONIFICACION_7AF3:
	ld a,(de)			;7af3   ; lee el byte de la tabla
	inc de			;7af4   ; avanza
	add a,b			;7af5   ; suma B
	add a,020h		;7af6   ; suma 0x20
	ld (hl),a			;7af8   ; lo guarda
	inc hl			;7af9
	dec c			;7afa
	jr nz,BONIFICACION_7AF3		;7afb
	pop hl			;7afd
	ld a,r		;7afe
	and 007h		;7b00
BONIFICACION_7B02:
	ex af,af'			;7b02   ; protege A
	push hl			;7b03   ; guarda el puntero
	ld e,l			;7b04   ; pasa el puntero a DE
	ld d,h			;7b05   ; y la parte alta
	inc hl			;7b06   ; avanza
	ld bc,00004h		;7b07
	ld a,(de)			;7b0a
	ldir		;7b0b
	ld (de),a			;7b0d
	pop hl			;7b0e
	ex af,af'			;7b0f
	dec a			;7b10
	jr nz,BONIFICACION_7B02		;7b11
	ld (0e10bh),a		;7b13
	ret			;7b16
BONIFICACION_7B17:
	ld a,(0e003h)		;7b17   ; la fase de la interrupcion
	and 01fh		;7b1a   ; la enmascara
	ret nz			;7b1c   ; sale si esta puesta
	ld a,(hl)			;7b1d   ; lee el contador
	inc (hl)			;7b1e   ; lo sube
	cp 006h		;7b1f   ; compara con 6
	jp nc,BONIFICACION_7B3A		;7b21
	dec a			;7b24
	ld c,a			;7b25
	add a,a			;7b26
	add a,0e1h		;7b27
	add a,e			;7b29
	ld e,a			;7b2a
	ld hl,0e167h		;7b2b
	ld b,000h		;7b2e
	add hl,bc			;7b30
	ld a,(hl)			;7b31
	call SACA_BYTE_VRAM		;7b32
	ld a,006h		;7b35
	jp SUMA_BONUS		;7b37
BONIFICACION_7B3A:
	ld a,007h		;7b3a   ; valor por defecto
	jp nz,MOTOR_ATLETA_6251		;7b3c   ; salta a la fisica
	call SUMA_BONUS		;7b3f   ; suma el bonus
	call MUEVE_BANDERA_7A82		;7b42   ; mueve la bandera
	ld a,(0e148h)		;7b45   ; lee el campo (0xE148)
	cp 010h		;7b48
	ret nz			;7b4a
	ld hl,07b70h		;7b4b
	call VUELCA_GUION_MASC		;7b4e
	ld de,00020h		;7b51
	jp LIMPIA_PANTALLA_4258		;7b54

; ----------------------------------------------------------------------
; DATOS rotulos_bonus: Rotulos PERFECT y BONUS
;   0x7b57..0x7b89  (50 bytes)
DATA_rotulos_bonus:
	defb 000h,000h,000h,000h,000h,000h,001h,000h,001h,0ffh,001h,000h,001h,001h,0ffh,001h	; 7b57  ................
	defb 000h,001h,000h,001h,001h,001h,001h,001h,000h,025h,079h,050h,045h,052h,046h,045h	; 7b67  .........%yPERFE
	defb 043h,054h,000h,042h,04fh,04eh,055h,053h,000h,032h,030h,030h,030h,000h,050h,054h	; 7b77  CT.BONUS.2000.PT
	defb 053h,0ffh	; 7b87

; ======================================================================
; CODIGO 0x7b89..0x7ca6  (285 bytes)
; ======================================================================


SUMA_BONUS:		; Suma el bonus a la puntuacion en BCD
	ld hl,0e002h		;7b89
	bit 6,(hl)		;7b8c
	ret z			;7b8e
SUMA_BONUS_7B8F:
	di			;7b8f   ; protege la interrupcion
	cp 002h		;7b90
	jr nz,SUMA_BONUS_7B9E		;7b92
	call SUMA_BONUS_7BA3		;7b94
	ld a,043h		;7b97
	call SUMA_BONUS_7BA3		;7b99
	ld a,044h		;7b9c
SUMA_BONUS_7B9E:
	call SUMA_BONUS_7BA3		;7b9e
	ei			;7ba1
	ret			;7ba2
SUMA_BONUS_7BA3:
	ld c,a			;7ba3   ; pasa el numero a C
	ld b,002h		;7ba4   ; dos digitos
	ld hl,0e012h		;7ba6   ; apunta a la prioridad (0xE012)
	cp 001h		;7ba9   ; compara con 1
	jr z,SUMA_BONUS_7BCA		;7bab   ; si coincide, salta
	cp 04dh		;7bad
	jr c,SUMA_BONUS_7BB8		;7baf
	cp 093h		;7bb1
	jr c,SUMA_BONUS_7BCA		;7bb3
	inc b			;7bb5
	jr SUMA_BONUS_7BD1		;7bb6
SUMA_BONUS_7BB8:
	dec b			;7bb8   ; baja el contador
	and 03fh		;7bb9
	cp 005h		;7bbb
	jr nc,SUMA_BONUS_7BD1		;7bbd
	cp 002h		;7bbf
	jr z,SUMA_BONUS_7BD1		;7bc1
	ld hl,0e028h		;7bc3
	cp 003h		;7bc6
	jr nz,SUMA_BONUS_7BD1		;7bc8
SUMA_BONUS_7BCA:
	ld hl,0e01dh		;7bca
	cp 001h		;7bcd
	jr z,SUMA_BONUS_7BDA		;7bcf
SUMA_BONUS_7BD1:
	ld a,(hl)			;7bd1   ; lee el digito
	and 03fh		;7bd2
	ld e,a			;7bd4
	ld a,c			;7bd5
	and 03fh		;7bd6
	cp e			;7bd8
	ret c			;7bd9
SUMA_BONUS_7BDA:
	add a,a			;7bda
	ld de,07de3h		;7bdb
	call DE_MAS_A		;7bde
	dec hl			;7be1
	dec hl			;7be2
SUMA_BONUS_7BE3:
	ld (hl),001h		;7be3   ; pone a uno
	inc hl			;7be5   ; avanza
	ld (hl),001h		;7be6   ; pone a uno
	inc hl			;7be8   ; avanza
	ld (hl),c			;7be9   ; escribe el digito
	inc hl			;7bea   ; avanza
	ld a,(de)			;7beb
	ld (hl),a			;7bec
	inc hl			;7bed
	inc de			;7bee
	ld a,(de)			;7bef
	ld (hl),a			;7bf0
	ld a,006h		;7bf1
	add a,l			;7bf3
	ld l,a			;7bf4
	ld (hl),000h		;7bf5
	inc hl			;7bf7
	inc de			;7bf8
	djnz SUMA_BONUS_7BE3		;7bf9
	ret			;7bfb
SUMA_BONUS_7BFC:
	inc hl			;7bfc   ; avanza
	ld a,(ix+009h)		;7bfd
	inc a			;7c00
	cp (hl)			;7c01
	jp z,ACTUALIZA_CANAL_7D30		;7c02
	jp m,SUMA_BONUS_7C09		;7c05
	dec a			;7c08
SUMA_BONUS_7C09:
	ex af,af'			;7c09   ; protege A
	ld a,(ix+002h)		;7c0a
	push bc			;7c0d
	call SUMA_BONUS_7BA3		;7c0e
	pop bc			;7c11
	ex af,af'			;7c12
	ld (ix+009h),a		;7c13
	ret			;7c16
SUMA_BONUS_7C17:
	ld a,(0e043h)		;7c17   ; lee la bandera del sonido (0xE043)
	ld e,a			;7c1a
	ld a,c			;7c1b
	cp 001h		;7c1c
	jr z,SUMA_BONUS_7C21		;7c1e
	dec a			;7c20
SUMA_BONUS_7C21:
	rlca			;7c21   ; la rota
	rlca			;7c22
	rlca			;7c23
	dec d			;7c24
	jr z,SUMA_BONUS_7C2B		;7c25
	cpl			;7c27
	and e			;7c28
	jr SUMA_BONUS_7C2C		;7c29
SUMA_BONUS_7C2B:
	or e			;7c2b
SUMA_BONUS_7C2C:
	set 2,a		;7c2c
	bit 5,a		;7c2e
	jr z,FIJA_MEZCLADOR		;7c30
	res 2,a		;7c32
FIJA_MEZCLADOR:		; Ajusta el registro 7 del PSG (mezclador)
	ld (0e043h),a		;7c34
	ld e,a			;7c37
	ld a,007h		;7c38
	jp 00093h		;7c3a   ; BIOS WRTPSG - Writes data to PSG-register
ACTUALIZA_SONIDO:		; Un cuadro del reproductor: recorre los tres canales
	ld a,(0e043h)		;7c3d
	call FIJA_MEZCLADOR		;7c40
	ld c,001h		;7c43
	ld ix,0e010h		;7c45
	exx			;7c49
	ld b,003h		;7c4a   ; tres canales de once bytes cada uno (0xE010)
	ld de,0000bh		;7c4c
ACTUALIZA_SONIDO_7C4F:
	exx			;7c4f   ; al banco alterno
	ld a,(ix+002h)		;7c50   ; lee el modo del canal
	push af			;7c53
	dec a			;7c54   ; baja el modo del canal
	call z,CANAL_EFECTO		;7c55   ; si es 1, efecto
	pop af			;7c58
	or a			;7c59   ; lo comprueba
	call nz,ACTUALIZA_CANAL		;7c5a
	inc c			;7c5d
	inc c			;7c5e
	exx			;7c5f
	add ix,de		;7c60
	djnz ACTUALIZA_SONIDO_7C4F		;7c62
	ret			;7c64
CANAL_EFECTO:		; Canal en modo efecto
	ld hl,0e034h		;7c65   ; apunta a la ficha del canal (0xE034)
	ld de,07ca9h		;7c68
	ld a,c			;7c6b
	cp 003h		;7c6c
	jr z,CANAL_EFECTO_7C76		;7c6e
	ld hl,0e038h		;7c70
	ld de,07cadh		;7c73
CANAL_EFECTO_7C76:
	ld a,(0e031h)		;7c76   ; lee el canal de efecto (0xE031)
	cp 001h		;7c79   ; compara con 1
	jr z,CANAL_EFECTO_7C8F		;7c7b   ; si coincide, salta
	jr c,CANAL_EFECTO_7C99		;7c7d   ; si es menor, otro caso
	ld a,002h		;7c7f
	add a,(hl)			;7c81
	ld (hl),a			;7c82
	dec hl			;7c83
	jr nc,CANAL_EFECTO_7C87		;7c84
	inc (hl)			;7c86
CANAL_EFECTO_7C87:
	dec hl			;7c87
CANAL_EFECTO_7C88:
	ld (ix+003h),l		;7c88
	ld (ix+004h),h		;7c8b
	ret			;7c8e
CANAL_EFECTO_7C8F:
	ld a,(hl)			;7c8f   ; lee la orden
	sub 002h		;7c90
	ld (hl),a			;7c92
	dec hl			;7c93
	jr nc,CANAL_EFECTO_7C87		;7c94
	dec (hl)			;7c96
	jr CANAL_EFECTO_7C87		;7c97
CANAL_EFECTO_7C99:
	push bc			;7c99   ; guarda la cuenta
	ex de,hl			;7c9a
	ld bc,00004h		;7c9b
	lddr		;7c9e
	ex de,hl			;7ca0
	pop bc			;7ca1
	inc hl			;7ca2
	inc hl			;7ca3
	jr CANAL_EFECTO_7C87		;7ca4

; ----------------------------------------------------------------------
; DATOS tabla_canal: Cabecera del canal
;   0x7ca6..0x7cae  (8 bytes)
DATA_tabla_canal:
	defb 001h,021h,091h,041h,001h,021h,091h,045h	; 7ca6  .!.A.!.E

; ======================================================================
; CODIGO 0x7cae..0x7dd9  (299 bytes)
; ======================================================================


ACTUALIZA_CANAL:		; Avanza un canal: nota, duracion y volumen
	bit 6,a		;7cae   ; mira el modo del canal
	ld d,001h		;7cb0
	call z,SUMA_BONUS_7C17		;7cb2
	ld a,(ix+002h)		;7cb5
	or a			;7cb8
	jp m,ACTUALIZA_CANAL_7D40		;7cb9
	dec (ix+000h)		;7cbc
	ret nz			;7cbf
ACTUALIZA_CANAL_7CC0:
	ld l,(ix+003h)		;7cc0   ; lee el puntero de la melodia
	ld h,(ix+004h)		;7cc3   ; la parte alta
	ld a,(hl)			;7cc6   ; lee la nota
	cp 0feh		;7cc7   ; compara con 0xFE
	jp z,SUMA_BONUS_7BFC		;7cc9   ; 0xFE cierra la melodia
	jr nc,ACTUALIZA_CANAL_7D30		;7ccc
	bit 7,(ix+002h)		;7cce
	jp nz,ACTUALIZA_CANAL_7D6A		;7cd2
	and 0f0h		;7cd5
	cp 020h		;7cd7
	jr nz,ACTUALIZA_CANAL_7CE2		;7cd9
	ld a,(hl)			;7cdb
	and 00fh		;7cdc
	ld (ix+001h),a		;7cde
	inc hl			;7ce1
ACTUALIZA_CANAL_7CE2:
	ld a,(hl)			;7ce2   ; lee la nota
	and 0f0h		;7ce3   ; aisla el nibble alto
	cp 010h		;7ce5   ; compara con 0x10
	jr nz,ACTUALIZA_CANAL_7CFB		;7ce7   ; si no, otro caso
	ld a,006h		;7ce9
	ld a,(hl)			;7ceb
	and 01fh		;7cec
	ld e,a			;7cee
	ld a,006h		;7cef
	call 00093h		;7cf1   ; BIOS WRTPSG - Writes data to PSG-register
	ld d,000h		;7cf4
	call SUMA_BONUS_7C17		;7cf6
	inc hl			;7cf9
	ld a,(hl)			;7cfa
ACTUALIZA_CANAL_7CFB:
	ld b,(ix+002h)		;7cfb   ; lee el modo
	bit 6,b		;7cfe   ; mira el bit 6 del modo
	jr z,ACTUALIZA_CANAL_7D0E		;7d00   ; si no, salta
	ld a,c			;7d02   ; lee la orden
	cp 005h		;7d03
	ld a,(hl)			;7d05
	jr nz,ACTUALIZA_CANAL_7D0E		;7d06
	inc hl			;7d08
	call CANAL_EFECTO_7C88		;7d09
	jr ACTUALIZA_CANAL_7D22		;7d0c
ACTUALIZA_CANAL_7D0E:
	and 0f0h		;7d0e   ; aisla el nibble alto
	ld b,a			;7d10   ; lo guarda
	xor (hl)			;7d11   ; combina con el tono
	ld d,a			;7d12   ; lo pasa a D
	inc hl			;7d13   ; avanza
	ld e,(hl)			;7d14
	inc hl			;7d15
	call CANAL_EFECTO_7C88		;7d16
	ex de,hl			;7d19
	call ACTUALIZA_CANAL_7DCE		;7d1a
	ld a,b			;7d1d
	rrca			;7d1e
	rrca			;7d1f
	rrca			;7d20
	rrca			;7d21
ACTUALIZA_CANAL_7D22:
	ld h,a			;7d22   ; pasa el tono a H
	ld a,(ix+001h)		;7d23
	ld (ix+000h),a		;7d26
	add a,002h		;7d29
	ld (ix+008h),a		;7d2b
	jr ACTUALIZA_CANAL_7D62		;7d2e
ACTUALIZA_CANAL_7D30:
	xor a			;7d30   ; pone a cero
	ld (ix+009h),a		;7d31
	ld d,001h		;7d34
	call SUMA_BONUS_7C17		;7d36
	xor a			;7d39
	ld (ix+002h),a		;7d3a
	ld h,a			;7d3d
	jr ACTUALIZA_CANAL_7D62		;7d3e
ACTUALIZA_CANAL_7D40:
	dec (ix+000h)		;7d40   ; baja el contador de duracion
	jp z,ACTUALIZA_CANAL_7CC0		;7d43
	dec (ix+008h)		;7d46
	ld a,(ix+008h)		;7d49
	cp (ix+000h)		;7d4c
	jr nz,ACTUALIZA_CANAL_7D56		;7d4f
	cp 002h		;7d51
	jr c,ACTUALIZA_CANAL_7D59		;7d53
	ret			;7d55
ACTUALIZA_CANAL_7D56:
	dec (ix+008h)		;7d56
ACTUALIZA_CANAL_7D59:
	ld a,(ix+007h)		;7d59
	dec a			;7d5c
	ret m			;7d5d
	ld (ix+007h),a		;7d5e
	ld h,a			;7d61
ACTUALIZA_CANAL_7D62:
	ld a,c			;7d62
	rrca			;7d63
	add a,088h		;7d64
	ld e,h			;7d66
	jp 00093h		;7d67   ; BIOS WRTPSG - Writes data to PSG-register
ACTUALIZA_CANAL_7D6A:
	and 0f0h		;7d6a   ; aisla el nibble
	cp 0d0h		;7d6c
	ld a,(hl)			;7d6e
	jr nz,ACTUALIZA_CANAL_7D78		;7d6f
	and 00fh		;7d71
	ld (ix+00ah),a		;7d73
	inc hl			;7d76
	ld a,(hl)			;7d77
ACTUALIZA_CANAL_7D78:
	cp 0f0h		;7d78   ; 0xF0 cierra la melodia
	jr c,ACTUALIZA_CANAL_7D83		;7d7a
	and 00fh		;7d7c
	ld (ix+006h),a		;7d7e
	inc hl			;7d81
	ld a,(hl)			;7d82
ACTUALIZA_CANAL_7D83:
	cp 0e0h		;7d83   ; 0xE0 es una orden
	jr c,ACTUALIZA_CANAL_7D8E		;7d85
	and 00fh		;7d87
	ld (ix+005h),a		;7d89
	inc hl			;7d8c
	ld a,(hl)			;7d8d
ACTUALIZA_CANAL_7D8E:
	and 00fh		;7d8e
	ld b,a			;7d90
	ld a,(ix+00ah)		;7d91
	jr z,ACTUALIZA_CANAL_7D9B		;7d94
ACTUALIZA_CANAL_7D96:
	add a,(ix+00ah)		;7d96
	djnz ACTUALIZA_CANAL_7D96		;7d99
ACTUALIZA_CANAL_7D9B:
	ld (ix+001h),a		;7d9b   ; guarda la duracion
	ld a,(hl)			;7d9e   ; lee la nota
	inc hl			;7d9f   ; avanza el puntero
	call CANAL_EFECTO_7C88		;7da0   ; calcula el tono
	and 0f0h		;7da3   ; aisla el nibble
	rrca			;7da5
	rrca			;7da6
	rrca			;7da7
	rrca			;7da8
	ld b,a			;7da9
	sub 00ch		;7daa
	ld (ix+007h),a		;7dac
	jr z,ACTUALIZA_CANAL_7DB7		;7daf
	ld a,(ix+006h)		;7db1
	ld (ix+007h),a		;7db4
ACTUALIZA_CANAL_7DB7:
	call ACTUALIZA_CANAL_7D22		;7db7   ; calcula el tono
	ld a,b			;7dba   ; pasa la nota a A
	ld hl,07dd9h		;7dbb   ; apunta a la tabla de tonos (0x7DD9)
	call HL_MAS_A		;7dbe   ; la indexa
	ld l,(hl)			;7dc1
	ld h,000h		;7dc2
	ld a,(ix+005h)		;7dc4
	or a			;7dc7
	jr z,ACTUALIZA_CANAL_7DCE		;7dc8
	ld b,a			;7dca
ACTUALIZA_CANAL_7DCB:
	add hl,hl			;7dcb
	djnz ACTUALIZA_CANAL_7DCB		;7dcc
ACTUALIZA_CANAL_7DCE:
	ld a,c			;7dce
	ld e,h			;7dcf
	call 00093h		;7dd0   ; BIOS WRTPSG - Writes data to PSG-register
	ld a,c			;7dd3
	dec a			;7dd4
	ld e,l			;7dd5
	jp 00093h		;7dd6   ; BIOS WRTPSG - Writes data to PSG-register

; ----------------------------------------------------------------------
; DATOS datos_musica: Tabla de tonos del PSG y las melodias/efectos
;   0x7dd9..0x8000  (551 bytes)
DATA_datos_musica:
	defb 06ah,064h,05fh,059h,054h,050h,04bh,047h,043h,03fh,03ch,038h,04eh,07eh,0bch,07fh	; 7dd9  jd_YTPKGC?<8N~..
	defb 0abh,07fh,0b7h,07fh,07fh,07fh,05ah,07eh,021h,07eh,036h,07eh,09bh,07fh,04fh,07eh	; 7de9  ......Z~!~6~..O~
	defb 0dfh,07fh,009h,07fh,084h,07fh,092h,07fh,064h,07eh,071h,07eh,075h,07fh,07ah,07fh	; 7df9  ........d~q~u.z.
	defb 089h,07eh,09dh,07eh,0b3h,07eh,0c7h,07eh,0ddh,07eh,0f4h,07eh,02fh,07fh,047h,07fh	; 7e09  .~.~.~.~.~.~/.G.
	defb 062h,07fh,04eh,07eh,04eh,07eh,04eh,07eh,023h,0d0h,080h,0c0h,050h,0a0h,050h,080h	; 7e19  b.N~N~N~#...P.P.
	defb 050h,0ffh,022h,0c2h,046h,0d2h,04dh,021h,0b2h,047h,092h,048h,0ffh,022h,012h,071h	; 7e29  P.".F.M!.G.H.".q
	defb 0a0h,091h,0a0h,0b1h,0a0h,0d1h,0a0h,0e1h,0a0h,0e1h,0a0h,0d1h,0a4h,0b1h,0a8h,091h	; 7e39  ................
	defb 0afh,071h,0b4h,061h,0b8h,0ffh,023h,018h,0f2h,050h,000h,000h,022h,01fh,0f1h,0f0h	; 7e49  .q.a..#..P.."...
	defb 0ffh,023h,0d0h,0a0h,0c0h,080h,0a0h,080h,080h,080h,0ffh,025h,014h,0d1h,000h,0a1h	; 7e59  .#.........%....
	defb 000h,0d1h,000h,0a1h,000h,091h,000h,0ffh,022h,012h,00dh,00ch,00ah,009h,00ah,00ch	; 7e69  ........".......
	defb 00dh,00eh,00eh,00dh,00dh,00bh,00bh,00ah,00ah,009h,009h,008h,007h,006h,005h,0ffh	; 7e79  ................
	defb 0d8h,0fdh,0e2h,070h,070h,070h,0e1h,000h,000h,000h,040h,040h,040h,0d6h,022h,020h	; 7e89  ...ppp....@@@." 
	defb 042h,070h,07bh,0ffh,0d8h,0fch,0e2h,040h,040h,040h,070h,070h,070h,0e1h,000h,000h	; 7e99  Bp{....@@@ppp...
	defb 000h,0d6h,0e2h,0b2h,0b0h,0e1h,002h,040h,04bh,0ffh,0d8h,0fch,0e2h,000h,000h,000h	; 7ea9  .......@K.......
	defb 040h,040h,040h,070h,070h,070h,0d6h,072h,070h,072h,0e1h,000h,00bh,0ffh,0d6h,0fdh	; 7eb9  @@@ppp.rpr......
	defb 0e2h,041h,040h,040h,041h,071h,060h,040h,021h,071h,070h,070h,071h,0a1h,090h,070h	; 7ec9  .A@@Aq`@!qppq..p
	defb 051h,07bh,0cfh,0ffh,0d6h,0fch,0e3h,071h,070h,070h,071h,0a1h,090h,090h,091h,0a1h	; 7ed9  Q{.....qppq.....
	defb 0a0h,0a0h,0a1h,0e2h,011h,000h,000h,001h,0e3h,0bbh,0ffh,0d6h,0fch,0e3h,001h,000h	; 7ee9  ................
	defb 000h,001h,001h,020h,040h,061h,031h,030h,030h,031h,031h,050h,070h,091h,07bh,0ffh	; 7ef9  ... @a10011Pp.{.
	defb 023h,0d0h,08fh,0d0h,0a0h,0d0h,08fh,0d0h,0a0h,0d0h,08fh,0d0h,0a0h,0d0h,08fh,0d0h	; 7f09  #...............
	defb 0a0h,0d0h,08fh,0d0h,0a0h,0d0h,08fh,0d0h,0a0h,0d0h,08fh,0d0h,0a0h,0d0h,08fh,0d0h	; 7f19  ................
	defb 0a0h,02fh,000h,000h,0feh,005h,0d8h,0fdh,0e2h,020h,020h,020h,0d6h,072h,020h,073h	; 7f29  ./.......   .r s
	defb 0d8h,090h,0b0h,0e1h,000h,0d6h,02bh,0d8h,040h,040h,040h,0d6h,06bh,0ffh,0d8h,0fch	; 7f39  ......+.@@@.k...
	defb 0e3h,0b0h,0b0h,0b0h,0d6h,0b2h,0b0h,0d6h,0b3h,0d8h,0e2h,000h,0e3h,0b0h,090h,0d6h	; 7f49  ................
	defb 0bbh,0d8h,0e1h,010h,010h,010h,0d6h,03bh,0ffh,0d8h,0fch,0e3h,020h,020h,020h,0d6h	; 7f59  .......;....   .
	defb 072h,020h,073h,003h,07bh,0d8h,090h,090h,090h,0d6h,0bbh,0ffh,0dah,0fdh,0e1h,075h	; 7f69  r s.{..........u
	defb 0ffh,0dah,0fdh,0e0h,005h,0ffh,021h,01fh,0d1h,0f0h,0ffh,021h,0a1h,0b0h,0b2h,0f0h	; 7f79  ......!....!....
	defb 0b1h,0a0h,083h,0c0h,082h,070h,072h,0b0h,0ffh,021h,01ah,00dh,00ch,00dh,009h,008h	; 7f89  .....pr..!......
	defb 00ch,0ffh,021h,01dh,0f1h,0b0h,0f1h,070h,01bh,0c1h,0c0h,0a1h,090h,081h,0d0h,071h	; 7f99  ..!....p.......q
	defb 060h,0ffh,023h,014h,091h,070h,000h,000h,091h,098h,000h,000h,0feh,013h,02fh,014h	; 7fa9  `.#..p......../.
	defb 00bh,0feh,00fh,024h,000h,000h,026h,090h,021h,090h,020h,090h,021h,090h,020h,02fh	; 7fb9  ...$..&.!. .!. /
	defb 000h,000h,000h,000h,026h,080h,021h,080h,020h,080h,021h,080h,020h,02fh,000h,000h	; 7fc9  ....&.!. .!. /..
	defb 000h,000h,000h,000h,0feh,002h,024h,000h,000h,022h,0e1h,070h,0d1h,050h,0e1h,050h	; 7fd9  ......$..".p.P.P
	defb 0d1h,078h,0c1h,070h,0c1h,058h,0a1h,050h,071h,070h,0a1h,060h,091h,048h,0b1h,040h	; 7fe9  .x.p.X.Pqp.`.H.@
	defb 0a1h,030h,091h,010h,081h,000h,0ffh	; 7ff9

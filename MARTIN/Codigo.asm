; Consigna:
; Debe tener conectado un teclado matricial de 4x4 en el puerto B, cuando se apriete cualquier
; tecla deber� interrumpir y desplegar en la LCD (conectada al puerto C) 
; el n�mero de la tecla que se est� apretando (en hexadecimal)
; Las cadenas de la LCD ser�n:
; "Temp. max: xxx�C"
; "Temp.:        �C"
; Deber� desplegar la temperatura utilizando el sensor LM35 con una resoluci�n de 0,25 �C,
; la entrada del sensor ser� RE2/AN7
; Al detectar un pulso por el puerto RB2 (en este caso) por el RC2 saco un pulso, comparando la
; temperatura del sensor y la seteada por el usuario.	    
	    
	    LIST P=16F887
	    
	    include <p16f887.inc>
	    include <Macros.inc>
	    include <Definiciones.inc>
	    
	    __config 0x2007,23E4
	    __config 0x2008,3FFF
	    
	    ORG 		0X0000	;Grabado a partir de la direcci�n 0000
	    
	    GOTO		INICIO
	    
	    ORG			0X0004  ;Grabado a partir de la direcci�n 0004
	    
	    include <Rescate.inc>
	    
	    GOTO		RSI	;Salto a la subrutina de Servicio de Interrupci�n

	    LCD_MACRO		;Tabla para LCD
	    TABLATECL		;Tabla para el teclado matricial 4x4 
	    TABLA_H_A		;Tabla Hexa a ASCII para el teclado 
	    
INICIO	    CLRF 		PORTA
	    CLRF 		PORTB
	    CLRF		PORTC
	    CLRF 		PORTD
	    CLRF		PORTE
	
	    BSF			STATUS,RP0
	    BSF			STATUS,RP1  ;Bank3
	
	    MOVLW		B'10001000' ;Entrada anal�gica por AN7 y AN3 (VREF+)
	    MOVWF 		ANSEL
	    CLRF		ANSELH
	    
	    BCF			STATUS,RP1  ;Bank1
	    
;Parte alta de B como entrada para el teclado y RB2 para  detectar el cruce por cero
	    MOVLW		B'11110100'	    ;La parte alta del puerto B es entrada 	
	    MOVWF		TRISB	     ;Debo modificar antes al TRISB que las resistencia de elevaci�n 
	    
	    MOVLW		B'11001011'
	    MOVWF		TRISC	     ;Puerto C bit 4 y 5 salidas para el teclado
	    CLRF		TRISD	    ;El puerto D es saliente por el teclado y LCD
	    
;**********************************************************************
;   Configuramos el Timer0 con Option_Reg
	    MOVLW		B'01010101' ;Activo RBPU, RB0/INT flancos de subida, TMR0 cuenta ciclos de m�quina, flancos de bajada, prescaler: 1:64 
	    MOVWF		OPTION_REG

	    COMF		IOCB,F	     ; Habilitamos todos los pines del puerto B como fuente de interrupci�n 
	    
	    MOVLW		B'00010000' ;Ajuste a la izq., Vref-=Vss, Vref+=An3
	    MOVWF		ADCON1
	      
;**********************************************************************  	    
	    BCF			STATUS,RP0  ;Bank0 
	    
	    include<Imprime32CaractLCD.inc>	    
;Variables:	    
	    CLRF		CONT_T0		; Limpiamos el registro que utiliza TMR0
	    
	    MOVLW		0X0B		;La primera direcci�n donde se muestra el numero es la LCD es 0x0B    
	    MOVWF		CONT_TEMP_LCD	;Cargo el contador para mostrar en la LCD en las posiciones indicadas: 0X0B 0X0C 0X0D
;**********************************************************************
;Configuraci�n del TMR0: Cada 0.124 [S] estoy interrumpiendo
	    MOVLW		.131	      ;Timer cuenta a 125 * 64 prescaler = 8000
	    MOVWF		TMR0	      ;256-125=131, el n�mero que nosotros queremos es 125!
	    
	    MOVLW		.62	      ;Lo cambie para que sean 500000 de ciclos
	    MOVWF		CONT5	      ;Contador cargado con 62
;Tiempo Muestreo = 125 * 64 (prescaler) * 62 = 496000 (aprox. 500000)
;	      256 - 125 = 131 (TMR0, lo que se debe cargar) 
;**********************************************************************
	    MOVLW		B'11011101'  ; Reloj ADC = RC interno, canal anal�gico = AN7(Fuente de tensi�n), no inicia, AD encendido
	    MOVWF		ADCON0
	    
; Necesitamos guardar el valor de los puertos
	    MOVF		PORTB,W		;Estamos leyendo el puerto
	  
;   Damos los permisos de interrupci�n	    	    
;   Recordar: se debe leer el puerto B antes de bajar la bandera RBIF
	    BCF			INTCON,RBIF ;Bajamos la bandera antes de dar los permisos
	    BSF			INTCON,RBIE ;Habilitamos las interrupciones por el puertoB
	    
	    BCF			INTCON,T0IF ;Bajamos la bandera de TMR0 antes de dar los permisos
	    BSF			INTCON,T0IE ;Habilitamos las interrupciones por TMR0
	    
	    BSF			INTCON,GIE  ;Habilitamos las interrupciones globales
	    
;***********************Programa Principal*****************************    
	    GOTO		    $	     ;El programa principal no esta haciendo nada por el momento
;*******************Rutina Servicio Interrupci�n***********************    
RSI	    BTFSS		INTCON,T0IF	 
	    GOTO		FUE_INT_CH    ;Soluci�n por interrupcion en B
	    
	    DECFSZ		CONT5,F
	    GOTO		BAJA_BANDERA	;Bajo la bandera hasta cumplir los 62 veces
	    
	    BSF			ADCON0,1	;Inicia la Conversi�n Anal�gica Digital
	    
	    MOVLW		.62
	    MOVWF		CONT5		;Vuelvo a cargar CONT5 con 62
	    
	    INCF		CONT_T0		;Ver esta instrucci�n!!!!
	    
	    BTFSC		ADCON0,1	;Ya termino la Conversi�n Anal�gica Digital?
	    GOTO		$-1
	    
	    MOVF		ADRESH,W    ;El resultado del ADC lo paso a W 
	    MOVWF		TEMPSEN	    ;Estoy guardando la temperatura del sensor en binario
	    MOVWF		DECIMAL	    ;Paso de binario a decimal
	    CALL		BIN_A_DEC
	    
	    MOVLW		0X48	    ;Donde queremos imprimir se lo pasamos al registro DIR_LCD
	    MOVWF		DIR_LCD
	    
	    CALL		IMPRIM_NUM ;Imprime la parte alta del resultado de la Conversi�n A-D
	    
	    BSF			STATUS,RP0  ; Bank1
	    
	    MOVF		ADRESL,W    ;Guardamos la parte baja del resultado en W
	    
	    BCF			STATUS,RP0  ; Bank 0
	    
	    MOVWF		ADL	     ;Guardamos la parte baja del resultado en ADL
	    
	    CLRW			      ;Caso ADRESL = 00
	    XORWF		ADL,W
	    BTFSS		STATUS,Z
	    
	    GOTO		LM35FUE01		
	    
	    MOVLW		'.'
	    CALL		CARACTER
	    MOVLW		'0'
	    CALL		CARACTER
	    MOVLW		'0'
	    CALL		CARACTER
	    
	    GOTO		BAJA_BANDERA
	    
LM35FUE01	   
	    MOVLW		B'01000000' ;Caso ADRESL = 01
	    XORWF		ADL,W
	    BTFSS		STATUS,Z
	    
	    GOTO		LM35FUE10
	    
	    MOVLW		'.'
	    CALL		CARACTER
	    MOVLW		'2'
	    CALL		CARACTER
	    MOVLW		'5'
	    CALL		CARACTER
	    
	    GOTO		BAJA_BANDERA
	    
LM35FUE10
	    MOVLW		B'10000000' ;Caso ADRESL = 10
	    XORWF		ADL,W
	    BTFSS		STATUS,Z
	    
	    GOTO		LM35FUE11
	    
	    MOVLW		'.'
	    CALL		CARACTER
	    MOVLW		'5'
	    CALL		CARACTER
	    MOVLW		'0'
	    CALL		CARACTER
	    
	    GOTO		BAJA_BANDERA
	    
LM35FUE11	    
	    MOVLW		'.'	      ;Caso ADRESL = 11
	    CALL		CARACTER
	    MOVLW		'7'
	    CALL		CARACTER
	    MOVLW		'5'
	    CALL		CARACTER
	    
;  Acomodo de nuevo la bandera
BAJA_BANDERA	    MOVLW		.131	      ; Timer cuenta a 125 * 264 prescaler = 8000
		    MOVWF		TMR0	      ; 256-250=6, el n�mero que nosotros queremos es 250!
	    
		    BCF			INTCON,T0IF  ; Bajo la bandera de interrupci�n del Timer0
	    
		    GOTO		REGRESA_INT  ; Regreso de la interrupci�n	    

;Interrupci�n por teclado:	    
FUE_INT_CH
;	    CALL		T25MS	    ;Elimino rebotes
	    CALL		T20MS
;Pregunto si RB0 es 1	    
	    BTFSS		PORTB,RB2 
	    GOTO		CRUCE0
;Caso en que fue el teclado	    
	    MOVLW		0XF0
	    ANDWF		PORTB,W
	    MOVWF		TECLADO4X4  ;Guardo la parte alta de B
	    
	    SWAPF		TECLADO4X4,F ;Lo guardo en la parte baja de la variable TECLADO4X4
	    
	    BSF			STATUS,RP0  ;Banco1
	    
	    MOVLW		B'11000000' ;Al apretar el bot�n coloco el RD7,RD6 como entrada 
	    MOVWF		TRISD	    
	    
	    MOVLW		B'11111111' ;Al apretar el bot�n coloco el RC5,RC4 como entrada 
	    MOVWF		TRISC
	    
	    MOVLW		B'00001111' ;Coloco la parte alta de B como salida
	    MOVWF		TRISB	       
	    
	    BCF			OPTION_REG,7 ;Activo las resistencia de elevaci�n
	    			    
	    BCF			STATUS,RP0   ;Banco0
	    
	    MOVLW		0XF0
	    MOVWF		PORTB		;Coloco en 1 el puerto B para que le llegue al D7,D6,C5,C4
	    
	    MOVLW		B'00110000'	;Me quedo con los bits del puerto C
	    ANDWF		PORTC,W
	    ADDWF		TECLADO4X4,F ;Valores concatenados para buscar en la tabla
	    
	    MOVLW		B'11000000'	;Me quedo con los bits del puerto D
	    ANDWF		PORTD,W
	    ADDWF		TECLADO4X4,F ;Valores concatenados para buscar en la tabla
	    
	    CLRF		CONT_TECL	;Contador que me permite recorrer la tabla y preguntar para cada caso
	    
BUSCA_TECLA 
	    MOVF		CONT_TECL,W
	    CALL		TABLA_TECL
	    XORWF		TECLADO4X4,W	;Pregunto por cada valor de la tabla para ver si es el que se apreto en el teclado
	    
	    BTFSC		STATUS,Z  ;Lo hacemos para que recorra todas las teclas y encuentre alg�n resultado
	    GOTO		DIRECC_IMPR
	    INCF		CONT_TECL,F
	    MOVLW		.16		;Se va a repetir de acuerdo a la cantidad de teclas
	    
	    XORWF		CONT_TECL,W  
	    BTFSS		STATUS,Z
	    GOTO		BUSCA_TECLA	;Cuando contador sea igual a 16 
	    MOVLW		.16
	    MOVWF		CONT_TECL
	    
DIRECC_IMPR	   		    
	    MOVF		CONT_TEMP_LCD,W ;Movemos el contenido cont-temp-lcd a W, es la direcci�n a mostrar en la LCD
	    MOVWF		DIR_LCD
	    CALL		DIRECCION_DDRAM
	    
	    MOVF		CONT_TECL,W	;Pasamos lo que encontramos a W 
	    call		CORRECT_TECL
	    CALL		TABLA_HEX_ASCII	;Estoy pasando de hex a ascii
	    CALL		CARACTER
	    
;Pregunto RD7,RD6,RC5,RC4 es cero entonces se dejo de apretar el bot�n	    
	    BTFSC		PORTC,RC4 ;De esta forma evito que entre permanentemente
	    GOTO		$-1
	    BTFSC		PORTC,RC5 ;al caso prohibido de forma permanente
	    GOTO		$-1
	    BTFSC		PORTD,RD6
	    GOTO		$-1
	    BTFSC		PORTD,RD7;NO queda permanentemente interrumpido
	    GOTO		$-1	    ;De esta forma evito que entre permanentemente al caso prohibido de forma permanente
					    ;NO queda permanentemente interrumpido
					    
;	    CALL		T25MS	    ;Elimino rebotes
	    CALL		T20MS
	    
	    BSF			STATUS,RP0  ;Banco1
	    
; Acomodo los puertos de nuevo para que siga funcionando el teclado   
	    MOVLW		B'11110100'	    ;Parte alta de B como entrada para el teclado y RB2 para 
	    MOVWF		TRISB		    ; detectar el cruce por cero

	    MOVLW		B'11001111'
	    MOVWF		TRISC	     ;Puerto C bit 4 y 5 salidas para el teclado
	    CLRF		TRISD	    ;El puerto D es saliente por el teclado y LCD	
	    
	    BCF			OPTION_REG,7 ;Activo las resistencia de elevaci�n
	    
	    BCF			STATUS,RP0   ;Banco0
	    
	    CLRF		PORTD		;Creo q se puede sacar
	    CLRF		PORTC		;Probar sacando estas dos l�neas
	    
	    INCF		CONT_TEMP_LCD,F ;Incrementamos el registro para que imprima en la pr�xima direcci�n
	    MOVLW		0X0E		  ;Si el resultado llego a 0x0A lo volvemos a cargar con 0x0D
	    XORWF		CONT_TEMP_LCD,W
	    BTFSS		STATUS,Z
	    GOTO		IMP_NEXT_DIR	    ;Imprimimos en la pr�xima direcci�n de la LCD
	    
	    MOVLW		0X0B		
	    MOVWF		CONT_TEMP_LCD	;Cargo el contador para mostrar en la LCD en las posiciones indicadas: 0X0B 0X0C 0X0D
	    
	    GOTO		IMP_NEXT_DIR
	    
CRUCE0	    
;	    Delay alpha=0[mS]	    
;	    Delay alpha=5[mS]
;	    Delay alpha=10[mS]
	    CALL    T6MS
	    BSF	     PORTC,RC2
	    CALL    T20US	    ;CALL    T600MS
	    BCF	     PORTC,RC2
;Bajo la bandera:	    
;Recordar: se debe leer el puerto B antes de bajar la bandera RBIF
IMP_NEXT_DIR	    
	    MOVF		PORTB,W    
	    BCF			INTCON,RBIF ;Bajamos la bandera antes de dar los permisos
	    
REGRESA_INT	
	    NOP		;Este nop es porque no permite tener la etiqueta pegada al include
	    include <Recuperacion.inc>    ;Contiene el RETFIE
	    
	    ;END al final del archivo

;****************Subrutina para corregir teclado **********************
CORRECT_TECL
;Caso centena:	    
	    MOVLW	0X0D
	    XORWF	CONT_TEMP_LCD,F
	    BTFSC	STATUS,Z
	    GOTO	CENTENA
;Caso decena:
	    MOVLW	0X0C
	    XORWF	CONT_TEMP_LCD,F
	    BTFSC	STATUS,Z
	    GOTO	DECENA
;;Caso unidad:	    
;	    MOVLW	0X0B
;	    XORWF	CONT_TEMP_LCD,F
;	    BTFSC	STATUS,Z
;;	    GOTO	UNIDAD
	    
CENTENA	    MOVF	CONT_TECL,W
	    MOVWF	CENTE		;Guarde el contenido binario en Cente 
	    MOVLW	0X02
	    SUBWF	CENTE,W		;CENTE-2
	    BTFSS	STATUS,C	;Cente es mayor o igual a 2? C: 1 positivo (cente >= 2)
	    
	    CALL	CENTEMEN2
	    
	    CALL	CENTEMAY2	 ;Mayor o igual   
	    
	    RETURN
	    
DECENA	    MOVF	CONT_TECL,W
	    MOVWF	DECE
	    MOVLW	.2
	    SUBWF	CENTE,W
	    BTFSC	STATUS,Z
	    CALL	CENTEIGUAL2
	    CALL	CENTEMENOR2
	    
	    RETURN

UNIDAD	    MOVF	CONT_TECL,W
	    MOVWF	UNID
	    MOVLW	.2
	    SUBWF	CENTE,W
	    BTFSC	STATUS,Z
	    CALL	CENTEIG2
	    CALL	CENTEME2
	    
;**************** Subrutinas de Binario a Decimal *********************
BIN_A_DEC  CLRF		UNID_L
	    CLRF		DECE_L
	    CLRF		CENT_L
	    
; Pasamos de binario a decimal
RESTA100   MOVLW		.100
	    SUBWF		DECIMAL,F
	    BTFSS		STATUS,C
	    GOTO		SUMA100
	    INCF		CENT_L,F
	    GOTO		RESTA100

SUMA100	    MOVLW		.100
	    ADDWF		DECIMAL,F
	    
RESTA10	    MOVLW		.10
	    SUBWF		DECIMAL,F
	    BTFSS		STATUS,C
	    GOTO		SUMA10
	    INCF		DECE_L,F
	    GOTO		RESTA10

SUMA10	    MOVLW		.10
	    ADDWF		DECIMAL,F
	    
	    MOVF		DECIMAL,W
	    MOVWF		UNID_L
	    
	    RETURN 
	    
;******* Subrutina para imprimir, primero sumamos 30 para pasarlo ASCII ********
IMPRIM_NUM	MOVLW		0X30
		ADDWF		UNID_L,F    ;Lo pasamos a ASCII sumandole 30
		ADDWF		DECE_L,F
		ADDWF		CENT_L,F
	    
; Le indicamos a partir de que direcci�n empiezo a imprimir
		MOVF		DIR_LCD,W    
		CALL		DIRECCION_DDRAM	

		MOVF		CENT_L,W
		CALL		CARACTER		;Imprimimos centenas	    
		MOVF		DECE_L,W
		CALL		CARACTER		;Imprimimos decenas
		MOVF		UNID_L,W
		CALL		CARACTER		;Imprimimos unidades

		RETURN	
	    
;*********************** Subrutinas de Tiempo *************************
	    include <SubrutinasTiempo.inc>    
;*********************** Subrutinas de Funciones LCD ******************	    
	    include <FuncionesLCD.inc>

;**********************La centena es mayor o igual 2******************	    
CENTEMAY2  MOVLW	0X02		  ;La centena es mayor o igual a 2  
	    MOVWF	CENTE	
;****************************************************
	    MOVLW	.20
	    MOVWF	AUXNUMUSU
	    MOVLW	.10    
CARGO200   ADDWF	NUMUSU,F
	    DECFSZ	AUXNUMUSU,F
	    GOTO	CARGO200    
	    RETURN
	    
;*********************La centena es menor 2***************************
CENTEMEN2  MOVLW	.1
	    MOVWF	AUXNUMUSU	;La centena es menor a 2
	    XORWF	CENTE
	    BTFSC	STATUS,Z	;CENTE = 1?
	    GOTO	CENTE1	   
	    RETURN			;CENTE = 0 NO HACE NADA
	    
	    
CENTE1	    MOVLW	.10
	    MOVWF	AUXNUMUSU   ;cente = a 10
CARGO100   ADDWF	NUMUSU,F    ;Sumo 10
	    DECFSZ	AUXNUMUSU,F 
	    GOTO	CARGO100  
	    RETURN
;*********************************************************************	    
CENTEIGUAL2
	    MOVLW	0X05
	    SUBWF	DECE,W		;DECE-5
	    BTFSC	STATUS,C	;DECE es mayor o igual a 5? C: 1 positivo (DECE >= 5)
	    
	    CALL	PONGO5
	    CALL	MENOR5
	    
CENTEMENOR2	
	    MOVLW	.9
	    SUBWF	DECE,W		;DECE-9
	    BTFSC	STATUS,C	;DECE ES MAYOR O IGUAL A 9?
	    CALL	PONGO9
	    CALL	MENOR9
	    
	    RETURN
	    
PONGO5	    MOVLW	.5
	    MOVWF	AUXNUMUSU
	    MOVLW	.10
CARGO50	    ADDWF	NUMUSU
	    DECFSZ	AUXNUMUSU,F
	    GOTO	CARGO50
	    RETURN
	    
MENOR5	    MOVLW	.4
	    MOVWF	AUXNUMUSU
DECREM	    MOVF	AUXNUMUSU,W
	    SUBWF	DECE,W
	    BTFSC	STATUS,Z  ;RESTO DECE Y AUXNUMUSU SI Z=0 DECREAUX0
	    CALL	NODECRE
	    CALL	DECREAUX0
	    
DECREAUX0  
	    DECFSZ	AUXNUMUSU,F
	    GOTO	DECR
	    
NODECRE	    MOVLW	.10
CARGOMEN5  ADDWF	NUMUSU
	    DECFSZ	AUXNUMUSU,F
	    GOTO	CARGOMEN5
	    RETURN
	    
PONGO9	    MOVLW	.9
	    MOVWF	AUXNUMUSU
	    MOVLW	.10
CARGO90	    ADDWF	NUMUSU
	    DECFSZ	AUXNUMUSU,F
	    GOTO	CARGO90
	    RETURN
	    
MENOR9	    MOVLW	.8
	    MOVWF	AUXNUMUSU
	    
	    
DECR	    MOVF	AUXNUMUSU,W
	    SUBWF	DECE,W
	    BTFSC	STATUS,Z  ;RESTO DECE Y AUXNUMUSU SI Z=0 DECREAUX0
	    CALL	NODEC
	    CALL	DECREAUX1
	    
DECREAUX1  
	    DECFSZ	AUXNUMUSU,F
	    GOTO	DECREM
	    
NODEC	    MOVLW	.10
CARGOMEN9  ADDWF	NUMUSU
	    DECFSZ	AUXNUMUSU,F
	    GOTO	CARGOMEN9
	    RETURN
	    
CENTEIG2   MOVLW	0X05
	    SUBWF	DECE,W		;DECE-5
	    BTFSC	STATUS,Z	;DECE es igual a 5? Z = 1 SON IGUALES	    
	    CALL	IGU5
	    CALL	MENO5
	    RETURN
	    
IGU5	    MOVLW	.5
	    SUBWF	UNID,W		;UNID-5
	    BTFSC	STATUS,C	;UNIDAD MAYOR O IGUAL A 5 C = 1
	    CALL	UNITY5
	    CALL	UNITYNO5
	    
	    
UNITY5	    MOVLW	.5
	    MOVWF	UNID
	    MOVWF	AUXNUMUSU
	    MOVLW	.1
CARGOM5	    ADDWF	NUMUSU
	    DECFSZ	AUXNUMUSU,F
	    GOTO	CARGOM5
	    RETURN
	    
UNITYNO5   MOVLW	.4
CARGM4	    MOVWF	AUXNUMUSU
	    SUBWF	UNID,W ;UNID-W
	    BTFSC	STATUS,Z
	    DECFSZ	AUXNUMUSU,F
	    GOTO	CARGM4
	    CALL	IGUALES4
	    
	    RETURN
IGUALES4   MOVLW	.1
	    ADDWF	NUMUSU
	    DECFSZ	AUXNUMUSU,F
	    GOTO	IGUALES4
	    RETURN
CENTEME2
	    MOVLW	.9
CARGM9	    MOVWF	AUXNUMUSU
	    SUBWF	UNID,W ;UNID-W
	    BTFSC	STATUS,Z
	    DECFSZ	AUXNUMUSU,F
	    GOTO	CARGM9
	    CALL	IGUALES9
	    
	    RETURN
IGUALES9   MOVLW	.1
	    ADDWF	NUMUSU
	    DECFSZ	AUXNUMUSU
	    GOTO	IGUALES9
	    RETURN   
	    
	    
MENO5	    MOVLW	.9
	    MOVWF	AUXNUMUSU
	    SUBWF	UNID,W ;UNID-W
	    BTFSS	STATUS,C
	    GOTO	CARGA99
	    CALL	IGUALES9
	    
	    RETURN
	  
	    

	    RETURN
	    
	    
	    
	    
	    END
	    
	    
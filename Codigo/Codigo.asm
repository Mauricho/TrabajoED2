; Consigna:
; Debe tener conectado un teclado matricial de 4x4 en el puerto B, cuando se apriete cualquier
; tecla deberá interrumpir y desplegar en la LCD (conectada al puerto C) 
; el número de la tecla que se está apretando (en hexadecimal)
; Las cadenas de la LCD serán:
; "Temp. max: xxx°C"
; "Temp.:        °C"
; Deberá desplegar la temperatura utilizando el sensor LM35 con una resolución de 0,25 °C,
; la entrada del sensor será RE2/AN7
; Al detectar un pulso por el puerto RB0 (en este caso) por el RC2 saco un pulso, comparando la
; temperatura del sensor y la seteada por el usuario.	    
	    
	    LIST P=16F887
	    
	    include <p16f887.inc>
	    include <Macros.inc>
	    include <Definiciones.inc>
	    
	    __config 0x2007,23E4
	    __config 0x2008,3FFF
	    
	    ORG 		0X0000	;Grabado a partir de la dirección 0000
	    
	    GOTO		INICIO
	    
	    ORG			0X0004  ;Grabado a partir de la dirección 0004
	    
	    include <Rescate.inc>
	    
	    GOTO		RSI	;Salto a la subrutina de Servicio de Interrupción

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
	
	    MOVLW		B'10001000' ;Entrada analógica por AN7 y AN3 (VREF+)
	    MOVWF 		ANSEL
	    CLRF		ANSELH
	    
	    BCF			STATUS,RP1  ;Bank1
	    
;Parte alta de B como entrada para el teclado y RB0 para  detectar el cruce por cero
	    MOVLW		B'11110000'	    ;La parte alta del puerto B es entrada 	para el teclado y RB0 para detectar el cruce por cero
	    MOVWF		TRISB	     ;Debo modificar antes al TRISB que las resistencia de elevación  
	    
	    MOVLW		B'11001111'
	    MOVWF		TRISC	     ;Puerto C bit 4 y 5 salidas para el teclado, bit 2 para Control plancha (al czo esta apagado)
	    CLRF		TRISD	    ;El puerto D es saliente por el teclado y LCD
	    
;**********************************************************************
;   Configuramos el Timer0 con Option_Reg, nos sirve para el teclado, TMR0 y RB0/INT
	    MOVLW		B'01010101' ;Activo RBPU, RB0/INT flancos de subida, TMR0 cuenta ciclos de máquina, flancos de bajada, prescaler: 1:64 
	    MOVWF		OPTION_REG
	    
	    MOVLW		B'11110000' ;Solo activamos las resistencias del teclado
	    MOVWF		WPUB
	    
	    COMF		IOCB,F
	    
	    MOVLW		B'00010000' ;Ajuste a la izq., Vref-=Vss, Vref+=An3
	    MOVWF		ADCON1
	      
;**********************************************************************  	    
	    BCF			STATUS,RP0  ;Bank0 
	    
	    include<Imprime32CaractLCD.inc>	    
;Variables:	    
	    CLRF		CONT_T0		; Limpiamos el registro que utiliza TMR0
	    
	    MOVLW		0X0B		;La primera dirección donde se muestra el numero es la LCD es 0x0B    
	    MOVWF		CONT_TEMP_LCD	;Cargo el contador para mostrar en la LCD en las posiciones indicadas: 0X0B 0X0C 0X0D
;**********************************************************************
;Configuración del TMR0: Cada 0.124 [S] estoy interrumpiendo
	    MOVLW		.131	      ;Timer cuenta a 125 * 64 prescaler = 8000
	    MOVWF		TMR0	      ;256-125=131, el número que nosotros queremos es 125!
	    
	    MOVLW		.62	      ;Lo cambie para que sean 500000 de ciclos
	    MOVWF		CONT5	      ;Contador cargado con 62
;Tiempo Muestreo = 125 * 64 (prescaler) * 62 = 496000 (aprox. 500000)
;	      256 - 125 = 131 (TMR0, lo que se debe cargar) 
;**********************************************************************
	    MOVLW		B'11011101'  ; Reloj ADC = RC interno, canal analógico = AN7(Fuente de tensión), no inicia, AD encendido
	    MOVWF		ADCON0
	    
; Necesitamos guardar el valor de los puertos
	    MOVF		PORTB,W		;Estamos leyendo el puerto
	  
;   Damos los permisos de interrupción	    	    
;   Recordar: se debe leer el puerto B antes de bajar la bandera RBIF	    
	    BCF			INTCON,RBIF ;Bajamos la bandera antes de dar los permisos
	    BSF			INTCON,RBIE ;Habilitamos las interrupciones por el puertoB
	    
;	    BCF			INTCON,INTF ;Bajamos la bandera de interrupción por RB0/INT
;	    BSF			INTCON,INTE ;Habilitamos las interrupciones por RB0   
	    
	    BCF			INTCON,T0IF ;Bajamos la bandera de TMR0 antes de dar los permisos
	    BSF			INTCON,T0IE ;Habilitamos las interrupciones por TMR0
	    
	    BSF			INTCON,GIE  ;Habilitamos las interrupciones globales
	    
;***********************Programa Principal*****************************    

	    
	    GOTO		    $	     ;El programa principal no esta haciendo nada por el momento
;*******************Rutina Servicio Interrupción***********************    
RSI	    
	    BTFSC		INTCON,INTF
	    GOTO		FUE_RB0	    ;Solución por interrupcion en RB0/INT	    
	    
	    BTFSS		INTCON,T0IF	 
	    GOTO		FUE_INT_CH    ;Solución por interrupcion a causa del teclado 

; Interrupción del TMR0	    
	    DECFSZ		CONT5,F
	    GOTO		BAJA_BANDERA	;Bajo la bandera hasta cumplir los 62 veces
	    
	    BSF			ADCON0,1	;Inicia la Conversión Analógica Digital
	    
	    MOVLW		.62
	    MOVWF		CONT5		;Vuelvo a cargar CONT5 con 62
	    
	    INCF		CONT_T0	
	    
	    BTFSC		ADCON0,1	;Ya termino la Conversión Analógica Digital?
	    GOTO		$-1
	    
	    MOVF		ADRESH,W    ;El resultado del ADC lo paso a W 
	    MOVWF		TEMPSEN	    ;Estoy guardando la temperatura del sensor en binario
	    MOVWF		DECIMAL	    ;Paso de binario a decimal
	    CALL		BIN_A_DEC
	    
	    MOVLW		0X48	    ;Donde queremos imprimir se lo pasamos al registro DIR_LCD
	    MOVWF		DIR_LCD
	    
	    CALL		IMPRIM_NUM ;Imprime la parte alta del resultado de la Conversión A-D
	    
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
	    
;Acomodo de nuevo la bandera del TMR0
BAJA_BANDERA	    MOVLW		.131	      ; Timer cuenta a 125 * 264 prescaler = 8000
		    MOVWF		TMR0	      ; 256-250=6, el número que nosotros queremos es 250!
	    
		    BCF			INTCON,T0IF  ; Bajo la bandera de interrupción del Timer0
	    
		    GOTO		REGRESA_INT  ; Regreso de la interrupción	    

;Interrupción por teclado:	    
FUE_INT_CH
	    CALL		T25MS	    ;Se debe dar tiempo para que lea los puertos pero tampoco tanto
	    CALL		T25MS				    ;perjudica el comportamiento del programa
;Caso en que fue el teclado	    
	    MOVLW		0XF0
	    ANDWF		PORTB,W
	    MOVWF		TECLADO4X4  ;Guardo la parte alta de B
	    
	    SWAPF		TECLADO4X4,F ;Lo guardo en la parte baja de la variable TECLADO4X4
	    
	    BSF			STATUS,RP0  ;Banco1
	    
	    MOVLW		B'11000000' ;Al apretar el botón coloco el RD7,RD6 como entrada 
	    MOVWF		TRISD	    
	    
	    MOVLW		B'11111111' ;Al apretar el botón coloco el RC5,RC4 como entrada 
	    MOVWF		TRISC
	    
	    MOVLW		B'00000000' ;Coloco la parte alta de B como salida, y la parte baja tambien para que no entre ruido
	    MOVWF		TRISB	       
	    
	    BCF			OPTION_REG,7 ;Activo las resistencia de elevación
	    			    
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
	    
	    BTFSC		STATUS,Z  ;Lo hacemos para que recorra todas las teclas y encuentre algún resultado
	    GOTO		DIRECC_IMPR
	    INCF		CONT_TECL,F
	    MOVLW		.16		;Se va a repetir de acuerdo a la cantidad de teclas
	    
	    XORWF		CONT_TECL,W  
	    BTFSS		STATUS,Z
	    GOTO		BUSCA_TECLA	;Cuando contador sea igual a 16 
	    MOVLW		.16
	    MOVWF		CONT_TECL
	    
DIRECC_IMPR	   		    
	    MOVF		CONT_TEMP_LCD,W ;Movemos el contenido cont-temp-lcd a W, es la dirección a mostrar en la LCD
	    MOVWF		DIR_LCD
	    CALL		DIRECCION_DDRAM
	    
	    MOVF		CONT_TECL,W	;Pasamos lo que encontramos a W 
	    CALL		CORRECT_TECL	;Corregimos la tecla
	    CALL		TABLA_HEX_ASCII
	    CALL		CARACTER
	    
;Pregunto RD7,RD6,RC5,RC4 es cero entonces se dejo de apretar el botón	    
	    BTFSC		PORTC,RC4 ;De esta forma evito que entre permanentemente
	    GOTO		$-1
	    BTFSC		PORTC,RC5 ;al caso prohibido de forma permanente
	    GOTO		$-1
	    BTFSC		PORTD,RD6
	    GOTO		$-1
	    BTFSC		PORTD,RD7;NO queda permanentemente interrumpido
	    GOTO		$-1	    ;De esta forma evito que entre permanentemente al caso prohibido de forma permanente
					    ;NO queda permanentemente interrumpido
					    
	    CALL		T100MS	    ;Se le da un tiempo para que termine de leer los valores
	    
;********************** PREGUNTAMOS SI YA SE DIGITO UNIDAD *************	    
	    MOVLW		0X0D			;Preguntamos si se digito la unidad	que es el tercer digito
	    XORWF		CONT_TEMP_LCD,W
	    BTFSC		STATUS,Z
	    GOTO		ON_RB0			;Habilitamos las interrupciones por RB0/INT
;**********************************************************************	 	    
OFF_RB0	    BSF			STATUS,RP0	;Banco 1
	    
	    MOVLW		B'11110000' ;La parte alta del puerto B es entrada para el teclado 
	    MOVWF		TRISB	     ;Debo modificar antes al TRISB que las resistencia de elevación
	    
	    MOVLW		B'11001111'
	    MOVWF		TRISC	     ;Puerto C bit 4 y 5 salidas para el teclado, bit 2 apagado control plancha
	    CLRF		TRISD	    ;El puerto D es saliente por el teclado y LCD	 
	    
	    BCF			OPTION_REG,7 ;Activo las resistencia de elevación
	    
	    MOVLW		B'11110000' ;Solo activamos las resistencias del teclado
	    MOVWF		WPUB	     ;Probar eliminando esta línea y la anterior	    
;Deshabilitamos RB0 ************************	     
	    BCF			INTCON,INTE ;Deshabilitamos las interrupciones por RB0	    
	    
	    BCF			STATUS,RP0	;Banco 0
	    
	    GOTO		SALTA_ON_RB0
;**********************************************************************
ON_RB0	    BSF			STATUS,RP0  ;Banco 1
	    
	    MOVLW		B'11110001'	    ;La parte alta del puerto B es entrada 	para el teclado y RB0 para detectar el cruce por cero
	    MOVWF		TRISB		    ;Debo modificar antes al TRISB que las resistencia de elevación
	    
	    MOVLW		B'11001011'
	    MOVWF		TRISC	     ;Puerto C bit 4 y 5 salidas para el teclado, bit 2 prendido control plancha
	    CLRF		TRISD	     ;El puerto D es saliente por el teclado y LCD
	    
	    BCF			OPTION_REG,7 ;Activo las resistencia de elevación
	    
	    MOVLW		B'11110001' ;Activamos las resistencias del teclado y RB0
	    MOVWF		WPUB	    
;Habilitamos RB0 ******************************************************	    
	    BCF			INTCON,INTF;1° Bajamos la bandera y despues habilitamos RB0
	    BSF			INTCON,INTE ;Habilitamos las interrupciones por RB0 
	    
	    BCF			STATUS,RP0   ;Banco 0	   
	    
SALTA_ON_RB0	    
	    CLRF		PORTD		
	    CLRF		PORTC		
	    
	    INCF		CONT_TEMP_LCD,F ;Incrementamos el registro para que imprima en la próxima dirección
	    MOVLW		0X0E		  ;Si el resultado llego a 0x0A lo volvemos a cargar con 0x0D
	    XORWF		CONT_TEMP_LCD,W
	    BTFSS		STATUS,Z
	    GOTO		IMP_NEXT_DIR	    ;Imprimimos en la próxima dirección de la LCD
	    
	    MOVLW		0X0B		
	    MOVWF		CONT_TEMP_LCD	;Cargo el contador para mostrar en la LCD en las posiciones indicadas: 0X0B 0X0C 0X0D
	    
IMP_NEXT_DIR	    
	    MOVF		PORTB,W      ;Recordar: se debe leer el puerto B antes de bajar la bandera RBIF
	    BCF			INTCON,RBIF ;Bajamos la bandera antes de dar los permisos
	    
	    BCF			INTCON,INTF ;Bajamos la bandera
	    
	    GOTO		REGRESA_INT  ; Regreso de la interrupción del teclado
	    

;Interrupción por RB0:    
FUE_RB0	    
	    MOVF		NUMUSU,W	;Controlo si la temperatura digitada es mayor o igual que la que se senso		
	    SUBWF		TEMPSEN,W	;TEMPSEN-NUMUSU
	    BTFSC		STATUS,C	;Si: NUMUSU > TEMPSEN la temperatura sigue subiendo
	    
	    GOTO		OFF_PWM		;Deshabilitamos las interrupciones por RB0/INT, se deshabilita para la pr?oxima interrupción
	    GOTO		ON_PWM      ;NUMUSU > TEPSEN
;**********************************************************************	    
OFF_PWM	
	    BSF			STATUS,RP0	;Banco 1
	    
	    MOVLW		B'11110000' ;La parte alta del puerto B es entrada para el teclado 
	    MOVWF		TRISB	     ;Debo modificar antes al TRISB que las resistencia de elevación
	    
	    MOVLW		B'11001111'
	    MOVWF		TRISC	     ;Puerto C bit 4 y 5 salidas para el teclado, bit 2 apagado control plancha 
	    
	    BCF			OPTION_REG,7 ;Activo las resistencia de elevación
	    
	    MOVLW		B'11110000' ;Solo activamos las resistencias del teclado
	    MOVWF		WPUB	     ;Probar eliminando esta línea y la anterior	    
;Deshabilitamos RB0 ************************	     
	    BCF			INTCON,INTE ;Deshabilitamos las interrupciones por RB0	    
	    
	    BCF			STATUS,RP0	;Banco 0	    
;**********************************************************************	    
ON_PWM	        
;	    	    
	    CALL		T25MS	    ;Elimino rebotes
;	    CALL		T1MS
	    BSF			PORTC,RC2
;	    CALL		T1MS
	    CALL		T25MS	    ;Elimino rebotes
	   
	    BCF			PORTC,RC2
	    
; Acomodo la bandera del RB0
	    BCF			INTCON,INTF ;Bajamos la bandera

; Acomodo la bandera del teclado (ver de cambiar esto último)
	    MOVF		PORTB,W    ;Recordar: se debe leer el puerto B antes de bajar la bandera RBIF
	    BCF			INTCON,RBIF ;Bajamos la bandera antes de dar los permisos

;	    BCF			INTCON,T0IF  ; Bajo la bandera de interrupción del Timer0
	    
;	    GOTO		REGRESA_INT  ; Regreso de la interrupción del RB0
;	    

	    
REGRESA_INT	
	    NOP		;Este nop es porque no permite tener la etiqueta pegada al include
	    include <Recuperacion.inc>    ;Contiene el RETFIE
	    
	    ;END al final del archivo
	    
;****************Subrutina para corregir teclado **********************
CORRECT_TECL
;Caso centena:	    
	    MOVLW	0X0B
	    XORWF	CONT_TEMP_LCD,W
	    BTFSC	STATUS,Z
	    GOTO	CENTENA
	    
;Caso decena:
	    MOVLW	0X0C
	    XORWF	CONT_TEMP_LCD,W
	    BTFSC	STATUS,Z
	    GOTO	DECENA
	    
;Caso unidad:	    
	    MOVLW	0X0D
	    XORWF	CONT_TEMP_LCD,W
	    BTFSC	STATUS,Z
	    GOTO	UNIDAD
	    
;**********************************************************************
;********************************* CENTENA ****************************
CENTENA
	    CLRF	CENTE
	    CLRF	DECE_TEC
	    CLRF	UNID_TEC
	    CLRF	NUMUSU
	    MOVF	CONT_TECL,W
	    MOVWF	CENTE		;Guarde el contenido binario en Cente 
	    MOVLW	.1
	    SUBWF	CENTE,W		;CENTE-1
	    BTFSC	STATUS,C	;Cente es mayor o igual a 2? C: 1 positivo (cente >= 2)    
	    GOTO	CENTEMAY2
	    GOTO	CENTEMEN2
	   
	    
CENTEMAY2
	    MOVLW	0X0D
	    SUBWF	CENTE,W
	    BTFSC	STATUS,Z
	    GOTO	ES0
	    MOVLW	0X02		  ;La centena es mayor o igual a 2  
	    MOVWF	CENTE	
	    MOVLW	.20
	    MOVWF	AUXNUMUSU
	    MOVLW	.10    
CARGO200 
	    ADDWF	NUMUSU,F
	    DECFSZ	AUXNUMUSU,F
	    GOTO	CARGO200   
	    MOVLW	.1
	    RETURN
	    
CENTEMEN2  
	    MOVLW	.1
	    MOVWF	AUXNUMUSU	;La centena es menor a 2
	    SUBWF	CENTE,W
	    BTFSS	STATUS,C	;CENTE = 1?
	    GOTO	CENTE1	   
	    GOTO	ES0			;CENTE = 0 NO HACE NADA
	    
CENTE1    MOVLW	.1
	    MOVWF	CENTE
	    MOVLW	.10
	    MOVWF	AUXNUMUSU   ;cente = a 10
CARGO100 
	    ADDWF	NUMUSU,F    ;Sumo 10
	    DECFSZ	AUXNUMUSU,F 
	    GOTO	CARGO100  
	    MOVLW	.0
	    RETURN
	    
;************************ DECENA **************************************
DECENA    
	    MOVF	CONT_TECL,W
	    MOVWF	DECE_TEC
	    MOVLW	.2
	    SUBWF	CENTE,W
	    BTFSC	STATUS,Z
	    GOTO	CENTEIGUAL2
	    GOTO	CENTEMENOR2
	        
CENTEIGUAL2
	    MOVLW	0X05
	    SUBWF	DECE_TEC,W		;DECE-5
	    BTFSC	STATUS,C	;DECE es mayor o igual a 5? C: 1 positivo (DECE >= 5)
	    
	    GOTO	PONGO5
	    GOTO	MENOR5

CENTEMENOR2	
	    MOVLW	.9
	    SUBWF	DECE_TEC,W		;DECE-9
	    BTFSC	STATUS,C	;DECE ES MAYOR O IGUAL A 9?
	    GOTO	PONGO9
	    GOTO	MENOR9
	    
PONGO5    
	    MOVLW	 0X0D
	    SUBWF	  DECE_TEC,W
	    BTFSC	STATUS,Z
	    GOTO	ES0
	    MOVLW	.5
	    MOVWF	DECE_TEC
	    MOVWF	AUXNUMUSU
	    MOVLW	.10
CARGO50  
	    ADDWF	NUMUSU
	    DECFSZ	AUXNUMUSU,F
	    GOTO	CARGO50
	    MOVLW	.5
	    RETURN
	    
MENOR5    
	    MOVLW	.3
	    SUBWF	DECE_TEC,W
	    BTFSC	STATUS,Z
	    GOTO	PONGO5
	    MOVLW	.4
	    MOVWF	AUXNUMUSU
DECREM    
	    MOVF	AUXNUMUSU,W
	    XORWF	DECE_TEC,W
	    BTFSC	STATUS,Z  ;RESTO DECE Y AUXNUMUSU SI Z=0 DECREAUX0
	    GOTO	NODECRE
	    GOTO	DECREAUX0
	    
DECREAUX0  	  
	    DECF	AUXNUMUSU,F
	    GOTO	DECREM
	    
	    
NODECRE  
	    MOVLW	.4
	    SUBWF	DECE_TEC,W
	    BTFSC	STATUS,Z
	    DECF	AUXNUMUSU,F
	    MOVF	AUXNUMUSU,W
	    MOVWF	DECE_TEC
	    MOVLW	.10
	    INCF	AUXNUMUSU,F
	    MOVF	AUXNUMUSU,W
	    MOVWF	DECE_TEC
	    MOVLW	.10
CARGOMEN5
	    ADDWF	NUMUSU
	    MOVLW	.10
	    DECFSZ	AUXNUMUSU,F
	    GOTO	CARGOMEN5
    	    MOVF	CONT_TECL,W
	    RETURN
PONGO9    
	    MOVLW	 0X0D
	    SUBWF	  DECE_TEC,W
	    BTFSC	STATUS,Z
	    GOTO	ES0
	    MOVLW	.9
	    MOVWF	DECE_TEC
	    MOVWF	AUXNUMUSU
	    MOVLW	.10
CARGO90
	    ADDWF	NUMUSU
	    DECFSZ	AUXNUMUSU,F
	    GOTO	CARGO90
    	    MOVLW	0X0A

	    RETURN
	    
MENOR9
	    MOVLW	.3
	    SUBWF	DECE_TEC,W
	    BTFSC	STATUS,Z
	    GOTO	PONGO9
	    MOVLW	.8
	    MOVWF	AUXNUMUSU
	    
DECR	    
	    MOVF	AUXNUMUSU,W
	    XORWF	DECE_TEC,W
	    BTFSC	STATUS,Z  ;RESTO DECE Y AUXNUMUSU SI Z=0 DECREAUX0
	    GOTO	NODEC
	    GOTO	DECREAUX1
	    
DECREAUX1  
	    DECF	AUXNUMUSU,F
	    GOTO	DECR
  	   
	    
NODEC	    
	    MOVLW	.3
	    SUBWF	DECE_TEC
	    BTFSS	STATUS,C
	    INCF	AUXNUMUSU,F
	    MOVF	AUXNUMUSU,W
	    MOVWF	DECE_TEC
	    MOVLW	.10
CARGOMEN9
	    ADDWF	NUMUSU
	    DECFSZ	AUXNUMUSU,F
	    GOTO	CARGOMEN9
	    MOVF	CONT_TECL,W
	    RETURN
	    
;*********************** UNIDAD ***************************************
UNIDAD
	    MOVF	CONT_TECL,W
	    MOVWF	UNID_TEC
	    MOVLW	.2
	    XORWF	CENTE,W
	    BTFSC	STATUS,Z
	    GOTO	CENTEIG2
	    GOTO	CENTEM2    	    

CENTEIG2 
	    MOVLW	0X05
	    XORWF	DECE_TEC,W		;DECE-5
	    BTFSS	STATUS,Z	;DECE es igual a 5?	    
	    GOTO	DECMENO5   
	    GOTO	DECIGU5
	    
DECIGU5
	    MOVLW	.5		;DECENA igual a 5
	    SUBWF	UNID_TEC,W		;UNID-5
	    BTFSC	STATUS,C	;UNIDAD MAYOR O IGUAL A 5 C = 1
	    GOTO	UNITY5
	    GOTO	UNITYNO5	    
	    
UNITY5
	    MOVLW	0X0D
	    SUBWF	UNID_TEC,W
	    BTFSC	STATUS,Z
	    GOTO	ES0
	    MOVLW	.5
	    MOVWF	UNID_TEC
	    MOVWF	AUXNUMUSU
	    MOVLW	.1
CARGOM5
	    ADDWF	NUMUSU
	    DECFSZ	AUXNUMUSU,F
	    GOTO	CARGOM5
	    MOVLW	.5
	    RETURN
	    
UNITYNO5 
	    MOVLW	.3
	    SUBWF	UNID_TEC,W
	    BTFSC	STATUS,Z
	    GOTO	UNITY5
	    	    
CARGM4	    
	    MOVLW	.3
	    SUBWF	UNID_TEC,W
	    BTFSS	STATUS,C
	    INCF	UNID_TEC
	    MOVF	UNID_TEC,W
	    MOVWF	AUXNUMUSU
IGUALES4 
	    MOVLW	.1
	    ADDWF	NUMUSU
	    DECF	AUXNUMUSU
	    MOVLW	.0
	    SUBWF	AUXNUMUSU,W
	    BTFSS	STATUS,Z
	    GOTO	IGUALES4
	    MOVF	CONT_TECL,W

	    RETURN
	    
DECMENO5 
	    MOVLW	.9
	    ;MOVWF	AUXNUMUSU
	    SUBWF	UNID_TEC,W ;UNID-W
	    BTFSS	STATUS,C;UNIDAD MAYOR O IGUAL 9 C=1
	    GOTO	CARGM9
	    GOTO	IGUALES9

IGUALES9 
	    MOVLW	0X0D
	    SUBWF	UNID_TEC,W
	    BTFSC	STATUS,Z
	    GOTO	ES0
	    MOVLW	.9
	    MOVWF	AUXNUMUSU
	    MOVWF	UNID_TEC
	    MOVLW	.1	
CARGADE9 
	    ADDWF	NUMUSU
	    DECFSZ	AUXNUMUSU
	    GOTO	CARGADE9
	    MOVLW	0X0A
    
	    RETURN  
    
CARGM9
	    MOVLW	.3
	    SUBWF	UNID_TEC,W
	    BTFSC	STATUS,Z
	    GOTO	IGUALES9
	    MOVLW	.9
	    MOVWF	AUXNUMUSU
PREG	    MOVF	AUXNUMUSU,W
	    XORWF	UNID_TEC,W;SUBWF	UNID_TEC
	    BTFSS	STATUS,Z;C=1?
	    GOTO	DECREMEAUX
	    GOTO    	YAESTA
	    
	    
DECREMEAUX  
	    DECF	AUXNUMUSU,F
	    GOTO	PREG	
	    	           
YAESTA    
	    MOVLW	.3
	    SUBWF	UNID_TEC,W
	    BTFSS	STATUS,C
	    INCF	UNID_TEC
	    MOVF	UNID_TEC,W
	    MOVWF	AUXNUMUSU
NOES0	     MOVLW	.1
	    ADDWF	NUMUSU,F
	    DECFSZ	AUXNUMUSU
	    GOTO	NOES0
    	    MOVF	CONT_TECL,W

	    RETURN
CENTEM2
	    GOTO	DECMENO5

ES0	    
	    MOVLW   .13
	    RETURN
	    
;*********************** END ****************************************
	    
;**************** Subrutinas de Binario a Decimal *********************
	    include <BinToDecimal.inc>	    
;******* Subrutina para imprimir, primero sumamos 30 para pasarlo ASCII ********
	    include <PrintASCII.inc>
;*********************** Subrutinas de Tiempo *************************
	    include <SubrutinasTiempo.inc>    
;*********************** Subrutinas de Funciones LCD ******************	    
	    include <FuncionesLCD.inc>
	    
	    END

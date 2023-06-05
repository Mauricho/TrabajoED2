; Consigna:
; Debe tener conectado un teclado matricial de 4x4 en el puerto B, cuando se apriete cualquier
; tecla deberá interrumpir y desplegar en la LCD (conectada al puerto C) 
; el número de la tecla que se está apretando (en hexadecimal)
; En el programa principal estará de forma permanente el contador de 00 a 99
; por los displays de 7 segmentos.
; La LCD llevará un conteo con espacios de tiempo de 0.5 segundos creado por Timer 0.
; Las cadenas de la LCD serán:
; "Contador:       "
; "Tecla:          "
	    
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
	    
	    SIETESEGK		;Tabla para display 7 seg cátodo común
;	    SIETESEGA		;Tabla para display 7 seg ánodo común
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
	
	    CLRF 		ANSEL
	    CLRF		ANSELH
	
	    BCF			STATUS,RP1  ;Bank1
	    
	    MOVLW		0XF0
	    MOVWF		TRISB	     ;Debo modificar antes al TRISB que las resistencia de elevación 
	    
	    CLRF		TRISC	     ;PuertoC=Salida
	    CLRF		TRISD
	    BCF			TRISA,0
	    BCF			TRISA,1
	    
;   Configuramos el Timer0 con Option_Reg
	    MOVLW		B'01010101' ;Activo RBPU, RB0/INT flancos de subida, TMR0 cuenta ciclos de máquina, flancos de bajada, prescaler: 1:64 
	    MOVWF		OPTION_REG
	    
	    COMF		IOCB,F	     ; Habilitamos todos los pines del puerto B como fuente de interrupción 
	    
	    BCF			STATUS,RP0  ;Bank0
	    
	    include<Imprime32CaractLCD.inc>	    
	    
	    CLRF		CONT_T0		; Limpiamos el registro
	    
; Como debemos contar 2500 eventos, dividimos en 2 y eso lo hacemos 5 veces.
; El número deseado es 250 => TMR0 = 256 - numDeseado	    
	    MOVLW		.131	      ; Timer cuenta a 125 * 64 prescaler = 8000
	    MOVWF		TMR0	      ; 256-125=131, el número que nosotros queremos es 125!
	    
	    MOVLW		.62	      ;Lo cambie para que sean 500000 de ciclos
	    MOVWF		CONT5	      ;Contador cargado con 125
	
; Necesitamos guardar el valor de los puertos
	    MOVF		PORTB,W
	    
;   Damos los permisos de interrupción	    	    
;   Recordar: se debe leer el puerto B antes de bajar la bandera RBIF
	    BCF			INTCON,RBIF ;Bajamos la bandera antes de dar los permisos
	    BSF			INTCON,RBIE ;Habilitamos las interrupciones por el puertoB
	    
	    BCF			INTCON,T0IF ;Bajamos la bandera de TMR0 antes de dar los permisos
	    BSF			INTCON,T0IE ;Habilitamos las interrupciones por TMR0
	    
	    BSF			INTCON,GIE  ;Habilitamos las interrupciones globales
	    
;***********************Programa Principal*****************************    
	    GOTO		    $
	    
;*******************Rutina Servicio Interrupción***********************    
RSI	    BTFSS		INTCON,T0IF
	    GOTO		FUE_INT_CH    ;Solución por interrupcion en RB0
	    
	    DECFSZ		CONT5,F
	    GOTO		BAJA_BANDERA
	    
	    MOVLW		.62
	    MOVWF		CONT5
	    
	    INCF		CONT_T0	    
	    
	    MOVF		CONT_T0	,W	    
	    MOVWF		DECIMAL	    ;Pasamos ALEA a DECIMAL
	    
	    CALL		BIN_A_DEC   
	    
	    MOVLW		0X0D	    ;Donde queremos imprimir se lo pasamos al registro DIR_LCD
	    MOVWF		DIR_LCD
	    
	    CALL		IMPRIM_NUM	      
	    
;   Acomodo de nuevo la bandera
BAJA_BANDERA	    MOVLW		.131	      ; Timer cuenta a 125 * 264 prescaler = 8000
		    MOVWF		TMR0	      ; 256-250=6, el número que nosotros queremos es 250!
	    
		    BCF			INTCON,T0IF  ; Bajo la bandera de interrupción del Timer0
	    
		    GOTO		REGRESA_INT  ; Regreso de la interrupción
	    
; Lo aleatorio esta en que se mantiene el botón y la variable ale se decrementa	
; El contador ALEA es independiente de los otros contadores y me sirve para que se 
; genere un número aleatorio mientras se aprieta el botón
	    
FUE_INT_CH CLRF		TRISA	    ;Se apagan los displays
		    
	    CALL		T25MS	    ;Elimino rebotes
	    
	    MOVLW		0XF0
	    ANDWF		PORTB,W
	    MOVWF		TECLADO4X4  ;Guardo la parte alta de B
	    
	    SWAPF		TECLADO4X4,F ;Lo guardo en la parte baja de la variable
	    
	    BSF			STATUS,RP0  ;Banco1
	    
	    MOVLW		0XF0	    ;Estoy definiendo cual es salida y entrada al apretar el botón. 
	    MOVWF		TRISD	    ;La parte alta es salida y la parte baja entrada. 
					    ;Los pines 7 6 5 4 sacan 0 y el resto es entrada
					    
	    CLRF		TRISB	       ;Todos los pines son salida
	    BCF			OPTION_REG,7 ;Activo las resistencia de elevación
	    			    
	    BCF			STATUS,RP0   ;Banco0
	    
;	    CLRF		PORTB
;	    CLRF		PORTD

	    MOVLW		0XF0
	    MOVWF		PORTB		;Coloco en 1 el puerto B para que le llegue al D
	    ANDWF		PORTD,W
   
	    ADDWF		TECLADO4X4,F ;Valores concatenados para buscar en la tabla
	    
	    CLRF		CONT_TECL
	    
BUSCA_TECLA MOVF		CONT_TECL,W
	    CALL		TABLA_TECL
	    XORWF		TECLADO4X4,W
	    
	    BTFSC		STATUS,Z  ;Lo hacemos para que recorra todas las teclas y encuentre algún resultado
	    GOTO		DIRECC_IMPR
	    INCF		CONT_TECL,F
	    MOVLW		.16
	    
	    XORWF		CONT_TECL,W  
	    BTFSS		STATUS,Z
	    GOTO		BUSCA_TECLA
	    MOVLW		.16
	    MOVWF		CONT_TECL
	    
DIRECC_IMPR	    
	    MOVLW		0X4F	    ;Donde queremos imprimir se lo pasamos al registro DIR_LCD
	    MOVWF		DIR_LCD
	    CALL		DIRECCION_DDRAM
	    
	    MOVF		CONT_TECL,W	; Pasamos lo que encontramos a W
	    CALL		TABLA_HEX_ASCII
	    CALL		CARACTER
	    
	    MOVLW		0X00
	    XORWF		PORTD,W
	    BTFSS		STATUS,Z
	    GOTO		$-3	    ;De esta forma evito que entre permanentemente al caso prohibido de forma permanente
					    ;NO queda permanentemente interrumpido
	    
	    CALL		T25MS	    ;Elimino rebotes
	    
	    BSF			STATUS,RP0  ;Banco1
	         
	    MOVLW		0XF0
	    MOVWF		TRISB
	    
	    CLRF		TRISD	       ;Todos los pines sacan 0
	    
	    BCF			OPTION_REG,7 ;Activo las resistencia de elevación
	    
;	    CLRF		TRISD	       ;Todos los pines sacan 0
;	   
;	    MOVLW		0XF0
;	    
;	    MOVWF		TRISB
;	    BCF			OPTION_REG,7 ;Activo las resistencia de elevación
	    
	    BCF			STATUS,RP0   ;Banco0
	    
	    CLRF		PORTD		;Creo q se puede sacar
	    
;   Recordar: se debe leer el puerto B antes de bajar la bandera RBIF	    
	    MOVF		PORTB,W    
	    BCF			INTCON,RBIF ;Bajamos la bandera antes de dar los permisos
	    
REGRESA_INT	
	    NOP		;Este nop en porque no permite tener la etiqueta pegada al include
	    include <Recuperacion.inc>    ;Contiene el RETFIE
	    
	    ;END al final del archivo

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
	    
; Le indicamos a partir de que dirección empiezo a imprimir
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
	    
	    END
; Consigna:
; Debe tener conectado un teclado matricial de 4x4 en el puerto B, cuando se apriete cualquier
; tecla deberá interrumpir y desplegar en la LCD (conectada al puerto C) 
; el número de la tecla que se está apretando (en hexadecimal)
; Las cadenas de la LCD serán:
; "Temp. max: xxx°C"
; "Temp.:        °C"
	    
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
	
	    CLRF		ANSELH
	    
	    BCF			STATUS,RP1  ;Bank1
	    
	    MOVLW		0XF0
	    MOVWF		TRISB	     ;"Debo modificar antes al TRISB que las resistencia de elevación" 
	    
	    CLRF		TRISC	     ;PuertoC=Salida
	   
	    BCF			OPTION_REG,7	;Habilitamos resistencias pull-up  
	    COMF		IOCB,F	     ; Habilitamos todos los pines del puerto B como fuente de interrupción 
	    
	    BCF			STATUS,RP0  ;Bank0
	    
	    MOVLW		0X0D		;La primera dirección donde se muestra el numero es la LCD es 0x0D    
	    MOVWF		CONT_TEMP_LCD	;Cargo el contador para mostrar en la LCD en las posiciones indicadas: 0X0B 0X0C 0X0D
	    
	    include<Imprime32CaractLCD.inc>	    
	    
; Necesitamos guardar el valor de los puertos
	    MOVF		PORTB,W		;Estamos leyendo el puerto
	  
;   Damos los permisos de interrupción	    	    
;   Recordar: se debe leer el puerto B antes de bajar la bandera RBIF
	    BCF			INTCON,RBIF ;Bajamos la bandera antes de dar los permisos
	    BSF			INTCON,RBIE ;Habilitamos las interrupciones por el puertoB
	    
	    BSF			INTCON,GIE  ;Habilitamos las interrupciones globales
	    
;***********************Programa Principal*****************************    
	    GOTO		    $	     ;El programa principal no esta haciendo nada por el momento
;*******************Rutina Servicio Interrupción***********************    
RSI	    
	    CALL		T25MS	    ;Elimino rebotes
	    
	    MOVLW		0XF0
	    ANDWF		PORTB,W
	    MOVWF		TECLADO4X4
	    
	    BSF			STATUS,RP0  ;Banco1
	    
	    MOVLW		0X0F
	    
	    MOVWF		TRISB
	    BCF			OPTION_REG,7 ;Activo las resistencia de elevación
	    
	    BCF			STATUS,RP0   ;Banco0
	    
	    CLRF		PORTB
	    
	    MOVLW		0X0F		
	    ANDWF		PORTB,W
	    
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
	    MOVF		CONT_TEMP_LCD,W	;Movemos el contenido cont-temp-lcd a W, es la dirección a mostrar en la LCD
	    MOVWF		DIR_LCD
	    CALL		DIRECCION_DDRAM
	    
	    MOVF		CONT_TECL,W	;Pasamos lo que encontramos a W 
	    CALL		TABLA_HEX_ASCII
	    CALL		CARACTER
	    
	    MOVLW		0X0F
	    XORWF		PORTB,W
	    BTFSS		STATUS,Z
	    GOTO		$-3	    ;De esta forma evito que entre permanentemente al caso prohibido de forma permanente
					    ;NO queda permanentemente interrumpido
					    
	    CALL		T25MS	    ;Elimino rebotes
	    
	    BSF			STATUS,RP0  ;Banco1
	    
	    MOVLW		0XF0
	    
	    MOVWF		TRISB
	    BCF			OPTION_REG,7 ;Activo las resistencia de elevación
	    
	    BCF			STATUS,RP0   ;Banco0
	    
	    DECF		CONT_TEMP_LCD,F ;Incrementamos el registro para que imprima en la próxima dirección
	    MOVLW		0X0A		  ;Si el resultado llego a 0x0A lo volvemos a cargar con 0x0D
	    XORWF		CONT_TEMP_LCD,W
	    BTFSS		STATUS,Z
	    GOTO		IMP_NEXT_DIR	    ;Imprimimos en la próxima dirección de la LCD
	    
	    MOVLW		0X0D		
	    MOVWF		CONT_TEMP_LCD	;Cargo el contador para mostrar en la LCD en las posiciones indicadas: 0X0B 0X0C 0X0D
	    
IMP_NEXT_DIR	    
	    MOVF		PORTB,W    
	    BCF			INTCON,RBIF ;Bajamos la bandera antes de dar los permisos
	    
REGRESA_INT	
	    NOP		;Este nop es porque no permite tener la etiqueta pegada al include
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
; Macro para llamar a la subrutinas de tiempo de una variable:
SUBT1V	MACRO	VAR1
	MOVLW	VAR1
	MOVWF	0X60
	CALL	ST1V
	ENDM
	
; Macro para llamar a la subrutinas de tiempo de dos variables:
SUBT2V  MACRO	VAR1,VAR2
	MOVLW	VAR2
	MOVWF	0X61
	MOVLW	VAR1
	MOVWF	0X62
	CALL	ST2V
        ENDM
	
; Macro para llamar a la subrutinas de tiempo de tres variabes:
SUBT3V  MACRO	VAR1,VAR2,VAR3
	MOVLW	VAR3
	MOVWF	0X64
        MOVLW	VAR2
	MOVWF	0X65
        MOVLW	VAR1
        MOVWF	0X66
        CALL	ST3V
	ENDM
	
; Macro para corregir los rebotes en la entrada de los puertos
PUSH_ANTIR  MACRO   PUERTO,PIN
	    BTFSS   PUERTO,PIN
	    GOTO    $-1
	    CALL    T25MS	;Si detecta 1 espera 25mS, tenemos en cuenta este ciclo
	    BTFSC   PUERTO,PIN
	    GOTO    $-1   
	    CALL    T25MS       ;Si detecta 0 espera 25mS, tenemos en cuenta este ciclo
	    ENDM	 
	    
; Macro para llamar a la subrutinas de tiempo de 25 mS:
SUBT25MS	MACRO
T25MS		SUBT3V	.3,.47,.25
		RETURN
		ENDM	

; Macro para display 7 segmentos cátodo común (enciende con unos)
SIETESEGK   MACRO
SIETESEG    ADDWF   PCL,F
	     DT 0X3F,0X06,0X5B,0X4F,0X66,0X6D,0X7D,0X07,0X7F,0X6F,0X77,0X7C,0X39,0X5E,0X79,0X71
	     ENDM
	    
; Macro para display 7 segmentos ánodo común (enciende con ceros)
SIETESEGA   MACRO
SIETESEG    ADDWF   PCL,F
	     DT 0XC0,0XF9,0XA4,0XB0,0X99,0X92,0X82,0XF8,0X80,0X98,0X88,0X83,0XC6,0XA1,0X86,0X8E
	     ENDM

; Macro para animaciones en matriz 8x8
LLAM_ANIM   MACRO		ETIQ,REPETICIONES,NUMERO_ANIM 
	    MOVLW		REPETICIONES	;Cada repetición dura 1/60 [S]
	    MOVWF		REPET
ETIQ	    MOVLW		8*NUMERO_ANIM   ;Despues del 8 se escribe el número de animación
	    MOVWF		NUM_ANIM
	    CALL		ANIMACION
	    
	    DECFSZ		REPET,F
	    GOTO		ETIQ	    
	    ENDM
	    
; Macro para LCD
LCD_MACRO   MACRO
TABLA_LCD   ADDWF   PCL,F
;	    DT "El numero       "
;	    DT "aleatorio es:   "
	    DT "Contador:       "
;	    DT "Cambio el pin:  "  	    
;	    DT "Contador:       "
	    DT "Tecla:		  "	   
   ENDM	    
   
; Macro para el teclado matricial 4x4   
TABLATECL   MACRO
TABLA_TECL  ADDWF   PCL,F
;	     DT 0XEE,0XDE,0XBE,0X7E,0XED,0XDD,0XBD,0X7D,0XEB,0XDB,0XBB,0X7B,0XE7,0XD7,0XB7,0X77
	     DT 0X1E,0X2E,0X4E,0X8E,0X1D,0X2D,0X4D,0X8D,0X1B,0X2B,0X4B,0X8B,0X17,0X27,0X47,0X87	
	     ENDM
	     
; Macro para la tabla de Hexa a ASCII  
TABLA_H_A	    MACRO	     
TABLA_HEX_ASCII   ADDWF PCL,F
		    DT	"0123456789ABCDEF@"
		    ENDM
	    
		    
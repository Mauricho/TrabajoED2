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
		
; Macro para llamar a la subrutinas de tiempo de 20 mS:
SUBT20MS	MACRO
T20MS		SUBT2V	.14,.196
		RETURN
		ENDM
	    
; Macro para LCD
LCD_MACRO   MACRO
TABLA_LCD   ADDWF   PCL,F
;	    DT "El numero       "
;	    DT "aleatorio es:   "
;	    DT "Contador:       "
;   	    DT "    Vi:       mV"
;	    DT "Cambio el pin:  "  	    
;	    DT "Contador:       "
;	    DT "Tec:  T=   .  "
	    DT	"Temp. max:    "
	    RETLW   0XDF ; Símbolo '°'
	    RETLW   'C'
	    DT  "Temp.:        "
	    RETLW   0XDF ; Símbolo '°'
	    RETLW   'C'
   ENDM	    
   
; Macro para el teclado matricial 4x4   
TABLATECL   MACRO
TABLA_TECL  ADDWF   PCL,F
	     DT 0XEE,0XDE,0XBE,0X7E,0XED,0XDD,0XBD,0X7D,0XEB,0XDB,0XBB,0X7B,0XE7,0XD7,0XB7,0X77
	     ENDM
	     
; Macro para la tabla de Hexa a ASCII  
TABLA_H_A	    MACRO	     
TABLA_HEX_ASCII   ADDWF PCL,F
		    DT	"0123456789ABCDEF@"
		    ENDM
	    
		    
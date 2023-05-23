	    CALL		SALUDO	    ;Inicialización del LCD
	    
	    CLRF		0X20
T1	    MOVF		0X20,W
	    
	    CALL		TABLA_LCD   ;Regreso con el valor en W
	    
	    CALL		CARACTER    ;Escribo el caracter
	    
	    INCF		0X20,F
	    
	    MOVLW		.16
	    XORWF		0X20,W
	    BTFSS		STATUS,Z
	    GOTO		T1
	    
	    MOVLW		0X40		    ;Cambio de dirección para escribir en el segundo renglón
	    CALL		DIRECCION_DDRAM

	    MOVLW		.16
	    MOVWF		0X20
T2	    MOVF		0X20,W
	    
	    CALL		TABLA_LCD   ;Regreso con el valor en W
	    
	    CALL		CARACTER    ;Escribo el caracter
	    
	    INCF		0X20,F
	    
	    MOVLW		.32
	    XORWF		0X20,W
	    BTFSS		STATUS,Z
	    GOTO		T2
	    
	    CALL		LCD_ON	    ;Escribo en la LCD


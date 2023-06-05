PUERTO	    EQU		    PORTC
;		    PUERTO	    EQU		    PORTB
		    
;   Subrutina de saludo del LCD, es la inicialización
SALUDO		    SUBT2V	    .61,.232	;Dejo pasar 100[mS]
		    CALL	    MINISALUDO
		    CALL	    MINISALUDO
		    CALL	    MINISALUDO

		    MOVLW	    B'00000010'
		    MOVWF	    PUERTO

		    CALL	    ACTIVA_E	;Habilito y deshabilito el LCD (PULSO)
		    CALL	    FUNCTION_SET		    
		    CALL	    LCD_OFF		    
		    CALL	    LIMPIA_LCD		 
		    
		    CALL	    ENTRY_MODE

		    RETURN
	    
;   Subrutina que se repite 3 veces en la inicialización del LCD	    
MINISALUDO	    MOVLW	    B'00000011'
		    MOVWF	    PUERTO
		    CALL	    ACTIVA_E	;Habilito y deshabilito el LCD (PULSO)
		    SUBT2V	    .4,.156	;Dejo pasar 5[mS]	
		    RETURN
	    
;   Subrutina que da un "pulso" para habilitar y deshabilitar el LCD
ACTIVA_E	    E_1				;Habilito el LCD	
		    NOP
		    NOP
		    NOP
		    NOP
		    E_0				;Deshabilito el LCD
		    SUBT2V	    .35,.8	;Dejo pasar 2[mS]
		    RETURN
		    
;   Subrutina para la función_set  	    
FUNCTION_SET	    MOVLW	    B'00101000'	;4 bits, 2 renglones, 5x7 pixeles
		    GOTO	    ESCRIBE	

;   Subrutina para lcd_off  	    
LCD_OFF		    MOVLW	    B'00001000'
		    GOTO	    ESCRIBE
		    
;   Subrutina para lcd_on  	    
LCD_ON		    MOVLW	    B'00001100'
		    GOTO	    ESCRIBE

;   Subrutina para lcd_on_c activa el cursor  	    
LCD_ON_C	    MOVLW	    B'00001110'
		    GOTO	    ESCRIBE

;   Subrutina para lcd_on_c_p activa el cursor con parpadeo	    
LCD_ON_C_P	    MOVLW	    B'00001111'
		    GOTO	    ESCRIBE
		    
;   Subrutina para limpia_lcd
LIMPIA_LCD	    MOVLW	    B'00000001'
		    GOTO	    ESCRIBE
		    
;   Subrutina para limpia_lcd		    
ENTRY_MODE	    MOVLW	    B'00000110'	;No desplaza información al escribir, apuntador con incremento
		    GOTO	    ESCRIBE

;   Subrutina retornar a casa		    
HOME		    MOVLW	    B'00000010'
		    GOTO	    ESCRIBE
		    
;   Subrutina para recorrer la información de la pantalla a la derecha		    
RECORRE_DER_LCD	    MOVLW	    B'00011100'
		    GOTO	    ESCRIBE		    

;   Subrutina para recorrer la información de la pantalla a la izquierda		    
RECORRE_IZQ_LCD	    MOVLW	    B'00011000'
		    GOTO	    ESCRIBE

;   Subrutina para recorrer el cursor a la derecha 		    
RECORRE_DER_CUR	    MOVLW	    B'00010100'
		    GOTO	    ESCRIBE
		    
;   Subrutina para recorrer el cursor a la izquierda		    
RECORRE_IZQ_CUR	    MOVLW	    B'00010000'
		    GOTO	    ESCRIBE
		    
;   Subrutina para cargar una dirección		    
DIRECCION_DDRAM	    IORLW	    B'10000000'
		    GOTO	    ESCRIBE

;   Subrutina que escribe un caracter
CARACTER	    MOVWF	    DATO
		    SWAPF	    DATO,W	;Hago swap para sacar primero la parte alta y luego la parte baja
		    ANDLW	    B'00001111'	;De esta forma solo toco la parte baja y no molesto la alta del PB que maneja el LCD
		    MOVWF	    PUERTO	
		    
		    RS_1			;Activo RS, para indicar que debo escribir en memoria
		    CALL	    ACTIVA_E	;Habilito y deshabilito el LCD (PULSO)
		    
		    MOVF	    DATO,W	;No hago swap ya que necesito la parte baja del DATO
		    ANDLW	    B'00001111'	;De esta forma solo toco la parte baja y no molesto la alta del PB que maneja el LCD
		    MOVWF	    PUERTO
		    
		    RS_1			;Activo RS, para indicar que debo escribir en memoria
		    CALL	    ACTIVA_E	;Habilito y deshabilito el LCD (PULSO)
		    RETURN    		    
		    
;   Rutina para escribir un dato en el LCD, se ejecuta para cada función		    
ESCRIBE		    MOVWF	    DATO
		    SWAPF	    DATO,W	;Hago swap para sacar primero la parte alta y luego la parte baja
		    ANDLW	    B'00001111'	;De esta forma solo toco la parte baja y no molesto la alta del PB que maneja el LCD
		    MOVWF	    PUERTO	
		    CALL	    ACTIVA_E	;Habilito y deshabilito el LCD (PULSO)
		    
		    MOVF	    DATO,W	;No hago swap ya que necesito la parte baja del DATO
		    ANDLW	    B'00001111'	;De esta forma solo toco la parte baja y no molesto la alta del PB que maneja el LCD
		    MOVWF	    PUERTO
		    CALL	    ACTIVA_E	;Habilito y deshabilito el LCD (PULSO)
		    RETURN
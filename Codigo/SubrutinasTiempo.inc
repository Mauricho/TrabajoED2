;   Subrutina de tiempo de una (1) variable
ST1V	NOP
	NOP
	NOP
        NOP
        DECFSZ 0X60,F
        GOTO ST1V
        RETURN

;   Subrutina de tiempo de dos (2) variables
ST2V	    MOVF 0X62,W
            MOVWF 0X63
DECRE2V	    NOP
            NOP
            NOP
            NOP	
	    DECFSZ 0X63,F
            GOTO DECRE2V
            DECFSZ 0X61,F
            GOTO ST2V
            RETURN
	        
;   Subrutina de tiempo de tres (3) variables
ST3V	    MOVF 0X66,W
	    MOVWF 0X67
RECARGA3V   MOVF 0X65,W
	    MOVWF 0X68
DECRE3V	    NOP
	    NOP
	    NOP
	    NOP
	    DECFSZ 0X68,F
	    GOTO DECRE3V
	    DECFSZ 0X67,F
            GOTO RECARGA3V
            DECFSZ 0X64,F
            GOTO ST3V
            RETURN

;   Subrutina de tiempo de 30 Segundos
T30S	    SUBT3V  .96,.211,.211
	    RETURN
	    
;   Subrutina de tiempo de 600 Milisegundos
T600MS	    SUBT3V  .247,.49,.7
	    RETURN

;   Subrutina de tiempo de 1/120 [S]
T120AVO	    SUBT2V  .7,.157	 
	    RETURN
	    
; Subrutinas de tiempo de 4 mS:
T4MS		SUBT2V	.142,.4
		NOP
		RETURN

; Subrutinas de tiempo de 2 mS:
T2MS		SUBT2V	.35,.8
		NOP
		RETURN
		
; Subrutinas de tiempo de 1 mS:
T1MS		SUBT1V	.142
		NOP
		RETURN
		
		
	    SUBT25MS    ;Se agrega porque el programa la llama mediante una macro que utiliza T25MS
			; entonces aquí llamamos a la macro que implementa el T25MS
	    SUBT20MS
	    
	    SUBT100MS
	    
	    SUBT80MS
		
; Subrutinas de tiempo de 0.5 mS = 500 uS:
;T500US		SUBT2V	.17,.4
;		NOP
;		RETURN

;;   Subrutina de tiempo de 6 milisegundos
;T6MS	    SUBT1V  .85
;	    RETURN
	    
;;   Subrutina de tiempo de 20 microsegundos
;T20US	    SUBT1V  .2
;	    NOP
;	    RETURN
	    
	    



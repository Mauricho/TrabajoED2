;		  Recupero los datos sobre las subrutinas de tiempo			    

    MOVF    0X75,W
    MOVWF   0X60
    MOVF    0X76,W
    MOVWF   0X61
    MOVF    0X77,W
    MOVWF   0X62
    MOVF    0X78,W
    MOVWF   0X63
    MOVF    0X79,W
    MOVWF   0X64
    MOVF    0X7A,W
    MOVWF   0X65
    MOVF    0X7B,W
    MOVWF   0X66
    MOVF    0X7C,W
    MOVWF   0X67
    MOVF    0X7D,W
    MOVWF   0X68
    
;		   Recupero W en W_R, STATUS en ST_R, PCLATH en PC_R
    MOVF    PC_R,W	    
    MOVWF   PCLATH	    ;Recupero PCLATH
    SWAPF   ST_R,W	    ;Swap STATUS para no cambiarlo y dejarlo como estaba
    MOVWF   STATUS	    ;Recupero el STATUS	    
    SWAPF   W_R,F	    ;Se hace swap ya que MOVF me cambia el STATUS 
    SWAPF   W_R,W      	    ;Recupero W como estaba
    
    RETFIE		    ;El archivo INCLUYE EL RETORNO DE INTERRUPCIÓN

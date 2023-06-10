;   Rescasto W en W_R, STATUS en ST_R, PCLATH en PC_R
    CBLOCK	0X70
	    W_R, ST_R, PC_R
    ENDC
    
    MOVWF   W_R		    ;Guardo W
    SWAPF   STATUS,W	    ;Swap STATUS para no cambiarlo
    MOVWF   ST_R	    ;Guardo el STATUS	    
    CLRF    STATUS	    ;Limpio el STATUS
    MOVF    PCLATH,W	    
    MOVWF   PC_R	    ;Guardo el PCLATH
    
;		  Rescato los datos sobre las subrutinas de tiempo			    
    MOVF    0X60,W
    MOVWF   0X75
    MOVF    0X61,W
    MOVWF   0X76
    MOVF    0X62,W
    MOVWF   0X77
    MOVF    0X63,W
    MOVWF   0X78
    MOVF    0X64,W
    MOVWF   0X79
    MOVF    0X65,W
    MOVWF   0X7A
    MOVF    0X66,W
    MOVWF   0X7B
    MOVF    0X67,W
    MOVWF   0X7C
    MOVF    0X68,W
    MOVWF   0X7D
	



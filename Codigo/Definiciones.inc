; Son definiciones para el manejo del LCD con el puerto B
PUERTO		EQU		    PORTC
	
    #DEFINE	RS_0	    BCF	    PUERTO,4	    ;RS en 0
    #DEFINE	RS_1	    BSF	    PUERTO,4	    ;RS en 1
    #DEFINE	E_0	    BCF	    PUERTO,5	    ;E en 0
    #DEFINE	E_1	    BSF	    PUERTO,5	    ;E en 1

; Lo utilizo para la LCD	    
UNID_L	    EQU	    0X25
DECE_L	    EQU	    0x26
CENT_L	    EQU	    0x27
DATO	    EQU	    0X2A

; Contador para llegar a 2500 eventos
CONT5	    EQU	    0X23
	
; Lo utilizo para guardar ALE en la subrutina de binario a decimal
DECIMAL	    EQU	    0X29

; Lo utilizo para indicar la dirección de la pantalla donde se va a imprimir
DIR_LCD	    EQU	    0X2B
	    
; Guardo el estado del puerto B al detectar una interrupción
ESTADO_PB   EQU	0X2C
   
; Lo utilizo para hacer el caso prohibido en los bits del puerto B que interrumpen
EST_NU_PB   EQU	0X2D
   
; Lo utilizamos para el teclado 4x4 para guardar el valor que se presiono
TECLADO4X4  EQU	0X2E
  
; Lo utilizamos para el teclado 4x4 como contador, para recorrer todos los valores de la tabla
CONT_TECL   EQU	0X2F

; Variable que nos permite ir recorriendo las distintas posiciones del LCD para mostrar el valor seteado
CONT_TEMP_LCD	EQU	0X28 ; Empiezo en 0x0D y lo hago hasta 0x0A

; Variable para mostrar numero en LCD posicion 0x0D
LCD_0D	EQU 0x21
	
; Variable para mostrar numero en LCD posicion 0x0C
LCD_0C	EQU 0X22

; Variable para mostrar numero en LCD posicion 0x0B
LCD_0B	EQU 0X24	
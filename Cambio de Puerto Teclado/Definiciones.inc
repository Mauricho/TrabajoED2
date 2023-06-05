; Son definiciones para el manejo de los displays 7 segmento
    #DEFINE	UNID_E	    BSF	    PORTA,0
    #DEFINE	UNID_A	    BCF	    PORTA,0
    #DEFINE	DECE_E	    BSF	    PORTA,1
    #DEFINE	DECE_A	    BCF	    PORTA,1
	    
; Son definiciones para el manejo del LCD con el puerto B
PUERTO		EQU		    PORTC
	
    #DEFINE	RS_0	    BCF	    PUERTO,4	    ;RS en 0
    #DEFINE	RS_1	    BSF	    PUERTO,4	    ;RS en 1
    #DEFINE	E_0	    BCF	    PUERTO,5	    ;E en 0
    #DEFINE	E_1	    BSF	    PUERTO,5	    ;E en 1
    
; Lo utilizo para los displays de 7 segmento	    
UNID	    EQU	    0X20
DECE	    EQU	    0X21
CONT60	    EQU	    0X22

; Lo utilizo para la LCD	    
UNID_L	    EQU	    0X25
DECE_L	    EQU	    0x26
CENT_L	    EQU	    0x27
DATO	    EQU	    0X2A

; Contador para llegar a 2500 eventos
CONT5	    EQU	    0X23

; Contador para los números aleatorios
ALEA	    EQU	    0X24

; Contador para el Timer 0
CONT_T0	    EQU	    0X28
	
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
  
; Lo utilizamos para el teclado 4x4 como contador
CONT_TECL   EQU	0X2F
  
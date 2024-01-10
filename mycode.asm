include 'emu8086.inc'
org 100h  

.data segment
    a DB 032H,088H,031H,0e0H   ;Represents a 4x4 matrix (a) used for encryption, where each element is a byte.
      DB 043H,05aH,031H,037H
      DB 0f6H,030H,098H,007H
      DB 0a8H,08dH,0a2H,034H        
      
    
    ;The initial Round key   
    
    key DB 0ffH,0ffH,0ffH,0ffH
        DB 0ffH,0ffH,0ffH,0ffH
        DB 0ffH,0ffH,0ffH,0ffH 
        DB 0ffH,0ffH,0ffH,0ffH 
     
     ;New key initialization that will be populated during the key expansion process
        
    newkey  DB 00H,00H,00H,00H
            DB 00H,00H,00H,00H
            DB 00H,00H,00H,00H
            DB 00H,00H,00H,00H  
               
       ;sbox that will be used in subBytes process
       
    sbox DB 063H,07cH,077H,07bH,0f2H,06bH,06fH,0c5H,030H,001H,067H,02bH,0feH,0d7H,0abH,076H
        DB 0caH,082H,0c9H,07dH,0faH,059H,047H,0f0H,0adH,0d4H,0a2H,0afH,09cH,0a4H,072H,0c0H
        DB 0b7H,0fdH,093H,026H,036H,03fH,0f7H,0ccH,034H,0a5H,0e5H,0f1H,071H,0d8H,031H,015H
        DB 004H,0c7H,023H,0c3H,018H,096H,005H,09aH,007H,012H,080H,0e2H,0ebH,027H,0b2H,075H
        DB 009H,083H,02cH,01aH,01bH,06eH,05aH,0a0H,052H,03bH,0d6H,0b3H,029H,0e3H,02fH,084H
        DB 053H,0d1H,000H,0edH,020H,0fcH,0b1H,05bH,06aH,0cbH,0beH,039H,04aH,04cH,058H,0cfH
        DB 0d0H,0efH,0aaH,0fbH,043H,04dH,033H,085H,045H,0f9H,002H,07fH,050H,03cH,09fH,0a8H
        DB 051H,0a3H,040H,08fH,092H,09dH,038H,0f5H,0bcH,0b6H,0daH,021H,010H,0ffH,0f3H,0d2H
        DB 0cdH,00cH,013H,0ecH,05fH,097H,044H,017H,0c4H,0a7H,07eH,03dH,064H,05dH,019H,073H
        DB 060H,081H,04fH,0dcH,022H,02aH,090H,088H,046H,0eeH,0b8H,014H,0deH,05eH,00bH,0dbH
        DB 0e0H,032H,03aH,00aH,049H,006H,024H,05cH,0c2H,0d3H,0acH,062H,091H,095H,0e4H,079H
        DB 0e7H,0c8H,037H,06dH,08dH,0d5H,04eH,0a9H,06cH,056H,0f4H,0eaH,065H,07aH,0aeH,008H
        DB 0baH,078H,025H,02eH,01cH,0a6H,0b4H,0c6H,0e8H,0ddH,074H,01fH,04bH,0bdH,08bH,08aH
        DB 070H,03eH,0b5H,066H,048H,003H,0f6H,00eH,061H,035H,057H,0b9H,086H,0c1H,01dH,09eH
        DB 0e1H,0f8H,098H,011H,069H,0d9H,08eH,094H,09bH,01eH,087H,0e9H,0ceH,055H,028H,0dfH
        DB 08cH,0a1H,089H,00dH,0bfH,0e6H,042H,068H,041H,099H,02dH,00fH,0b0H,054H,0bbH,016H
        
     ;used in MixColumns step (galois matrix)   
    mat DB 2,3,1,1
        DB 1,2,3,1
        DB 1,1,2,3
        DB 3,1,1,2  
     
     ;round constants used in key expansion   
    rcon    DB 01H,02H,04H,08H,10H,20H,40H,80H,1BH,36H
            DB 00H,00H,00H,00H,00H,00H,00H,00H,00H,00H
            DB 00H,00H,00H,00H,00H,00H,00H,00H,00H,00H
            DB 00H,00H,00H,00H,00H,00H,00H,00H,00H,00H    
      
      ;constants used in the algorithm  
    MS1 DB 00FH
    MS2 DB 0F0H
    MS3 DB 00011011B 
    
    roundcount DW 0

.code segment
    MOV BH, 4         ;4 bits are enough per number           
    MOV BL, 4                    
    
    LEA SI, a         ; index of the array           
    LEA DI, mat                  
    
    ;CALL UserInput
    
    CALL Step4                          

Loop1:    
    CALL KeySchedule    
    CALL Step1             
    CALL Step2        
    CALL Step3
    CALL Step4
    INC roundcount
    
    CMP roundcount,9
    JNE Loop1
    
 
    PRINTN
    
    CALL KeySchedule    
    CALL Step1             
    CALL Step2            
    CALL Step4
    
    PRINT "Cipher Text: "
    PRINTN
    CALL PRINT_2D_ARRAY             ;Got from Google 
    PRINTN
ret

 ;User input       

UserInput PROC 
    ;saves values of registers
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH SI
       
    MOV AH,1  ;int 21h intteruppt will be used for input
        
    MOV CL,16 ;counter until = 0
    MOV CH,0  
    MOV SI,0  ;index of array
        
    PRINT "Enter values without pressing enter or space:"
    PRINTN
        
    INPUT:
        INT 21H     ;interrupt for input
        CALL AdjustDigit
        SAL AL,4      ;shift by 4 bits
        Mov BL,AL     
           
        INT 21H
        CALL AdjustDigit
           
        Add AL,BL
        MOV a[SI],AL  ;store result in the array 
        INC SI        ;increment array index
    LOOP INPUT
    
    POP SI
    POP CX
    POP BX
    POP AX
    
    RET    
UserInput ENDP

AdjustDigit Proc
    CMP AL,065   ;compare ascii with 65 if less than
    JL  Digit    ;jump to here                 
    SUB AL,055   ;subtract 55 to get hexa between (A to F) aka (10-15)                 
Digit:
    AND AL,0FH                         
    RET     
AdjustDigit ENDP  


;KEY SCHEDULE
KeySchedule PROC
    PUSH AX    
    PUSH BX
    PUSH CX
    PUSH SI
    PUSH DI                     
    
    ;Step 1: Shift last column of the key to first column 
    ;puts it in new key           
           
           
    MOV AL,key[3]                   
    MOV newkey[12],AL    
    
    MOV AL,key[7]
    MOV newkey[0],AL
        
    MOV AL,key[11]                   
    MOV newkey[4],AL
        
    MOV AL,key[15]                   
    MOV newkey[8],AL     
    
    ;Step 2: SubByte(MACRO) - shifts rows
    ;substitution of bytes with Sbox
    
    MOV CL, BL    ;counter(CL = 4)
    MOV SI, 0                     
    
    ;L1 = LOOP 1
    ;L2

    KeyScheduleL0:                 
       MOV AL,newkey[SI]               
       
       CALL SubByte ;index of byte in sbox array
       
       MOV  AH,sbox[DI] ;get the byte from sub matrix
       MOV  newkey[SI],AH ;update the array with the substitution  

       ADD SI, 4                  
       DEC CL                     
    JNZ KeyScheduleL0 
    
    ;Step 3: XOR         
                    
    MOV DI, roundcount                   
    MOV SI, 0
    MOV CL, BL                   

    KeyScheduleL1:                        
            MOV AL, key[SI]  ;load original key 
            MOV AH, newkey[SI]  ;load newly generated key                     
            XOR AL,AH  ;xor both
            
            MOV AH,rcon[DI] ;load from rounconstant  
            XOR AL,AH   ;xor reslut with rconstannt 
                   
            MOV  newkey[SI],AL  ;store in newkey       

            ADD SI, 4  ;move next column in key
            ADD DI, 10 ;move to next round                
            DEC CL     ;dec counter               
    JNZ KeyScheduleL1  ;continue loop if counter aint zero           
    
    MOV CH,3 ;another counter           
    MOV SI,1 ;second column of key 
    KeyScheduleL2:
            MOV CL, BL   ;load counter value
            KeyScheduleL3:                        
                MOV AL, key[SI] ;load from original key
                MOV AH, newkey[SI-1]  ;load from previously generated key                    
                XOR AL,AH     ;xor both                 
                       
                MOV  newkey[SI],AL  ;store result in newkey       
    
                ADD SI, 4  ;move to next column           
                DEC CL     ;dec counter               
            JNZ KeyScheduleL3  ;cont loop if not zero
            
            SUB SI,15  ;move back to first column
            DEC CH     ;dec counter
    JNZ KeyScheduleL2  ;cont if counter is not zero

    MOV CL,16
    MOV SI,0
    KeyScheduleL4:                        
         MOV AL, newkey[SI] ;load byte from newly key
         MOV key[SI],AL  ;store in original key                               
    
         ADD SI, 1  ;move to next byte in newkey array          
         DEC CL     ;dec counter               
    JNZ KeyScheduleL4  ;cont if not zero
            
    POP DI
    POP SI
    POP CX
    POP BX
    POP AX
    RET
KeySchedule ENDP   


  
  
 ;ENCYRPTION
 ; First Step: SubBytes(MACRO)            
                                
Step1 PROC
   PUSH AX                       
   PUSH CX                        
   PUSH SI                        
   PUSH DI                     
       
   MOV CX, BX                     
   MOV SI, 0
   
   Step1L1:                   ;outer loop         
     MOV CL, BL                   

     Step1L2:                 ;inner loop     
       MOV AL, a[SI]               
       
       CALL SubByte ;gives the index of the byte in sbox array
       
       MOV  AH,sbox[DI] ;get the byte from sub matrix
       MOV  a[SI],AH ;update the array 'a' with the substitution  

       ADD SI, 1 ;move to next element in 'a'                
       DEC CL    ;dec counter              
     JNZ Step1L2 ;cont loop if cl aint zero            
                    
     DEC CH   ;dec ounter loop counter                     
   JNZ Step1L1;cont if ch aint zero             
   
   POP DI                      
   POP SI                      
   POP CX                      
   POP AX                       
    
   RET    
Step1 ENDP

SubByte PROC  
    MOV AH,AL
                                 ;input is Al 
    AND AL,MS1  ;bitwise first 4bits
    AND AH,MS2  ;bitwise last 4 bits
    ROR AH,04   ;rotate bits to the right 4 pos
    
    SAL  AH,4  ;shift by 4 then * 16
    ADD  AL,AH ;AL= AL + AH gives the required index
    MOV  AH,0  ;to copy only AL to DI 
    MOV  DI,AX ;because we can't copy AL to DI directly so we copied AX to DI(both are 16 bits)
    
    RET
SubByte ENDP

;Second Step: ShiftRows(MACRO)   
;#functionality_explanation: the bytes in the last three rows of the State are cyclically
;shifted over different numbers of bytes (offsets)
                                        
Step2 PROC
    PUSH AX                       
    
    MOV AL,a[4] ;second row shift
    
    MOV AH,a[5]
    MOV a[4],AH    
    MOV AH,a[6]
    MOV a[5],AH    
    MOV AH,a[7]
    MOV a[6],AH
        
    MOV a[7],AL
    
    
    MOV AL,a[8] ;third row shift
    MOV AH,a[10]
    MOV a[8],AH        
    MOV a[10],AL
    MOV AL,a[9]                    
    MOV AH,a[11]
    MOV a[9],AH        
    MOV a[11],AL
    
    
    MOV AL,a[15] ;fourth row shift
    
    MOV AH,a[14]
    MOV a[15],AH    
    MOV AH,a[13]
    MOV a[14],AH    
    MOV AH,a[12]
    MOV a[13],AH
        
    MOV a[12],AL
    
    POP AX                       
    RET    
Step2 ENDP
 
;Third Step: Mix Columns MACRO ; 
;#procedure_explanation: transformation(similar to matrix multiplication) operates on the State column-by-column,
;treating each column as a four-term polynomial
Step3 PROC
   PUSH AX                       
   PUSH BX                     
   PUSH CX                       
   PUSH DX                         
   PUSH SI                      
   PUSH DI                      
       
   MOV CX, BX  ;CX=BX (outer loop)
   MOV DI,0    ;matrix 
   MOV SI,0    ;array 'a'

   Step3L1: ;DH=BL (inner loop)
        MOV    DH,BL
        Step3L2:  
             MOV CL, BL                 
             MOV AH,0    ;AH act as XOR Sum

             Step3L3:                       
                   MOV AL, a[SI] ;load byte from array 'a'            
                   MOV DL, mat[DI] ;load value from matrix              
                   
                   CMP DL,1 ;check if value = 1                  
                   JE Cont  ;if yes then
                   
                   CMP DL,2              
                   JE  Two
                   JMP Three                  
                   
                   Two:
                   CALL MixColumn2
                   JMP  Cont   
                   
                   Three:
                   CALL MixColumn3
             
                   Cont:
                   XOR  AH,AL ;xor result with al  
            
                   ADD SI, 4 ;move to next col in array 'a'              
                   ADD DI, 1 ;move to next element                
                   DEC CL    ;dec col counter               
             JNZ Step3L3 ;jump to label @INNER_LOOP if CL!=0
     
             PUSH   AX ;done for the whole AX since stack rules must be 16 bits (we need only AH)
             SUB    SI,16 ;move back to start of row
             DEC    DH    ;dec inner loop counter
        JNZ Step3L2       ;cont if dh is not zero 
        
   
   ;get results from stack into array
   
        MOV   CL, BL;Initialize CL to 4 again to pop 4 values from stack to array again
        ADD   SI,16 ;Last loop you subtract 16, you don't enter this loop again
                    ;Add another 16 to pop from the stack and insert it back
                    ;column with proper order (from bottom to top) 
        ResultLoop:
        POP   AX
        SUB   SI,4
        MOV   a[SI],AH
        DEC   CL
        JNZ   ResultLoop
        
        ADD   SI,1
        SUB   DI,16               
        DEC   CH                       
   JNZ Step3L1      ;=step3, loop1          
   
   POP DI                         
   POP SI                     
   POP DX            
   POP CX                      
   POP BX                         
   POP AX                         
    
   RET    
Step3 ENDP
 
 ; Helper Functions for MixColumns(MACRO) 
MixColumn2 PROC
    CMP     AL, 0  ;cmp al with 0
    JL      isNegative ;jmp if al is -ve
    SAL     AL,1  ;shift al to the left by 1
    JMP     exit1
isNegative:
    SAL     AL,1  ;shift al to the left by 1
    XOR     AL,MS3 ;xor al with ms3    
exit1:    
    RET
MixColumn2 ENDP


MixColumn3 PROC
    MOV     DL,AL
    CALL    MixColumn2
    XOR     AL,DL        
    RET
MixColumn3 ENDP
 
;Fourth step: Add Round Key (MACRO)   
;#procedure_explanation:Round Key is added to the State by a simple bitwise XOR operation.
;Each Round Key consists of Nb words from the key schedule
Step4 PROC
   PUSH AX                     
   PUSH CX                       
   PUSH SI                      
   PUSH DI                     
       
   MOV CX, BX                    
   MOV SI, 0

   Step4L1:                
     MOV CL, BL                

     Step4L2:                   
           MOV AL,a[SI]           
           MOV AH,key[SI]
           XOR AL,AH
           
           MOV  a[SI],AL;updating the array 
    
           ADD SI, 4                  
           DEC CL                    
     JNZ Step4L2             
     
     SUB SI,15               
     DEC CH                      
   JNZ Step4L1                
   
   POP DI                         
   POP SI                        
   POP CX                        
   POP AX                         
    
   RET
Step4 ENDP     

; printing function   
                               
                               
PRINT_2D_ARRAY PROC

   PUSH AX                       
   PUSH CX                     
   PUSH DX                        
   PUSH SI                       
   
   MOV CX, BX                     

   @OUTER_LOOP:               
     MOV CL, BL               

     @INNER_LOOP:                
       MOV AH, 2   ;set output function
       MOV DL, 20H ;ascii code for space            
       INT 21H  ;print a character
                             
       MOV AL, [SI]               
                            
       CALL OUTDEC             

       ADD SI, 1               
       DEC CL                 
     JNZ @INNER_LOOP             
                           
     MOV AH, 2                 
     MOV DL, 0DH ;ascii code for return                
     INT 21H  ;print a character

     MOV DL, 0AH ;ascii code for line feed                
     INT 21H  ;print a character

     DEC CH                     
   JNZ @OUTER_LOOP ;jump to label @OUTER_LOOP if ch!=0
   
   MOV AH, 2 ;set output function
   MOV DL, 0DH               
   INT 21H

   POP SI                     
   POP DX                         
   POP CX                    
   POP AX                         

   RET
PRINT_2D_ARRAY ENDP

OUTDEC PROC
   PUSH BX                        
   PUSH CX                       
   PUSH DX                        
    
   mov cx,2  ;print 2 hex digits (8 bits)
    .print_digit:
        rol al,4  ;move the currently left-most digit into the least significant 4 bits
        mov dl,al
        and dl,0xF  ;the hex digit to be isolated
        add dl,'0'  ;to convert the character
        cmp dl,'9'  
        jbe .ok  ;jmp if less than or equal to 9   
        add dl,7   
    .ok:            
        push ax    
        mov ah,2    
        int 0x21
        pop ax    
        loop .print_digit
        
   POP DX                        
   POP CX                         
   POP BX                         
   ret                     
OUTDEC ENDP
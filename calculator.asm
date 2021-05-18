assume ss:stack, ds:data, cs:code

data segment

    info db 'input the expression: ', 13, 10, '$'
    resultmsg db 13, 10, 'result: $'
    errormsg db 13, 10, 'input not valid, please try again', 13, 10, '$'
    tex db 60 dup('#')         ; text user input
    resultAsscii db 30 dup(?) ; result by asscii code 
    exp dw 20 dup(0)        ; the expression after parased
    result dw 10 dup(0)     ;result
   
data ends

stack segment stack
    dw 129 DUP(?) ;
stack ends

code segment
main proc far
   start:
        ;set cursor
        lea si, tex
        mov ax, data
        mov ds, ax

        lea dx, info
        mov ah, 9
        int 21h
        
        input:
            mov ah, 01h
            int 21h
            
            cmp al, 0dh
            mov byte ptr [si], '#' ; set end sign
            je solve
            
            cmp al, 51h ; exit 
            je exitca
            
            cmp al, 71h
            je exitca
            
            number:
                cmp al, '0'
                jl checksign ; check while char not a number
                
                cmp al, '9'
                jg checksign ; checksign while char not a number

                jmp ouput 


                checksign:
                    cmp al, '+'
                    je ouput
                    
                    cmp al, '-'
                    je ouput
                    
                    cmp al, '*'
                    je ouput

                    cmp al, '/'
                    je ouput
                    jne inputerr


                    jmp start ; expression not valid, change to exit

                ouput:
                    mov [si], al ; ouput to screen
                    inc si
                    jmp input ; get next char

                inputerr:
                    lea dx, errormsg
                    mov ah, 9
                    int 21h 
                    jmp exitca
            solve:
                call paraseinput
                call calculate
                call paraseresult2asscii

                lea dx, resultmsg
                mov ah, 9
                int 21h 

                mov ah, 09h
                lea dx, resultAsscii
                int 21h

                jmp exitca

            exitca:
                call exitcalc


    calculate proc near
        lea si, exp   ; si := address of expression
        lea di, result; di := address of result
        mov cx, '#'
        push cx ; set the end sign of stack
        
        get_pair: 
            mov ah, [si] ; get number
            inc si
            mov al, [si]
            inc si

            mov bh, [si]
            inc si
            mov bl, [si]
            inc si

            mov [di], ah
            inc di
            mov [di], al
            inc di

            pop cx
            push cx

            cmp cl, '#' ; check the stack empty
            jne unempty

            cmp bl, '#'
            je exeremaing  ; if get the end sign

            push bx
            jmp get_pair
        unempty:            ; op stack 
            cmp bl, '#'     
            je exeremaing
            next_sign:
                pop cx
                push cx
                cmp cl, '#'
                je end_sign
                
                mov al, cl
                mov ah, bl
                ;do cmp
                call cmp_sign

                cmp al, ah ; compare two sign, and put the bigger one into 
                jge run_stack

                jmp end_sign
        run_stack:
            dec di          ; get two number from stack
            mov al, [di]
            dec di
            mov ah, [di]

            dec di
            mov dl, [di]
            dec di
            mov dh, [di]

            pop cx

            cmp cl, '+'
            je plus

            cmp cl, '-'
            je mines

            cmp cl, '*'
            je multi

            cmp cl, '/'
            je divide

            plus:
                add dx, ax ; dx = dx + ax
                jmp add_to_result
            mines:
                sub dx, ax ; dx = dx - ax
                jmp add_to_result
            multi:
                imul dx     ; dx:ax = ax * dx
                mov dx, ax  ; set dx = result
                jmp add_to_result
            divide:
                xchg ax, dx ; exchange ax and dx
                mov bp, dx
                mov dx, 0
                idiv bp
                mov dx, ax ; ax = dx:ax / bp
                jmp add_to_result

        add_to_result:
            mov [di], dh
            inc di
            mov [di], dl
            inc di
            jmp next_sign
        end_sign:
            push bx
            jmp get_pair

        exeremaing:
            run_stack2:
                dec di
                mov al,[di]
                dec di
                mov ah, [di]
                
                dec di
                mov dl, [di]
                dec di
                mov dh, [di]

                pop cx

                cmp cl, '#'
                je lastexit

                cmp cl, '+'
                je plus2

                cmp cl, '-'
                je mines2

                cmp cl, '*'
                je multi2

                cmp cl, '/'
                je divide2
                
            plus2:
                add dx, ax ; dx = dx + ax
                jmp add_to_result2
            mines2:
                sub dx, ax ; dx = dx - ax
                jmp add_to_result2
            multi2:
                mul dx     ; dx:ax = ax * dx
                mov dx, ax  ; set dx = result
                jmp add_to_result2
            divide2:
                xchg ax, dx ; exchange ax and dx
                mov bp, dx
                mov dx, 0
                div bp
                mov dx, ax ; ax = dx:ax / bp
                jmp add_to_result2

            add_to_result2:
                mov [di], dh
                inc di
                mov [di], dl
                inc di
                jmp run_stack2
            lastexit:
                ret
    calculate endp

    ; compare priority of sign first in al, second in ah. 
    cmp_sign proc near
        cmp al, '+'
        je plus2al
        cmp al, '-'
        je mines2al
        cmp al, '*'
        je multi2al
        cmp al, '/'
        je divide2al
        plus2al:
            mov al, 0
            jmp setah
        mines2al:
            mov al, 0
            jmp setah
        multi2al:
            mov al, 1
            jmp setah
        divide2al:
            mov al, 1
            jmp setah

        setah:
            cmp ah, '+'
            je plus2ah
            cmp ah, '-'
            je mines2ah
            cmp ah, '*'
            je multi2ah
            cmp ah, '/'
            je divide2ah
        plus2ah:
            mov ah, 0
            jmp exit
        mines2ah:
            mov ah, 0
            jmp exit
        multi2ah:
            mov ah, 1
            jmp exit
        divide2ah:
            mov ah, 1
            jmp exit
        exit:
            ret        
    cmp_sign endp

    paraseinput proc near
        lea si, tex
        lea di, exp

        next_char:
            mov bl, [si]

            cmp bl, '+'
            je insert_char

            cmp bl, '-'
            je insert_char

            cmp bl, '*'
            je insert_char
            
            cmp bl, '/'
            je insert_char
            
            mov cx, 10
            mov bx, 0
            mov bp, 0

            convert_next:
                mov bl, [si]
                sub bl, 30h
                mov bh, 0

                mov ax, bp
                mul cx
                mov bp, ax
                
                add bp, bx

                inc si
                cmp byte ptr [si] , '0'
                jl insert_number
                cmp byte ptr [si] , '9'
                jg insert_number

                insert_char:
                    mov bh, 0
                    mov [di], bh
                    inc di
                    mov [di], bl
                    inc di
                    inc si
                    jmp next
                
                jmp convert_next

                insert_number:
                    mov bx, bp
                    mov [di], bh
                    inc di
                    mov [di], bl
                    inc di
                    jmp next

                next:
                    cmp byte ptr[si] , '#' ; check the end of the text
                    jne next_char          ; if not end then continue 

        mov byte ptr [di], 0
        inc di
        mov byte ptr [di], '#' ; insert end sign of expression
        ret
    paraseinput endp

    paraseresult2asscii proc near
        mov ah, byte ptr result
        mov al, byte ptr result + 1
        test ax, 8000H
        mov di, 0
        jz axispositive
        neg ax
        mov di, 1
    axispositive:
        mov cx, 10
        lea si, resultAsscii
        add si, 29
        mov bp, 0
        charloop:
            mov dx, 0
            div cx
            or dl, 30h
            mov [si], dl
            dec si
            inc bp
            cmp ax, 0
            ja charloop
        cmp di, 0 ; check the number is negative
        jz rest
        mov dl, '-'
        mov [si], dl
        dec si
        inc bp
    rest:
        lea di, resultAsscii
        sortchar:
            inc si
            mov al, byte ptr [si]
            mov byte ptr [di], al
            inc di
            dec bp  
            cmp bp, 0
            ja sortchar
        mov cl, '$'
        mov byte ptr [di], cl
        ret
    paraseresult2asscii endp
    
    exitcalc proc near
        mov ax,4C00H
        int 21h
        ret
    exitcalc endp
    
main endp
code ends
end start
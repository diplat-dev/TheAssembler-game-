include game.inc

PUBLIC util_memset
PUBLIC util_memcpy
PUBLIC util_memcmp
PUBLIC util_strlen
PUBLIC util_copy_cstr
PUBLIC util_append_cstr
PUBLIC util_append_char
PUBLIC util_append_uint

.code

util_memset PROC
    mov r9, rcx
    mov al, dl
    mov rcx, r8
    test rcx, rcx
    jz util_memset_done
util_memset_loop:
    mov byte ptr [r9], al
    inc r9
    dec rcx
    jne util_memset_loop
util_memset_done:
    ret
util_memset ENDP

util_memcpy PROC
    mov r9, rcx
    mov r10, rdx
    mov rcx, r8
    test rcx, rcx
    jz util_memcpy_done
util_memcpy_loop:
    mov al, byte ptr [r10]
    mov byte ptr [r9], al
    inc r10
    inc r9
    dec rcx
    jne util_memcpy_loop
util_memcpy_done:
    ret
util_memcpy ENDP

util_memcmp PROC
    mov r9, rcx
    mov r10, rdx
    mov rcx, r8
    xor eax, eax
    test rcx, rcx
    jz util_memcmp_done
util_memcmp_loop:
    mov dl, byte ptr [r9]
    cmp dl, byte ptr [r10]
    jne util_memcmp_diff
    inc r9
    inc r10
    dec rcx
    jne util_memcmp_loop
    xor eax, eax
    ret
util_memcmp_diff:
    mov eax, 1
util_memcmp_done:
    ret
util_memcmp ENDP

util_strlen PROC
    mov rax, rcx
util_strlen_loop:
    cmp byte ptr [rax], 0
    je util_strlen_done
    inc rax
    jmp util_strlen_loop
util_strlen_done:
    sub rax, rcx
    ret
util_strlen ENDP

util_copy_cstr PROC
    mov r8, rcx
util_copy_loop:
    mov al, byte ptr [rdx]
    mov byte ptr [r8], al
    inc r8
    inc rdx
    test al, al
    jne util_copy_loop
    lea rax, [r8 - 1]
    ret
util_copy_cstr ENDP

util_append_cstr PROC
    mov r8, rcx
util_append_loop:
    mov al, byte ptr [rdx]
    mov byte ptr [r8], al
    inc r8
    inc rdx
    test al, al
    jne util_append_loop
    lea rax, [r8 - 1]
    ret
util_append_cstr ENDP

util_append_char PROC
    mov byte ptr [rcx], dl
    inc rcx
    mov byte ptr [rcx], 0
    mov rax, rcx
    ret
util_append_char ENDP

util_append_uint PROC FRAME
    sub rsp, 56
    .allocstack 56
    .endprolog

    mov r8, rcx
    lea r9, [rsp + 32]
    xor r10d, r10d
    mov eax, edx
    test eax, eax
    jne util_append_uint_digits
    mov byte ptr [r8], '0'
    inc r8
    mov byte ptr [r8], 0
    mov rax, r8
    add rsp, 56
    ret

util_append_uint_digits:
    mov r11d, 10
util_append_uint_divloop:
    xor edx, edx
    div r11d
    add dl, '0'
    mov byte ptr [r9 + r10], dl
    inc r10
    test eax, eax
    jne util_append_uint_divloop

util_append_uint_copyback:
    dec r10
    mov dl, byte ptr [r9 + r10]
    mov byte ptr [r8], dl
    inc r8
    test r10, r10
    jne util_append_uint_copyback

    mov byte ptr [r8], 0
    mov rax, r8
    add rsp, 56
    ret
util_append_uint ENDP

END

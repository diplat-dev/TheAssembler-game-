include game.inc

EXTERN gs_magic:DWORD
EXTERN game_state_size_value:QWORD
EXTERN gs_version:DWORD
EXTERN str_save_path:BYTE
EXTERN str_msg_saved:BYTE
EXTERN str_msg_save_failed:BYTE
EXTERN str_msg_loaded:BYTE
EXTERN str_msg_load_failed:BYTE
EXTERN platform_write_file:PROC
EXTERN platform_read_file:PROC
EXTERN sim_add_message:PROC
EXTERN vis_update:PROC

PUBLIC save_write_quick
PUBLIC save_read_quick

.code

save_write_quick PROC FRAME
    sub rsp, 40
    .allocstack 40
    .endprolog

    lea rcx, str_save_path
    lea rdx, gs_magic
    mov r8d, dword ptr [game_state_size_value]
    call platform_write_file
    test eax, eax
    jz save_write_fail
    lea rcx, str_msg_saved
    call sim_add_message
    mov eax, 1
    add rsp, 40
    ret
save_write_fail:
    lea rcx, str_msg_save_failed
    call sim_add_message
    xor eax, eax
    add rsp, 40
    ret
save_write_quick ENDP

save_read_quick PROC FRAME
    sub rsp, 40
    .allocstack 40
    .endprolog

    lea rcx, str_save_path
    lea rdx, gs_magic
    mov r8d, dword ptr [game_state_size_value]
    call platform_read_file
    test eax, eax
    jz save_read_fail
    cmp dword ptr [gs_magic], SAVE_MAGIC
    jne save_read_fail
    cmp dword ptr [gs_version], STATE_VERSION
    jne save_read_fail
    call vis_update
    lea rcx, str_msg_loaded
    call sim_add_message
    mov eax, 1
    add rsp, 40
    ret
save_read_fail:
    lea rcx, str_msg_load_failed
    call sim_add_message
    xor eax, eax
    add rsp, 40
    ret
save_read_quick ENDP

END

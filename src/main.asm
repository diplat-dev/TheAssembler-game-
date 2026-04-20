include game.inc

EXTERN rt_quit_requested:DWORD
EXTERN rt_last_ms:QWORD
EXTERN rt_accumulator_ms:QWORD
EXTERN platform_init:PROC
EXTERN platform_pump_messages:PROC
EXTERN platform_get_ticks:PROC
EXTERN platform_sleep_brief:PROC
EXTERN render_frame:PROC
EXTERN sim_new_run:PROC
EXTERN sim_handle_input:PROC
EXTERN sim_tick:PROC
EXTERN ExitProcess:PROC

PUBLIC mainCRTStartup

.code

mainCRTStartup PROC FRAME
    sub rsp, 40
    .allocstack 40
    .endprolog

    call platform_init
    call platform_get_ticks
    mov qword ptr [rt_last_ms], rax
    xor ecx, eax
    xor ecx, 0A5A55A5h
    call sim_new_run

main_loop:
    call platform_pump_messages
    cmp dword ptr [rt_quit_requested], 0
    jne main_exit

    call sim_handle_input

    call platform_get_ticks
    mov r10, rax
    mov rdx, r10
    sub rdx, qword ptr [rt_last_ms]
    mov qword ptr [rt_last_ms], r10
    cmp rdx, 250
    jle main_delta_ready
    mov edx, 250
main_delta_ready:
    add qword ptr [rt_accumulator_ms], rdx

main_tick_loop:
    mov rax, qword ptr [rt_accumulator_ms]
    cmp rax, FIXED_STEP_MS
    jb main_render
    sub qword ptr [rt_accumulator_ms], FIXED_STEP_MS
    call sim_tick
    jmp main_tick_loop

main_render:
    call render_frame
    call platform_sleep_brief
    jmp main_loop

main_exit:
    xor ecx, ecx
    call ExitProcess
mainCRTStartup ENDP

END

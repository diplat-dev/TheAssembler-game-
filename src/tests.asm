include game.inc

EXTERN gs_seed:DWORD
EXTERN gs_paused:DWORD
EXTERN gs_game_over:DWORD
EXTERN gs_queue_count:DWORD
EXTERN gs_queue_head:DWORD
EXTERN gs_queue_tail:DWORD
EXTERN gs_command_queue:BYTE
EXTERN gs_room_count:DWORD
EXTERN gs_entity_hp:DWORD
EXTERN gs_entity_x:BYTE
EXTERN gs_entity_y:BYTE
EXTERN gs_entity_status_type:BYTE
EXTERN gs_entity_status_ticks:DWORD
EXTERN gs_inventory_kind:BYTE
EXTERN gs_inventory_count:BYTE
EXTERN gs_map_tiles:BYTE
EXTERN util_strlen:PROC
EXTERN util_memset:PROC
EXTERN map_rng_seed:PROC
EXTERN map_rng_next:PROC
EXTERN map_tile_index:PROC
EXTERN sim_new_run:PROC
EXTERN sim_queue_command:PROC
EXTERN sim_pop_command:PROC
EXTERN save_write_quick:PROC
EXTERN save_read_quick:PROC
EXTERN vis_has_los:PROC
EXTERN WriteFile:PROC
EXTERN GetStdHandle:PROC
EXTERN ExitProcess:PROC

PUBLIC tests_mainCRTStartup

.data
test_pass_msg db "All tests passed.", 13, 10, 0
test_rng_fail db "RNG repeatability failed.", 13, 10, 0
test_queue_fail db "Queue ordering failed.", 13, 10, 0
test_run_fail db "New run setup failed.", 13, 10, 0
test_los_fail db "LOS blocking failed.", 13, 10, 0
test_save_fail db "Save/load round-trip failed.", 13, 10, 0

.data?
test_stdout_handle dq ?
test_bytes_written dd ?
test_rng_a dd ?
test_rng_b dd ?

.code

test_print PROC FRAME
    sub rsp, 56
    .allocstack 56
    .endprolog

    mov qword ptr [rsp + 40], rcx
    mov rcx, qword ptr [rsp + 40]
    call util_strlen
    mov r10d, eax

    mov rcx, qword ptr [test_stdout_handle]
    mov rdx, qword ptr [rsp + 40]
    mov r8d, r10d
    lea r9, test_bytes_written
    mov qword ptr [rsp + 32], 0
    call WriteFile

    add rsp, 56
    ret
test_print ENDP

test_fail PROC FRAME
    sub rsp, 40
    .allocstack 40
    .endprolog

    call test_print
    mov ecx, 1
    call ExitProcess
test_fail ENDP

tests_mainCRTStartup PROC FRAME
    sub rsp, 40
    .allocstack 40
    .endprolog

    mov ecx, STD_OUTPUT_HANDLE
    call GetStdHandle
    mov qword ptr [test_stdout_handle], rax

    mov ecx, 12345
    call map_rng_seed
    call map_rng_next
    mov dword ptr [test_rng_a], eax
    call map_rng_next
    mov dword ptr [test_rng_b], eax
    mov ecx, 12345
    call map_rng_seed
    call map_rng_next
    cmp eax, dword ptr [test_rng_a]
    jne tests_rng_failed
    call map_rng_next
    cmp eax, dword ptr [test_rng_b]
    jne tests_rng_failed

    mov dword ptr [gs_queue_count], 0
    mov dword ptr [gs_queue_head], 0
    mov dword ptr [gs_queue_tail], 0
    mov cl, CMD_MOVE_UP
    call sim_queue_command
    mov cl, CMD_WAIT
    call sim_queue_command
    mov cl, CMD_RANGED
    call sim_queue_command
    call sim_pop_command
    cmp eax, CMD_MOVE_UP
    jne tests_queue_failed
    call sim_pop_command
    cmp eax, CMD_WAIT
    jne tests_queue_failed
    call sim_pop_command
    cmp eax, CMD_RANGED
    jne tests_queue_failed

    mov ecx, 4242
    call sim_new_run
    cmp dword ptr [gs_room_count], 0
    jle tests_run_failed
    movzx ecx, byte ptr [gs_entity_x + PLAYER_ENTITY_INDEX]
    movzx edx, byte ptr [gs_entity_y + PLAYER_ENTITY_INDEX]
    call map_tile_index
    cmp byte ptr [gs_map_tiles + rax], TILE_FLOOR
    jne tests_run_failed

    lea rcx, gs_map_tiles
    mov edx, TILE_FLOOR
    mov r8d, MAP_TILE_COUNT
    call util_memset
    mov ecx, 2
    mov edx, 1
    call map_tile_index
    mov byte ptr [gs_map_tiles + rax], TILE_WALL
    mov ecx, 1
    mov edx, 1
    mov r8d, 3
    mov r9d, 1
    call vis_has_los
    cmp eax, 0
    jne tests_los_failed
    mov ecx, 2
    mov edx, 1
    call map_tile_index
    mov byte ptr [gs_map_tiles + rax], TILE_FLOOR
    mov ecx, 1
    mov edx, 1
    mov r8d, 3
    mov r9d, 1
    call vis_has_los
    cmp eax, 1
    jne tests_los_failed

    mov ecx, 777
    call sim_new_run
    mov dword ptr [gs_paused], 1
    mov dword ptr [gs_game_over], 0
    mov dword ptr [gs_queue_count], 3
    mov dword ptr [gs_queue_head], 0
    mov dword ptr [gs_queue_tail], 3
    mov byte ptr [gs_command_queue], CMD_MOVE_RIGHT
    mov byte ptr [gs_command_queue + 1], CMD_WAIT
    mov byte ptr [gs_command_queue + 2], CMD_USE
    mov byte ptr [gs_inventory_kind], ITEM_TONIC
    mov byte ptr [gs_inventory_count], 2
    mov byte ptr [gs_inventory_kind + 1], ITEM_POTION
    mov byte ptr [gs_inventory_count + 1], 1
    mov byte ptr [gs_entity_status_type + PLAYER_ENTITY_INDEX], STATUS_REGEN
    mov dword ptr [gs_entity_status_ticks + PLAYER_ENTITY_INDEX * 4], 12
    mov dword ptr [gs_entity_hp + PLAYER_ENTITY_INDEX * 4], 5
    call save_write_quick
    test eax, eax
    jz tests_save_failed
    mov dword ptr [gs_entity_hp + PLAYER_ENTITY_INDEX * 4], 1
    mov dword ptr [gs_queue_count], 0
    mov byte ptr [gs_inventory_kind], ITEM_NONE
    mov byte ptr [gs_inventory_count], 0
    mov byte ptr [gs_entity_status_type + PLAYER_ENTITY_INDEX], STATUS_NONE
    mov dword ptr [gs_entity_status_ticks + PLAYER_ENTITY_INDEX * 4], 0
    call save_read_quick
    test eax, eax
    jz tests_save_failed
    cmp dword ptr [gs_entity_hp + PLAYER_ENTITY_INDEX * 4], 5
    jne tests_save_failed
    cmp dword ptr [gs_paused], 1
    jne tests_save_failed
    cmp dword ptr [gs_queue_count], 3
    jne tests_save_failed
    cmp byte ptr [gs_command_queue], CMD_MOVE_RIGHT
    jne tests_save_failed
    cmp byte ptr [gs_command_queue + 1], CMD_WAIT
    jne tests_save_failed
    cmp byte ptr [gs_command_queue + 2], CMD_USE
    jne tests_save_failed
    cmp byte ptr [gs_inventory_kind], ITEM_TONIC
    jne tests_save_failed
    cmp byte ptr [gs_inventory_count], 2
    jne tests_save_failed
    cmp byte ptr [gs_inventory_kind + 1], ITEM_POTION
    jne tests_save_failed
    cmp byte ptr [gs_inventory_count + 1], 1
    jne tests_save_failed
    cmp byte ptr [gs_entity_status_type + PLAYER_ENTITY_INDEX], STATUS_REGEN
    jne tests_save_failed
    cmp dword ptr [gs_entity_status_ticks + PLAYER_ENTITY_INDEX * 4], 12
    jne tests_save_failed

    lea rcx, test_pass_msg
    call test_print
    xor ecx, ecx
    call ExitProcess

tests_rng_failed:
    lea rcx, test_rng_fail
    call test_fail
tests_queue_failed:
    lea rcx, test_queue_fail
    call test_fail
tests_run_failed:
    lea rcx, test_run_fail
    call test_fail
tests_los_failed:
    lea rcx, test_los_fail
    call test_fail
tests_save_failed:
    lea rcx, test_save_fail
    call test_fail
tests_mainCRTStartup ENDP

END

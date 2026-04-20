include game.inc

EXTERN gs_magic:DWORD
EXTERN game_state_size_value:QWORD
EXTERN gs_version:DWORD
EXTERN gs_seed:DWORD
EXTERN gs_rng_state:DWORD
EXTERN gs_tick:DWORD
EXTERN gs_paused:DWORD
EXTERN gs_game_over:DWORD
EXTERN gs_queue_count:DWORD
EXTERN gs_queue_head:DWORD
EXTERN gs_queue_tail:DWORD
EXTERN gs_player_index:DWORD
EXTERN gs_entity_count:DWORD
EXTERN gs_item_count:DWORD
EXTERN gs_command_queue:BYTE
EXTERN gs_map_tiles:BYTE
EXTERN gs_map_visible:BYTE
EXTERN gs_entity_active:BYTE
EXTERN gs_entity_kind:BYTE
EXTERN gs_entity_ai:BYTE
EXTERN gs_entity_x:BYTE
EXTERN gs_entity_y:BYTE
EXTERN gs_entity_hp:DWORD
EXTERN gs_entity_max_hp:DWORD
EXTERN gs_entity_cooldown:DWORD
EXTERN gs_entity_status_type:BYTE
EXTERN gs_entity_status_ticks:DWORD
EXTERN gs_item_active:BYTE
EXTERN gs_item_kind:BYTE
EXTERN gs_item_x:BYTE
EXTERN gs_item_y:BYTE
EXTERN gs_item_stack:BYTE
EXTERN gs_inventory_kind:BYTE
EXTERN gs_inventory_count:BYTE
EXTERN gs_room_count:DWORD
EXTERN gs_room_cx:BYTE
EXTERN gs_room_cy:BYTE
EXTERN gs_message_log:BYTE
EXTERN rt_quit_requested:DWORD
EXTERN rt_key_pressed:BYTE
EXTERN rt_screen:DWORD
EXTERN rt_return_screen:DWORD
EXTERN str_msg_new_run:BYTE
EXTERN str_msg_queue_full:BYTE
EXTERN str_msg_queue_removed:BYTE
EXTERN str_msg_picked_up:BYTE
EXTERN str_msg_picked_up_tonic:BYTE
EXTERN str_msg_inventory_full:BYTE
EXTERN str_msg_used_potion:BYTE
EXTERN str_msg_used_tonic:BYTE
EXTERN str_msg_no_item:BYTE
EXTERN str_msg_dropped_item:BYTE
EXTERN str_msg_dropped_tonic:BYTE
EXTERN str_msg_enemy_hit:BYTE
EXTERN str_msg_player_hit:BYTE
EXTERN str_msg_player_dead:BYTE
EXTERN str_msg_restart:BYTE
EXTERN str_msg_ranged_miss:BYTE
EXTERN str_msg_ranged_hit:BYTE
EXTERN str_msg_paused:BYTE
EXTERN str_msg_resumed:BYTE
EXTERN util_memset:PROC
EXTERN util_memcpy:PROC
EXTERN util_copy_cstr:PROC
EXTERN map_rng_seed:PROC
EXTERN map_rng_next:PROC
EXTERN map_rng_range:PROC
EXTERN map_is_walkable:PROC
EXTERN map_generate:PROC
EXTERN map_random_room_tile:PROC
EXTERN save_write_quick:PROC
EXTERN save_read_quick:PROC
EXTERN vis_update:PROC
EXTERN vis_has_los:PROC

PUBLIC sim_new_run
PUBLIC sim_handle_input
PUBLIC sim_tick
PUBLIC sim_add_message
PUBLIC sim_queue_command
PUBLIC sim_pop_command
PUBLIC sim_find_entity_at
PUBLIC sim_try_move_actor

.code

sim_add_message PROC FRAME
    sub rsp, 56
    .allocstack 56
    .endprolog

    mov qword ptr [rsp + 40], rcx

    lea rcx, [gs_message_log + (MESSAGE_CHARS * 3)]
    lea rdx, [gs_message_log + (MESSAGE_CHARS * 2)]
    mov r8d, MESSAGE_CHARS
    call util_memcpy

    lea rcx, [gs_message_log + (MESSAGE_CHARS * 2)]
    lea rdx, [gs_message_log + MESSAGE_CHARS]
    mov r8d, MESSAGE_CHARS
    call util_memcpy

    lea rcx, [gs_message_log + MESSAGE_CHARS]
    lea rdx, gs_message_log
    mov r8d, MESSAGE_CHARS
    call util_memcpy

    lea rcx, gs_message_log
    xor edx, edx
    mov r8d, MESSAGE_CHARS
    call util_memset

    lea rcx, gs_message_log
    mov rdx, qword ptr [rsp + 40]
    call util_copy_cstr

    add rsp, 56
    ret
sim_add_message ENDP

sim_queue_command PROC FRAME
    sub rsp, 40
    .allocstack 40
    .endprolog

    cmp dword ptr [gs_queue_count], MAX_QUEUE
    jl sim_queue_space
    lea rcx, str_msg_queue_full
    call sim_add_message
    xor eax, eax
    add rsp, 40
    ret
sim_queue_space:
    mov eax, dword ptr [gs_queue_tail]
    mov byte ptr [gs_command_queue + rax], cl
    inc eax
    cmp eax, MAX_QUEUE
    jl sim_queue_store_tail
    xor eax, eax
sim_queue_store_tail:
    mov dword ptr [gs_queue_tail], eax
    inc dword ptr [gs_queue_count]
    mov eax, 1
    add rsp, 40
    ret
sim_queue_command ENDP

sim_pop_command PROC
    cmp dword ptr [gs_queue_count], 0
    jg sim_pop_have
    xor eax, eax
    ret
sim_pop_have:
    mov eax, dword ptr [gs_queue_head]
    movzx eax, byte ptr [gs_command_queue + rax]
    mov edx, dword ptr [gs_queue_head]
    inc edx
    cmp edx, MAX_QUEUE
    jl sim_pop_store_head
    xor edx, edx
sim_pop_store_head:
    mov dword ptr [gs_queue_head], edx
    dec dword ptr [gs_queue_count]
    ret
sim_pop_command ENDP

sim_find_entity_at PROC
    xor r8d, r8d
sim_find_entity_loop:
    cmp r8d, MAX_ENTITIES
    jge sim_find_entity_none
    cmp byte ptr [gs_entity_active + r8], 0
    je sim_find_entity_next
    cmp dword ptr [gs_entity_hp + r8 * 4], 0
    jle sim_find_entity_next
    movzx eax, byte ptr [gs_entity_x + r8]
    cmp eax, ecx
    jne sim_find_entity_next
    movzx eax, byte ptr [gs_entity_y + r8]
    cmp eax, edx
    jne sim_find_entity_next
    mov eax, r8d
    ret
sim_find_entity_next:
    inc r8d
    jmp sim_find_entity_loop
sim_find_entity_none:
    mov eax, -1
    ret
sim_find_entity_at ENDP

sim_find_item_at PROC
    xor r8d, r8d
sim_find_item_loop:
    cmp r8d, MAX_ITEMS
    jge sim_find_item_none
    cmp byte ptr [gs_item_active + r8], 0
    je sim_find_item_next
    movzx eax, byte ptr [gs_item_x + r8]
    cmp eax, ecx
    jne sim_find_item_next
    movzx eax, byte ptr [gs_item_y + r8]
    cmp eax, edx
    jne sim_find_item_next
    mov eax, r8d
    ret
sim_find_item_next:
    inc r8d
    jmp sim_find_item_loop
sim_find_item_none:
    mov eax, -1
    ret
sim_find_item_at ENDP

sim_damage_entity PROC FRAME
    sub rsp, 40
    .allocstack 40
    .endprolog

    sub dword ptr [gs_entity_hp + rcx * 4], edx
    cmp dword ptr [gs_entity_hp + rcx * 4], 0
    jg sim_damage_done
    mov dword ptr [gs_entity_hp + rcx * 4], 0
    mov byte ptr [gs_entity_active + rcx], 0
    cmp ecx, PLAYER_ENTITY_INDEX
    jne sim_damage_done
    mov dword ptr [gs_game_over], 1
    mov dword ptr [gs_paused], 1
    lea rcx, str_msg_player_dead
    call sim_add_message
sim_damage_done:
    add rsp, 40
    ret
sim_damage_entity ENDP

sim_try_move_actor PROC FRAME
    sub rsp, 72
    .allocstack 72
    .endprolog

    mov dword ptr [rsp + 32], ecx
    mov dword ptr [rsp + 36], edx
    mov dword ptr [rsp + 40], r8d

    movzx eax, byte ptr [gs_entity_x + rcx]
    add eax, edx
    mov dword ptr [rsp + 44], eax
    movzx eax, byte ptr [gs_entity_y + rcx]
    add eax, r8d
    mov dword ptr [rsp + 48], eax

    mov ecx, dword ptr [rsp + 44]
    mov edx, dword ptr [rsp + 48]
    call sim_find_entity_at
    cmp eax, -1
    je sim_try_move_check_map
    cmp eax, dword ptr [rsp + 32]
    je sim_try_move_fail
    mov r10d, eax
    mov eax, dword ptr [rsp + 32]
    movzx ecx, byte ptr [gs_entity_kind + rax]
    movzx edx, byte ptr [gs_entity_kind + r10]
    cmp ecx, edx
    je sim_try_move_fail
    mov ecx, r10d
    mov edx, 1
    call sim_damage_entity
    mov eax, dword ptr [rsp + 32]
    cmp eax, PLAYER_ENTITY_INDEX
    jne sim_try_move_player_hit
    lea rcx, str_msg_enemy_hit
    call sim_add_message
    mov eax, 1
    add rsp, 72
    ret
sim_try_move_player_hit:
    lea rcx, str_msg_player_hit
    call sim_add_message
    mov eax, 1
    add rsp, 72
    ret

sim_try_move_check_map:
    mov ecx, dword ptr [rsp + 44]
    mov edx, dword ptr [rsp + 48]
    call map_is_walkable
    test eax, eax
    jz sim_try_move_fail
    mov eax, dword ptr [rsp + 44]
    mov ecx, dword ptr [rsp + 32]
    mov byte ptr [gs_entity_x + rcx], al
    mov eax, dword ptr [rsp + 48]
    mov byte ptr [gs_entity_y + rcx], al
    mov eax, 1
    add rsp, 72
    ret

sim_try_move_fail:
    xor eax, eax
    add rsp, 72
    ret
sim_try_move_actor ENDP

sim_pickup_item PROC FRAME
    sub rsp, 40
    .allocstack 40
    .endprolog

    movzx ecx, byte ptr [gs_entity_x + PLAYER_ENTITY_INDEX]
    movzx edx, byte ptr [gs_entity_y + PLAYER_ENTITY_INDEX]
    call sim_find_item_at
    cmp eax, -1
    jne sim_pickup_have_item
    lea rcx, str_msg_no_item
    call sim_add_message
    add rsp, 40
    ret
sim_pickup_have_item:
    mov r10d, eax
    xor r11d, r11d
sim_pickup_slot_loop:
    cmp r11d, MAX_INV
    jge sim_pickup_full
    movzx eax, byte ptr [gs_item_kind + r10]
    cmp byte ptr [gs_inventory_kind + r11], al
    je sim_pickup_add_here
    cmp byte ptr [gs_inventory_kind + r11], ITEM_NONE
    je sim_pickup_add_here
    inc r11d
    jmp sim_pickup_slot_loop
sim_pickup_add_here:
    movzx eax, byte ptr [gs_item_kind + r10]
    mov byte ptr [gs_inventory_kind + r11], al
    inc byte ptr [gs_inventory_count + r11]
    mov byte ptr [gs_item_active + r10], 0
    cmp byte ptr [gs_item_kind + r10], ITEM_TONIC
    jne sim_pickup_potion_msg
    lea rcx, str_msg_picked_up_tonic
    call sim_add_message
    add rsp, 40
    ret
sim_pickup_potion_msg:
    lea rcx, str_msg_picked_up
    call sim_add_message
    add rsp, 40
    ret
sim_pickup_full:
    lea rcx, str_msg_inventory_full
    call sim_add_message
    add rsp, 40
    ret
sim_pickup_item ENDP

sim_use_item PROC FRAME
    sub rsp, 40
    .allocstack 40
    .endprolog

    xor r10d, r10d
sim_use_item_loop:
    cmp r10d, MAX_INV
    jge sim_use_item_none
    cmp byte ptr [gs_inventory_count + r10], 0
    je sim_use_item_next
    cmp byte ptr [gs_inventory_kind + r10], ITEM_NONE
    jne sim_use_item_found
sim_use_item_next:
    inc r10d
    jmp sim_use_item_loop

sim_use_item_found:
    movzx eax, byte ptr [gs_inventory_kind + r10]
    dec byte ptr [gs_inventory_count + r10]
    cmp byte ptr [gs_inventory_count + r10], 0
    jne sim_use_item_apply
    mov byte ptr [gs_inventory_kind + r10], ITEM_NONE

sim_use_item_apply:
    cmp eax, ITEM_TONIC
    jne sim_use_item_potion
    mov byte ptr [gs_entity_status_type + PLAYER_ENTITY_INDEX], STATUS_REGEN
    mov dword ptr [gs_entity_status_ticks + PLAYER_ENTITY_INDEX * 4], TONIC_REGEN_TICKS
    lea rcx, str_msg_used_tonic
    call sim_add_message
    add rsp, 40
    ret

sim_use_item_potion:
    add dword ptr [gs_entity_hp + PLAYER_ENTITY_INDEX * 4], POTION_HEAL
    mov eax, dword ptr [gs_entity_hp + PLAYER_ENTITY_INDEX * 4]
    cmp eax, dword ptr [gs_entity_max_hp + PLAYER_ENTITY_INDEX * 4]
    jle sim_use_potion_msg
    mov eax, dword ptr [gs_entity_max_hp + PLAYER_ENTITY_INDEX * 4]
    mov dword ptr [gs_entity_hp + PLAYER_ENTITY_INDEX * 4], eax
sim_use_potion_msg:
    lea rcx, str_msg_used_potion
    call sim_add_message
    add rsp, 40
    ret

sim_use_item_none:
    lea rcx, str_msg_no_item
    call sim_add_message
    add rsp, 40
    ret
sim_use_item ENDP

sim_drop_item PROC FRAME
    sub rsp, 40
    .allocstack 40
    .endprolog

    xor r10d, r10d
sim_drop_find_inv:
    cmp r10d, MAX_INV
    jge sim_drop_none
    cmp byte ptr [gs_inventory_count + r10], 0
    je sim_drop_next_inv
    cmp byte ptr [gs_inventory_kind + r10], ITEM_NONE
    jne sim_drop_have_inv
sim_drop_next_inv:
    inc r10d
    jmp sim_drop_find_inv

sim_drop_have_inv:
    xor r11d, r11d
sim_drop_item_slot:
    cmp r11d, MAX_ITEMS
    jge sim_drop_none
    cmp byte ptr [gs_item_active + r11], 0
    je sim_drop_place
    inc r11d
    jmp sim_drop_item_slot

sim_drop_place:
    mov byte ptr [gs_item_active + r11], 1
    movzx eax, byte ptr [gs_inventory_kind + r10]
    mov byte ptr [gs_item_kind + r11], al
    movzx eax, byte ptr [gs_entity_x + PLAYER_ENTITY_INDEX]
    mov byte ptr [gs_item_x + r11], al
    movzx eax, byte ptr [gs_entity_y + PLAYER_ENTITY_INDEX]
    mov byte ptr [gs_item_y + r11], al
    mov byte ptr [gs_item_stack + r11], 1
    dec byte ptr [gs_inventory_count + r10]
    cmp byte ptr [gs_inventory_count + r10], 0
    jne sim_drop_msg
    mov byte ptr [gs_inventory_kind + r10], ITEM_NONE
sim_drop_msg:
    cmp byte ptr [gs_item_kind + r11], ITEM_TONIC
    jne sim_drop_potion_msg
    lea rcx, str_msg_dropped_tonic
    call sim_add_message
    add rsp, 40
    ret
sim_drop_potion_msg:
    lea rcx, str_msg_dropped_item
    call sim_add_message
    add rsp, 40
    ret

sim_drop_none:
    lea rcx, str_msg_no_item
    call sim_add_message
    add rsp, 40
    ret
sim_drop_item ENDP

sim_ranged_attack PROC FRAME
    sub rsp, 88
    .allocstack 88
    .endprolog

    mov dword ptr [rsp + 32], -1
    mov dword ptr [rsp + 36], 9999
    movzx r10d, byte ptr [gs_entity_x + PLAYER_ENTITY_INDEX]
    movzx r11d, byte ptr [gs_entity_y + PLAYER_ENTITY_INDEX]
    mov dword ptr [rsp + 40], 1

sim_ranged_loop:
    cmp dword ptr [rsp + 40], MAX_ENTITIES
    jge sim_ranged_done_scan
    mov ecx, dword ptr [rsp + 40]
    cmp byte ptr [gs_entity_active + rcx], 0
    je sim_ranged_next
    cmp dword ptr [gs_entity_hp + rcx * 4], 0
    jle sim_ranged_next
    movzx eax, byte ptr [gs_entity_x + rcx]
    movzx edx, byte ptr [gs_entity_y + rcx]
    mov dword ptr [rsp + 44], eax
    mov dword ptr [rsp + 48], edx
    mov ecx, edx
    imul ecx, MAP_WIDTH
    add ecx, eax
    cmp byte ptr [gs_map_visible + rcx], 0
    je sim_ranged_next

    mov eax, dword ptr [rsp + 44]
    sub eax, r10d
    jns sim_ranged_abs_x
    neg eax
sim_ranged_abs_x:
    mov dword ptr [rsp + 52], eax
    mov eax, dword ptr [rsp + 48]
    sub eax, r11d
    jns sim_ranged_abs_y
    neg eax
sim_ranged_abs_y:
    add eax, dword ptr [rsp + 52]
    cmp eax, LOS_RADIUS
    jg sim_ranged_next
    mov dword ptr [rsp + 56], eax

    mov ecx, r10d
    mov edx, r11d
    mov r8d, dword ptr [rsp + 44]
    mov r9d, dword ptr [rsp + 48]
    call vis_has_los
    test eax, eax
    jz sim_ranged_next
    mov eax, dword ptr [rsp + 56]
    cmp eax, dword ptr [rsp + 36]
    jge sim_ranged_next
    mov dword ptr [rsp + 36], eax
    mov eax, dword ptr [rsp + 40]
    mov dword ptr [rsp + 32], eax

sim_ranged_next:
    inc dword ptr [rsp + 40]
    jmp sim_ranged_loop

sim_ranged_done_scan:
    cmp dword ptr [rsp + 32], -1
    jne sim_ranged_hit
    lea rcx, str_msg_ranged_miss
    call sim_add_message
    add rsp, 88
    ret

sim_ranged_hit:
    mov ecx, dword ptr [rsp + 32]
    mov edx, 1
    call sim_damage_entity
    lea rcx, str_msg_ranged_hit
    call sim_add_message
    add rsp, 88
    ret
sim_ranged_attack ENDP

sim_execute_player_command PROC FRAME
    sub rsp, 56
    .allocstack 56
    .endprolog

    call sim_pop_command
    mov dword ptr [rsp + 32], eax
    cmp eax, 0
    jne sim_exec_have
    xor eax, eax
    add rsp, 56
    ret
sim_exec_have:
    cmp dword ptr [rsp + 32], CMD_MOVE_UP
    jne sim_exec_not_up
    mov ecx, PLAYER_ENTITY_INDEX
    mov edx, 0
    mov r8d, -1
    call sim_try_move_actor
    mov eax, PLAYER_ACTION_TICKS
    add rsp, 56
    ret
sim_exec_not_up:
    cmp dword ptr [rsp + 32], CMD_MOVE_DOWN
    jne sim_exec_not_down
    mov ecx, PLAYER_ENTITY_INDEX
    mov edx, 0
    mov r8d, 1
    call sim_try_move_actor
    mov eax, PLAYER_ACTION_TICKS
    add rsp, 56
    ret
sim_exec_not_down:
    cmp dword ptr [rsp + 32], CMD_MOVE_LEFT
    jne sim_exec_not_left
    mov ecx, PLAYER_ENTITY_INDEX
    mov edx, -1
    mov r8d, 0
    call sim_try_move_actor
    mov eax, PLAYER_ACTION_TICKS
    add rsp, 56
    ret
sim_exec_not_left:
    cmp dword ptr [rsp + 32], CMD_MOVE_RIGHT
    jne sim_exec_not_right
    mov ecx, PLAYER_ENTITY_INDEX
    mov edx, 1
    mov r8d, 0
    call sim_try_move_actor
    mov eax, PLAYER_ACTION_TICKS
    add rsp, 56
    ret
sim_exec_not_right:
    cmp dword ptr [rsp + 32], CMD_WAIT
    jne sim_exec_not_wait
    mov eax, PLAYER_ACTION_TICKS
    add rsp, 56
    ret
sim_exec_not_wait:
    cmp dword ptr [rsp + 32], CMD_PICKUP
    jne sim_exec_not_pickup
    call sim_pickup_item
    mov eax, PLAYER_ACTION_TICKS
    add rsp, 56
    ret
sim_exec_not_pickup:
    cmp dword ptr [rsp + 32], CMD_USE
    jne sim_exec_not_use
    call sim_use_item
    mov eax, PLAYER_ACTION_TICKS
    add rsp, 56
    ret
sim_exec_not_use:
    cmp dword ptr [rsp + 32], CMD_DROP
    jne sim_exec_not_drop
    call sim_drop_item
    mov eax, PLAYER_ACTION_TICKS
    add rsp, 56
    ret
sim_exec_not_drop:
    call sim_ranged_attack
    mov eax, RANGED_ACTION_TICKS
    add rsp, 56
    ret
sim_execute_player_command ENDP

sim_process_player PROC FRAME
    sub rsp, 40
    .allocstack 40
    .endprolog

    cmp dword ptr [gs_entity_hp + PLAYER_ENTITY_INDEX * 4], 0
    jle sim_process_player_done
    cmp dword ptr [gs_entity_cooldown + PLAYER_ENTITY_INDEX * 4], 0
    jne sim_process_player_done
    cmp dword ptr [gs_queue_count], 0
    jle sim_process_player_done
    call sim_execute_player_command
    mov dword ptr [gs_entity_cooldown + PLAYER_ENTITY_INDEX * 4], eax
sim_process_player_done:
    add rsp, 40
    ret
sim_process_player ENDP

sim_process_enemies PROC FRAME
    sub rsp, 72
    .allocstack 72
    .endprolog

    movzx r10d, byte ptr [gs_entity_x + PLAYER_ENTITY_INDEX]
    movzx r11d, byte ptr [gs_entity_y + PLAYER_ENTITY_INDEX]
    mov dword ptr [rsp + 32], r10d
    mov dword ptr [rsp + 36], r11d
    mov r9d, 1

sim_enemy_loop:
    cmp r9d, MAX_ENTITIES
    jge sim_enemy_done
    cmp byte ptr [gs_entity_active + r9], 0
    je sim_enemy_next
    cmp dword ptr [gs_entity_hp + r9 * 4], 0
    jle sim_enemy_next
    cmp dword ptr [gs_entity_cooldown + r9 * 4], 0
    jne sim_enemy_next

    movzx eax, byte ptr [gs_entity_x + r9]
    mov dword ptr [rsp + 40], eax
    movzx eax, byte ptr [gs_entity_y + r9]
    mov dword ptr [rsp + 44], eax

    mov eax, dword ptr [rsp + 32]
    sub eax, dword ptr [rsp + 40]
    mov dword ptr [rsp + 48], eax
    mov ecx, eax
    jns sim_enemy_absdx
    neg ecx
sim_enemy_absdx:
    mov dword ptr [rsp + 52], ecx

    mov eax, dword ptr [rsp + 36]
    sub eax, dword ptr [rsp + 44]
    mov dword ptr [rsp + 56], eax
    mov ecx, eax
    jns sim_enemy_absdy
    neg ecx
sim_enemy_absdy:
    mov dword ptr [rsp + 60], ecx

    mov eax, dword ptr [rsp + 52]
    add eax, dword ptr [rsp + 60]
    cmp eax, 14
    jle sim_enemy_chase
    jmp sim_enemy_next

sim_enemy_chase:
    mov eax, dword ptr [rsp + 52]
    cmp eax, dword ptr [rsp + 60]
    jl sim_enemy_try_y_first

    mov ecx, r9d
    mov edx, dword ptr [rsp + 48]
    test edx, edx
    jz sim_enemy_try_alt_y
    mov edx, 1
    jg sim_enemy_x_dir_ready
    mov edx, -1
sim_enemy_x_dir_ready:
    mov r8d, 0
    call sim_try_move_actor
    test eax, eax
    jnz sim_enemy_set_cd

sim_enemy_try_alt_y:
    mov ecx, r9d
    mov r8d, dword ptr [rsp + 56]
    test r8d, r8d
    jz sim_enemy_set_cd
    mov r8d, 1
    jg sim_enemy_y_dir_ready_a
    mov r8d, -1
sim_enemy_y_dir_ready_a:
    xor edx, edx
    call sim_try_move_actor
    jmp sim_enemy_set_cd

sim_enemy_try_y_first:
    mov ecx, r9d
    mov r8d, dword ptr [rsp + 56]
    test r8d, r8d
    jz sim_enemy_try_alt_x
    mov r8d, 1
    jg sim_enemy_y_dir_ready_b
    mov r8d, -1
sim_enemy_y_dir_ready_b:
    xor edx, edx
    call sim_try_move_actor
    test eax, eax
    jnz sim_enemy_set_cd

sim_enemy_try_alt_x:
    mov ecx, r9d
    mov edx, dword ptr [rsp + 48]
    test edx, edx
    jz sim_enemy_set_cd
    mov edx, 1
    jg sim_enemy_x_dir_ready_b
    mov edx, -1
sim_enemy_x_dir_ready_b:
    mov r8d, 0
    call sim_try_move_actor

sim_enemy_set_cd:
    cmp byte ptr [gs_entity_kind + r9], ENTITY_BRUTE
    jne sim_enemy_set_slime_cd
    mov dword ptr [gs_entity_cooldown + r9 * 4], BRUTE_ACTION_TICKS
    jmp sim_enemy_next
sim_enemy_set_slime_cd:
    mov dword ptr [gs_entity_cooldown + r9 * 4], ENEMY_ACTION_TICKS

sim_enemy_next:
    inc r9d
    jmp sim_enemy_loop

sim_enemy_done:
    add rsp, 72
    ret
sim_process_enemies ENDP

sim_spawn_from_room PROC FRAME
    sub rsp, 72
    .allocstack 72
    .endprolog

    mov dword ptr [rsp + 32], ecx
    mov dword ptr [rsp + 36], edx
    mov dword ptr [rsp + 40], r8d
    mov dword ptr [rsp + 44], r9d
    mov dword ptr [rsp + 48], 0

sim_spawn_try:
    mov ecx, dword ptr [rsp + 36]
    call map_random_room_tile
    mov dword ptr [rsp + 52], eax
    mov dword ptr [rsp + 56], edx
    mov ecx, dword ptr [rsp + 52]
    mov edx, dword ptr [rsp + 56]
    call sim_find_entity_at
    cmp eax, -1
    jne sim_spawn_retry
    mov ecx, dword ptr [rsp + 52]
    mov edx, dword ptr [rsp + 56]
    call sim_find_item_at
    cmp eax, -1
    jne sim_spawn_retry

    mov ecx, dword ptr [rsp + 32]
    mov byte ptr [gs_entity_active + rcx], 1
    mov byte ptr [gs_entity_ai + rcx], AI_CHASE
    mov eax, dword ptr [rsp + 52]
    mov byte ptr [gs_entity_x + rcx], al
    mov eax, dword ptr [rsp + 56]
    mov byte ptr [gs_entity_y + rcx], al
    mov eax, dword ptr [rsp + 36]
    and eax, 3
    cmp eax, 0
    je sim_spawn_brute
    mov byte ptr [gs_entity_kind + rcx], ENTITY_SLIME
    mov eax, dword ptr [rsp + 40]
    mov dword ptr [gs_entity_hp + rcx * 4], eax
    mov dword ptr [gs_entity_max_hp + rcx * 4], eax
    mov eax, dword ptr [rsp + 44]
    mov dword ptr [gs_entity_cooldown + rcx * 4], eax
    add rsp, 72
    ret

sim_spawn_brute:
    mov byte ptr [gs_entity_kind + rcx], ENTITY_BRUTE
    mov eax, dword ptr [rsp + 40]
    add eax, 2
    mov dword ptr [gs_entity_hp + rcx * 4], eax
    mov dword ptr [gs_entity_max_hp + rcx * 4], eax
    mov eax, dword ptr [rsp + 44]
    add eax, 2
    mov dword ptr [gs_entity_cooldown + rcx * 4], eax
    add rsp, 72
    ret

sim_spawn_retry:
    inc dword ptr [rsp + 48]
    cmp dword ptr [rsp + 48], 8
    jl sim_spawn_try
    add rsp, 72
    ret
sim_spawn_from_room ENDP

sim_spawn_item_in_room PROC FRAME
    sub rsp, 56
    .allocstack 56
    .endprolog

    mov dword ptr [rsp + 32], ecx
    mov dword ptr [rsp + 36], edx

    mov ecx, dword ptr [rsp + 36]
    call map_random_room_tile
    mov dword ptr [rsp + 40], eax
    mov dword ptr [rsp + 44], edx
    mov ecx, dword ptr [rsp + 40]
    mov edx, dword ptr [rsp + 44]
    call sim_find_entity_at
    cmp eax, -1
    jne sim_spawn_item_done
    mov ecx, dword ptr [rsp + 40]
    mov edx, dword ptr [rsp + 44]
    call sim_find_item_at
    cmp eax, -1
    jne sim_spawn_item_done

    mov ecx, dword ptr [rsp + 32]
    mov byte ptr [gs_item_active + rcx], 1
    mov eax, dword ptr [rsp + 32]
    and eax, 1
    cmp eax, 0
    jne sim_spawn_item_potion
    mov byte ptr [gs_item_kind + rcx], ITEM_TONIC
    jmp sim_spawn_item_kind_done
sim_spawn_item_potion:
    mov byte ptr [gs_item_kind + rcx], ITEM_POTION
sim_spawn_item_kind_done:
    mov byte ptr [gs_item_stack + rcx], 1
    mov eax, dword ptr [rsp + 40]
    mov byte ptr [gs_item_x + rcx], al
    mov eax, dword ptr [rsp + 44]
    mov byte ptr [gs_item_y + rcx], al

sim_spawn_item_done:
    add rsp, 56
    ret
sim_spawn_item_in_room ENDP

sim_new_run PROC FRAME
    sub rsp, 72
    .allocstack 72
    .endprolog

    mov dword ptr [rsp + 32], ecx

    lea rcx, gs_magic
    xor edx, edx
    mov r8d, dword ptr [game_state_size_value]
    call util_memset

    mov dword ptr [gs_magic], SAVE_MAGIC
    mov dword ptr [gs_version], STATE_VERSION
    mov dword ptr [gs_player_index], PLAYER_ENTITY_INDEX
    mov dword ptr [gs_paused], 1
    mov dword ptr [gs_game_over], 0
    mov ecx, dword ptr [rsp + 32]
    call map_rng_seed
    call map_generate

    mov byte ptr [gs_entity_active + PLAYER_ENTITY_INDEX], 1
    mov byte ptr [gs_entity_kind + PLAYER_ENTITY_INDEX], ENTITY_PLAYER
    mov byte ptr [gs_entity_ai + PLAYER_ENTITY_INDEX], AI_IDLE
    movzx eax, byte ptr [gs_room_cx]
    mov byte ptr [gs_entity_x + PLAYER_ENTITY_INDEX], al
    movzx eax, byte ptr [gs_room_cy]
    mov byte ptr [gs_entity_y + PLAYER_ENTITY_INDEX], al
    mov dword ptr [gs_entity_hp + PLAYER_ENTITY_INDEX * 4], 8
    mov dword ptr [gs_entity_max_hp + PLAYER_ENTITY_INDEX * 4], 8
    mov dword ptr [gs_entity_cooldown + PLAYER_ENTITY_INDEX * 4], 0
    mov dword ptr [gs_entity_count], 1

    xor r10d, r10d
    mov r11d, 1
sim_spawn_enemy_loop:
    cmp r11d, dword ptr [gs_room_count]
    jge sim_spawn_items_begin
    cmp dword ptr [gs_entity_count], MAX_ENTITIES
    jge sim_spawn_items_begin
    mov ecx, ENEMY_ACTION_TICKS
    call map_rng_range
    mov r9d, eax
    mov ecx, dword ptr [gs_entity_count]
    mov edx, r11d
    mov r8d, 2
    call sim_spawn_from_room
    inc dword ptr [gs_entity_count]
    inc r10d
    cmp r10d, 5
    jge sim_spawn_items_begin
    inc r11d
    jmp sim_spawn_enemy_loop

sim_spawn_items_begin:
    mov dword ptr [gs_item_count], 0
    mov r10d, 1
    xor r11d, r11d
sim_spawn_item_loop:
    cmp r10d, dword ptr [gs_room_count]
    jge sim_finish_new_run
    cmp r11d, 5
    jge sim_finish_new_run
    mov ecx, dword ptr [gs_item_count]
    mov edx, r10d
    call sim_spawn_item_in_room
    inc dword ptr [gs_item_count]
    inc r11d
    add r10d, 2
    jmp sim_spawn_item_loop

sim_finish_new_run:
    mov dword ptr [rt_screen], SCREEN_GAME
    mov dword ptr [rt_return_screen], SCREEN_GAME
    call vis_update
    lea rcx, str_msg_new_run
    call sim_add_message

    add rsp, 72
    ret
sim_new_run ENDP

sim_decrement_cooldowns PROC
    xor r10d, r10d
sim_decrement_loop:
    cmp r10d, MAX_ENTITIES
    jge sim_decrement_done
    cmp dword ptr [gs_entity_cooldown + r10 * 4], 0
    jle sim_decrement_next
    dec dword ptr [gs_entity_cooldown + r10 * 4]
sim_decrement_next:
    inc r10d
    jmp sim_decrement_loop
sim_decrement_done:
    ret
sim_decrement_cooldowns ENDP

sim_process_statuses PROC
    xor r10d, r10d
sim_status_loop:
    cmp r10d, MAX_ENTITIES
    jge sim_status_done
    cmp byte ptr [gs_entity_active + r10], 0
    je sim_status_next
    cmp dword ptr [gs_entity_hp + r10 * 4], 0
    jle sim_status_next
    cmp byte ptr [gs_entity_status_type + r10], STATUS_REGEN
    jne sim_status_next
    cmp dword ptr [gs_entity_status_ticks + r10 * 4], 0
    jle sim_status_clear
    dec dword ptr [gs_entity_status_ticks + r10 * 4]
    mov eax, dword ptr [gs_entity_status_ticks + r10 * 4]
    test eax, 3
    jne sim_status_check_clear
    mov eax, dword ptr [gs_entity_hp + r10 * 4]
    cmp eax, dword ptr [gs_entity_max_hp + r10 * 4]
    jge sim_status_check_clear
    inc dword ptr [gs_entity_hp + r10 * 4]
sim_status_check_clear:
    cmp dword ptr [gs_entity_status_ticks + r10 * 4], 0
    jg sim_status_next
sim_status_clear:
    mov byte ptr [gs_entity_status_type + r10], STATUS_NONE
    mov dword ptr [gs_entity_status_ticks + r10 * 4], 0
sim_status_next:
    inc r10d
    jmp sim_status_loop
sim_status_done:
    ret
sim_process_statuses ENDP

sim_tick PROC FRAME
    sub rsp, 40
    .allocstack 40
    .endprolog

    cmp dword ptr [gs_paused], 0
    je sim_tick_live
    add rsp, 40
    ret
sim_tick_live:
    cmp dword ptr [gs_game_over], 0
    jne sim_tick_done
    inc dword ptr [gs_tick]
    call sim_decrement_cooldowns
    call sim_process_statuses
    call sim_process_player
    call sim_process_enemies
    call vis_update
sim_tick_done:
    add rsp, 40
    ret
sim_tick ENDP

sim_handle_input PROC FRAME
    sub rsp, 56
    .allocstack 56
    .endprolog

    cmp dword ptr [rt_screen], SCREEN_HELP
    je sim_input_help
    cmp dword ptr [rt_screen], SCREEN_GAME
    je sim_input_game

    cmp byte ptr [rt_key_pressed + VK_ESCAPE], 0
    jne sim_input_quit
    cmp byte ptr [rt_key_pressed + 'Q'], 0
    jne sim_input_quit
    cmp byte ptr [rt_key_pressed + 'H'], 0
    jne sim_input_open_help_from_title
    cmp byte ptr [rt_key_pressed + VK_RETURN], 0
    jne sim_input_start_from_title
    cmp byte ptr [rt_key_pressed + VK_SPACE], 0
    jne sim_input_start_from_title
    cmp byte ptr [rt_key_pressed + 'R'], 0
    jne sim_input_start_from_title
    cmp byte ptr [rt_key_pressed + VK_F9], 0
    je sim_input_done
    call save_read_quick
    test eax, eax
    jz sim_input_done
    mov dword ptr [rt_screen], SCREEN_GAME
    mov dword ptr [rt_return_screen], SCREEN_GAME
    jmp sim_input_done

sim_input_start_from_title:
    mov ecx, dword ptr [gs_seed]
    inc ecx
    call sim_new_run
    jmp sim_input_done

sim_input_open_help_from_title:
    mov dword ptr [rt_return_screen], SCREEN_TITLE
    mov dword ptr [rt_screen], SCREEN_HELP
    jmp sim_input_done

sim_input_help:
    cmp byte ptr [rt_key_pressed + VK_ESCAPE], 0
    jne sim_input_leave_help
    cmp byte ptr [rt_key_pressed + VK_RETURN], 0
    jne sim_input_leave_help
    cmp byte ptr [rt_key_pressed + VK_SPACE], 0
    jne sim_input_leave_help
    cmp byte ptr [rt_key_pressed + 'H'], 0
    jne sim_input_leave_help
    jmp sim_input_done

sim_input_leave_help:
    mov eax, dword ptr [rt_return_screen]
    mov dword ptr [rt_screen], eax
    jmp sim_input_done

sim_input_game:
    cmp byte ptr [rt_key_pressed + VK_ESCAPE], 0
    je sim_input_no_title
    mov dword ptr [gs_paused], 1
    mov dword ptr [rt_return_screen], SCREEN_TITLE
    mov dword ptr [rt_screen], SCREEN_TITLE
    jmp sim_input_done
sim_input_no_title:

    cmp byte ptr [rt_key_pressed + 'H'], 0
    je sim_input_no_help
    mov dword ptr [gs_paused], 1
    mov dword ptr [rt_return_screen], SCREEN_GAME
    mov dword ptr [rt_screen], SCREEN_HELP
    jmp sim_input_done
sim_input_no_help:

    cmp byte ptr [rt_key_pressed + VK_SPACE], 0
    je sim_input_no_space
    cmp dword ptr [gs_game_over], 0
    jne sim_input_no_space
    xor eax, eax
    cmp dword ptr [gs_paused], 0
    sete al
    mov dword ptr [gs_paused], eax
    cmp eax, 0
    je sim_input_resumed
    lea rcx, str_msg_paused
    call sim_add_message
    jmp sim_input_no_space
sim_input_resumed:
    lea rcx, str_msg_resumed
    call sim_add_message
sim_input_no_space:

    cmp byte ptr [rt_key_pressed + VK_F9], 0
    je sim_input_no_load
    call save_read_quick
    test eax, eax
    jz sim_input_no_load
    mov dword ptr [rt_screen], SCREEN_GAME
    mov dword ptr [rt_return_screen], SCREEN_GAME
sim_input_no_load:

    cmp byte ptr [rt_key_pressed + 'R'], 0
    jne sim_input_restart
    cmp byte ptr [rt_key_pressed + VK_RETURN], 0
    je sim_input_no_restart
    cmp dword ptr [gs_game_over], 0
    je sim_input_no_restart
sim_input_restart:
    mov ecx, dword ptr [gs_seed]
    inc ecx
    call sim_new_run
    lea rcx, str_msg_restart
    call sim_add_message
sim_input_no_restart:

    cmp dword ptr [gs_game_over], 0
    jne sim_input_done
    cmp dword ptr [gs_paused], 0
    je sim_input_done

    cmp byte ptr [rt_key_pressed + VK_BACK], 0
    je sim_input_no_back
    cmp dword ptr [gs_queue_count], 0
    jle sim_input_no_back
    mov eax, dword ptr [gs_queue_tail]
    dec eax
    jns sim_input_back_ok
    mov eax, MAX_QUEUE - 1
sim_input_back_ok:
    mov dword ptr [gs_queue_tail], eax
    dec dword ptr [gs_queue_count]
    lea rcx, str_msg_queue_removed
    call sim_add_message
sim_input_no_back:

    cmp byte ptr [rt_key_pressed + VK_F5], 0
    je sim_input_no_save
    call save_write_quick
sim_input_no_save:

    cmp byte ptr [rt_key_pressed + 'W'], 0
    jne sim_input_queue_up
    cmp byte ptr [rt_key_pressed + VK_UP], 0
    je sim_input_no_up
sim_input_queue_up:
    mov cl, CMD_MOVE_UP
    call sim_queue_command
sim_input_no_up:

    cmp byte ptr [rt_key_pressed + 'S'], 0
    jne sim_input_queue_down
    cmp byte ptr [rt_key_pressed + VK_DOWN], 0
    je sim_input_no_down
sim_input_queue_down:
    mov cl, CMD_MOVE_DOWN
    call sim_queue_command
sim_input_no_down:

    cmp byte ptr [rt_key_pressed + 'A'], 0
    jne sim_input_queue_left
    cmp byte ptr [rt_key_pressed + VK_LEFT], 0
    je sim_input_no_left
sim_input_queue_left:
    mov cl, CMD_MOVE_LEFT
    call sim_queue_command
sim_input_no_left:

    cmp byte ptr [rt_key_pressed + 'D'], 0
    jne sim_input_queue_right
    cmp byte ptr [rt_key_pressed + VK_RIGHT], 0
    je sim_input_no_right
sim_input_queue_right:
    mov cl, CMD_MOVE_RIGHT
    call sim_queue_command
sim_input_no_right:

    cmp byte ptr [rt_key_pressed + '.'], 0
    je sim_input_no_wait
    mov cl, CMD_WAIT
    call sim_queue_command
sim_input_no_wait:

    cmp byte ptr [rt_key_pressed + 'G'], 0
    je sim_input_no_pickup
    mov cl, CMD_PICKUP
    call sim_queue_command
sim_input_no_pickup:

    cmp byte ptr [rt_key_pressed + 'I'], 0
    je sim_input_no_use
    mov cl, CMD_USE
    call sim_queue_command
sim_input_no_use:

    cmp byte ptr [rt_key_pressed + 'X'], 0
    je sim_input_no_drop
    mov cl, CMD_DROP
    call sim_queue_command
sim_input_no_drop:

    cmp byte ptr [rt_key_pressed + 'F'], 0
    je sim_input_done
    mov cl, CMD_RANGED
    call sim_queue_command
    jmp sim_input_done

sim_input_quit:
    mov dword ptr [rt_quit_requested], 1

sim_input_done:
    lea rcx, rt_key_pressed
    xor edx, edx
    mov r8d, 256
    call util_memset

    add rsp, 56
    ret
sim_handle_input ENDP

END

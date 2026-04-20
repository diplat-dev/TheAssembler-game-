include game.inc

EXTERN gs_seed:DWORD
EXTERN gs_rng_state:DWORD
EXTERN gs_map_tiles:BYTE
EXTERN gs_map_visible:BYTE
EXTERN gs_map_discovered:BYTE
EXTERN gs_room_count:DWORD
EXTERN gs_room_x1:BYTE
EXTERN gs_room_y1:BYTE
EXTERN gs_room_x2:BYTE
EXTERN gs_room_y2:BYTE
EXTERN gs_room_cx:BYTE
EXTERN gs_room_cy:BYTE
EXTERN util_memset:PROC

PUBLIC map_rng_seed
PUBLIC map_rng_next
PUBLIC map_rng_range
PUBLIC map_tile_index
PUBLIC map_is_walkable
PUBLIC map_generate
PUBLIC map_random_room_tile

.code

map_rng_seed PROC
    mov eax, ecx
    test eax, eax
    jne map_rng_seed_store
    mov eax, 1
map_rng_seed_store:
    mov dword ptr [gs_seed], eax
    mov dword ptr [gs_rng_state], eax
    ret
map_rng_seed ENDP

map_rng_next PROC
    mov eax, dword ptr [gs_rng_state]
    test eax, eax
    jne map_rng_continue
    mov eax, 1
map_rng_continue:
    mov edx, eax
    shl edx, 13
    xor eax, edx
    mov edx, eax
    shr edx, 17
    xor eax, edx
    mov edx, eax
    shl edx, 5
    xor eax, edx
    mov dword ptr [gs_rng_state], eax
    ret
map_rng_next ENDP

map_rng_range PROC
    test ecx, ecx
    jg map_rng_range_real
    xor eax, eax
    ret
map_rng_range_real:
    mov r8d, ecx
    call map_rng_next
    xor edx, edx
    div r8d
    mov eax, edx
    ret
map_rng_range ENDP

map_tile_index PROC
    mov eax, edx
    imul eax, MAP_WIDTH
    add eax, ecx
    ret
map_tile_index ENDP

map_is_walkable PROC
    cmp ecx, 0
    jl map_is_walkable_no
    cmp ecx, MAP_WIDTH
    jge map_is_walkable_no
    cmp edx, 0
    jl map_is_walkable_no
    cmp edx, MAP_HEIGHT
    jge map_is_walkable_no
    call map_tile_index
    cmp byte ptr [gs_map_tiles + rax], TILE_FLOOR
    jne map_is_walkable_no
    mov eax, 1
    ret
map_is_walkable_no:
    xor eax, eax
    ret
map_is_walkable ENDP

map_carve_room PROC
    mov r10d, r9d
    mov r11d, edx
map_carve_room_y:
    mov ecx, ecx
    mov r9d, r8d
    mov eax, r11d
    imul eax, MAP_WIDTH
    add eax, ecx
    lea rdx, [gs_map_tiles + rax]
map_carve_room_x:
    mov byte ptr [rdx], TILE_FLOOR
    inc rdx
    dec r9d
    jne map_carve_room_x
    inc r11d
    dec r10d
    jne map_carve_room_y
    ret
map_carve_room ENDP

map_carve_h_corridor PROC
    cmp ecx, edx
    jle map_carve_h_sorted
    xchg ecx, edx
map_carve_h_sorted:
    mov r10d, edx
    mov edx, r8d
map_carve_h_loop:
    call map_tile_index
    mov byte ptr [gs_map_tiles + rax], TILE_FLOOR
    inc ecx
    cmp ecx, r10d
    jle map_carve_h_loop
    ret
map_carve_h_corridor ENDP

map_carve_v_corridor PROC
    cmp edx, r8d
    jle map_carve_v_sorted
    xchg edx, r8d
map_carve_v_sorted:
    mov r10d, r8d
map_carve_v_loop:
    call map_tile_index
    mov byte ptr [gs_map_tiles + rax], TILE_FLOOR
    inc edx
    cmp edx, r10d
    jle map_carve_v_loop
    ret
map_carve_v_corridor ENDP

map_generate PROC FRAME
    sub rsp, 88
    .allocstack 88
    .endprolog

    lea rcx, gs_map_tiles
    mov edx, TILE_WALL
    mov r8d, MAP_TILE_COUNT
    call util_memset

    lea rcx, gs_map_visible
    xor edx, edx
    mov r8d, MAP_TILE_COUNT
    call util_memset

    lea rcx, gs_map_discovered
    xor edx, edx
    mov r8d, MAP_TILE_COUNT
    call util_memset

    mov dword ptr [gs_room_count], 0
    xor r10d, r10d

map_generate_attempt:
    cmp r10d, 48
    jge map_generate_done
    cmp dword ptr [gs_room_count], MAX_ROOMS
    jge map_generate_done
    inc r10d

    mov ecx, 8
    call map_rng_range
    add eax, 5
    mov dword ptr [rsp + 32], eax

    mov ecx, 6
    call map_rng_range
    add eax, 4
    mov dword ptr [rsp + 36], eax

    mov eax, MAP_WIDTH - 2
    sub eax, dword ptr [rsp + 32]
    mov ecx, eax
    call map_rng_range
    add eax, 1
    mov dword ptr [rsp + 40], eax

    mov eax, MAP_HEIGHT - 2
    sub eax, dword ptr [rsp + 36]
    mov ecx, eax
    call map_rng_range
    add eax, 1
    mov dword ptr [rsp + 44], eax

    mov eax, dword ptr [rsp + 40]
    add eax, dword ptr [rsp + 32]
    dec eax
    mov dword ptr [rsp + 48], eax

    mov eax, dword ptr [rsp + 44]
    add eax, dword ptr [rsp + 36]
    dec eax
    mov dword ptr [rsp + 52], eax

    mov eax, dword ptr [rsp + 40]
    mov ecx, dword ptr [rsp + 32]
    shr ecx, 1
    add eax, ecx
    mov dword ptr [rsp + 56], eax

    mov eax, dword ptr [rsp + 44]
    mov ecx, dword ptr [rsp + 36]
    shr ecx, 1
    add eax, ecx
    mov dword ptr [rsp + 60], eax

    xor r11d, r11d
map_overlap_loop:
    cmp r11d, dword ptr [gs_room_count]
    jge map_no_overlap

    movzx eax, byte ptr [gs_room_x1 + r11]
    movzx ecx, byte ptr [gs_room_y1 + r11]
    movzx edx, byte ptr [gs_room_x2 + r11]
    movzx r8d, byte ptr [gs_room_y2 + r11]

    mov r9d, dword ptr [rsp + 48]
    inc r9d
    cmp dword ptr [rsp + 40], edx
    jg map_overlap_next
    inc edx
    cmp r9d, eax
    jl map_overlap_next

    mov r9d, dword ptr [rsp + 52]
    inc r9d
    cmp dword ptr [rsp + 44], r8d
    jg map_overlap_next
    inc r8d
    cmp r9d, ecx
    jl map_overlap_next
    jmp map_generate_attempt

map_overlap_next:
    inc r11d
    jmp map_overlap_loop

map_no_overlap:
    mov ecx, dword ptr [rsp + 40]
    mov edx, dword ptr [rsp + 44]
    mov r8d, dword ptr [rsp + 32]
    mov r9d, dword ptr [rsp + 36]
    call map_carve_room

    cmp dword ptr [gs_room_count], 0
    je map_store_room
    mov eax, dword ptr [gs_room_count]
    dec eax
    mov r11d, eax
    movzx ecx, byte ptr [gs_room_cx + r11]
    movzx edx, byte ptr [gs_room_cy + r11]
    mov r8d, dword ptr [rsp + 56]
    mov r9d, dword ptr [rsp + 60]
    push rcx
    push rdx
    mov ecx, 2
    call map_rng_range
    pop rdx
    pop rcx
    test eax, eax
    jne map_corridor_vertical_first
    mov r8d, edx
    mov edx, dword ptr [rsp + 56]
    call map_carve_h_corridor
    mov ecx, dword ptr [rsp + 56]
    mov r8d, dword ptr [rsp + 60]
    call map_carve_v_corridor
    jmp map_store_room

map_corridor_vertical_first:
    mov r8d, dword ptr [rsp + 60]
    call map_carve_v_corridor
    mov ecx, dword ptr [rsp + 56]
    mov edx, dword ptr [rsp + 60]
    mov r8d, ecx
    movzx ecx, byte ptr [gs_room_cx + r11]
    call map_carve_h_corridor

map_store_room:
    mov r11d, dword ptr [gs_room_count]
    mov eax, dword ptr [rsp + 40]
    mov byte ptr [gs_room_x1 + r11], al
    mov eax, dword ptr [rsp + 44]
    mov byte ptr [gs_room_y1 + r11], al
    mov eax, dword ptr [rsp + 48]
    mov byte ptr [gs_room_x2 + r11], al
    mov eax, dword ptr [rsp + 52]
    mov byte ptr [gs_room_y2 + r11], al
    mov eax, dword ptr [rsp + 56]
    mov byte ptr [gs_room_cx + r11], al
    mov eax, dword ptr [rsp + 60]
    mov byte ptr [gs_room_cy + r11], al
    inc dword ptr [gs_room_count]
    jmp map_generate_attempt

map_generate_done:
    add rsp, 88
    ret
map_generate ENDP

map_random_room_tile PROC FRAME
    sub rsp, 56
    .allocstack 56
    .endprolog

    mov r10d, ecx
    movzx eax, byte ptr [gs_room_x1 + r10]
    movzx edx, byte ptr [gs_room_x2 + r10]
    sub edx, eax
    inc edx
    mov dword ptr [rsp + 32], eax
    mov ecx, edx
    call map_rng_range
    add eax, dword ptr [rsp + 32]
    mov dword ptr [rsp + 40], eax

    movzx eax, byte ptr [gs_room_y1 + r10]
    movzx edx, byte ptr [gs_room_y2 + r10]
    sub edx, eax
    inc edx
    mov dword ptr [rsp + 36], eax
    mov ecx, edx
    call map_rng_range
    add eax, dword ptr [rsp + 36]
    mov edx, eax
    mov eax, dword ptr [rsp + 40]

    add rsp, 56
    ret
map_random_room_tile ENDP

END

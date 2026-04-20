include game.inc

EXTERN gs_map_tiles:BYTE
EXTERN gs_map_visible:BYTE
EXTERN gs_map_discovered:BYTE
EXTERN gs_entity_x:BYTE
EXTERN gs_entity_y:BYTE
EXTERN util_memset:PROC
EXTERN map_tile_index:PROC

PUBLIC vis_update
PUBLIC vis_has_los

.code

vis_mark_tile PROC
    call map_tile_index
    mov byte ptr [gs_map_visible + rax], 1
    mov byte ptr [gs_map_discovered + rax], 1
    ret
vis_mark_tile ENDP

vis_trace_mark PROC FRAME
    sub rsp, 88
    .allocstack 88
    .endprolog

    mov dword ptr [rsp + 32], ecx
    mov dword ptr [rsp + 36], edx
    mov dword ptr [rsp + 40], r8d
    mov dword ptr [rsp + 44], r9d

    mov eax, r8d
    sub eax, ecx
    mov r10d, 1
    cmp eax, 0
    jge vis_mark_dx_ok
    neg eax
    mov r10d, -1
vis_mark_dx_ok:
    mov dword ptr [rsp + 48], eax
    mov dword ptr [rsp + 52], r10d

    mov eax, r9d
    sub eax, edx
    mov r10d, 1
    cmp eax, 0
    jge vis_mark_dy_ok
    neg eax
    mov r10d, -1
vis_mark_dy_ok:
    neg eax
    mov dword ptr [rsp + 56], eax
    mov dword ptr [rsp + 60], r10d

    mov eax, dword ptr [rsp + 48]
    add eax, dword ptr [rsp + 56]
    mov dword ptr [rsp + 64], eax

vis_mark_loop:
    mov ecx, dword ptr [rsp + 32]
    mov edx, dword ptr [rsp + 36]
    call vis_mark_tile
    mov eax, dword ptr [rsp + 32]
    cmp eax, dword ptr [rsp + 40]
    jne vis_mark_not_target
    mov eax, dword ptr [rsp + 36]
    cmp eax, dword ptr [rsp + 44]
    jne vis_mark_not_target
    mov eax, 1
    add rsp, 88
    ret

vis_mark_not_target:
    mov ecx, dword ptr [rsp + 32]
    mov edx, dword ptr [rsp + 36]
    call map_tile_index
    cmp byte ptr [gs_map_tiles + rax], TILE_WALL
    jne vis_mark_continue
    xor eax, eax
    add rsp, 88
    ret

vis_mark_continue:
    mov eax, dword ptr [rsp + 64]
    add eax, eax
    mov dword ptr [rsp + 68], eax

    mov eax, dword ptr [rsp + 68]
    cmp eax, dword ptr [rsp + 56]
    jl vis_mark_skip_x
    mov eax, dword ptr [rsp + 64]
    add eax, dword ptr [rsp + 56]
    mov dword ptr [rsp + 64], eax
    mov eax, dword ptr [rsp + 32]
    add eax, dword ptr [rsp + 52]
    mov dword ptr [rsp + 32], eax
vis_mark_skip_x:
    mov eax, dword ptr [rsp + 68]
    cmp eax, dword ptr [rsp + 48]
    jg vis_mark_skip_y
    mov eax, dword ptr [rsp + 64]
    add eax, dword ptr [rsp + 48]
    mov dword ptr [rsp + 64], eax
    mov eax, dword ptr [rsp + 36]
    add eax, dword ptr [rsp + 60]
    mov dword ptr [rsp + 36], eax
vis_mark_skip_y:
    jmp vis_mark_loop
vis_trace_mark ENDP

vis_has_los PROC FRAME
    sub rsp, 88
    .allocstack 88
    .endprolog

    mov dword ptr [rsp + 32], ecx
    mov dword ptr [rsp + 36], edx
    mov dword ptr [rsp + 40], r8d
    mov dword ptr [rsp + 44], r9d

    mov eax, r8d
    sub eax, ecx
    mov r10d, 1
    cmp eax, 0
    jge vis_los_dx_ok
    neg eax
    mov r10d, -1
vis_los_dx_ok:
    mov dword ptr [rsp + 48], eax
    mov dword ptr [rsp + 52], r10d

    mov eax, r9d
    sub eax, edx
    mov r10d, 1
    cmp eax, 0
    jge vis_los_dy_ok
    neg eax
    mov r10d, -1
vis_los_dy_ok:
    neg eax
    mov dword ptr [rsp + 56], eax
    mov dword ptr [rsp + 60], r10d

    mov eax, dword ptr [rsp + 48]
    add eax, dword ptr [rsp + 56]
    mov dword ptr [rsp + 64], eax

vis_los_loop:
    mov eax, dword ptr [rsp + 32]
    cmp eax, dword ptr [rsp + 40]
    jne vis_los_not_target
    mov eax, dword ptr [rsp + 36]
    cmp eax, dword ptr [rsp + 44]
    jne vis_los_not_target
    mov eax, 1
    add rsp, 88
    ret

vis_los_not_target:
    mov ecx, dword ptr [rsp + 32]
    mov edx, dword ptr [rsp + 36]
    call map_tile_index
    cmp byte ptr [gs_map_tiles + rax], TILE_WALL
    jne vis_los_continue
    xor eax, eax
    add rsp, 88
    ret

vis_los_continue:
    mov eax, dword ptr [rsp + 64]
    add eax, eax
    mov dword ptr [rsp + 68], eax

    mov eax, dword ptr [rsp + 68]
    cmp eax, dword ptr [rsp + 56]
    jl vis_los_skip_x
    mov eax, dword ptr [rsp + 64]
    add eax, dword ptr [rsp + 56]
    mov dword ptr [rsp + 64], eax
    mov eax, dword ptr [rsp + 32]
    add eax, dword ptr [rsp + 52]
    mov dword ptr [rsp + 32], eax
vis_los_skip_x:
    mov eax, dword ptr [rsp + 68]
    cmp eax, dword ptr [rsp + 48]
    jg vis_los_skip_y
    mov eax, dword ptr [rsp + 64]
    add eax, dword ptr [rsp + 48]
    mov dword ptr [rsp + 64], eax
    mov eax, dword ptr [rsp + 36]
    add eax, dword ptr [rsp + 60]
    mov dword ptr [rsp + 36], eax
vis_los_skip_y:
    jmp vis_los_loop
vis_has_los ENDP

vis_update PROC FRAME
    sub rsp, 72
    .allocstack 72
    .endprolog

    lea rcx, gs_map_visible
    xor edx, edx
    mov r8d, MAP_TILE_COUNT
    call util_memset

    movzx eax, byte ptr [gs_entity_x + PLAYER_ENTITY_INDEX]
    mov dword ptr [rsp + 48], eax
    movzx eax, byte ptr [gs_entity_y + PLAYER_ENTITY_INDEX]
    mov dword ptr [rsp + 52], eax
    mov ecx, dword ptr [rsp + 48]
    mov edx, dword ptr [rsp + 52]
    call vis_mark_tile

    mov eax, dword ptr [rsp + 52]
    sub eax, LOS_RADIUS
    mov dword ptr [rsp + 32], eax
    mov eax, dword ptr [rsp + 52]
    add eax, LOS_RADIUS
    mov dword ptr [rsp + 36], eax

vis_outer_y:
    mov eax, dword ptr [rsp + 32]
    cmp eax, dword ptr [rsp + 36]
    jg vis_update_done
    mov eax, dword ptr [rsp + 48]
    sub eax, LOS_RADIUS
    mov dword ptr [rsp + 40], eax
    mov eax, dword ptr [rsp + 48]
    add eax, LOS_RADIUS
    mov dword ptr [rsp + 44], eax
vis_outer_x:
    mov eax, dword ptr [rsp + 40]
    cmp eax, dword ptr [rsp + 44]
    jg vis_next_row
    cmp eax, 0
    jl vis_next_x
    cmp eax, MAP_WIDTH
    jge vis_next_x
    mov edx, dword ptr [rsp + 32]
    cmp edx, 0
    jl vis_next_x
    cmp edx, MAP_HEIGHT
    jge vis_next_x

    mov eax, dword ptr [rsp + 40]
    sub eax, dword ptr [rsp + 48]
    imul eax, eax
    mov edx, dword ptr [rsp + 32]
    sub edx, dword ptr [rsp + 52]
    imul edx, edx
    add eax, edx
    cmp eax, LOS_RADIUS * LOS_RADIUS
    jg vis_next_x

    mov ecx, dword ptr [rsp + 48]
    mov edx, dword ptr [rsp + 52]
    mov r8d, dword ptr [rsp + 40]
    mov r9d, dword ptr [rsp + 32]
    call vis_trace_mark

vis_next_x:
    inc dword ptr [rsp + 40]
    jmp vis_outer_x

vis_next_row:
    inc dword ptr [rsp + 32]
    jmp vis_outer_y

vis_update_done:
    add rsp, 72
    ret
vis_update ENDP

END

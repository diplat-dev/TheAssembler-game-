include game.inc

EXTERN rt_window:QWORD
EXTERN rt_font:QWORD
EXTERN rt_screen:DWORD
EXTERN rt_backbuffer:DWORD
EXTERN rt_bmi:BYTE
EXTERN gs_paused:DWORD
EXTERN gs_game_over:DWORD
EXTERN gs_seed:DWORD
EXTERN gs_tick:DWORD
EXTERN gs_queue_count:DWORD
EXTERN gs_queue_head:DWORD
EXTERN gs_command_queue:BYTE
EXTERN gs_inventory_kind:BYTE
EXTERN gs_inventory_count:BYTE
EXTERN gs_message_log:BYTE
EXTERN gs_map_tiles:BYTE
EXTERN gs_map_visible:BYTE
EXTERN gs_map_discovered:BYTE
EXTERN gs_entity_active:BYTE
EXTERN gs_entity_kind:BYTE
EXTERN gs_entity_x:BYTE
EXTERN gs_entity_y:BYTE
EXTERN gs_entity_hp:DWORD
EXTERN gs_entity_max_hp:DWORD
EXTERN gs_entity_status_type:BYTE
EXTERN gs_entity_status_ticks:DWORD
EXTERN gs_item_active:BYTE
EXTERN gs_item_kind:BYTE
EXTERN gs_item_x:BYTE
EXTERN gs_item_y:BYTE
EXTERN hud_line0:BYTE
EXTERN hud_line1:BYTE
EXTERN hud_line2:BYTE
EXTERN hud_line3:BYTE
EXTERN hud_line4:BYTE
EXTERN hud_line5:BYTE
EXTERN hud_line6:BYTE
EXTERN hud_line7:BYTE
EXTERN hud_line8:BYTE
EXTERN hud_line9:BYTE
EXTERN render_queue_text:BYTE
EXTERN render_inventory_text:BYTE
EXTERN str_label_paused:BYTE
EXTERN str_label_running:BYTE
EXTERN str_label_dead:BYTE
EXTERN str_label_seed:BYTE
EXTERN str_label_tick:BYTE
EXTERN str_label_hp:BYTE
EXTERN str_label_status:BYTE
EXTERN str_label_enemies:BYTE
EXTERN str_label_queue:BYTE
EXTERN str_label_inventory:BYTE
EXTERN str_controls0:BYTE
EXTERN str_controls1:BYTE
EXTERN str_controls2:BYTE
EXTERN str_controls3:BYTE
EXTERN str_queue_empty:BYTE
EXTERN str_inventory_empty:BYTE
EXTERN str_status_none:BYTE
EXTERN str_status_regen:BYTE
EXTERN str_title0:BYTE
EXTERN str_title1:BYTE
EXTERN str_title2:BYTE
EXTERN str_title3:BYTE
EXTERN str_title4:BYTE
EXTERN str_title5:BYTE
EXTERN str_help0:BYTE
EXTERN str_help1:BYTE
EXTERN str_help2:BYTE
EXTERN str_help3:BYTE
EXTERN str_help4:BYTE
EXTERN str_help5:BYTE
EXTERN str_help6:BYTE
EXTERN str_help7:BYTE
EXTERN util_memset:PROC
EXTERN util_strlen:PROC
EXTERN util_copy_cstr:PROC
EXTERN util_append_cstr:PROC
EXTERN util_append_char:PROC
EXTERN util_append_uint:PROC

EXTERN GetDC:PROC
EXTERN ReleaseDC:PROC
EXTERN StretchDIBits:PROC
EXTERN SetBkMode:PROC
EXTERN SetTextColor:PROC
EXTERN SelectObject:PROC
EXTERN TextOutA:PROC

PUBLIC render_frame
PUBLIC render_present

COLOR_BG             equ 000A0F14h
COLOR_PANEL          equ 00111822h
COLOR_BORDER         equ 00304860h
COLOR_FLOOR_VIS      equ 002B3642h
COLOR_FLOOR_FOG      equ 0018222Ah
COLOR_WALL_VIS       equ 00505D70h
COLOR_WALL_FOG       equ 0027303Bh
COLOR_UNSEEN         equ 0006080Bh
COLOR_PLAYER         equ 0046D46Ch
COLOR_ENEMY          equ 00D14F4Fh
COLOR_ENEMY_BRUTE    equ 00A65DDBh
COLOR_ITEM           equ 00D6B24Bh
COLOR_ITEM_TONIC     equ 00D98AC1h
COLOR_MENU_PANEL     equ 00131C29h
COLOR_MENU_ACCENT    equ 0045708Fh
COLOR_TEXT           equ 00E8E8D8h

.code

render_fill_rect_color PROC
    test r8d, r8d
    jle render_fill_done
    test r9d, r9d
    jle render_fill_done
    mov r10d, r9d
    mov r11d, edx
render_fill_row:
    mov edx, r11d
    imul edx, WINDOW_WIDTH
    add edx, ecx
    lea rdx, [rt_backbuffer + rdx * 4]
    mov r9d, r8d
render_fill_col:
    mov dword ptr [rdx], eax
    add rdx, 4
    dec r9d
    jne render_fill_col
    inc r11d
    dec r10d
    jne render_fill_row
render_fill_done:
    ret
render_fill_rect_color ENDP

render_clear PROC
    xor ecx, ecx
    xor edx, edx
    mov r8d, WINDOW_WIDTH
    mov r9d, WINDOW_HEIGHT
    mov eax, COLOR_BG
    call render_fill_rect_color
    ret
render_clear ENDP

render_draw_menu_background PROC
    mov ecx, 80
    mov edx, 72
    mov r8d, 1120
    mov r9d, 576
    mov eax, COLOR_MENU_PANEL
    call render_fill_rect_color

    mov ecx, 80
    mov edx, 72
    mov r8d, 1120
    mov r9d, 4
    mov eax, COLOR_BORDER
    call render_fill_rect_color

    mov ecx, 80
    mov edx, 644
    mov r8d, 1120
    mov r9d, 4
    mov eax, COLOR_BORDER
    call render_fill_rect_color

    mov ecx, 80
    mov edx, 72
    mov r8d, 4
    mov r9d, 576
    mov eax, COLOR_BORDER
    call render_fill_rect_color

    mov ecx, 1196
    mov edx, 72
    mov r8d, 4
    mov r9d, 576
    mov eax, COLOR_BORDER
    call render_fill_rect_color

    mov ecx, 112
    mov edx, 110
    mov r8d, 24
    mov r9d, 460
    mov eax, COLOR_MENU_ACCENT
    call render_fill_rect_color

    mov ecx, 160
    mov edx, 110
    mov r8d, 320
    mov r9d, 24
    mov eax, COLOR_MENU_ACCENT
    call render_fill_rect_color
    ret
render_draw_menu_background ENDP

render_draw_world PROC
    xor r10d, r10d
render_world_y:
    cmp r10d, MAP_HEIGHT
    jge render_world_entities
    xor r11d, r11d
render_world_x:
    cmp r11d, MAP_WIDTH
    jge render_world_next_y
    mov eax, r10d
    imul eax, MAP_WIDTH
    add eax, r11d
    movzx ecx, byte ptr [gs_map_discovered + rax]
    movzx edx, byte ptr [gs_map_visible + rax]
    movzx r8d, byte ptr [gs_map_tiles + rax]
    cmp ecx, 0
    je render_world_unseen
    cmp r8d, TILE_WALL
    je render_world_wall
    cmp edx, 0
    je render_world_floor_fog
    mov eax, COLOR_FLOOR_VIS
    jmp render_world_tile_ready
render_world_floor_fog:
    mov eax, COLOR_FLOOR_FOG
    jmp render_world_tile_ready
render_world_wall:
    cmp edx, 0
    je render_world_wall_fog
    mov eax, COLOR_WALL_VIS
    jmp render_world_tile_ready
render_world_wall_fog:
    mov eax, COLOR_WALL_FOG
    jmp render_world_tile_ready
render_world_unseen:
    mov eax, COLOR_UNSEEN
render_world_tile_ready:
    mov ecx, r11d
    imul ecx, TILE_SIZE
    mov edx, r10d
    imul edx, TILE_SIZE
    mov r8d, TILE_SIZE
    mov r9d, TILE_SIZE
    call render_fill_rect_color
    inc r11d
    jmp render_world_x
render_world_next_y:
    inc r10d
    jmp render_world_y

render_world_entities:
    xor r10d, r10d
render_item_loop:
    cmp r10d, MAX_ITEMS
    jge render_entity_loop
    cmp byte ptr [gs_item_active + r10], 0
    je render_item_next
    movzx eax, byte ptr [gs_item_x + r10]
    movzx edx, byte ptr [gs_item_y + r10]
    mov ecx, edx
    imul ecx, MAP_WIDTH
    add ecx, eax
    cmp byte ptr [gs_map_visible + rcx], 0
    je render_item_next
    mov ecx, eax
    imul ecx, TILE_SIZE
    add ecx, 6
    imul edx, TILE_SIZE
    add edx, 6
    mov r8d, 4
    mov r9d, 4
    cmp byte ptr [gs_item_kind + r10], ITEM_TONIC
    jne render_item_potion
    mov eax, COLOR_ITEM_TONIC
    call render_fill_rect_color
    jmp render_item_next
render_item_potion:
    mov eax, COLOR_ITEM
    call render_fill_rect_color
render_item_next:
    inc r10d
    jmp render_item_loop

render_entity_loop:
    xor r10d, r10d
render_entity_iter:
    cmp r10d, MAX_ENTITIES
    jge render_panel
    cmp byte ptr [gs_entity_active + r10], 0
    je render_entity_next
    cmp dword ptr [gs_entity_hp + r10 * 4], 0
    jle render_entity_next
    movzx eax, byte ptr [gs_entity_x + r10]
    movzx edx, byte ptr [gs_entity_y + r10]
    cmp r10d, PLAYER_ENTITY_INDEX
    je render_entity_draw
    mov ecx, edx
    imul ecx, MAP_WIDTH
    add ecx, eax
    cmp byte ptr [gs_map_visible + rcx], 0
    je render_entity_next
render_entity_draw:
    mov ecx, eax
    imul ecx, TILE_SIZE
    add ecx, 4
    imul edx, TILE_SIZE
    add edx, 4
    mov r8d, 8
    mov r9d, 8
    cmp r10d, PLAYER_ENTITY_INDEX
    jne render_entity_enemy
    mov eax, COLOR_PLAYER
    call render_fill_rect_color
    jmp render_entity_next
render_entity_enemy:
    cmp byte ptr [gs_entity_kind + r10], ENTITY_BRUTE
    jne render_entity_slime
    mov eax, COLOR_ENEMY_BRUTE
    call render_fill_rect_color
    jmp render_entity_next
render_entity_slime:
    mov eax, COLOR_ENEMY
    call render_fill_rect_color
render_entity_next:
    inc r10d
    jmp render_entity_iter

render_panel:
    mov ecx, HUD_X
    xor edx, edx
    mov r8d, HUD_WIDTH
    mov r9d, WINDOW_HEIGHT
    mov eax, COLOR_PANEL
    call render_fill_rect_color

    mov ecx, HUD_X
    xor edx, edx
    mov r8d, 2
    mov r9d, WINDOW_HEIGHT
    mov eax, COLOR_BORDER
    call render_fill_rect_color
    ret
render_draw_world ENDP

render_count_enemies PROC
    xor eax, eax
    mov r10d, 1
render_count_loop:
    cmp r10d, MAX_ENTITIES
    jge render_count_done
    cmp byte ptr [gs_entity_active + r10], 0
    je render_count_next
    cmp dword ptr [gs_entity_hp + r10 * 4], 0
    jle render_count_next
    inc eax
render_count_next:
    inc r10d
    jmp render_count_loop
render_count_done:
    ret
render_count_enemies ENDP

render_build_queue PROC FRAME
    sub rsp, 40
    .allocstack 40
    .endprolog

    lea rcx, render_queue_text
    lea rdx, str_label_queue
    call util_copy_cstr
    mov r11, rax
    mov eax, dword ptr [gs_queue_count]
    test eax, eax
    jne render_build_queue_items
    mov rcx, r11
    lea rdx, str_queue_empty
    call util_append_cstr
    add rsp, 40
    ret

render_build_queue_items:
    xor r10d, r10d
    mov r9d, dword ptr [gs_queue_head]
render_build_queue_loop:
    cmp r10d, dword ptr [gs_queue_count]
    jge render_build_queue_done
    movzx edx, byte ptr [gs_command_queue + r9]
    cmp edx, CMD_MOVE_UP
    jne render_queue_not_up
    mov dl, '^'
    jmp render_queue_emit
render_queue_not_up:
    cmp edx, CMD_MOVE_DOWN
    jne render_queue_not_down
    mov dl, 'v'
    jmp render_queue_emit
render_queue_not_down:
    cmp edx, CMD_MOVE_LEFT
    jne render_queue_not_left
    mov dl, '<'
    jmp render_queue_emit
render_queue_not_left:
    cmp edx, CMD_MOVE_RIGHT
    jne render_queue_not_right
    mov dl, '>'
    jmp render_queue_emit
render_queue_not_right:
    cmp edx, CMD_WAIT
    jne render_queue_not_wait
    mov dl, '.'
    jmp render_queue_emit
render_queue_not_wait:
    cmp edx, CMD_PICKUP
    jne render_queue_not_pickup
    mov dl, 'G'
    jmp render_queue_emit
render_queue_not_pickup:
    cmp edx, CMD_USE
    jne render_queue_not_use
    mov dl, 'I'
    jmp render_queue_emit
render_queue_not_use:
    cmp edx, CMD_DROP
    jne render_queue_not_drop
    mov dl, 'X'
    jmp render_queue_emit
render_queue_not_drop:
    mov dl, 'F'
render_queue_emit:
    mov rcx, r11
    call util_append_char
    mov r11, rax
    mov dl, ' '
    mov rcx, r11
    call util_append_char
    mov r11, rax
    inc r10d
    inc r9d
    cmp r9d, MAX_QUEUE
    jl render_build_queue_loop
    xor r9d, r9d
    jmp render_build_queue_loop
render_build_queue_done:
    add rsp, 40
    ret
render_build_queue ENDP

render_build_inventory PROC FRAME
    sub rsp, 40
    .allocstack 40
    .endprolog

    lea rcx, render_inventory_text
    lea rdx, str_label_inventory
    call util_copy_cstr
    mov r11, rax
    xor r10d, r10d
    xor r9d, r9d
render_inventory_loop:
    cmp r10d, MAX_INV
    jge render_inventory_finish
    cmp byte ptr [gs_inventory_count + r10], 0
    je render_inventory_next
    mov rcx, r11
    cmp byte ptr [gs_inventory_kind + r10], ITEM_TONIC
    jne render_inventory_potion
    mov dl, 'T'
    call util_append_char
    jmp render_inventory_count
render_inventory_potion:
    mov dl, 'P'
    call util_append_char
render_inventory_count:
    mov r11, rax
    movzx edx, byte ptr [gs_inventory_count + r10]
    cmp edx, 1
    jle render_inventory_space
    mov rcx, r11
    call util_append_uint
    mov r11, rax
render_inventory_space:
    mov rcx, r11
    mov dl, ' '
    call util_append_char
    mov r11, rax
    inc r9d
render_inventory_next:
    inc r10d
    jmp render_inventory_loop
render_inventory_finish:
    cmp r9d, 0
    jne render_inventory_done
    mov rcx, r11
    lea rdx, str_inventory_empty
    call util_append_cstr
render_inventory_done:
    add rsp, 40
    ret
render_build_inventory ENDP

render_build_hud PROC FRAME
    sub rsp, 40
    .allocstack 40
    .endprolog

    cmp dword ptr [gs_game_over], 0
    jne render_status_dead
    cmp dword ptr [gs_paused], 0
    jne render_status_paused
    lea rdx, str_label_running
    jmp render_status_copy
render_status_paused:
    lea rdx, str_label_paused
    jmp render_status_copy
render_status_dead:
    lea rdx, str_label_dead
render_status_copy:
    lea rcx, hud_line0
    call util_copy_cstr

    lea rcx, hud_line1
    lea rdx, str_label_seed
    call util_copy_cstr
    mov rcx, rax
    mov edx, dword ptr [gs_seed]
    call util_append_uint

    lea rcx, hud_line2
    lea rdx, str_label_tick
    call util_copy_cstr
    mov rcx, rax
    mov edx, dword ptr [gs_tick]
    call util_append_uint

    lea rcx, hud_line3
    lea rdx, str_label_hp
    call util_copy_cstr
    mov rcx, rax
    mov edx, dword ptr [gs_entity_hp + PLAYER_ENTITY_INDEX * 4]
    call util_append_uint
    mov rcx, rax
    mov dl, '/'
    call util_append_char
    mov rcx, rax
    mov edx, dword ptr [gs_entity_max_hp + PLAYER_ENTITY_INDEX * 4]
    call util_append_uint

    lea rcx, hud_line4
    lea rdx, str_label_status
    call util_copy_cstr
    mov r11, rax
    cmp byte ptr [gs_entity_status_type + PLAYER_ENTITY_INDEX], STATUS_REGEN
    jne render_status_line_none
    cmp dword ptr [gs_entity_status_ticks + PLAYER_ENTITY_INDEX * 4], 0
    jle render_status_line_none
    mov rcx, r11
    lea rdx, str_status_regen
    call util_append_cstr
    mov rcx, rax
    mov edx, dword ptr [gs_entity_status_ticks + PLAYER_ENTITY_INDEX * 4]
    call util_append_uint
    jmp render_status_line_done
render_status_line_none:
    mov rcx, r11
    lea rdx, str_status_none
    call util_append_cstr
render_status_line_done:

    lea rcx, hud_line5
    lea rdx, str_label_enemies
    call util_copy_cstr
    mov r11, rax
    call render_count_enemies
    mov rcx, r11
    mov edx, eax
    call util_append_uint

    call render_build_queue
    lea rcx, hud_line6
    lea rdx, render_queue_text
    call util_copy_cstr

    call render_build_inventory
    lea rcx, hud_line7
    lea rdx, render_inventory_text
    call util_copy_cstr

    lea rcx, hud_line8
    xor edx, edx
    mov r8d, 96
    call util_memset
    lea rcx, hud_line9
    xor edx, edx
    mov r8d, 96
    call util_memset

    add rsp, 40
    ret
render_build_hud ENDP

render_draw_text_line PROC FRAME
    sub rsp, 56
    .allocstack 56
    .endprolog

    mov qword ptr [rsp + 40], rcx
    mov dword ptr [rsp + 48], edx
    mov dword ptr [rsp + 52], r8d
    mov qword ptr [rsp + 32], r9
    mov rcx, r9
    call util_strlen
    mov r10d, eax
    mov rcx, qword ptr [rsp + 40]
    mov edx, dword ptr [rsp + 48]
    mov r8d, dword ptr [rsp + 52]
    mov r9, qword ptr [rsp + 32]
    mov qword ptr [rsp + 32], r10
    call TextOutA
    add rsp, 56
    ret
render_draw_text_line ENDP

render_present PROC FRAME
    sub rsp, 168
    .allocstack 168
    .endprolog

    mov rcx, qword ptr [rt_window]
    call GetDC
    mov qword ptr [rsp + 160], rax

    mov rcx, rax
    mov edx, TRANSPARENT
    call SetBkMode

    mov rcx, qword ptr [rsp + 160]
    mov edx, COLOR_TEXT
    call SetTextColor

    mov rcx, qword ptr [rsp + 160]
    mov rdx, qword ptr [rt_font]
    call SelectObject

    mov rcx, qword ptr [rsp + 160]
    xor edx, edx
    xor r8d, r8d
    mov r9d, WINDOW_WIDTH
    mov qword ptr [rsp + 32], WINDOW_HEIGHT
    mov qword ptr [rsp + 40], 0
    mov qword ptr [rsp + 48], 0
    mov qword ptr [rsp + 56], WINDOW_WIDTH
    mov qword ptr [rsp + 64], WINDOW_HEIGHT
    lea rax, rt_backbuffer
    mov qword ptr [rsp + 72], rax
    lea rax, rt_bmi
    mov qword ptr [rsp + 80], rax
    mov qword ptr [rsp + 88], DIB_RGB_COLORS
    mov qword ptr [rsp + 96], SRCCOPY
    call StretchDIBits

    cmp dword ptr [rt_screen], SCREEN_GAME
    jne render_present_menu

    mov rcx, qword ptr [rsp + 160]
    mov edx, HUD_X + 12
    mov r8d, 12
    lea r9, hud_line0
    call render_draw_text_line

    mov rcx, qword ptr [rsp + 160]
    mov edx, HUD_X + 12
    mov r8d, 40
    lea r9, hud_line1
    call render_draw_text_line

    mov rcx, qword ptr [rsp + 160]
    mov edx, HUD_X + 12
    mov r8d, 60
    lea r9, hud_line2
    call render_draw_text_line

    mov rcx, qword ptr [rsp + 160]
    mov edx, HUD_X + 12
    mov r8d, 80
    lea r9, hud_line3
    call render_draw_text_line

    mov rcx, qword ptr [rsp + 160]
    mov edx, HUD_X + 12
    mov r8d, 100
    lea r9, hud_line4
    call render_draw_text_line

    mov rcx, qword ptr [rsp + 160]
    mov edx, HUD_X + 12
    mov r8d, 120
    lea r9, hud_line5
    call render_draw_text_line

    mov rcx, qword ptr [rsp + 160]
    mov edx, HUD_X + 12
    mov r8d, 152
    lea r9, hud_line6
    call render_draw_text_line

    mov rcx, qword ptr [rsp + 160]
    mov edx, HUD_X + 12
    mov r8d, 172
    lea r9, hud_line7
    call render_draw_text_line

    mov rcx, qword ptr [rsp + 160]
    mov edx, HUD_X + 12
    mov r8d, 220
    lea r9, gs_message_log
    call render_draw_text_line

    mov rcx, qword ptr [rsp + 160]
    mov edx, HUD_X + 12
    mov r8d, 240
    lea r9, [gs_message_log + MESSAGE_CHARS]
    call render_draw_text_line

    mov rcx, qword ptr [rsp + 160]
    mov edx, HUD_X + 12
    mov r8d, 260
    lea r9, [gs_message_log + (MESSAGE_CHARS * 2)]
    call render_draw_text_line

    mov rcx, qword ptr [rsp + 160]
    mov edx, HUD_X + 12
    mov r8d, 280
    lea r9, [gs_message_log + (MESSAGE_CHARS * 3)]
    call render_draw_text_line

    mov rcx, qword ptr [rsp + 160]
    mov edx, HUD_X + 12
    mov r8d, 560
    lea r9, str_controls0
    call render_draw_text_line

    mov rcx, qword ptr [rsp + 160]
    mov edx, HUD_X + 12
    mov r8d, 580
    lea r9, str_controls1
    call render_draw_text_line

    mov rcx, qword ptr [rsp + 160]
    mov edx, HUD_X + 12
    mov r8d, 600
    lea r9, str_controls2
    call render_draw_text_line

    mov rcx, qword ptr [rsp + 160]
    mov edx, HUD_X + 12
    mov r8d, 620
    lea r9, str_controls3
    call render_draw_text_line
    jmp render_present_done

render_present_menu:
    cmp dword ptr [rt_screen], SCREEN_HELP
    jne render_present_title

    mov rcx, qword ptr [rsp + 160]
    mov edx, 160
    mov r8d, 120
    lea r9, str_help0
    call render_draw_text_line

    mov rcx, qword ptr [rsp + 160]
    mov edx, 160
    mov r8d, 170
    lea r9, str_help1
    call render_draw_text_line

    mov rcx, qword ptr [rsp + 160]
    mov edx, 160
    mov r8d, 205
    lea r9, str_help2
    call render_draw_text_line

    mov rcx, qword ptr [rsp + 160]
    mov edx, 160
    mov r8d, 240
    lea r9, str_help3
    call render_draw_text_line

    mov rcx, qword ptr [rsp + 160]
    mov edx, 160
    mov r8d, 275
    lea r9, str_help4
    call render_draw_text_line

    mov rcx, qword ptr [rsp + 160]
    mov edx, 160
    mov r8d, 310
    lea r9, str_help5
    call render_draw_text_line

    mov rcx, qword ptr [rsp + 160]
    mov edx, 160
    mov r8d, 345
    lea r9, str_help6
    call render_draw_text_line

    mov rcx, qword ptr [rsp + 160]
    mov edx, 160
    mov r8d, 400
    lea r9, str_help7
    call render_draw_text_line
    jmp render_present_done

render_present_title:
    mov rcx, qword ptr [rsp + 160]
    mov edx, 160
    mov r8d, 120
    lea r9, str_title0
    call render_draw_text_line

    mov rcx, qword ptr [rsp + 160]
    mov edx, 160
    mov r8d, 170
    lea r9, str_title1
    call render_draw_text_line

    mov rcx, qword ptr [rsp + 160]
    mov edx, 160
    mov r8d, 230
    lea r9, str_title2
    call render_draw_text_line

    mov rcx, qword ptr [rsp + 160]
    mov edx, 160
    mov r8d, 260
    lea r9, str_title3
    call render_draw_text_line

    mov rcx, qword ptr [rsp + 160]
    mov edx, 160
    mov r8d, 290
    lea r9, str_title4
    call render_draw_text_line

    mov rcx, qword ptr [rsp + 160]
    mov edx, 160
    mov r8d, 350
    lea r9, str_title5
    call render_draw_text_line

render_present_done:
    mov rcx, qword ptr [rt_window]
    mov rdx, qword ptr [rsp + 160]
    call ReleaseDC

    add rsp, 168
    ret
render_present ENDP

render_frame PROC FRAME
    sub rsp, 40
    .allocstack 40
    .endprolog

    call render_clear
    cmp dword ptr [rt_screen], SCREEN_GAME
    jne render_frame_menu
    call render_draw_world
    call render_build_hud
    jmp render_frame_present
render_frame_menu:
    call render_draw_menu_background
render_frame_present:
    call render_present
    add rsp, 40
    ret
render_frame ENDP

END

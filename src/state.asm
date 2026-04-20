include game.inc

PUBLIC game_state_size_value

PUBLIC gs_magic
PUBLIC gs_version
PUBLIC gs_seed
PUBLIC gs_rng_state
PUBLIC gs_tick
PUBLIC gs_paused
PUBLIC gs_game_over
PUBLIC gs_queue_count
PUBLIC gs_queue_head
PUBLIC gs_queue_tail
PUBLIC gs_player_index
PUBLIC gs_entity_count
PUBLIC gs_item_count
PUBLIC gs_command_queue
PUBLIC gs_map_tiles
PUBLIC gs_map_visible
PUBLIC gs_map_discovered
PUBLIC gs_entity_active
PUBLIC gs_entity_kind
PUBLIC gs_entity_ai
PUBLIC gs_entity_x
PUBLIC gs_entity_y
PUBLIC gs_entity_hp
PUBLIC gs_entity_max_hp
PUBLIC gs_entity_cooldown
PUBLIC gs_entity_status_type
PUBLIC gs_entity_status_ticks
PUBLIC gs_item_active
PUBLIC gs_item_kind
PUBLIC gs_item_x
PUBLIC gs_item_y
PUBLIC gs_item_stack
PUBLIC gs_inventory_kind
PUBLIC gs_inventory_count
PUBLIC gs_room_count
PUBLIC gs_room_x1
PUBLIC gs_room_y1
PUBLIC gs_room_x2
PUBLIC gs_room_y2
PUBLIC gs_room_cx
PUBLIC gs_room_cy
PUBLIC gs_message_log

PUBLIC rt_instance
PUBLIC rt_window
PUBLIC rt_quit_requested
PUBLIC rt_last_ms
PUBLIC rt_accumulator_ms
PUBLIC rt_key_down
PUBLIC rt_key_pressed
PUBLIC rt_font
PUBLIC rt_msg
PUBLIC rt_wndclass
PUBLIC rt_rect
PUBLIC rt_bytes_io
PUBLIC rt_backbuffer
PUBLIC rt_bmi
PUBLIC hud_line0
PUBLIC hud_line1
PUBLIC hud_line2
PUBLIC hud_line3
PUBLIC hud_line4
PUBLIC hud_line5
PUBLIC hud_line6
PUBLIC hud_line7
PUBLIC hud_line8
PUBLIC hud_line9
PUBLIC render_queue_text
PUBLIC render_inventory_text
PUBLIC render_number_buffer

PUBLIC str_class_name
PUBLIC str_window_title
PUBLIC str_save_path
PUBLIC str_msg_new_run
PUBLIC str_msg_queue_full
PUBLIC str_msg_queue_removed
PUBLIC str_msg_picked_up
PUBLIC str_msg_inventory_full
PUBLIC str_msg_used_potion
PUBLIC str_msg_no_item
PUBLIC str_msg_dropped_item
PUBLIC str_msg_enemy_hit
PUBLIC str_msg_player_hit
PUBLIC str_msg_player_dead
PUBLIC str_msg_saved
PUBLIC str_msg_save_failed
PUBLIC str_msg_loaded
PUBLIC str_msg_load_failed
PUBLIC str_msg_restart
PUBLIC str_msg_ranged_miss
PUBLIC str_msg_ranged_hit
PUBLIC str_label_paused
PUBLIC str_label_running
PUBLIC str_label_dead
PUBLIC str_label_queue
PUBLIC str_label_inventory
PUBLIC str_label_seed
PUBLIC str_label_tick
PUBLIC str_label_hp
PUBLIC str_label_enemies
PUBLIC str_controls0
PUBLIC str_controls1
PUBLIC str_controls2
PUBLIC str_controls3
PUBLIC str_queue_empty
PUBLIC str_inventory_empty
PUBLIC str_item_potion

.data

gs_magic             dd SAVE_MAGIC
gs_version           dd STATE_VERSION
gs_seed              dd 1
gs_rng_state         dd 1
gs_tick              dd 0
gs_paused            dd 1
gs_game_over         dd 0
gs_queue_count       dd 0
gs_queue_head        dd 0
gs_queue_tail        dd 0
gs_player_index      dd PLAYER_ENTITY_INDEX
gs_entity_count      dd 0
gs_item_count        dd 0
gs_command_queue     db MAX_QUEUE dup(0)
gs_map_tiles         db MAP_TILE_COUNT dup(0)
gs_map_visible       db MAP_TILE_COUNT dup(0)
gs_map_discovered    db MAP_TILE_COUNT dup(0)
gs_entity_active     db MAX_ENTITIES dup(0)
gs_entity_kind       db MAX_ENTITIES dup(0)
gs_entity_ai         db MAX_ENTITIES dup(0)
gs_entity_x          db MAX_ENTITIES dup(0)
gs_entity_y          db MAX_ENTITIES dup(0)
gs_entity_hp         dd MAX_ENTITIES dup(0)
gs_entity_max_hp     dd MAX_ENTITIES dup(0)
gs_entity_cooldown   dd MAX_ENTITIES dup(0)
gs_entity_status_type db MAX_ENTITIES dup(0)
gs_entity_status_ticks dd MAX_ENTITIES dup(0)
gs_item_active       db MAX_ITEMS dup(0)
gs_item_kind         db MAX_ITEMS dup(0)
gs_item_x            db MAX_ITEMS dup(0)
gs_item_y            db MAX_ITEMS dup(0)
gs_item_stack        db MAX_ITEMS dup(0)
gs_inventory_kind    db MAX_INV dup(0)
gs_inventory_count   db MAX_INV dup(0)
gs_room_count        dd 0
gs_room_x1           db MAX_ROOMS dup(0)
gs_room_y1           db MAX_ROOMS dup(0)
gs_room_x2           db MAX_ROOMS dup(0)
gs_room_y2           db MAX_ROOMS dup(0)
gs_room_cx           db MAX_ROOMS dup(0)
gs_room_cy           db MAX_ROOMS dup(0)
gs_message_log       db MAX_MESSAGES * MESSAGE_CHARS dup(0)
game_state_end:

game_state_size_value dq game_state_end - gs_magic

str_class_name       db "AssemblerRogueWindow", 0
str_window_title     db "The Assembler - Win64 Roguelike", 0
str_save_path        db "save.dat", 0
str_msg_new_run      db "New run started.", 0
str_msg_queue_full   db "Command queue is full.", 0
str_msg_queue_removed db "Removed queued command.", 0
str_msg_picked_up    db "Picked up a potion.", 0
str_msg_inventory_full db "Inventory is full.", 0
str_msg_used_potion  db "Potion used.", 0
str_msg_no_item      db "No usable item.", 0
str_msg_dropped_item db "Dropped a potion.", 0
str_msg_enemy_hit    db "Enemy hit.", 0
str_msg_player_hit   db "You were hit.", 0
str_msg_player_dead  db "You died. Press R.", 0
str_msg_saved        db "Game saved.", 0
str_msg_save_failed  db "Save failed.", 0
str_msg_loaded       db "Game loaded.", 0
str_msg_load_failed  db "Load failed.", 0
str_msg_restart      db "Run restarted.", 0
str_msg_ranged_miss  db "No ranged target.", 0
str_msg_ranged_hit   db "Ranged hit.", 0
str_label_paused     db "PAUSED", 0
str_label_running    db "RUNNING", 0
str_label_dead       db "DEAD", 0
str_label_queue      db "Queue: ", 0
str_label_inventory  db "Inventory: ", 0
str_label_seed       db "Seed: ", 0
str_label_tick       db "Tick: ", 0
str_label_hp         db "HP: ", 0
str_label_enemies    db "Enemies: ", 0
str_controls0        db "Space pause  Back remove", 0
str_controls1        db "WASD/Arrows queue move", 0
str_controls2        db ". wait  F fire  G/I/X", 0
str_controls3        db "F5 save  F9 load  R reset", 0
str_queue_empty      db "(empty)", 0
str_inventory_empty  db "(empty)", 0
str_item_potion      db "Potion", 0

.data?

rt_instance          dq ?
rt_window            dq ?
rt_quit_requested    dd ?
rt_last_ms           dq ?
rt_accumulator_ms    dq ?
rt_key_down          db 256 dup(?)
rt_key_pressed       db 256 dup(?)
rt_font              dq ?
rt_msg               db 48 dup(?)
rt_wndclass          db 80 dup(?)
rt_rect              dd 4 dup(?)
rt_bytes_io          dd ?
rt_backbuffer        dd WINDOW_WIDTH * WINDOW_HEIGHT dup(?)
rt_bmi               db 44 dup(?)

hud_line0            db 96 dup(?)
hud_line1            db 96 dup(?)
hud_line2            db 96 dup(?)
hud_line3            db 96 dup(?)
hud_line4            db 96 dup(?)
hud_line5            db 96 dup(?)
hud_line6            db 96 dup(?)
hud_line7            db 96 dup(?)
hud_line8            db 96 dup(?)
hud_line9            db 96 dup(?)
render_queue_text    db 96 dup(?)
render_inventory_text db 96 dup(?)
render_number_buffer db 32 dup(?)

END

WINDOW_WIDTH        equ 1280
WINDOW_HEIGHT       equ 720
TILE_SIZE           equ 16
MAP_WIDTH           equ 64
MAP_HEIGHT          equ 36
MAP_TILE_COUNT      equ 2304
HUD_X               equ 1024
HUD_WIDTH           equ 256
MAX_ENTITIES        equ 64
MAX_ITEMS           equ 128
MAX_INV             equ 16
MAX_QUEUE           equ 16
MAX_MESSAGES        equ 4
MESSAGE_CHARS       equ 64
MAX_ROOMS           equ 12
FIXED_STEP_MS       equ 33
PLAYER_ACTION_TICKS equ 5
ENEMY_ACTION_TICKS  equ 8
BRUTE_ACTION_TICKS  equ 10
RANGED_ACTION_TICKS equ 6
POTION_HEAL         equ 3
TONIC_REGEN_TICKS   equ 16
LOS_RADIUS          equ 8
STATE_VERSION       equ 1
SAVE_MAGIC          equ 0414C4752h

SCREEN_TITLE        equ 0
SCREEN_GAME         equ 1
SCREEN_HELP         equ 2
SCREEN_DEAD         equ 3

TILE_WALL           equ 0
TILE_FLOOR          equ 1

ENTITY_NONE         equ 0
ENTITY_PLAYER       equ 1
ENTITY_SLIME        equ 2
ENTITY_BRUTE        equ 3

AI_IDLE             equ 0
AI_CHASE            equ 1

ITEM_NONE           equ 0
ITEM_POTION         equ 1
ITEM_TONIC          equ 2

STATUS_NONE         equ 0
STATUS_REGEN        equ 1

CMD_NONE            equ 0
CMD_MOVE_UP         equ 1
CMD_MOVE_DOWN       equ 2
CMD_MOVE_LEFT       equ 3
CMD_MOVE_RIGHT      equ 4
CMD_WAIT            equ 5
CMD_PICKUP          equ 6
CMD_USE             equ 7
CMD_DROP            equ 8
CMD_RANGED          equ 9

PLAYER_ENTITY_INDEX equ 0

VK_BACK             equ 08h
VK_RETURN           equ 0Dh
VK_ESCAPE           equ 1Bh
VK_SPACE            equ 20h
VK_LEFT             equ 25h
VK_UP               equ 26h
VK_RIGHT            equ 27h
VK_DOWN             equ 28h
VK_F5               equ 74h
VK_F9               equ 78h

WM_DESTROY          equ 0002h
WM_CLOSE            equ 0010h
WM_PAINT            equ 000Fh
WM_ERASEBKGND       equ 0014h
WM_KEYDOWN          equ 0100h
WM_KEYUP            equ 0101h
WM_SYSKEYDOWN       equ 0104h
WM_SYSKEYUP         equ 0105h

PM_REMOVE           equ 0001h

CS_VREDRAW          equ 0001h
CS_HREDRAW          equ 0002h

WS_CAPTION          equ 00C00000h
WS_SYSMENU          equ 00080000h
WS_MINIMIZEBOX      equ 00020000h
WINDOW_STYLE        equ 00CA0000h
CW_USEDEFAULT       equ 80000000h
SW_SHOWDEFAULT      equ 10

IDC_ARROW           equ 32512
BI_RGB              equ 0
DIB_RGB_COLORS      equ 0
SRCCOPY             equ 00CC0020h
ANSI_FIXED_FONT     equ 11
TRANSPARENT         equ 1

GENERIC_READ        equ 80000000h
GENERIC_WRITE       equ 40000000h
FILE_SHARE_READ     equ 00000001h
CREATE_ALWAYS       equ 2
OPEN_EXISTING       equ 3
FILE_ATTRIBUTE_NORMAL equ 80h
INVALID_HANDLE_VALUE equ -1

STD_OUTPUT_HANDLE   equ -11

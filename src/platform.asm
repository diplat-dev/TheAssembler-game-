include game.inc

EXTERN rt_instance:QWORD
EXTERN rt_window:QWORD
EXTERN rt_quit_requested:DWORD
EXTERN rt_last_ms:QWORD
EXTERN rt_accumulator_ms:QWORD
EXTERN rt_key_down:BYTE
EXTERN rt_key_pressed:BYTE
EXTERN rt_font:QWORD
EXTERN rt_msg:BYTE
EXTERN rt_wndclass:BYTE
EXTERN rt_rect:DWORD
EXTERN rt_bytes_io:DWORD
EXTERN rt_bmi:BYTE
EXTERN str_class_name:BYTE
EXTERN str_window_title:BYTE
EXTERN util_memset:PROC

EXTERN GetModuleHandleA:PROC
EXTERN LoadCursorA:PROC
EXTERN RegisterClassExA:PROC
EXTERN AdjustWindowRectEx:PROC
EXTERN CreateWindowExA:PROC
EXTERN ShowWindow:PROC
EXTERN PeekMessageA:PROC
EXTERN TranslateMessage:PROC
EXTERN DispatchMessageA:PROC
EXTERN DefWindowProcA:PROC
EXTERN DestroyWindow:PROC
EXTERN PostQuitMessage:PROC
EXTERN Sleep:PROC
EXTERN GetTickCount64:PROC
EXTERN CreateFileA:PROC
EXTERN WriteFile:PROC
EXTERN ReadFile:PROC
EXTERN CloseHandle:PROC
EXTERN GetStockObject:PROC

PUBLIC platform_init
PUBLIC platform_pump_messages
PUBLIC platform_get_ticks
PUBLIC platform_sleep_brief
PUBLIC platform_write_file
PUBLIC platform_read_file

WNDCLASSEX_cbSize       equ 0
WNDCLASSEX_style        equ 4
WNDCLASSEX_lpfnWndProc  equ 8
WNDCLASSEX_cbClsExtra   equ 16
WNDCLASSEX_cbWndExtra   equ 20
WNDCLASSEX_hInstance    equ 24
WNDCLASSEX_hIcon        equ 32
WNDCLASSEX_hCursor      equ 40
WNDCLASSEX_hbrBackground equ 48
WNDCLASSEX_lpszMenuName equ 56
WNDCLASSEX_lpszClassName equ 64
WNDCLASSEX_hIconSm      equ 72

RECT_left               equ 0
RECT_top                equ 4
RECT_right              equ 8
RECT_bottom             equ 12

MSG_message             equ 8

BITMAPINFO_biSize       equ 0
BITMAPINFO_biWidth      equ 4
BITMAPINFO_biHeight     equ 8
BITMAPINFO_biPlanes     equ 12
BITMAPINFO_biBitCount   equ 14
BITMAPINFO_biCompression equ 16
BITMAPINFO_biSizeImage  equ 20
BITMAPINFO_biXPelsPerMeter equ 24
BITMAPINFO_biYPelsPerMeter equ 28
BITMAPINFO_biClrUsed    equ 32
BITMAPINFO_biClrImportant equ 36

.code

WndProc PROC FRAME
    sub rsp, 40
    .allocstack 40
    .endprolog

    cmp edx, WM_KEYDOWN
    je WndProc_KeyDown
    cmp edx, WM_SYSKEYDOWN
    je WndProc_KeyDown
    cmp edx, WM_KEYUP
    je WndProc_KeyUp
    cmp edx, WM_SYSKEYUP
    je WndProc_KeyUp
    cmp edx, WM_ERASEBKGND
    je WndProc_Erase
    cmp edx, WM_CLOSE
    je WndProc_Close
    cmp edx, WM_DESTROY
    je WndProc_Destroy

WndProc_Default:
    call DefWindowProcA
    add rsp, 40
    ret

WndProc_KeyDown:
    cmp r8d, 255
    ja WndProc_KeyHandled
    mov byte ptr [rt_key_down + r8], 1
    mov eax, r9d
    shr eax, 30
    and eax, 1
    cmp eax, 0
    jne WndProc_KeyHandled
    mov byte ptr [rt_key_pressed + r8], 1
WndProc_KeyHandled:
    xor eax, eax
    add rsp, 40
    ret

WndProc_KeyUp:
    cmp r8d, 255
    ja WndProc_KeyUpDone
    mov byte ptr [rt_key_down + r8], 0
WndProc_KeyUpDone:
    xor eax, eax
    add rsp, 40
    ret

WndProc_Erase:
    mov eax, 1
    add rsp, 40
    ret

WndProc_Close:
    call DestroyWindow
    xor eax, eax
    add rsp, 40
    ret

WndProc_Destroy:
    mov dword ptr [rt_quit_requested], 1
    xor ecx, ecx
    call PostQuitMessage
    xor eax, eax
    add rsp, 40
    ret
WndProc ENDP

platform_init PROC FRAME
    sub rsp, 120
    .allocstack 120
    .endprolog

    xor edx, edx
    lea rcx, rt_key_down
    mov r8d, 256
    call util_memset

    xor edx, edx
    lea rcx, rt_key_pressed
    mov r8d, 256
    call util_memset

    mov dword ptr [rt_quit_requested], 0
    mov qword ptr [rt_accumulator_ms], 0

    xor ecx, ecx
    call GetModuleHandleA
    mov qword ptr [rt_instance], rax

    mov dword ptr [rt_rect + RECT_left], 0
    mov dword ptr [rt_rect + RECT_top], 0
    mov dword ptr [rt_rect + RECT_right], WINDOW_WIDTH
    mov dword ptr [rt_rect + RECT_bottom], WINDOW_HEIGHT

    lea rcx, rt_rect
    mov edx, WINDOW_STYLE
    xor r8d, r8d
    xor r9d, r9d
    call AdjustWindowRectEx

    xor ecx, ecx
    mov edx, IDC_ARROW
    call LoadCursorA
    mov qword ptr [rsp + 104], rax

    lea r10, rt_wndclass
    mov dword ptr [r10 + WNDCLASSEX_cbSize], 80
    mov dword ptr [r10 + WNDCLASSEX_style], CS_HREDRAW or CS_VREDRAW
    mov rax, OFFSET WndProc
    mov qword ptr [r10 + WNDCLASSEX_lpfnWndProc], rax
    mov dword ptr [r10 + WNDCLASSEX_cbClsExtra], 0
    mov dword ptr [r10 + WNDCLASSEX_cbWndExtra], 0
    mov rax, qword ptr [rt_instance]
    mov qword ptr [r10 + WNDCLASSEX_hInstance], rax
    mov qword ptr [r10 + WNDCLASSEX_hIcon], 0
    mov rax, qword ptr [rsp + 104]
    mov qword ptr [r10 + WNDCLASSEX_hCursor], rax
    mov qword ptr [r10 + WNDCLASSEX_hbrBackground], 0
    mov qword ptr [r10 + WNDCLASSEX_lpszMenuName], 0
    mov rax, OFFSET str_class_name
    mov qword ptr [r10 + WNDCLASSEX_lpszClassName], rax
    mov qword ptr [r10 + WNDCLASSEX_hIconSm], 0

    lea rcx, rt_wndclass
    call RegisterClassExA

    mov eax, dword ptr [rt_rect + RECT_right]
    sub eax, dword ptr [rt_rect + RECT_left]
    mov dword ptr [rsp + 96], eax
    mov eax, dword ptr [rt_rect + RECT_bottom]
    sub eax, dword ptr [rt_rect + RECT_top]
    mov dword ptr [rsp + 92], eax

    sub rsp, 96
    xor ecx, ecx
    lea rdx, str_class_name
    lea r8, str_window_title
    mov r9d, WINDOW_STYLE
    mov eax, CW_USEDEFAULT
    mov qword ptr [rsp + 32], rax
    mov qword ptr [rsp + 40], rax
    mov eax, dword ptr [rsp + 192]
    mov qword ptr [rsp + 48], rax
    mov eax, dword ptr [rsp + 188]
    mov qword ptr [rsp + 56], rax
    mov qword ptr [rsp + 64], 0
    mov qword ptr [rsp + 72], 0
    mov rax, qword ptr [rt_instance]
    mov qword ptr [rsp + 80], rax
    mov qword ptr [rsp + 88], 0
    call CreateWindowExA
    add rsp, 96

    mov qword ptr [rt_window], rax

    mov rcx, rax
    mov edx, SW_SHOWDEFAULT
    call ShowWindow

    mov ecx, ANSI_FIXED_FONT
    call GetStockObject
    mov qword ptr [rt_font], rax

    mov dword ptr [rt_bmi + BITMAPINFO_biSize], 40
    mov dword ptr [rt_bmi + BITMAPINFO_biWidth], WINDOW_WIDTH
    mov dword ptr [rt_bmi + BITMAPINFO_biHeight], -WINDOW_HEIGHT
    mov word ptr [rt_bmi + BITMAPINFO_biPlanes], 1
    mov word ptr [rt_bmi + BITMAPINFO_biBitCount], 32
    mov dword ptr [rt_bmi + BITMAPINFO_biCompression], BI_RGB
    mov dword ptr [rt_bmi + BITMAPINFO_biSizeImage], 0
    mov dword ptr [rt_bmi + BITMAPINFO_biXPelsPerMeter], 0
    mov dword ptr [rt_bmi + BITMAPINFO_biYPelsPerMeter], 0
    mov dword ptr [rt_bmi + BITMAPINFO_biClrUsed], 0
    mov dword ptr [rt_bmi + BITMAPINFO_biClrImportant], 0

    call GetTickCount64
    mov qword ptr [rt_last_ms], rax

    add rsp, 120
    ret
platform_init ENDP

platform_pump_messages PROC FRAME
    sub rsp, 56
    .allocstack 56
    .endprolog

platform_pump_loop:
    lea rcx, rt_msg
    xor edx, edx
    xor r8d, r8d
    xor r9d, r9d
    mov qword ptr [rsp + 32], PM_REMOVE
    call PeekMessageA
    test eax, eax
    jz platform_pump_done

    cmp dword ptr [rt_msg + MSG_message], 0012h
    jne platform_pump_dispatch
    mov dword ptr [rt_quit_requested], 1
    jmp platform_pump_loop

platform_pump_dispatch:
    lea rcx, rt_msg
    call TranslateMessage
    lea rcx, rt_msg
    call DispatchMessageA
    jmp platform_pump_loop

platform_pump_done:
    add rsp, 56
    ret
platform_pump_messages ENDP

platform_get_ticks PROC
    sub rsp, 40
    call GetTickCount64
    add rsp, 40
    ret
platform_get_ticks ENDP

platform_sleep_brief PROC
    sub rsp, 40
    mov ecx, 1
    call Sleep
    add rsp, 40
    ret
platform_sleep_brief ENDP

platform_write_file PROC FRAME
    sub rsp, 104
    .allocstack 104
    .endprolog

    mov qword ptr [rsp + 56], rcx
    mov qword ptr [rsp + 64], rdx
    mov dword ptr [rsp + 72], r8d

    mov rcx, qword ptr [rsp + 56]
    mov edx, GENERIC_WRITE
    mov r8d, FILE_SHARE_READ
    xor r9d, r9d
    mov qword ptr [rsp + 32], CREATE_ALWAYS
    mov qword ptr [rsp + 40], FILE_ATTRIBUTE_NORMAL
    mov qword ptr [rsp + 48], 0
    call CreateFileA

    cmp rax, INVALID_HANDLE_VALUE
    jne platform_write_have_file
    xor eax, eax
    add rsp, 104
    ret

platform_write_have_file:
    mov qword ptr [rsp + 80], rax
    mov dword ptr [rt_bytes_io], 0

    mov rcx, qword ptr [rsp + 80]
    mov rdx, qword ptr [rsp + 64]
    mov r8d, dword ptr [rsp + 72]
    lea r9, rt_bytes_io
    mov qword ptr [rsp + 32], 0
    call WriteFile

    mov dword ptr [rsp + 88], eax

    mov rcx, qword ptr [rsp + 80]
    call CloseHandle

    cmp dword ptr [rsp + 88], 0
    je platform_write_fail
    mov eax, dword ptr [rt_bytes_io]
    cmp eax, dword ptr [rsp + 72]
    jne platform_write_fail
    mov eax, 1
    add rsp, 104
    ret

platform_write_fail:
    xor eax, eax
    add rsp, 104
    ret
platform_write_file ENDP

platform_read_file PROC FRAME
    sub rsp, 104
    .allocstack 104
    .endprolog

    mov qword ptr [rsp + 56], rcx
    mov qword ptr [rsp + 64], rdx
    mov dword ptr [rsp + 72], r8d

    mov rcx, qword ptr [rsp + 56]
    mov edx, GENERIC_READ
    mov r8d, FILE_SHARE_READ
    xor r9d, r9d
    mov qword ptr [rsp + 32], OPEN_EXISTING
    mov qword ptr [rsp + 40], FILE_ATTRIBUTE_NORMAL
    mov qword ptr [rsp + 48], 0
    call CreateFileA

    cmp rax, INVALID_HANDLE_VALUE
    jne platform_read_have_file
    xor eax, eax
    add rsp, 104
    ret

platform_read_have_file:
    mov qword ptr [rsp + 80], rax
    mov dword ptr [rt_bytes_io], 0

    mov rcx, qword ptr [rsp + 80]
    mov rdx, qword ptr [rsp + 64]
    mov r8d, dword ptr [rsp + 72]
    lea r9, rt_bytes_io
    mov qword ptr [rsp + 32], 0
    call ReadFile

    mov dword ptr [rsp + 88], eax

    mov rcx, qword ptr [rsp + 80]
    call CloseHandle

    cmp dword ptr [rsp + 88], 0
    je platform_read_fail
    mov eax, dword ptr [rt_bytes_io]
    cmp eax, dword ptr [rsp + 72]
    jne platform_read_fail
    mov eax, 1
    add rsp, 104
    ret

platform_read_fail:
    xor eax, eax
    add rsp, 104
    ret
platform_read_file ENDP

END

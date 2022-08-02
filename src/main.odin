package app

import win32 "core:sys/windows"
import fmt "core:fmt"

// some constants for easy changeability
TITLE :: "Sample app"
WINDOW_CLASS_NAME :: "Sample app window class"

global_is_running : bool

// Basic logging, in order to control what happens on logging messages
log :: proc(format : string, args : ..any)
{
    s := fmt.tprintf(format, ..args)
    win32.OutputDebugStringW(win32.utf8_to_wstring(s ,context.temp_allocator))
}

// WNDPPROC procedure. stdcall is needed to make it compatible with win32 api. The Odin context is then also not passed along
window_on_message :: proc "stdcall" (window : win32.HWND, message : win32.UINT, w : win32.WPARAM, l : win32.LPARAM) -> win32.LRESULT
{
    result : win32.LRESULT

    switch message {
    case win32.WM_DESTROY:
        global_is_running = false
        result = 0
    case:
        result = win32.DefWindowProcW(window, message, w, l)
    }

    return result
}

main :: proc()
{
    global_is_running = true

    window_class_name_w := win32.utf8_to_wstring(WINDOW_CLASS_NAME, context.temp_allocator)         // convert the standard Odin utf-8 strings to win32 wide strings (16-bit)
    instance : win32.HANDLE = auto_cast win32.GetModuleHandleW(nil)
    icon := win32.LoadIconA(nil, win32.IDI_APPLICATION)
    cursor := win32.LoadCursorA(nil, win32.IDC_ARROW)
    background_brush := win32.GetSysColorBrush(win32.COLOR_HIGHLIGHT)

    window_class : win32.WNDCLASSEXW = 
    {
        cbSize = size_of(win32.WNDCLASSEXW),
        style = 0,
        lpfnWndProc = window_on_message,
        hInstance = instance,
        hIcon = icon,
        hCursor = cursor,
        hbrBackground = background_brush,
        lpszClassName = window_class_name_w,
    }

    if win32.RegisterClassExW(&window_class) != auto_cast 0
    {
        // Creating a simple window with defaults
        title_w := win32.utf8_to_wstring(TITLE, context.temp_allocator)
        window := win32.CreateWindowExW(0, 
                                        window_class.lpszClassName, 
                                        title_w, 
                                        win32.WS_OVERLAPPEDWINDOW, 
                                        win32.CW_USEDEFAULT, 
                                        win32.CW_USEDEFAULT, 
                                        win32.CW_USEDEFAULT, 
                                        win32.CW_USEDEFAULT, 
                                        nil, 
                                        nil, 
                                        instance, 
                                        nil)
        if window != nil
        {
            win32.ShowWindow(window, win32.SW_SHOW)
            for global_is_running == true
            {
                message : win32.MSG
                for message_result :=  win32.PeekMessageW(&message, window, 0, 0, win32.PM_REMOVE); message_result; message_result =  win32.PeekMessageW(&message, window, 0, 0, win32.PM_REMOVE)
                {
                    win32.TranslateMessage(&message)
                    win32.DispatchMessageW(&message)
                }
            }
        }
        else
        {
            log("Cannot create a window\n")
        }
    }
    else
    {
        log("Cannot register a window class\n")
    }
}

module mar.windows.user32;

pragma(lib, "kernel32.lib");

import mar.c : cint, cuint;
import mar.windows.types : WindowHandle;

extern (Windows) WindowHandle GetActiveWindow() nothrow @nogc;

enum MessageBoxType : cuint
{
    ok = 0,
    abortRetryIgnore = 0x2,
    cancelTryContinue = 0x6,
    help = 0x4000,
}

extern (Windows) cint MessageBoxA(
    WindowHandle window,
    const(char)* text,
    const(char)* caption,
    MessageBoxType type
) nothrow @nogc;
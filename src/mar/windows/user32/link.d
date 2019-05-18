module mar.windows.user32.link;

pragma(lib, "kernel32.lib");

import mar.c : cint, cuint;
import mar.windows : WindowHandle;
import mar.windows.user32.nolink;

extern (Windows) WindowHandle GetActiveWindow() nothrow @nogc;

extern (Windows) cint MessageBoxA(
    WindowHandle window,
    const(char)* text,
    const(char)* caption,
    MessageBoxType type
) nothrow @nogc;

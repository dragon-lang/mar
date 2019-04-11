module mar.windows.io;

import mar.windows.kernel32 : GetStdHandle;
import mar.windows.file : FileD;

private __gshared FileD stdinHandle = FileD.invalidValue;
private __gshared FileD stdoutHandle = FileD.invalidValue;
private __gshared FileD stderrHandle = FileD.invalidValue;
/*
static this()
{
    version (DontInitializeStandardHandles)
    {

    }
    else
    {
        import mar.windows.user32;
        MessageBoxA(GetActiveWindow(), "initializing standard handles", "debug", MessageBoxType.ok);
        stdinHandle = GetStdHandle(cast(uint)cast(int)-10).asFileD;
        stdoutHandle = GetStdHandle(cast(uint)cast(int)-11).asFileD;
        stderrHandle = GetStdHandle(cast(uint)cast(int)-12).asFileD;
        MessageBoxA(GetActiveWindow(), "initialized standard handles", "debug", MessageBoxType.ok);
    }
}
*/
pragma(inline) FileD stdin() nothrow @nogc
{
    if (!stdinHandle.isValid)
        stdinHandle = GetStdHandle(cast(uint)cast(int)-10).asFileD;
    return stdinHandle;
}
pragma(inline) FileD stdout() nothrow @nogc
{
    if (!stdoutHandle.isValid)
        stdoutHandle = GetStdHandle(cast(uint)cast(int)-11).asFileD;
    return stdoutHandle;
}
pragma(inline) FileD stderr() nothrow @nogc
{
    if (!stderrHandle.isValid)
        stderrHandle = GetStdHandle(cast(uint)cast(int)-12).asFileD;
    return stderrHandle;
}

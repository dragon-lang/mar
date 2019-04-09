module mar.windows.io;

import mar.windows.kernel32 : GetStdHandle;
import mar.windows.file : FileD;

private __gshared FileD stdinHandle;
private __gshared FileD stdoutHandle;
private __gshared FileD stderrHandle;
static this()
{
    version (DontInitializeStandardHandles)
    {

    }
    else
    {
        stdinHandle = GetStdHandle(cast(uint)cast(int)-10).asFileD;
        stdoutHandle = GetStdHandle(cast(uint)cast(int)-11).asFileD;
        stderrHandle = GetStdHandle(cast(uint)cast(int)-12).asFileD;
    }
}
pragma(inline) FileD stdin() nothrow @nogc { return stdinHandle; }
pragma(inline) FileD stdout() nothrow @nogc { return stdoutHandle; }
pragma(inline) FileD stderr() nothrow @nogc { return stderrHandle; }

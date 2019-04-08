module mar.windows.io;

import mar.windows.file : FileD;

// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// I don't think this is right for windows
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
pragma(inline) const(FileD) stdin() pure nothrow @nogc { return FileD(0); }
pragma(inline) const(FileD) stdout() pure nothrow @nogc { return FileD(1); }
pragma(inline) const(FileD) stderr() pure nothrow @nogc { return FileD(2); }

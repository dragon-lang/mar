module mar.linux.io;

import mar.linux.file : FileD;

pragma(inline) const(FileD) stdin() pure nothrow @nogc { return FileD(0); }
pragma(inline) const(FileD) stdout() pure nothrow @nogc { return FileD(1); }
pragma(inline) const(FileD) stderr() pure nothrow @nogc { return FileD(2); }

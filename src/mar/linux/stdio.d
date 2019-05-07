module mar.linux.io;

import mar.linux.file : FileD;

const(FileD) stdin() pure nothrow @nogc { pragma(inline, true); return FileD(0); }
const(FileD) stdout() pure nothrow @nogc { pragma(inline, true); return FileD(1); }
const(FileD) stderr() pure nothrow @nogc { pragma(inline, true); return FileD(2); }

module windows.kernel32;

pragma(lib, "kernel32.lib");

import mar.wrap;
import mar.c : cint;
import mar.windows.file : FileD;

extern (Windows) uint GetLastError();
extern (Windows) WindowsHandle GetStdHandle(uint handle);

/**
Represents semantics of the windows BOOL return type.
*/
struct BoolExpectNonZero
{
    private cint _value;
    pragma(inline) bool failed() const { return _value == 0; }
    pragma(inline) bool passed() const { return _value != 0; }

    auto print(P)(P printer) const
    {
        printer.put(passed ? "TRUE" : "FALSE");
    }
}

struct WindowsHandle
{
    private ptrdiff_t _value = -1;
    this(typeof(_value) value) pure nothrow @nogc
    {
        this._value = value;
    }
    bool isValid() const { return _value != -1; }
    pragma(inline) ptrdiff_t numval() const { return _value; }
    void setInvalid() { this._value = -1; }
    mixin WrapperFor!"_value";
    mixin WrapOpCast;
    pragma(inline) FileD asFileD() inout { return FileD(_value); }

    auto print(P)(P printer) const
    {
        import mar.print : printDecimal;
        return printDecimal(printer, _value);
    }
}

extern (Windows) BoolExpectNonZero WriteFile(
    const WindowsHandle handle,
    const(void)* buffer,
    uint length,
    uint* written,
    void* overlapped
);

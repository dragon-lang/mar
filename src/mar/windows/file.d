module mar.windows.file;

import mar.wrap;
import mar.c : cstring;

import mar.windows.kernel32 :
    WindowsHandle,
    GetLastError, WriteFile;

uint getLastErrorMustBeNonZero()
{
    auto result = GetLastError();
    return (result == 0) ?  500 : result;
}

struct WriteResult
{
    private uint _errorCode;
    private uint _writtenOnFailure;
    pragma(inline) bool failed() const { return _errorCode != 0; }
    pragma(inline) bool passed() const { return _errorCode == 0; }

    pragma(inline) uint onFailWritten() const
    in { assert(_errorCode != 0, "code bug"); } do
    { return _writtenOnFailure; }
    pragma(inline) uint errorCode() const { return _errorCode; }
}

extern (C) WriteResult tryWrite(WindowsHandle handle, const(void)* ptr, size_t n)
{
    size_t initialSize = n;
    while (n > 0)
    {
        auto nextLength = cast(uint)n;
        uint written;
        auto result = WriteFile(handle, ptr, nextLength, &written, null);
        n -= written;
        if (result.failed)
            return WriteResult(getLastErrorMustBeNonZero(), initialSize - n);
    }
    return WriteResult(0);
}

struct FileD
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

    pragma(inline) WindowsHandle asWindowsHandle() const { return WindowsHandle(_value); }

    auto print(P)(P printer) const
    {
        import mar.print : printDecimal;
        return printDecimal(printer, _value);
    }

    pragma(inline)
    WriteResult tryWrite(const(void)* ptr, size_t n) { return .tryWrite(asWindowsHandle, ptr, n); }
    pragma(inline)
    WriteResult tryWrite(const(void)[] array) { return .tryWrite(asWindowsHandle, array.ptr, array.length); }

    void write(T...)(T args) const
    {
        import mar.print : DefaultBufferedFilePrinterPolicy, BufferedFilePrinter, printArgs;
        alias Printer = BufferedFilePrinter!DefaultBufferedFilePrinterPolicy;

        char[DefaultBufferedFilePrinterPolicy.bufferLength] buffer;
        auto printer = Printer(this, buffer.ptr, 0);
        printArgs(&printer, args);
        printer.flush();
    }

    pragma(inline)
    void writeln(T...)(T args) const
    {
        write(args, '\n');
    }
}

bool fileExists(cstring filename)
{
    assert(0, "not impl');");
}
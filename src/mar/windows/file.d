module mar.windows.file;

import mar.wrap;
import mar.c : cstring;

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

    auto print(P)(P printer) const
    {
        import mar.print : printDecimal;
        return printDecimal(printer, _value);
    }

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
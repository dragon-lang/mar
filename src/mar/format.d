module mar.format;

import mar.traits : isArithmetic, Unqual;
import mar.sentinel : SentinelArray;

auto argsToPrinter(Printer, T...)(Printer printer, T args)
{
    import mar.array : acopy;
    import mar.string : isStringLike;

    foreach (arg; args)
    {
        //pragma(msg, typeof(arg).stringof);


        // TODO: handle wrapper types!

        //static if (is(typeof(arg.toString(printer))))
        //static if (__traits(compiles, arg.toString(printer)))
        static if (__traits(hasMember, arg, "toString"))
        {
            arg.toString(printer);
        }
        else static if (isStringLike!(typeof(arg)))
        {
            //pragma(msg, "  isStringLike");
            printer.put(cast(const(char)[])arg);
        }
        else static if (is(typeof(arg) == char))
        {
            //pragma(msg, "  is a char");
            printer.putc(arg);
        }
        else static if (isArithmetic!(typeof(arg)))
        {
            //pragma(msg, "  integral");
            printDecimal(printer, arg);
        }
        else static if (is(typeof(arg) == void*))
        {
            //pragma(msg, "  void*");
            printDecimal(printer, cast(size_t)arg);
        }
        else static if (is(typeof(arg.asCString)))
        {
            import mar.string : strlen;
            auto cString = arg.asCString;
            size_t size = strlen(cString);
            printer.put(cString[0 .. size]);
        }
        else static assert(0, "don't know how to print type " ~ typeof(arg).stringof);
    }
}

template maxDecimalDigits(T)
{
         static if (T.sizeof == 1)
        enum maxDecimalDigits = 3; // 255
    else static if (T.sizeof == 2)
        enum maxDecimalDigits = 5; // 65,535
    else static if (T.sizeof == 4)
        enum maxDecimalDigits = 10; // 4,294,967,295
    else static if (T.sizeof == 8)
        enum maxDecimalDigits = 19; // 9,223,372,036,854,775,807
    else static assert(0, "don't know max decimal digit count for " ~ T.stringof);
}

pragma(inline)
void printDecimal(T, Printer)(Printer printer, T value) if (!is(T == Unqual!T))
{
    printDecimal!(Unqual!T)(printer, value);
}
void printDecimal(T, Printer)(Printer printer, T value) if (is(T == Unqual!T))
{
    import mar.array : areverse;

    auto buffer = printer.getTempBuffer!(
        1 + // 1 for the '-' character
        maxDecimalDigits!T);
    scope (exit) printer.commitBuffer(buffer.commitValue);

    if (value == 0)
    {
        buffer.ptr[0] = '0';
        buffer.ptr++;
        return;
    }
    static if (T.min < 0)
    {
        if (value < 0)
        {
            buffer.ptr[0] = '-';
            buffer.ptr++;
            value *= -1; // NOTE: this won't always work
        }
    }
    auto saveDigitStart = buffer.ptr;
    for (;;)
    {
        buffer.ptr[0] = (value % 10) + '0';
        buffer.ptr++;
        value /= 10;
        if (value == 0)
        {
            areverse(saveDigitStart, buffer.ptr);
            return;
        }
    }
}


immutable hexTableLower = "0123456789abcdef";
immutable hexTableUpper = "0123456789ABCDEF";
pragma(inline)
void printHex(T, Printer)(Printer printer, T value) if (!is(T == Unqual!T))
{
    printHex!(Unqual!T)(printer, value);
}
void printHex(T, Printer)(Printer printer, T value) if (is(T == Unqual!T))
{
    import mar.array : areverse;

    auto buffer = printer.getTempBuffer!(
        1 +          // 1 for the '-' character
        T.sizeof * 2 //max hex digits
        );
    scope (exit) printer.commitBuffer(buffer.commitValue);

    auto saveDigitStart = buffer.ptr;
    for (;;)
    {
        buffer.ptr[0] = hexTableLower[value & 0b1111];
        buffer.ptr++;
        value >>= 4;
        if (value == 0)
        {
            areverse(saveDigitStart, buffer.ptr);
            return;
        }
    }
}

// Every printer should be able to return a buffer
// large enough to hold at least some characters for
// things like printing numbers and such
//enum MinPrinterBufferLength = 100;


struct DefaultBufferedFilePrinterPolicy
{
    enum bufferLength = 50;

    // TODO: make this a template
    //static void throwError(T...)(T msg)
    static void throwError(const(char)[] msg)
    {
        import mar.file : stderr, write;
        import mar.process : exit;

        write(stderr, msg);
        exit(1);
    }
}

struct DefaultPrinterBuffer
{
    char* ptr;
    auto commitValue()
    {
        return this;
    }
    pragma(inline) void putc(char c) { ptr[0] = c; ptr++; }
}


struct BufferedFilePrinter(Policy)
{
    import mar.array : acopy;
    import mar.file : FileD, write;

    static assert(__traits(hasMember, Policy, "throwError"));
    static assert(__traits(hasMember, Policy, "bufferLength"));

    private FileD fd;
    private char* buffer;
    private size_t bufferedLength;

    //
    // The Printer Interface
    //
    void flush()
    {
        if (bufferedLength > 0)
        {
            auto result = write(fd, buffer[0 .. bufferedLength]);
            if (result.val != bufferedLength)
            {
                //Policy.throwError("write ", len, " bytes to ", fd, " failed, returned ", result);
                Policy.throwError("write failed");
            }
            bufferedLength = 0;
        }
    }
    void put(const(char)[] str)
    {
        auto left = Policy.bufferLength - bufferedLength;
        if (left < str.length)
        {
            flush();
            auto result = write(fd, str);
            if (result.val != str.length)
            {
                //Policy.throwError("write ", str.length, " bytes to ", fd, " failed, returned ", result);
                Policy.throwError("write failed");
            }
        }
        else
        {
            acopy(buffer + bufferedLength, str);
            bufferedLength += str.length;
        }
    }
    void putc(const char c)
    {
        if (bufferedLength == Policy.bufferLength)
            flush();
        buffer[bufferedLength++] = c;
    }

    /**
    Example:
    ---
    auto buffer = printer.getTempBuffer(10);
    buffer.ptr[0] = 'a';
    buffer.ptr[1] = 'b';
    printer.commitBuffer(buffer.commitValue);
    ---
    WARNING: you cannot call other printer functions while
             using this buffer, like `flush`, `put`.
    */
    pragma(inline)
    auto getTempBuffer(size_t size)()
    {
        static assert(size <= Policy.bufferLength);
        auto left = Policy.bufferLength - bufferedLength;
        if (left < size)
            flush();
        return DefaultPrinterBuffer(buffer + bufferedLength);
    }
    auto tryGetTempBufferImpl(size_t size)
    {
        if (size > Policy.bufferLength)
            return DefaultPrinterBuffer(null); // can't get a buffer of that size
        auto left = Policy.bufferLength - bufferedLength;
        if (left < size)
            flush();
        return DefaultPrinterBuffer(buffer + bufferedLength);
    }
    void commitBuffer(DefaultPrinterBuffer buf)
    {
        bufferedLength = buf.ptr - buffer;
    }
}


private struct FormatHex(T)
{
    T value;
    void toString(Printer)(Printer printer) const
    {
        static if (T.sizeof <= size_t.sizeof)
            printHex(printer, cast(size_t)value);
        else
            printHex(printer, cast(ulong)value);
    }
}
auto formatHex(T)(T value)
{
    return FormatHex!T(value);
}


struct StringPrinter
{
    import mar.array : acopy;

    private char[] buffer;
    private size_t bufferedLength;

    private auto capacity() const { return buffer.length - bufferedLength; }
    private void enforceCapacity(size_t needed)
    {
        assert(capacity >= needed, "StringPrinter capacity is too small");
    }

    //
    // The Printer Interface
    //
    pragma(inline)
    void flush() { }
    void put(const(char)[] str)
    {
        enforceCapacity(str.length);
        acopy(buffer.ptr + bufferedLength, str);
        bufferedLength += str.length;
    }
    void putc(const char c)
    {
        enforceCapacity(1);
        buffer[bufferedLength++] = c;
    }

    pragma(inline)
    auto getTempBuffer(size_t size)()
    {
        enforceCapacity(size);
        return DefaultPrinterBuffer(buffer.ptr +  + bufferedLength);
    }
    auto tryGetTempBufferImpl(size_t size)
    {
        return (capacity < size) ?
            DefaultPrinterBuffer(null) :
            DefaultPrinterBuffer(buffer.ptr + bufferedLength);
    }
    void commitBuffer(DefaultPrinterBuffer buf)
    {
        bufferedLength = buf.ptr - buffer.ptr;
    }
}

struct CalculateSizePrinter
{
    private size_t size;
    //
    // The Printer Interface
    //
    pragma(inline)
    void flush() { }
    void put(const(char)[] str) { size += str.length; }
    void putc(const char c) { size++; }
    /+
    pragma(inline)
    auto getTempBuffer(size_t size)()
    {
        enforceCapacity(size);
        return DefaultPrinterBuffer(buffer.ptr +  + bufferedLength);
    }
    auto tryGetTempBufferImpl(size_t size)
    {
        return (capacity < size) ?
            DefaultPrinterBuffer(null) :
            DefaultPrinterBuffer(buffer.ptr + bufferedLength);
    }
    void commitBuffer(DefaultPrinterBuffer buf)
    {
        bufferedLength = buf.ptr - buffer.ptr;
    }
    +/
}
size_t getPrintSize(T...)(T args)
{
    auto printer = CalculateSizePrinter(0);
    argsToPrinter(&printer, args);
    return printer.size;
}


size_t sprint(T...)(char[] buffer, T args)
{
    auto printer = StringPrinter(buffer, 0);
    argsToPrinter(&printer, args);
    return printer.bufferedLength;
}

char[] sprintMallocNoSentinel(T...)(T args)
{
    import mar.mem : malloc;

    auto totalSize = getPrintSize(args);
    auto buffer = cast(char*)malloc(totalSize);
    if (!buffer)
        return null;
    const printedSize = sprint(buffer[0 .. totalSize], args);
    assert(printedSize == totalSize, "codebug: precalculated print size differed from actual size");
    return buffer[0 .. totalSize];
}
SentinelArray!char sprintMallocSentinel(T...)(T args)
{
    import mar.mem : malloc;
    import mar.sentinel : assumeSentinel;

    auto totalSize = getPrintSize(args);
    auto buffer = cast(char*)malloc(totalSize + 1);
    if (!buffer)
        return SentinelArray!char.nullValue;
    const printedSize = sprint(buffer[0 .. totalSize], args);
    assert(printedSize == totalSize, "codebug: precalculated print size differed from actual size");
    buffer[totalSize] = '\0';
    return buffer[0 .. totalSize].assumeSentinel;
}

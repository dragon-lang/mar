module mar.print;

import mar.traits : isArithmetic, Unqual;
import mar.sentinel : SentinelArray;

/**
Takes a single argument and prints it to the given `printer`.
The function will try each of the following in order to print the argument

1. if `arg` has a `print` method, it will call that
2. if `isStringLike!(typeof(arg))`, it will forward it to `printer.put`
3. If `typeof(arg) == char`, it will forward it to `printer.putc`
4. if `typeof(arg) == bool`, it will call `printer.put(arg ? "true" : "false")`
5. if `typeof(arg) == void*`, it will call `printHex(printer, arg)`
6. is `isArithmetic!(typeof(arg))`, it will call `printDecimal(printer, arg)`

*/
auto printArg(Printer, T)(Printer printer, T arg)
{
    pragma(inline, true);
    import mar.string : isStringLike;

    //static if (is(typeof(arg.print(printer))))
    //static if (__traits(compiles, arg.print(printer)))
    static if (__traits(hasMember, arg, "print"))
        return arg.print(printer);
    else static if (isStringLike!(typeof(arg)))
        return printer.put(cast(const(char)[])arg);
    else static if (is(Unqual!(typeof(arg)) == char))
        return printer.putc(arg);
    else static if (is(Unqual!(typeof(arg)) == bool))
        return printer.put(arg ? "true" : "false");
    else static if (is(typeof(arg) == void*))
        return printHex(printer, cast(size_t)arg);
    else static if (is(Unqual!(typeof(arg)) == float))
        return printFloat(printer, arg);
    else static if (isArithmetic!(typeof(arg)))
    //else static if (__traits(compiles, printDecimal(printer, arg)))
        return printDecimal(printer, arg);
    else static assert(0, "don't know how to print type " ~ typeof(arg).stringof);
}

/**
Call `printArg` on each argument, but stop printing if one of them fails.
*/
auto printArgs(Printer, T...)(Printer printer, T args)
{
    foreach (arg; args)
    {
        auto result = printArg(printer, arg);
        if (result.failed)
            return result;
    }
    return Printer.success;
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

/**
NOTE: this is a "normalization" function to prevent template bloat
*/
auto printDecimal(T, Printer)(Printer printer, T value)
{
    pragma(inline, true);
    auto buffer = printer.getTempBuffer!(
        1 + // 1 for the '-' character
        maxDecimalDigits!T);
    scope (exit) printer.commitBuffer(buffer.commitValue);

    static if (T.sizeof > size_t.sizeof)
    {
        static if (T.sizeof > long.sizeof)
            static assert(0, "printing numbers with this bit width is not implemented");
        else
        {
            alias stype = long;
            alias utype = ulong;
        }
    }
    else
    {
        alias stype = ptrdiff_t;
        alias utype = size_t;
    }

    static if (T.min >= 0)
    {
        buffer.ptr = printDecimalTemplate!utype(buffer.ptr, cast(utype)value);
    }
    else
    {
        if (value < 0)
        {
            buffer.ptr[0] = '-';
            buffer.ptr++;
            buffer.ptr = printDecimalTemplate!utype(buffer.ptr, cast(utype)(-cast(stype)value));
        }
        else
        {
            buffer.ptr = printDecimalTemplate!utype(buffer.ptr, cast(utype)value);
        }
    }
    return Printer.success;
}

unittest
{
    import mar.array : aequals;
    char[50] buffer;
    char[] str(T)(T num)
    {
        auto result = buffer[0 .. sprint(buffer, num)];
        import mar.stdio; stdout.writeln("TestNumber: ", result);
        return result;
    }

    assert(aequals(str(short.min), "-32768"));
    assert(aequals(str(short.max), "32767"));
    assert(aequals(str(ushort.min), "0"));
    assert(aequals(str(ushort.max), "65535"));
    assert(aequals(str(int.min), "-2147483648"));
    assert(aequals(str(int.max), "2147483647"));
    assert(aequals(str(uint.min), "0"));
    assert(aequals(str(uint.max), "4294967295"));

    // TODO: remove this static if when all integer sizes are implemented
    static if (long.sizeof <= size_t.sizeof)
    {
        assert(aequals(str(long.min), "-9223372036854775808"));
        assert(aequals(str(long.max), "9223372036854775807"));
        assert(aequals(str(ulong.min), "0"));
        assert(aequals(str(ulong.max), "18446744073709551615"));
    }
}

private char* printDecimalTemplate(T)(char* buffer, T value)
{
    import mar.array : areverse;

    if (value == 0)
    {
        buffer[0] = '0';
        return buffer + 1;
    }
    auto start = buffer;
    for (;;)
    {
        buffer[0] = (value % 10) + '0';
        buffer++;
        value /= 10;
        if (value == 0)
        {
            areverse(start, buffer);
            return buffer;
        }
    }
}

immutable hexTableLower = "0123456789abcdef";
immutable hexTableUpper = "0123456789ABCDEF";
auto printHex(T, Printer)(Printer printer, T value)
{
    import mar.array : areverse;

    auto buffer = printer.getTempBuffer!(
        1 +          // 1 for the '-' character
        T.sizeof * 2 //max hex digits
        );
    scope (exit) printer.commitBuffer(buffer.commitValue);

    static if (T.sizeof > size_t.sizeof)
    {
        static if (T.sizeof > ulong.sizeof)
            static assert(0, "printing numbers with this bit width is not implemented");
        else
        {
            alias utype = ulong;
        }
    }
    else
    {
        alias utype = size_t;
    }

    static if (T.min < 0)
        static assert(0, "printing signed hex values not implemented");
    else
    {
        buffer.ptr = printHexTemplate!utype(buffer.ptr, cast(utype)value);
    }
    return Printer.success;
}
private char* printHexTemplate(T)(char* buffer, T value)
{
    import mar.array : areverse;

    auto start = buffer;
    for (;;)
    {
        buffer[0] = hexTableLower[value & 0b1111];
        buffer++;
        value >>= 4;
        if (value == 0)
        {
            areverse(start, buffer);
            return buffer;
        }
    }
}

auto printFloat(Printer)(Printer printer, float f)
{
    import mar.ryu : FLOAT_MAX_CHARS, floatToString;

    auto buffer = printer.getTempBuffer!(FLOAT_MAX_CHARS);
    scope (exit) printer.commitBuffer(buffer.commitValue);
    buffer.ptr += floatToString(f, buffer.ptr);
    return Printer.success;
}

// TODO: maybe put this somewhere else
//       a printer could return this type if will not return errors.
//       an example of this would be a printer that exits on failure instead
//       of returning the error
struct CannotFail
{
    static bool failed() { pragma(inline, true); return false; }
}

// Every printer should be able to return a buffer
// large enough to hold at least some characters for
// things like printing numbers and such
//enum MinPrinterBufferLength = 30; ??

struct BufferedFileReturnErrorPrinterPolicy
{
    import mar.file : FileD;
    import mar.expect;

    enum bufferLength = 50;

    mixin ExpectMixin!("PutResult", void,
        ErrorCase!("writeFailed", "write failed, returned %", ptrdiff_t));

    static PutResult success() { pragma(inline, true); return PutResult.success; }
    static PutResult writeFailed(FileD dest, size_t writeSize, ptrdiff_t errno)
    {
        // TODO: do something with dest/writeSize
        return PutResult.writeFailed(errno);
    }
}
version (NoExit)
    alias DefaultBufferedFilePrinterPolicy = BufferedFileReturnErrorPrinterPolicy;
else
{
    alias DefaultBufferedFilePrinterPolicy = BufferedFileExitPrinterPolicy;
    struct BufferedFileExitPrinterPolicy
    {
        import mar.file : FileD;

        enum bufferLength = 50;

        alias PutResult = CannotFail;
        static CannotFail success() { return CannotFail(); }
        static CannotFail writeFailed(FileD dest, size_t writeSize, ptrdiff_t returnValue)
        {
            import mar.stdio : stderr;
            import mar.process : exit;
            stderr.write("Error: write failed! (TODO: print error writeSize and returnValue)");
            exit(1);
            assert(0);
        }
    }
}

struct DefaultPrinterBuffer
{
    char* ptr;
    auto commitValue()
    {
        return this;
    }
    void putc(char c) { pragma(inline, true); ptr[0] = c; ptr++; }
}

struct BufferedFilePrinter(Policy)
{
    import mar.array : acopy;
    import mar.file : FileD;

    static assert(__traits(hasMember, Policy, "PutResult"));
    static assert(__traits(hasMember, Policy, "success"));
    static assert(__traits(hasMember, Policy, "writeFailed"));
    static assert(__traits(hasMember, Policy, "bufferLength"));

    private FileD fd;
    private char* buffer;
    private size_t bufferedLength;

    //
    // The Printer Interface
    //
    alias PutResult = Policy.PutResult;
    static PutResult success() { return Policy.success; }
    PutResult flush()
    {
        if (bufferedLength > 0)
        {
            auto result = fd.tryWrite(buffer, bufferedLength);
            if (result.failed)
                return Policy.writeFailed(fd, bufferedLength, result.errorCode/*, result.onFailWritten*/);
            bufferedLength = 0;
        }
        return success;
    }
    PutResult put(const(char)[] str)
    {
        auto left = Policy.bufferLength - bufferedLength;
        if (left < str.length)
        {
            {
                auto result = flush();
                if (result.failed)
                    return result;
            }
            {
                auto result = fd.tryWrite(str);
                if (result.failed)
                    return Policy.writeFailed(fd, str.length, result.errorCode/*, result.onFailWritten*/);
            }
        }
        else
        {
            acopy(buffer + bufferedLength, str);
            bufferedLength += str.length;
        }
        return success;
    }
    PutResult putc(const char c)
    {
        if (bufferedLength == Policy.bufferLength)
        {
            auto result = flush();
            if (result.failed)
                return result;
        }
        buffer[bufferedLength++] = c;
        return success;
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
    auto getTempBuffer(size_t size)()
    {
        pragma(inline, true);
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
    auto print(P)(P printer) const
    {
        static if (T.sizeof <= size_t.sizeof)
            return printHex(printer, cast(size_t)value);
        else
            return printHex(printer, cast(ulong)value);
    }
}
auto formatHex(T)(T value)
{
    return FormatHex!T(value);
}
unittest
{
    char[50] buf;
    sprint(buf, formatHex(10));
    assert(buf[0 .. 1] == "a");
}

unittest
{
    import mar.array : aequals;

    static struct Point
    {
        int x;
        int y;
        auto print(P)(P printer) const
        {
            return printArgs(printer, x, ',', y);
            /*
            import mar.print;
            {
                auto result = printDecimal(printer, x);
                if (result.failed)
                    return result;
            }
            {
                auto result = printer.putc(',');
                if (result.failed)
                    return result;
            }
            return printDecimal(printer, y);
            */
        }
        auto formatHex() const
        {
            static struct Print
            {
                const(Point)* p;
                auto print(P)(P printer) const
                {
                    return printArgs(printer, "0x",
                        mar.print.formatHex(p.x), ",0x", mar.print.formatHex(p.y));
                }
            }
            return Print(&this);
        }
    }

    char[40] buf;
    auto p = Point(10, 18);
    assert(5 == sprint(buf, p));
    assert(aequals("10,18", buf.ptr));
    assert(8 == sprint(buf, p.formatHex));
    assert(aequals("0xa,0x12", buf.ptr));
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
    alias PutResult = CannotFail;
    static PutResult success() { return CannotFail(); }

    PutResult flush() { pragma(inline, true); return success; }
    PutResult put(const(char)[] str)
    {
        enforceCapacity(str.length);
        acopy(buffer.ptr + bufferedLength, str);
        bufferedLength += str.length;
        return success;
    }
    PutResult putc(const char c)
    {
        enforceCapacity(1);
        buffer[bufferedLength++] = c;
        return success;
    }

    auto getTempBuffer(size_t size)()
    {
        pragma(inline, true);
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
    alias PutResult = CannotFail;
    static PutResult success() { return CannotFail(); }
    PutResult flush() { pragma(inline, true); return CannotFail(); }
    PutResult put(const(char)[] str) { size += str.length; return CannotFail(); }
    PutResult putc(const char c) { size++; return CannotFail(); }
    /+
    auto getTempBuffer(size_t size)()
    {
        pragma(inline, true);
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
    printArgs(&printer, args);
    return printer.size;
}

size_t sprint(T...)(char[] buffer, T args)
{
    auto printer = StringPrinter(buffer, 0);
    printArgs(&printer, args);
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

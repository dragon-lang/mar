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

version (unittest)
{
    void testFormattedValue(size_t bufferSize = 100, T)(string expected, T formattedValue,
         string file = __FILE__, uint line = __LINE__)
    {
        //{import mar.stdio; stdout.writeln("testFormattedValue(line=", line, ") '", expected, "'");}
        char[bufferSize] buffer;
        const actual = sprint(buffer, formattedValue);
        if (expected != actual)
        {
            import mar.stdio;
            stderr.writeln(file, "(", line, "): testFormattedValue failed with:");
            stderr.writeln("  expected '", expected, "'");
            stderr.writeln("  actual   '", actual, "'");
            assert(0, "testFormattedValue failed");
        }
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

// TODO: more common number probably won't be so big,
//       make this a little more optimized
ubyte decimalDigitsUint(const uint value)
{
    if (value >= 1000000000) { return 10; }
    if (value >= 100000000) { return 9; }
    if (value >= 10000000) { return 8; }
    if (value >= 1000000) { return 7; }
    if (value >= 100000) { return 6; }
    if (value >= 10000) { return 5; }
    if (value >= 1000) { return 4; }
    if (value >= 100) { return 3; }
    if (value >= 10) { return 2; }
    return 1;
}
// TODO: more common number probably won't be so big,
//       make this a little more optimized
ubyte decimalDigitsUlong(const ulong value)
{
    if (value <= uint.max)
        return decimalDigitsUint(cast(uint)value);
    if (value >= 10000000000000000000LU) { return 20; }
    if (value >= 1000000000000000000LU) { return 19; }
    if (value >= 100000000000000000LU) { return 18; }
    if (value >= 10000000000000000LU) { return 17; }
    if (value >= 1000000000000000LU) { return 16; }
    if (value >= 100000000000000LU) { return 15; }
    if (value >= 10000000000000LU) { return 14; }
    if (value >= 1000000000000LU) { return 13; }
    if (value >= 100000000000LU) { return 12; }
    return 11;
}
ubyte decimalDigitsSizet(const size_t value)
{
    pragma(inline, true);
    static if (size_t.sizeof == uint.sizeof)
        return decimalDigitsUint(value);
    else static if (size_t.sizeof == size_t.sizeof)
        return decimalDigitsUlong(value);
    else static assert(0);
}



/**
NOTE: this is a "normalization" function to prevent template bloat
*/
auto printDecimal(T, Printer)(Printer printer, T value)
{
    pragma(inline, true);

    static if (T.sizeof <= size_t.sizeof)
    {
        alias stype = ptrdiff_t;
        alias utype = size_t;
    }
    else static if (T.sizeof <= ulong.sizeof)
    {
        alias stype = long;
        alias utype = ulong;
    }
    else static assert(0, "printing numbers with this bit width is not implemented");

    static if (T.min >= 0)
        return printDecimalSizetOrUlong(printer, cast(utype)value);
    else
        return printDecimalPtrdifftOrLong!(stype, utype)(printer, cast(stype)value);
}
auto printDecimalSizetOrUlong(T, Printer)(Printer printer, T value)
if (is(T == size_t) || is(T == ulong))
{
    static if (is(Printer == CalculateSizePrinter*))
    {
        static if (is(T == size_t))
            printer.size += decimalDigitsSizet(value);
        else
            printer.size += decimalDigitsUlong(value);
    }
    else
    {
        auto buffer = printer.getTempBuffer!(maxDecimalDigits!T);
        scope (exit) printer.commitBuffer(buffer.commitValue);
        buffer.ptr = sizetOrUlongToDecimal(buffer.ptr, value);
    }
    return Printer.success;
}
auto printDecimalPtrdifftOrLong(T, TUnsigned, Printer)(Printer printer, T value)
if (is(T == ptrdiff_t) || is(T == long))
{
    static if (is(Printer == CalculateSizePrinter*))
    {
        if (value < 0)
        {
            printer.size++;
            value = -value;
        }
        static if (is(T == ptrdiff_t))
            printer.size += decimalDigitsSizet(cast(TUnsigned)value);
        else
            printer.size += decimalDigitsUlong(cast(TUnsigned)value);
    }
    else
    {
        auto buffer = printer.getTempBuffer!(
            1 + // 1 for the '-' character
            maxDecimalDigits!T);
        scope (exit) printer.commitBuffer(buffer.commitValue);
        if (value < 0)
        {
            buffer.ptr[0] = '-';
            buffer.ptr++;
            value = -value;
        }
        buffer.ptr = sizetOrUlongToDecimal(buffer.ptr, cast(TUnsigned)value);
    }
    return Printer.success;
}
char* sizetOrUlongToDecimal(T)(char* buffer, T value) if (is(T == size_t) || is(T == ulong))
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

unittest
{
    testFormattedValue("-32768", short.min);
    testFormattedValue("32767", short.max);
    testFormattedValue("0", ushort.min);
    testFormattedValue("65535", ushort.max);
    testFormattedValue("-2147483648", int.min);
    testFormattedValue("2147483647", int.max);
    testFormattedValue("0", uint.min);
    testFormattedValue("4294967295", uint.max);
    testFormattedValue("-9223372036854775808", long.min);
    testFormattedValue("9223372036854775807", long.max);
    testFormattedValue("0", ulong.min);
    testFormattedValue("18446744073709551615", ulong.max);
}

immutable hexTableLower = "0123456789abcdef";
immutable hexTableUpper = "0123456789ABCDEF";
auto printHex(T, Printer)(Printer printer, T value)
{
    pragma(inline, true);
    static if (T.sizeof <= size_t.sizeof)
        alias utype = size_t;
    else static if (T.sizeof <= ulong.sizeof)
        alias utype = ulong;
    else static assert(0, "printing numbers with this bit width is not implemented");

    return printHexSizetOrUlong(printer, cast(utype)value);
}
auto printHexSizetOrUlong(T, Printer)(Printer printer, T value) if (is(T == size_t) || is(T == ulong))
{
    static if (is(Printer == CalculateSizePrinter*))
    {
        auto next = value.max;
        auto hexDigitCount = value.sizeof * 2;
        for (;value < next; next >>= 8, hexDigitCount -= 2)
        { }
        next >>= 4;
        if (value < next)
            hexDigitCount--;
        if (hexDigitCount == 0)
            hexDigitCount = 1;
        printer.size += hexDigitCount;
    }
    else
    {
        auto buffer = printer.getTempBuffer!(
            1 +          // 1 for the '-' character
            T.sizeof * 2 //max hex digits
            );
        scope (exit) printer.commitBuffer(buffer.commitValue);
        buffer.ptr = sizetOrUlongToHex!T(buffer.ptr, value);
    }
    return Printer.success;
}
private char* sizetOrUlongToHex(T)(char* buffer, T value) if (is(T == size_t) || is(T == ulong))
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
    testFormattedValue("a", 10.formatHex);
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

    auto p = Point(10, 18);
    testFormattedValue("10,18", p);
    testFormattedValue("0xa,0x12", p.formatHex);
}


private struct FormatMany(T)
{
    size_t count;
    T value;
    auto print(P)(P printer) const
    {
        static if (is(T == char))
            return printOneCharManyTimes(printer, count, value);
        else static assert(0, "FormatMany!(" ~ T.stringof ~ ") not implemented");
    }
}
// TODO: implement more than just one character
auto formatMany(char c, size_t count)
{
    return FormatMany!char(count, c);
}
auto printOneCharManyTimes(P)(P printer, size_t n, char c)
{
    char[100] buffer; // Is this a good size? Maybe use alloca with a max size?
    if (n < buffer.length)
        buffer[0 .. n] = c;
    else
        buffer[] = c;
    for (;n >= buffer.length; n -= buffer.length)
    {
        auto result = printer.put(buffer);
        if (result.failed)
            return result;
    }
    if (n > 0)
    {
        auto result = printer.put(buffer[0 .. n]);
        if (result.failed)
            return result;
    }
    return printer.success;
}
unittest
{
    testFormattedValue("", 'a'.formatMany(0));
    testFormattedValue("a", 'a'.formatMany(1));
    testFormattedValue("aa", 'a'.formatMany(2));
    testFormattedValue("aaa", 'a'.formatMany(3));
    testFormattedValue("aaaaaaaaaa", 'a'.formatMany(10));
}


private struct FormatPadLeft(T)
{
    T value;
    size_t width;
    char padChar;
    auto print(P)(P printer) const
    {
        const size = getPrintSize(value);
        if (size < width)
        {
            auto result = printOneCharManyTimes(printer, width - size, padChar);
            if (result.failed)
                return result;
        }
        return printArg(printer, value);
    }
}
auto formatPadLeft(T)(T value, size_t width, char padChar)
{
    return FormatPadLeft!T(value, width, padChar);
}

unittest
{
    testFormattedValue("0", 0.formatPadLeft(0, '0'));
    testFormattedValue("0", 0.formatPadLeft(1, '0'));
    testFormattedValue("00", 0.formatPadLeft(2, '0'));

    testFormattedValue("1", 1.formatPadLeft(0, '0'));
    testFormattedValue("1", 1.formatPadLeft(1, '0'));
    testFormattedValue("01", 1.formatPadLeft(2, '0'));
    testFormattedValue("001", 1.formatPadLeft(3, '0'));

    testFormattedValue("-1", (-1).formatPadLeft(0, 'Z'));
    testFormattedValue("-1", (-1).formatPadLeft(1, 'Z'));
    testFormattedValue("-1", (-1).formatPadLeft(2, 'Z'));
    testFormattedValue("Z-1", (-1).formatPadLeft(3, 'Z'));
    testFormattedValue("ZZ-1", (-1).formatPadLeft(4, 'Z'));

    testFormattedValue("0", 0.formatHex.formatPadLeft(0, '0'));
    testFormattedValue("0", 0.formatHex.formatPadLeft(1, '0'));
    testFormattedValue("00", 0.formatHex.formatPadLeft(2, '0'));
    // TODO: add more tests?
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

/**
Does not return errors, user is responsible for making sure buffer is
large enough.  Otherwise, should result in an array out of bounds error.
*/
size_t sprintJustReturnSize(T...)(char[] buffer, T args)
{
    auto printer = StringPrinter(buffer, 0);
    printArgs(&printer, args);
    return printer.bufferedLength;
}
size_t sprintSentinelJustReturnSize(T...)(char[] buffer, T args)
{
    auto printer = StringPrinter(buffer, 0);
    printArgs(&printer, args, '\0');
    return printer.bufferedLength - 1;
}

/// ditto
char[] sprint(T...)(char[] buffer, T args)
{
    pragma(inline, true);

    return buffer[0 .. sprintJustReturnSize(buffer, args)];
}
SentinelArray!char sprintSentinel(T...)(char[] buffer, T args)
{
    pragma(inline, true);
    import mar.sentinel : assumeSentinel;

    return buffer[0 .. sprintSentinelJustReturnSize(buffer, args)].assumeSentinel;
}

char[] sprintMallocNoSentinel(T...)(T args)
{
    import mar.mem : malloc;

    auto totalSize = getPrintSize(args);
    auto buffer = cast(char*)malloc(totalSize);
    if (!buffer)
        return null;
    const printedSize = sprintJustReturnSize(buffer[0 .. totalSize], args);
    assert(printedSize == totalSize, "codebug: precalculated print size differed from actual size");
    return buffer[0 .. totalSize];
}
SentinelArray!char sprintMallocSentinel(T...)(T args)
{
    import mar.mem : malloc;
    import mar.sentinel : assumeSentinel;

    const totalSize = getPrintSize(args);
    auto buffer = cast(char*)malloc(totalSize + 1);
    if (!buffer)
        return SentinelArray!char.nullValue;
    const printedSize = sprintJustReturnSize(buffer[0 .. totalSize], args);
    assert(printedSize == totalSize, "codebug: precalculated print size differed from actual size");
    buffer[printedSize] = '\0';
    return buffer[0 .. totalSize].assumeSentinel;
}

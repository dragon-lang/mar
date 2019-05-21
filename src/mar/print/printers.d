module mar.print.printers;

// TODO: make one for bigint?
// TODO: detect size_t overflow?
struct CalculateSizePrinterSizet
{
    import mar.cannotfail;

    private size_t size;
    //
    // The IsCalculateSizePrinter Interface
    //
    auto getSize() const { return size; }
    auto addSize(size_t size) { this.size += size; }
    //
    // The Printer Interface
    //
    enum IsPrinter = true;
    enum IsCalculateSizePrinter = true;
    alias PutResult = CannotFail;
    static PutResult success() { return CannotFail(); }
    PutResult flush() { pragma(inline, true); return CannotFail(); }
    PutResult put(const(char)[] str) { size += str.length; return CannotFail(); }
    PutResult putc(const char c) { size++; return CannotFail(); }
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

/**
Prints a set of values into a given character array.
If the character array is too small, it asserts.
TODO: support ability to return failure?
*/
struct FixedSizeStringPrinter
{
    import mar.array : acopy;
    import mar.cannotfail;

    private char[] buffer;
    private size_t bufferedLength;

    auto getLength() const { return bufferedLength; }
    private auto capacity() const { return buffer.length - bufferedLength; }
    private void enforceCapacity(size_t needed)
    {
        assert(capacity >= needed, "StringPrinter capacity is too small");
    }

    //
    // The Printer Interface
    //
    enum IsPrinter = true;
    enum IsCalculateSizePrinter = false;
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
    /+
    auto tryGetTempBufferImpl(size_t size)
    {
        return (capacity < size) ?
            DefaultPrinterBuffer(null) :
            DefaultPrinterBuffer(buffer.ptr + bufferedLength);
    }
    +/
    void commitBuffer(DefaultPrinterBuffer buf)
    {
        bufferedLength = buf.ptr - buffer.ptr;
    }
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
        import mar.cannotfail;
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
    enum IsPrinter = true;
    enum IsCalculateSizePrinter = false;
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
    /+
    auto tryGetTempBufferImpl(size_t size)
    {
        if (size > Policy.bufferLength)
            return DefaultPrinterBuffer(null); // can't get a buffer of that size
        auto left = Policy.bufferLength - bufferedLength;
        if (left < size)
            flush();
        return DefaultPrinterBuffer(buffer + bufferedLength);
    }
    +/
    void commitBuffer(DefaultPrinterBuffer buf)
    {
        bufferedLength = buf.ptr - buffer;
    }
}


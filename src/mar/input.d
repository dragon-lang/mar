module mar.input;

struct ReadResult
{
    enum State
    {
        success,
        mallocFailed,
        lineTooLong,
        readError,
    }
    union
    {
        char[] data;
        ptrdiff_t errorCode;
    }
    State state;
    private this(State state)
    {
        this.state = state;
    }
    bool failed() const { return state > State.success; }

    static auto success(char[] data)
    {
        auto result = ReadResult(State.success);
        result.data = data;
        return result;
    }
    static auto lineTooLong() { return ReadResult(State.lineTooLong); }
    static auto mallocFailed() { return ReadResult(State.mallocFailed); }
    static auto readError(ptrdiff_t errorCode)
    {
        auto result = ReadResult(State.readError);
        result.errorCode = errorCode;
        return result;
    }
    auto formatError() const
    {
        return "<ReadResult.formatError not implemented>";
    }
}

struct LineReader(Hooks)
{
    static assert(Hooks.minRead > 0, "minRead must be > 0");

    Hooks.Reader reader;
    char[] buffer;
    size_t lineStart;
    size_t dataLimit;

    mixin Hooks.ReaderMixinTemplate;

    // TODO: return expected!(size_t, error_code)
    /** returns: index of newline */
    ReadResult readln()
    {
        import mar.array : amove;

        size_t searchStart = lineStart;
        for (;;)
        {
            // find the newline
            for (size_t i = searchStart; i < dataLimit; i++)
            {
                if (buffer[i] == '\n')
                {
                    auto saveLineStart = lineStart;
                    lineStart = i + 1;
                    return ReadResult.success(buffer[saveLineStart .. i]);
                }
            }

            if (lineStart > 0)
            {
                auto dataSize = dataLimit - lineStart;
                if (dataSize > 0)
                    amove(buffer.ptr, buffer.ptr + lineStart, dataSize);
                lineStart = 0;
                dataLimit = dataSize;
            }

            auto available = buffer.length - dataLimit;
            if (available < Hooks.minRead)
            {
                auto result = Hooks.increaseBuffer(buffer, dataLimit);
                if (result.failed)
                    return result;
                assert(result.data.length > this.buffer.length, "code bug");
                this.buffer = result.data;
                available = buffer.length - dataLimit;
            }

            auto lastReadLength = reader.read(buffer[dataLimit .. $]);
            if (lastReadLength <= 0)
            {
                if (lastReadLength < 0)
                    return ReadResult.readError(lastReadLength);
                auto saveLineStart = lineStart;
                lineStart = dataLimit;
                return ReadResult.success(buffer[saveLineStart .. dataLimit]);
            }

            searchStart = dataLimit;
            dataLimit += lastReadLength;
        }
    }
}

ReadResult defaultMallocIncreaseBuffer(size_t initialLength = 1024)(char[] buffer, size_t dataLength)
{
    import mar.array : acopy;
    import mar.mem : malloc, free;

    size_t newSize;
    if (buffer.length == 0)
        newSize = initialLength;
    else
        newSize = buffer.length * 2;

    auto newBuffer = cast(char*)malloc(newSize);
    if (!newBuffer)
        return ReadResult.mallocFailed;

    if (dataLength > 0)
        acopy(newBuffer, buffer[0 .. dataLength]);
    free(buffer.ptr);
    return ReadResult.success(newBuffer[0 .. newSize]);
}

struct DefaultFileLineReaderHooks
{
    static import mar.file;
    enum minRead = 1;
    static struct Reader
    {
        mar.file.FileD file;
        pragma(inline)
        auto read(char[] buffer)
        {
            return mar.file.read(file, buffer).numval;
        }
    }
    mixin template ReaderMixinTemplate()
    {
        import mar.file : FileD;
        this(FileD file)
        {
            this.reader = Hooks.Reader(file);
        }
        ~this()
        {
            import mar.mem : free;
            if (buffer.ptr)
                free(buffer.ptr);
        }
    }
    alias increaseBuffer = defaultMallocIncreaseBuffer;
}


// used for unittesting at the moment
//extern (C) void main(int argc, void *argv, void* envp)
unittest
{
    {
        import mar.file : FileD;
        auto reader = LineReader!DefaultFileLineReaderHooks(FileD(-1));
        auto result = reader.readln();
        assert(result.failed);
        assert(result.state == ReadResult.State.readError);
    }

    struct TestHooks
    {
        enum minRead = 1;
        static struct Reader
        {
            string str;
            size_t defaultReadSize;
            size_t nextOffset;
            auto read(char[] buffer)
            {
                auto readSize = defaultReadSize;

                if (nextOffset + readSize > str.length)
                    readSize = str.length - nextOffset;

                if (readSize > buffer.length)
                    readSize = buffer.length;

                auto save = nextOffset;
                nextOffset += readSize;
                import mar.array : acopy;
                acopy(buffer.ptr, str.ptr + save, readSize);
                return readSize;
            }
        }

        mixin template ReaderMixinTemplate()
        {
            this(string str, size_t readSize)
            {
                this.reader = Hooks.Reader(str, readSize);
            }
            ~this()
            {
                import mar.mem : free;
                if (buffer.ptr)
                    free(buffer.ptr);
            }
        }
        alias increaseBuffer = defaultMallocIncreaseBuffer!1;
    }

    {
        auto reader = LineReader!TestHooks("", 1);
        auto result = reader.readln();
        assert(!result.failed);
        assert(result.data.length == 0);
    }

    static struct TestCase
    {
        string input;
        string[] lines;
    }

    enum longString =
        "12345678901234567890123456789012345678901234567890" ~
        "12345678901234567890123456789012345678901234567890" ~
        "12345678901234567890123456789012345678901234567890" ~
        "12345678901234567890123456789012345678901234567890" ~
        "12345678901234567890123456789012345678901234567890" ~
        "12345678901234567890123456789012345678901234567890" ~
        "12345678901234567890123456789012345678901234567890" ~
        "12345678901234567890123456789012345678901234567890";
    enum longString2 = longString ~ longString ~ longString ~ longString;
    static immutable TestCase[] testCases = [
        TestCase("a", ["a"]),
        TestCase("a\n", ["a"]),
        TestCase("a\nb", ["a", "b"]),
        TestCase("a\nb\n", ["a", "b"]),
        TestCase("a\nb\nc", ["a", "b", "c"]),
        TestCase("a\nb\nc\n", ["a", "b", "c"]),
        TestCase("foo", ["foo"]),
        TestCase("foo\n", ["foo"]),
        TestCase(longString, [longString]),
        TestCase(longString ~ "\n", [longString]),
        TestCase(longString ~ "\na" ~ longString, [longString, "a" ~ longString]),
        TestCase(longString2, [longString2]),
        TestCase(longString2 ~ "\n", [longString2]),
        TestCase(longString2 ~ "\na" ~ longString2, [longString2, "a" ~ longString2]),
    ];
    foreach (testCase; testCases)
    {
        //import mar.file; print(stdout, "TestCase '''\n", testCase.input, "\n'''\n");
        foreach (readSize; 1 .. testCase.input.length + 1)
        {
            //import mar.file; print(stdout, "  readSize ", readSize, "\n");
            auto reader = LineReader!TestHooks(testCase.input, readSize);
            foreach (line; testCase.lines)
            {
                auto result = reader.readln();
                assert(!result.failed);
                assert(result.data == line);
            }
            {
                auto result = reader.readln();
                assert(!result.failed);
                assert(result.data.length == 0);
            }
        }
    }
}

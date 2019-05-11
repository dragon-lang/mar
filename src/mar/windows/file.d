module mar.windows.file;

import mar.passfail;
import mar.wrap;
import mar.c : cstring;

import mar.windows.types : Handle;
import mar.windows.kernel32 :
    GetLastError, WriteFile;

uint getLastErrorMustBeNonZero()
{
    auto result = GetLastError();
    return (result == 0) ?  500 : result;
}

enum FileShareMode : uint
{
    read = 0x1,
    write = 0x2,
    delete_ = 0x4,
}

/*
                |    if file exists     | if file doesn't exist |           success error code             |
----------------|-----------------------|-----------------------|------------------------------------------|
createNew       | ERROR_FILE_EXISTS(80) |        new file       |                    N/A                   |
createAlways    |     overwrite file    |        new file       | ERROR_ALREADY_EXISTS(183) if file exists |
openExisting    |     open existing     |ERROR_FILE_NOT_FOUND(2)|                    N/A                   |
openAlways      |     open existing     |        new file       | ERROR_ALREADY_EXISTS(183) if file exists |
truncateExisting|     overwrite file    |ERROR_FILE_NOT_FOUND(2)|                    N/A                   |
*/
enum FileCreateMode : uint
{
    createNew = 1,        // create a new file if it doesn't exist, otherwise, fail with ERROR_FILE_EXISTS(80)
    createAlways = 2,     // create a new file, truncate it if it already exists and set error code to ERROR_ALREADY_EXISTS(183)
    openExisting = 3,     // open the file if it exists, otherwise, fail with ERROR_FILE_NOT_FOUND(2)
    openAlways = 4,       // open the file or create a new empty file if it doesn't exist
    truncateExisting = 5, // open the file and trucate it if it exists, otherwise, fail with ERROR_FILE_NOT_FOUND(2)
}

struct WriteResult
{
    private uint _errorCode;
    private uint _writtenOnFailure;
    bool failed() const { pragma(inline, true); return _errorCode != 0; }
    bool passed() const { pragma(inline, true); return _errorCode == 0; }

    uint onFailWritten() const
    in { assert(_errorCode != 0, "code bug"); } do
    { pragma(inline, true); return _writtenOnFailure; }
    uint errorCode() const { pragma(inline, true); return _errorCode; }
}

extern (C) WriteResult tryWrite(Handle handle, const(void)* ptr, size_t n)
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
    import mar.expect;

    private ptrdiff_t _value = -1;
    this(typeof(_value) value) pure nothrow @nogc
    {
        this._value = value;
    }
    bool isValid() nothrow @nogc const { return _value != -1; }
    ptrdiff_t numval() const { pragma(inline, true); return _value; }
    void setInvalid() { this._value = -1; }
    static FileD invalidValue() { return FileD(-1); }
    mixin WrapperFor!"_value";
    mixin WrapOpCast;

    final void close() const
    {
        pragma(inline, true);
        import mar.windows.kernel32 : CloseHandle;
        CloseHandle(Handle(_value));
    }

    Handle asHandle() const { pragma(inline, true); return Handle(_value); }

    auto print(P)(P printer) const
    {
        import mar.print : printDecimal;
        return printDecimal(printer, _value);
    }

    WriteResult tryWrite(const(void)* ptr, size_t n) { pragma(inline, true); return .tryWrite(asHandle, ptr, n); }
    WriteResult tryWrite(const(void)[] array) { pragma(inline, true); return .tryWrite(asHandle, array.ptr, array.length); }

    void write(T...)(T args) const
    {
        import mar.print : DefaultBufferedFilePrinterPolicy, BufferedFilePrinter, printArgs;
        alias Printer = BufferedFilePrinter!DefaultBufferedFilePrinterPolicy;

        char[DefaultBufferedFilePrinterPolicy.bufferLength] buffer;
        auto printer = Printer(this, buffer.ptr, 0);
        printArgs(&printer, args);
        printer.flush();
    }

    void writeln(T...)(T args) const
    {
        pragma(inline, true);
        write(args, '\n');
    }

    passfail tryFlush()
    {
        pragma(inline, true);
        import mar.windows.kernel32 : FlushFileBuffers;

        if (FlushFileBuffers(asHandle).failed)
            return passfail.fail;
        return passfail.pass;
    }

    mixin ExpectMixin!("ReadResult", uint,
        ErrorCase!("readFileFailed", "ReadFile failed, error=%", uint));
    auto read(T)(T[] buffer) const if (T.sizeof <= 1)
    {
        pragma(inline, true);
        import mar.windows.kernel32 : ReadFile;
        uint bytesRead;
        if (ReadFile(asHandle, buffer.ptr, 1, &bytesRead, null).failed)
            return ReadResult.readFileFailed(GetLastError());
        return ReadResult.success(bytesRead);
    }
}

bool fileExists(cstring filename)
{
    assert(0, "not impl');");
}

bool isDir(cstring path)
{
    import mar.windows.types : FileAttributes;
    import mar.windows.kernel32 : GetFileAttributesA;

    auto result = GetFileAttributesA(path);
    return result.isValid && ((result.val & FileAttributes.directory) != 0);
}

enum OpenAccess : uint
{
    //none      = 0b00, // neither read or write access
    readOnly  = 0x80000000, // GENERIC_READ
    writeOnly = 0x40000000, // GENERIC_WRITE
    readWrite = readOnly | writeOnly,
}

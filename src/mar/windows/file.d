module mar.windows.file;

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
    pragma(inline) bool failed() const { return _errorCode != 0; }
    pragma(inline) bool passed() const { return _errorCode == 0; }

    pragma(inline) uint onFailWritten() const
    in { assert(_errorCode != 0, "code bug"); } do
    { return _writtenOnFailure; }
    pragma(inline) uint errorCode() const { return _errorCode; }
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
    private ptrdiff_t _value = -1;
    this(typeof(_value) value) pure nothrow @nogc
    {
        this._value = value;
    }
    bool isValid() nothrow @nogc const { return _value != -1; }
    pragma(inline) ptrdiff_t numval() const { return _value; }
    void setInvalid() { this._value = -1; }
    static FileD invalidValue() { return FileD(-1); }
    mixin WrapperFor!"_value";
    mixin WrapOpCast;

    pragma(inline)
    final void close() const
    {
        import mar.windows.kernel32 : CloseHandle;
        CloseHandle(Handle(_value));
    }

    pragma(inline) Handle asHandle() const { return Handle(_value); }

    auto print(P)(P printer) const
    {
        import mar.print : printDecimal;
        return printDecimal(printer, _value);
    }

    pragma(inline)
    WriteResult tryWrite(const(void)* ptr, size_t n) { return .tryWrite(asHandle, ptr, n); }
    pragma(inline)
    WriteResult tryWrite(const(void)[] array) { return .tryWrite(asHandle, array.ptr, array.length); }

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

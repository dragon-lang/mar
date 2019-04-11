module windows.kernel32;

pragma(lib, "kernel32.lib");

import mar.wrap;
import mar.c : cint, cstring;
import mar.windows.types : Handle;
import mar.windows.file : OpenAccess, FileShareMode, FileCreateMode, FileD;

extern (Windows) uint GetLastError() nothrow @nogc;
extern (Windows) Handle GetStdHandle(uint handle) nothrow @nogc;

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
        return printer.put(passed ? "TRUE" : "FALSE");
    }
}

extern (Windows) void ExitProcess(uint) nothrow @nogc;
extern (Windows) BoolExpectNonZero CloseHandle(Handle) nothrow @nogc;

enum HeapCreateOptions : uint
{
    none               = 0,
    noSerialize        = 0x00000001,
    generateExceptions = 0x00000004,
    enableExecute      = 0x00040000,
}
extern (Windows) Handle HeapCreate(
  HeapCreateOptions  options,
  size_t initialSize,
  size_t maxSize
) @nogc;

enum HeapAllocOptions : uint
{
    none               = 0,
    noSerialize        = 0x00000001,
    generateExceptions = 0x00000004,
    zeroMemory         = 0x00000008,
}
extern (Windows) void* HeapAlloc(
  Handle heap,
  HeapAllocOptions options,
  size_t size
) @nogc;

enum HeapFreeOptions : uint
{
    none               = 0,
    noSerialize        = 0x00000001,
}
extern (Windows) BoolExpectNonZero HeapFree(
  Handle hHeap,
  HeapFreeOptions options,
  void* ptr
);


extern (Windows) BoolExpectNonZero WriteFile(
    const Handle handle,
    const(void)* buffer,
    uint length,
    uint* written,
    void* overlapped
) nothrow @nogc;


struct FileAttributesOrError
{
    import mar.windows.types : FileAttributes;

    pragma(inline)
    private static FileAttributes invalidEnumValue() { return cast(FileAttributes)-1; }
    pragma(inline)
    static FileAttributesOrError invalidValue() { return FileAttributesOrError(invalidEnumValue); }

    private FileAttributes _attributes;
    bool isValid() const { return _attributes != invalidEnumValue; }
    FileAttributes val() const { return _attributes; }
}

extern (Windows) FileAttributesOrError GetFileAttributesA(
    cstring filename
) nothrow @nogc;

extern (Windows) BoolExpectNonZero CreateDirectoryA(
    cstring filename,
    void* securityAttrs,
) nothrow @nogc;

extern (Windows) FileD CreateFileA(
    cstring filename,
    OpenAccess access,
    FileShareMode shareMode,
    void* securityAttrs,
    FileCreateMode createMode,
    uint flagsAndAttributes,
    Handle tempalteFile
) nothrow @nogc;
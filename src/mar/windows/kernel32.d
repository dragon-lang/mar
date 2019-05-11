module windows.kernel32;

// Note: the reason for separating function definitions by which dll
//       they appear in is so they can all be in the same file as the
//       pragma that will cause the library to be linked
pragma(lib, "kernel32.lib");

import mar.wrap;
import mar.c : cint, cstring;
import mar.windows.types :
    Handle, ModuleHandle, SecurityAttributes, SRWLock,
    ThreadStartRoutine, ThreadPriority, InputRecord;
import mar.windows.file : OpenAccess, FileShareMode, FileCreateMode, FileD;

extern (Windows) uint GetLastError() nothrow @nogc;
extern (Windows) Handle GetStdHandle(uint handle) nothrow @nogc;

/**
Represents semantics of the windows BOOL return type.
*/
struct BoolExpectNonZero
{
    private cint _value;
    bool failed() const { pragma(inline, true); return _value == 0; }
    bool passed() const { pragma(inline, true); return _value != 0; }

    auto print(P)(P printer) const
    {
        return printer.put(passed ? "TRUE" : "FALSE");
    }
}

extern (Windows) void ExitProcess(uint) nothrow @nogc;
extern (Windows) BoolExpectNonZero CloseHandle(Handle) nothrow @nogc;

extern (Windows) uint GetCurrentThreadId();

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
extern (Windows) BoolExpectNonZero ReadFile(
    const Handle handle,
    const(void)* buffer,
    uint length,
    uint* read,
    void* overlapped
) nothrow @nogc;

struct FileAttributesOrError
{
    import mar.windows.types : FileAttributes;

    private static FileAttributes invalidEnumValue() { pragma(inline, true); return cast(FileAttributes)-1; }
    static FileAttributesOrError invalidValue() { pragma(inline, true); return FileAttributesOrError(invalidEnumValue); }

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


extern (Windows) uint GetFileSize(
    Handle file,
    uint* fileSizeHigh,
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
extern (Windows) Handle CreateFileMappingA(
    Handle file,
    SecurityAttributes* attributes,
    uint protect,
    uint maxSizeHigh,
    uint maxSizeLow,
    cstring name
) nothrow @nogc;
extern (Windows) void* MapViewOfFile(
    Handle fileMappingObject,
    uint desiredAccess,
    uint offsetHigh,
    uint offsetLow,
    size_t size
) nothrow @nogc;
extern (Windows) BoolExpectNonZero UnmapViewOfFile(void* ptr);

extern (Windows) void InitializeSRWLock(SRWLock* lock);
extern (Windows) void AcquireSRWLockExclusive(SRWLock* lock);
extern (Windows) void ReleaseSRWLockExclusive(SRWLock* lock);

extern (Windows) Handle CreateEventA(
    SecurityAttributes* eventAttributes,
    cint manualReset,
    cint initialState,
    cstring name
);
extern (Windows) BoolExpectNonZero SetEvent(Handle handle);
extern (Windows) BoolExpectNonZero ResetEvent(Handle handle);

extern (Windows) BoolExpectNonZero QueryPerformanceFrequency(long* frequency);
extern (Windows) BoolExpectNonZero QueryPerformanceCounter(long* count);

extern (Windows) uint WaitForSingleObject(
    Handle handle,
    uint  millis
);

extern (Windows) Handle CreateThread(
    SecurityAttributes* attributes,
    size_t stackSize,
    ThreadStartRoutine start,
    void* parameter,
    uint creationFlags,
    uint* threadID
);
extern (Windows) Handle GetCurrentThread();
extern (Windows) cint GetThreadPriority(Handle thread);
extern (Windows) BoolExpectNonZero SetThreadPriority(
    Handle thread,
    ThreadPriority priority
);

extern (Windows) ModuleHandle LoadLibraryA(cstring fileName);
extern (Windows) void* GetProcAddress(ModuleHandle, cstring fileName);

extern (Windows) BoolExpectNonZero FlushFileBuffers(Handle file);

extern (Windows) BoolExpectNonZero GetConsoleMode(
    Handle consoleHandle, uint* mode);
extern (Windows) BoolExpectNonZero SetConsoleMode(
    Handle consoleHandle, uint mode);
extern (Windows) BoolExpectNonZero ReadConsoleInputA(
    Handle consoleHandle,
    InputRecord* buffer,
    uint length,
    uint* numberOfEventsRead
);

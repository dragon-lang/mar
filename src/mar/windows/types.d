module mar.windows.types;

import mar.wrap;
import mar.c : cint;
import mar.windows.file : FileD;

enum FileAttributes : uint
{
    directory = 0x800,
}

/**
Equivalent to windows HANDLE type.
*/
struct Handle
{
    static Handle nullValue() { return Handle(0); }
    static Handle invalidValue() { return Handle(-1); }

    private ptrdiff_t _value = -1;
    this(typeof(_value) value) pure nothrow @nogc
    {
        this._value = value;
    }
    bool isValid() nothrow @nogc const { return _value != -1; }
    bool isNull() nothrow @nogc const { return _value == 0; }
    ptrdiff_t numval() nothrow @nogc const { pragma(inline, true); return _value; }
    void setInvalid() nothrow @nogc { this._value = -1; }
    mixin WrapperFor!"_value";
    mixin WrapOpCast;
    FileD asFileD() nothrow @nogc inout { pragma(inline, true); return FileD(_value); }

    auto print(P)(P printer) const
    {
        import mar.print : printDecimal;
        return printDecimal(printer, _value);
    }
}

/**
Equivalent to windows HWND type.
*/
struct WindowHandle
{
    private Handle _handle;
    mixin WrapperFor!"_handle";
    mixin WrapOpCast;
}

struct ModuleHandle
{
    static Handle nullValue() { return Handle(0); }

    private size_t _value = 0;
    this(typeof(_value) value) pure nothrow @nogc
    {
        this._value = value;
    }
    bool isNull() nothrow @nogc const { return _value == 0; }
    ptrdiff_t numval() nothrow @nogc const { pragma(inline, true); return _value; }
    void setNull() nothrow @nogc { this._value = 0; }
    mixin WrapperFor!"_value";
    mixin WrapOpCast;
}

struct ListEntry
{
    ListEntry* next;
    ListEntry* prev;
}
private struct CriticalSectionDebug
{
    ushort           type;
    ushort           creatorBackTraceIndex;
    CriticalSection* criticalSection;
    ListEntry        processLocksList;
    uint             entryCount;
    uint             contentionCount;
    uint[2]          spare;
}
struct CriticalSection
{
    CriticalSectionDebug* debugInfo;
    int                   LockCount;
    int                   RecursionCount;
    Handle                owningThread;
    Handle                lockSemaphore;
    size_t                spinCount; // TODO: is size_t right here?
}

struct Guid
{
    uint a;
    ushort b;
    ushort c;
    ubyte[8] d;

    static Guid fromString(string str)()
    {
        return mixin(uuidToGuidMixinCode!str);
    }
    private template uuidToGuidMixinCode(string uuid)
    {
        static assert(uuid.length == 36, "uuid must be 36 characters");
        enum uuidToGuidMixinCode = "Guid("
            ~   "cast(uint)  0x" ~ uuid[ 0 ..  8]
            ~ ", cast(ushort)0x" ~ uuid[ 9 .. 13]
            ~ ", cast(ushort)0x" ~ uuid[14 .. 18]
            ~ ",[cast(ubyte)0x"  ~ uuid[19 .. 21]
            ~ ", cast(ubyte)0x"  ~ uuid[21 .. 23]
            ~ ", cast(ubyte)0x"  ~ uuid[24 .. 26]
            ~ ", cast(ubyte)0x"  ~ uuid[26 .. 28]
            ~ ", cast(ubyte)0x"  ~ uuid[28 .. 30]
            ~ ", cast(ubyte)0x"  ~ uuid[30 .. 32]
            ~ ", cast(ubyte)0x"  ~ uuid[32 .. 34]
            ~ ", cast(ubyte)0x"  ~ uuid[34 .. 36]
            ~ "])";
    }
}

struct SRWLock
{
    void* ptr;
}

enum INFINITE = 0xffffffffL;

alias ThreadStartRoutine = extern (Windows) uint function(void* param);
enum ThreadPriority : cint
{
    normal = 0,
    aboveNormal = 1,
    belowNormal = -1,
    highest = 2,
    idle = -15,
    lowest = -2,
    timeCritical = 15,
}

struct FocusEventRecord
{
    import mar.c : cint;

    cint setFocus;
}
struct KeyEventRecord
{
    import mar.c : cint;

    cint down;
    ushort repeatCount;
    ushort keyCode;
    ushort scanCode;
    union
    {
        wchar unicodeChar;
        char asciiChar;
    }
    uint controlKeyState;
}

enum EventType
{
    key              = 0x0001,
    mouse            = 0x0002,
    windowBufferSize = 0x0004,
    menu             = 0x0008,
    focus            = 0x0010,
}
struct InputRecord
{
    ushort  type;
    union
    {
        KeyEventRecord          key;
        //MOUSE_EVENT_RECORD        mouse;
        //WINDOW_BUFFER_SIZE_RECORD windowBufferSize;
        //MENU_EVENT_RECORD         menu;
        FocusEventRecord        focus;
    }
}

enum ConsoleFlag : uint
{
    enableProcessedInput = 0x0001,
    enableLineInput      = 0x0002,
    enableEchoInput      = 0x0004,
    enableWindowInput    = 0x0008,
    enableMouseInput     = 0x0010,
}
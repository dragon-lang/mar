/**
Contains code to interface with windows that does not require linking to any external libraries.
*/
module mar.windows;

import mar.wrap;
import mar.c : cint;
import mar.windows.file : FileD;

enum FileAttributes : uint
{
    directory = 0x800,
}

/**
Equivalent to HRESULT
*/
struct HResult
{
    private uint value;
    @property auto passed() const pure nothrow @nogc { return (value & 0x80000000) == 0; }
    @property auto failed() const pure nothrow @nogc { return (value & 0x80000000) != 0; }
    // TODO: file/line number also?
    void enforce(E...)(E errorMsgValues) const
    {
        static import mar.enforce;
        mar.enforce.enforce(this, errorMsgValues);
    }
    auto print(P)(P printer) const
    {
        import mar.print : printArgs, formatHex;
        return printArgs(printer, "(0x", value.formatHex,
            " facility=0x", (0x7FF & (value >> 16)).formatHex,
            " code=0x", (0xFFFF & value).formatHex, ")");
    }
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

struct SecurityAttributes
{
    uint length;
    void* descriptor;
    cint inheritHandle;
}


struct SRWLock
{
    void* ptr;
}

enum INFINITE = 0xffffffffL;
enum INVALID_FILE_SIZE = 0xffffffff;

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

alias ThreadEntry = extern (Windows) uint function(void* param);
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

ubyte LOBYTE(T)(T value) { pragma(inline, true); return cast(ubyte)value; }
ubyte HIBYTE(T)(T value) { pragma(inline, true); return cast(ubyte)(cast(ushort)value >> 8); }
ushort LOWORD(T)(T value) { pragma(inline, true); return cast(ushort)value; }
ushort HIWORD(T)(T value) { pragma(inline, true); return cast(ushort)(cast(uint)value >> 16); }

//
// COM
//
enum ClsCtx : uint
{
    inprocServer        = 0x00000001,
    inprocHandler       = 0x00000002,
    localServer         = 0x00000004,
    inprocServer16      = 0x00000008,
    removeServer        = 0x00000010,
    inprocHandler16     = 0x00000020,
    reserved1           = 0x00000040,
    reserved2           = 0x00000080,
    reserved3           = 0x00000100,
    reserved4           = 0x00000200,
    noCodeDownload      = 0x00000400,
    reserved5           = 0x00000800,
    noCustomMarshal     = 0x00001000,
    enableCodeDownload  = 0x00002000,
    noFailureLog        = 0x00004000,
    disableAaa          = 0x00008000,
    enableAaa           = 0x00010000,
    fromDefaultContext  = 0x00020000,
    activate32BitServer = 0x00040000,
    activate64BitServer = 0x00080000,
    enableCloaking      = 0x00100000,
    all                 = inprocServer | inprocHandler | localServer | removeServer,
}

enum VarType : ushort
{
    empty           =    0,
    null_           =    1,
    //cint            =    2,
    //clong           =    3,
    float_          =    4,
    double_         =    5,
    currency        =    6,
    date            =    7,
    string_         =    8,
    object          =    9,
    error           =   10,
    //bool_         =   11,
    variant         =   12,
    dataObject      =   13,
    decimal         =   14,
    byte_           =   17,
    long_           =   20,
    userDefinedType =   36,
    array           = 8192,
}
struct PropVariant
{
    VarType type; static assert(type.offsetof == 0);
    short reserved1; static assert(reserved1.offsetof == 2);
    short reserved2; static assert(reserved2.offsetof == 4);
    short reserved3; static assert(reserved3.offsetof == 6);

    union VariantUnion
    {
        char char_;      static assert(char_.offsetof == 0);
        ubyte ubyte_;    static assert(ubyte_.offsetof == 0);
        short short_;    static assert(short_.offsetof == 0);
        ushort ushort_;  static assert(ushort_.offsetof == 0);
        int int_;        static assert(int_.offsetof == 0);
        uint uint_;      static assert(uint_.offsetof == 0);
        long long_;      static assert(long_.offsetof == 0);
        float float_;    static assert(float_.offsetof == 0);
        double double_;  static assert(double_.offsetof == 0);
        Guid* guidPtr;   static assert(guidPtr.offsetof == 0);
        // There are more possible types, add as needed
    }
    VariantUnion val;
}

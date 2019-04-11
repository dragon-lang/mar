module mar.windows.types;

import mar.wrap;
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
    pragma(inline) ptrdiff_t numval() nothrow @nogc const { return _value; }
    void setInvalid() nothrow @nogc { this._value = -1; }
    mixin WrapperFor!"_value";
    mixin WrapOpCast;
    pragma(inline) FileD asFileD() nothrow @nogc inout { return FileD(_value); }

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
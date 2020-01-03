module mar.windows.ole32.nolink;

enum CoInit : uint
{
    multiThreaded     = 0,
    apartmentThreaded = 2,
    disableOle1Dd3    = 4,
    speedOverMemory   = 8,
}

/// Equivalent to CLSID
struct ClassID
{
    import mar.windows : Guid;

    static ClassID fromString(string str)()
    {
        return ClassID(Guid.fromString!str);
    }

    private Guid guid;
}
/// Equivalent to IID
struct InterfaceID
{
    import mar.windows : Guid;

    static InterfaceID fromString(string str)()
    {
        return InterfaceID(Guid.fromString!str);
    }

    private Guid guid;
}

mixin template InterfaceMixin(alias VTableMixin, T)
{
    static struct VTable { mixin VTableMixin!T; }
    private VTable* vtable;
    static foreach (func; __traits(allMembers, VTable))
    {
        mixin("auto " ~ func ~ "(T...)(T args) {\n"
            ~ "    return vtable." ~ func ~ "(&this, args);\n"
            ~ "}\n");
    }
}

struct IUnknown
{
    import mar.windows : HResult;

    __gshared static immutable id =
        InterfaceID.fromString!"00000000-0000-0000-C000-000000000046";

    mixin template VTableMixin(T)
    {
        extern (Windows) HResult function(T* obj, const(InterfaceID)* interfaceID, void** object) queryInterface;
        extern (Windows) uint function(T* obj) addRef;
        extern (Windows) uint function(T* obj) release;
        static assert(queryInterface.offsetof == size_t.sizeof * 0);
        static assert(addRef.offsetof         == size_t.sizeof * 1);
        static assert(release.offsetof        == size_t.sizeof * 2);
    }
    mixin InterfaceMixin!(VTableMixin, typeof(this));
    HResult queryInterfaceTo(T)(T** typedObj)
    {
        return queryInterface(&T.id, cast(void**)typedObj);
    }
}

struct IEnumUnknown
{
    import mar.windows : HResult;

    __gshared static immutable id = InterfaceID.fromString!"00000100-0000-0000-C000-000000000046";

    mixin template VTableMixin(T)
    {
        mixin IUnknown.VTableMixin!T;
        extern (Windows) HResult function(T* obj, uint count, IUnknown** arr, uint* arrLength) next;
        extern (Windows) HResult function(T* obj, uint count) skip;
        extern (Windows) HResult function(T* obj) reset;
        extern (Windows) HResult function(T* obj, IEnumUnknown** enumerator) clone;
    }
    mixin InterfaceMixin!(VTableMixin, typeof(this));
}

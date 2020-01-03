module mar.windows.mscoree.nolink;


struct CLRMetaHost
{
    import mar.windows.ole32.nolink : ClassID;
    static __gshared immutable id = ClassID.fromString!"9280188d-0e8e-4867-b30c-7fa83884e8de";
}
struct CLRMetaHostPolicy
{
    import mar.windows.ole32.nolink : ClassID;
    //static __gshared immutable id = ClassID.fromString!"???";
}
struct CLRDebugging
{
    import mar.windows.ole32.nolink : ClassID;
    //static __gshared immutable id = ClassID.fromString!"???";
}

struct ICLRMetaHost
{
    import mar.sentinel : SentinelPtr;
    import mar.windows : HResult, Handle, Guid;
    import mar.windows.ole32.nolink : InterfaceID, InterfaceMixin, IUnknown, IEnumUnknown;

    static __gshared immutable id = InterfaceID.fromString!"D332DB9E-B9B3-4125-8207-A14884F53216";

    mixin template VTableMixin(T)
    {
        mixin IUnknown.VTableMixin!T;
        extern (Windows) HResult function(T*,
            SentinelPtr!(const(wchar)) version_,
            const(InterfaceID)* interfaceID,
            void** runtime) getRuntime; // Should be an interface matching interfaceID

        extern (Windows) HResult function(T*,
            SentinelPtr!(const(wchar)) filePath,
            wchar* buffer,
            uint* bufferLength) getVersionFromFile;

        extern (Windows) HResult function(T*,
            IEnumUnknown** enumerator) enumerateInstalledRuntimes;

        extern (Windows) HResult function(T*,
            Handle processHandle,
            IEnumUnknown** enumerator) enumerateLoadedRuntimes;

        extern (Windows) HResult function(T*,
            void* reserved1) requestRuntimeLoadedNotification;

        extern (Windows) HResult function(T*,
            const(InterfaceID)* interfaceID,
            void** runtime) queryLegacyV2RuntimeBinding; // Should be an interface matching interfaceID
    }
    mixin InterfaceMixin!(VTableMixin, typeof(this));

    HResult getRuntimeOf(T)(SentinelPtr!(const(wchar)) version_, T** iface)
    {
        return getRuntime(version_, &T.id, cast(void**)iface);
    }
}

public struct ICLRRuntimeInfo
{
    import mar.sentinel : SentinelPtr;
    import mar.c : cint;
    import mar.windows : HResult, Handle, Guid;
    import mar.windows.ole32.nolink : ClassID, InterfaceID, InterfaceMixin, IUnknown;

    static __gshared immutable id = InterfaceID.fromString!"BD39D1D2-BA2F-486A-89B0-B4B0CB466891";

    mixin template VTableMixin(T)
    {
        mixin IUnknown.VTableMixin!T;
        extern (Windows) HResult function(T*,
            wchar* buffer,
            uint* bufferSize) getVersionString;
        extern (Windows) HResult function(T*,
            wchar* buffer,
            uint* bufferSize) getRuntimeDirectory;
        extern (Windows) HResult function(T*,
            Handle processHandle,
            cint* loaded) isLoaded;
        extern (Windows) HResult function(T*,
            uint resourceID,
            SentinelPtr!wchar buffer,
            uint* bufferSize,
            uint localeID) loadErrorString;
        extern (Windows) HResult function(T*,
            SentinelPtr!(const(wchar)) dllName,
            Handle *module_) loadLibrary;
        extern (Windows) HResult function(T*,
            SentinelPtr!(const(wchar)) procName,
            void** proc) getProcAddress;
        extern (Windows) HResult function(T*,
            const(ClassID)* classID,
            const(InterfaceID)* interfaceID,
            void** outInterface) getInterface;
    }
    mixin InterfaceMixin!(VTableMixin, typeof(this));

    HResult getInterfaceOf(T)(const(ClassID)* classID, T** iface)
    {
        return getInterface(classID, &T.id, cast(void**)iface);
    }
}

public struct CorRuntimeHost
{
    import mar.windows.ole32.nolink : ClassID;
    static __gshared immutable id = ClassID.fromString!"CB2F6723-AB3A-11D2-9C40-00C04FA30A3E";
}
public struct ICorRuntimeHost
{
    import mar.sentinel : SentinelPtr;
    import mar.c : cint;
    import mar.windows : HResult, Handle, Guid;
    import mar.windows.ole32.nolink : ClassID, InterfaceID, InterfaceMixin, IUnknown;

    static __gshared immutable id = InterfaceID.fromString!"CB2F6722-AB3A-11d2-9C40-00C04FA30A3E";

    mixin template VTableMixin(T)
    {
        mixin IUnknown.VTableMixin!T;
        extern (Windows) HResult function(T* obj) createLogicalThreadState; // DO NOT USE
        extern (Windows) HResult function(T* obj) deleteLogicalThreadState; // DO NOT USE
        extern (Windows) HResult function(T* obj, uint* cookie) switchinLogicalThreadState; // DO NOT USE
        extern (Windows) HResult function(T* obj, uint** cookie) switchoutLogicalThreadState; // DO NOT USE
        extern (Windows) HResult function(T* obj, uint* count) locksHeldByLogicalThread; // DO NOT USE
        extern (Windows) HResult function(T* obj, Handle file, Handle* outAddress) mapFile;
        extern (Windows) HResult function(T* obj, ICorConfiguration** config) getConfiguration;
        extern (Windows) HResult function(T* obj) start;
        extern (Windows) HResult function(T* obj) stop;
        extern (Windows) HResult function(T* obj,
            SentinelPtr!(const(wchar)) name,
            IUnknown* identityArray,
            void** appDomain) createDomain;
        extern (Windows) HResult function(T* obj, IUnknown** domain) getDefaultDomain;
        // TODO: finish the rest
        //alias HCORENUM = uint; // TODO: what is this?
        //extern (Windows) HResult function(T* obj, HCORENUM* enum_) enumDomains;
        //extern (Windows) HResult function(T* obj, HCORENUM enum_, void** appDomain) nextDomain;
        //extern (Windows) HResult function(T* obj, HCORENUM enum_) closeEnum;
    }
    mixin InterfaceMixin!(VTableMixin, typeof(this));
}

public struct ICorConfiguration
{
}
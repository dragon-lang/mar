module audio.windows.coreaudio;

import mar.c : cint, cwstring;
import mar.windows : ClsCtx, PropVariant;

enum DataFlow
{
    render = 0,
    capture = 1,
    both = 2,
    /*
    render = 0x01,
    capture = 0x02,
    both = render | capture,
    */
}

public enum DeviceState : uint
{
    active     = 0x00000001, /// Same as DEVICE_STATE_ACTIVE
    disabled   = 0x00000002, /// Same as DEVICE_STATE_DISABLED
    notPresent = 0x00000004, /// Same as DEVICE_STATE_NOTPRESENT
    unplugged  = 0x00000008, /// Same as DEVICE_STATE_UNPLUGGED
    all        = 0x0000000F, /// Same as DEVICE_STATEMASK_ALL
}
public enum StorageAccessMode : uint
{
    read,
    write,
    readWrite,
}

enum Role
{
    console = 0,
    multimedia = 1,
    communications = 2,
}

// Equivalent to PROPERTYKEY
struct PropertyKey
{
    import mar.windows : Guid;

    Guid formatID;
    int propertyId;
}

struct IPropertyStore
{
    extern (Windows) cint function(cint* propCount) getCount;
    extern (Windows) cint function(cint property, PropertyKey* key) getAt;
    extern (Windows) cint function(ref PropertyKey key, PropVariant* value) getValue;
    extern (Windows) cint function(ref PropertyKey key, PropVariant* value) setValue;
    extern (Windows) cint function() commit;
}

struct IMMDevice
{
    import mar.windows : HResult;
    import mar.windows.ole32.nolink : InterfaceID, InterfaceMixin, IUnknown;

    static __gshared immutable id = InterfaceID.fromString!"D666063F-1587-4E43-81F1-B948E807363F";

    mixin template VTableMixin(T)
    {
        mixin IUnknown.VTableMixin!T;
        extern (Windows) HResult function(T*, const(InterfaceID)* id, ClsCtx clsCtx, PropVariant* activationParams, void** outInterface) activate;
        extern (Windows) HResult function(T*, StorageAccessMode stgmAccess, out IPropertyStore properties) openPropertyStore;
        extern (Windows) HResult function(T*, cwstring* id) getId;
        extern (Windows) HResult function(T*, DeviceState* state) getState;
    }
    mixin InterfaceMixin!(VTableMixin, typeof(this));
}
struct IMMDeviceCollection
{
    import mar.windows : HResult;
    import mar.windows.ole32.nolink : InterfaceID, InterfaceMixin, IUnknown;

    static __gshared immutable id = InterfaceID.fromString!"0BD7A1BE-7A1A-44DB-8397-CC5392387B5E";

    mixin template VTableMixin(T)
    {
        extern (Windows) HResult function(T*, cint* numDevices) getCount;
        extern (Windows) HResult function(T*, cint deviceNumber, IMMDevice* device) item;
    }
    mixin InterfaceMixin!(VTableMixin, typeof(this));
}
struct IMMNotificationClient
{
    import mar.windows : HResult;
    import mar.windows.ole32.nolink : InterfaceID, InterfaceMixin, IUnknown;

    static __gshared immutable id = InterfaceID.fromString!"7991EEC9-7E89-4D85-8390-6C703CEC60C0";

    mixin template VTableMixin(T)
    {
        mixin IUnknown.VTableMixin!T;
        extern (Windows) void function(T*, cwstring deviceId, DeviceState newState) onDeviceStateChanged;
        extern (Windows) void function(T*, cwstring pwstrDeviceId) onDeviceAdded;
        extern (Windows) void function(T*, cwstring deviceId) onDeviceRemoved;
        extern (Windows) void function(T*, DataFlow flow, Role role, cwstring defaultDeviceId) onDefaultDeviceChanged;
        extern (Windows) void function(T*, cwstring pwstrDeviceId, PropertyKey key) onPropertyValueChanged;
    }
    mixin InterfaceMixin!(VTableMixin, typeof(this));
}
struct IMMDeviceEnumerator
{
    import mar.windows : HResult;
    import mar.windows.ole32.nolink : InterfaceID, InterfaceMixin, IUnknown;

    static __gshared immutable id = InterfaceID.fromString!"A95664D2-9614-4F35-A746-DE8DB63617E6";

    mixin template VTableMixin(T)
    {
        mixin IUnknown.VTableMixin!T;
        extern (Windows) HResult function(T* obj, DataFlow dataFlow, DeviceState stateMask,
            IMMDeviceCollection* devices) enumAudioEndpoints;
        static assert(enumAudioEndpoints.offsetof == size_t.sizeof * 3);
        extern (Windows) HResult function(T* obj, DataFlow dataFlow, Role role, IMMDevice** endpoint) getDefaultAudioEndpoint;
        static assert(getDefaultAudioEndpoint.offsetof == size_t.sizeof * 4);
        extern (Windows) HResult function(T* obj, cwstring id, IMMDevice* deviceName) getDevice;
        extern (Windows) HResult function(T* obj, IMMNotificationClient client) registerEndpointNotificationCallback;
        extern (Windows) HResult function(T* obj, IMMNotificationClient client) unregisterEndpointNotificationCallback;
    }
    mixin InterfaceMixin!(VTableMixin, typeof(this));

}
struct MMDeviceEnumerator
{
    import mar.windows.ole32.nolink : ClassID;

    static __gshared immutable id = ClassID.fromString!"BCDE0395-E52F-467C-8E3D-C4579291692E";
}

enum AudioClientShareMode
{
    shared_,   /// AUDCLNT_SHAREMODE_SHARED
    exclusive, /// AUDCLNT_SHAREMODE_EXCLUSIVE
}
enum AudioClientStreamFlags : uint
{
    none = 0,
    crossProcess  = 0x00010000, /// AUDCLNT_STREAMFLAGS_CROSSPROCESS
    loopback      = 0x00020000, /// AUDCLNT_STREAMFLAGS_LOOPBACK
    eventCallback = 0x00040000, /// AUDCLNT_STREAMFLAGS_EVENTCALLBACK
    noPersist     = 0x00080000, /// AUDCLNT_STREAMFLAGS_NOPERSIST
}

struct IAudioClient
{
    import mar.windows : HResult, Handle, Guid;
    import mar.windows.ole32.nolink : InterfaceID, InterfaceMixin, IUnknown;
    import mar.windows.waveout : WaveFormatEx;

    static __gshared immutable id = InterfaceID.fromString!"1CB9AD4C-DBFA-4c32-B178-C2F568A703B2";

    mixin template VTableMixin(T)
    {
        mixin IUnknown.VTableMixin!T;
        extern (Windows) HResult function(T*,
            AudioClientShareMode shareMode,
            AudioClientStreamFlags streamFlags,
            long fufferDuration, // REFERENCE_TIME
            long periodicity, // REFERENCE_TIME
            const(WaveFormatEx)* format,
            const(Guid)* audioSessionGuid) initialize;
        extern (Windows) HResult function(T*, uint* bufferSize) getBufferSize;
        extern (Windows) HResult function(T*, long* latency) getStreamLatency;
        extern (Windows) HResult function(T*, uint* currentPadding) getCurrentPadding;
        extern (Windows) HResult function(T*,
            AudioClientShareMode shareMode,
            const(WaveFormatEx)* format,
            WaveFormatEx* closestMatchFormat) isFormatSupported;
        extern (Windows) HResult function(T*, WaveFormatEx** deviceFormatPointer) getMixFormat;
        extern (Windows) HResult function(T*,
            long* defaultDevicePeriod,
            long* minimumDevicePeriod) getDevicePeriod;
        extern (Windows) HResult function(T*) start;
        extern (Windows) HResult function(T*) stop;
        extern (Windows) HResult function(T*) reset;
        extern (Windows) HResult function(T*, Handle eventHandle) setEventHandle;
        extern (Windows) HResult function(T*, const(InterfaceID)* id, void** obj) getService;

    }
    mixin InterfaceMixin!(VTableMixin, typeof(this));
}
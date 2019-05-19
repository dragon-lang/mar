/**
OLE = Object Linking and Embedding
*/
module mar.windows.ole32.link;

pragma(lib, "ole32.lib");

import mar.windows : HResult, ClsCtx;
import mar.windows.ole32.nolink;

extern (Windows) HResult CoInitialize(
    void* reserved
);

extern (Windows) HResult CoInitializeEx(
    void* reserved,
    CoInit coInit
);

extern (Windows) HResult CoCreateInstance(
    const(ClassID)*  classID,
    void* unknownInterface,
    ClsCtx clsContext,
    const(InterfaceID)* interfaceID,
    void** ppv
);

extern (Windows) void CoTaskMemFree(
    void* ptr
) nothrow @nogc;

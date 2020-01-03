/**
OLE = Object Linking and Embedding
*/
module mar.windows.mscoree.link;

version (DisablePragmaLib) { }
else {
    pragma(lib, "mscoree.lib");
}

import mar.windows : HResult;
import mar.windows.ole32.nolink : ClassID, InterfaceID;
import mar.windows.mscoree.nolink;


extern (Windows) HResult CLRCreateInstance(
    const(ClassID)* classID,
    const(InterfaceID)* interfaceID,
    void** ctx
) nothrow @nogc;

HResult CLRCreateInstanceOf(T)(const(ClassID)* classID, T** interfacePtr)
{
    return CLRCreateInstance(classID, &T.id, cast(void**)interfacePtr);
}
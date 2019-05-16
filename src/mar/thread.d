/**
Platform-agnostic thread API
*/
module mar.thread;

import mar.expect : ExpectMixin, ErrorCase;

version (Windows)
{
    import mar.windows : Handle;
    static import mar.windows;

    alias ThreadEntry = mar.windows.ThreadEntry;
    mixin ExpectMixin!("StartThreadResult", Handle,
        ErrorCase!("createThreadFailed", "CreateThread failed, e=%", uint));
    enum ThreadEntryResult : uint
    {
        fail = 0, // error is zero
        pass = 1, // success is non-zero
    }
}
else static assert("mar.thread not implemented on this platform");

/**
Usage:
---
mixin threadEntryMixin!("myThread", q{
    // thread code
});
---
*/
mixin template threadEntryMixin(string name, string body_)
{
    version (Windows)
        enum signature = "extern (Windows) uint " ~ name ~ "(void* threadArg)";
    else static assert("mar.thread.threadEntryMixin not implemented on this platform");

    mixin(signature ~ "\n{\n" ~ body_ ~ "\n}\n");
}

StartThreadResult startThread(ThreadEntry entry)
{
    version (Windows)
    {
        pragma(inline, true);

        import mar.windows.kernel32 : GetLastError, CreateThread;
        const handle = CreateThread(null, 0, entry, null, 0, null);
        if (handle.isNull)
            return StartThreadResult.createThreadFailed(GetLastError());
        return StartThreadResult.success(handle);
    }
    else static assert("mar.thread.startThread not implemented on this platform");
}
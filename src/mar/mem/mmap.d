/**
An extremely dumb and expensive version of malloc.

Currently only works on linux but support could be added for windows.
*/
module mar.mem_mmap;

import mar.file : FileD;
version (linux)
{
    import mar.mmap : mmap, munmap, mremap, PROT_READ, PROT_WRITE,
        MAP_PRIVATE, MAP_ANONYMOUS, MREMAP_MAYMOVE;

    void* malloc(size_t size)
    {
        size += size_t.sizeof;
        auto map = mmap(null, size, PROT_READ | PROT_WRITE,
            MAP_PRIVATE | MAP_ANONYMOUS, FileD(-1), 0);
        if (map.failed)
            return null;
        (cast(size_t*)map.val)[0] = size;
        version (TraceMallocFree)
        {
            import mar.file : stdout;
            stdout.write("malloc(", size, ") > ", (map.val + size_t.sizeof), "\n");
        }
        return map.val + size_t.sizeof;
    }
    void free(void* mem)
    {
        version (TraceMallocFree)
        {
            import mar.file : stdout;
            stdout.write("free(0x", mem, ")\n");
        }
        if (mem)
        {
            mem = (cast(ubyte*)mem) - size_t.sizeof;
            auto size = (cast(size_t*)mem)[0];
            auto result = munmap(cast(ubyte*)mem, size);
            assert(result.passed, "munmap failed");
        }
    }

    // Returns: true if it resized, false otherwise
    bool tryRealloc(void* mem, size_t size)
    {
        version (TraceMallocFree)
        {
            import mar.file : stdout;
            stdout.write("realloc(", mem, ", ", size, ") > ", (map.val + size_t.sizeof), "\n");
        }
        if (mem is null)
            return false;
        size += size_t.sizeof;
        auto base = mem - size_t.sizeof;
        return mremap(base, (cast(size_t*)base)[0], size, 0).failed ? false : true;
    }
    unittest
    {
        import mar.array;
        {
            auto result = malloc(100);
            assert(result);
            acopy(result, "1234567890");
            assert((cast(char*)result)[0 .. 10] == "1234567890");
            free(result);
        }
    }
}
else static assert(0, "mem.mmap module not implemented for this platform");

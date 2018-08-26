/**
An extremely dumb and expensive version of malloc.
*/
module mar.mem_mmap;

import mar.linux.file : FileD;
import mar.linux.mmap : mmap, munmap, PROT_READ, PROT_WRITE, MAP_PRIVATE, MAP_ANONYMOUS;

void* malloc(size_t size)
{
    size += size_t.sizeof;
    auto map = mmap(null, size, PROT_READ | PROT_WRITE,
        MAP_PRIVATE | MAP_ANONYMOUS, FileD(-1), 0);
    if (map.failed)
        return null;
    (cast(size_t*)map.val)[0] = size;
    return map.val + size_t.sizeof;
}
void free(void* mem)
{
    if (mem)
    {
        mem = (cast(ubyte*)mem) - size_t.sizeof;
        auto size = (cast(size_t*)mem)[0];
        auto result = munmap(cast(ubyte*)mem, size);
        assert(result.passed, "munmap failed");
    }
}

unittest
{
    {
        auto result = malloc(100);
        assert(result);
        (cast(char*)result)[0 .. 10] = "1234567890";
        assert((cast(char*)result)[0 .. 10] == "1234567890");
        free(result);
    }
}
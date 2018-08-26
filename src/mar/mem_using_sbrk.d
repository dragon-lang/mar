module mar.mem;

import mar.typecons : enforce;

version (linux)
{
    import mar.linux.mem : sbrk;
}
else static assert(0, "unsupported platform");

__gshared MemBlock* data_seg_ptr;
__gshared void* data_seg_limit;

static this()
{
    version (linux)
    {
        import mar.linux.file; write(stdout, "[DEBUG] mar.mem static this!\n");
        data_seg_ptr = cast(MemBlock*)sbrk(0).enforce("sbrk(0) failed");
        // TODO: check the return value for success
        data_seg_limit = data_seg_ptr;
   }
   else static assert(0, "unsupported platform");
}

private struct MemBlock
{
    size_t size;
    bool available;
}

// TODO: support freeing null?
void free(void* buffer)
{
    MemBlock* mcb = cast(MemBlock*)(buffer - MemBlock.sizeof);
    mcb.available = true;
}

void* malloc(size_t size)
{
    size += MemBlock.sizeof;
    MemBlock *ptr = data_seg_ptr;
    for (;; ptr += ptr.size)
    {
        if (ptr == data_seg_limit)
        {
            sbrk(size).enforce("sbrk failed");
            data_seg_limit += size;
            ptr.size = size;
            break;
        }
        if (ptr.available && size <= ptr.size)
        {
            ptr.available = false;
        }
    }
    ptr.available = false;
    return ptr + MemBlock.sizeof;
}

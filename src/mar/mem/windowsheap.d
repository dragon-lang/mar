module mar.mem.windowsheap;

import mar.enforce : enforce;
import mar.windows.types : Handle, CriticalSection;
import mar.windows.kernel32 :
    HeapCreateOptions, HeapAllocOptions, HeapFreeOptions,
    GetLastError,
    HeapCreate, HeapAlloc, HeapFree;

// TODO:
// need a way to initialize this!!
private __gshared CriticalSection heapCS;

private __gshared Handle defaultHeap = Handle.nullValue;
private Handle tryGetDefaultHeap()
{
    // double-checked locking
    if (defaultHeap.isNull)
    {
        //synchronized 
        {
            if (defaultHeap.isNull)
            {
                // HeapCreateOptions.noSerialize because we are already synchronized
                auto heap = HeapCreate(HeapCreateOptions.noSerialize, HeapCreateOptions.none, 0);
                if (!heap.isNull)
                {
                    defaultHeap = heap;
                }
            }
        }
    }
    return defaultHeap;
}
private Handle getDefaultHeap()
{
    auto heap = tryGetDefaultHeap();
    enforce(!heap.isNull, "HeapCreate failed, error is ", GetLastError());
    return heap;
}

void* malloc(size_t size)
{
    auto heap = tryGetDefaultHeap();
    if (heap.isNull)
        return null;
    return HeapAlloc(heap, HeapAllocOptions.none, size);
}
void free(void* mem)
{
    auto result = HeapFree(getDefaultHeap(), HeapFreeOptions.none, mem);
    enforce(result.passed, "HeapFree failed, error is ", GetLastError());
}
bool tryRealloc(void* mem, size_t size)
{
    assert(0, "tryRealloc no impl");
}
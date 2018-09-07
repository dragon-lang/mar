module mar.arraybuilder;

import mar.expect : MemoryResult;

struct MallocArrayBuilderPolicy(size_t InitialItemCount)
{
    static import mar.mem;

    /** Returns: null if out of memory */
    pragma(inline)
    static T[] increaseBuffer(T)(T[] buffer, size_t minNewLength, size_t preserveLength)
    {
        import mar.conv : staticCast;
        auto result = increaseBuffer(buffer, minNewLength, preserveLength, T.sizeof);
        return staticCast!(T[])(result);
    }
    /// ditto
    static void[] increaseBuffer(void[] buffer, size_t minNewLength, size_t preserveLength, size_t elementSize)
    {
        import mar.array : acopy;

        size_t newLength;
        if (buffer.length == 0)
            newLength = InitialItemCount;
        else
            newLength = buffer.length * 2;
        if (newLength < minNewLength)
            newLength = minNewLength;

        auto newByteSize = newLength * elementSize;

        void* newBuffer;
        if (mar.mem.tryRealloc(buffer.ptr, newByteSize))
            newBuffer = buffer.ptr;
        else
        {
            newBuffer = mar.mem.malloc(newByteSize);
            if (!newBuffer)
                return null;
            acopy(newBuffer, buffer.ptr, preserveLength * elementSize);
            mar.mem.free(buffer.ptr);
        }
        return newBuffer[0 .. newLength];
    }
    pragma(inline)
    static void free(T)(T[] buffer)
    {
        mar.mem.free(buffer.ptr);
    }
}

struct ArrayBuilder(T, Policy = MallocArrayBuilderPolicy!32)
{
    private T[] buffer;
    private size_t count;

    pragma(inline)
    T[] data() const { return (cast(T[])buffer)[0 .. count]; }

    MemoryResult tryPut(T item)
    {
        if (count == buffer.length)
        {
            auto result = Policy.increaseBuffer!T(buffer, count + 1, count);
            if (result.length < count + 1)
                return MemoryResult.outOfMemory;
            this.buffer = result;
        }
        buffer[count++] = item;
        return MemoryResult.success;
    }
    MemoryResult tryPutRange(U)(U[] items)
    {
        import mar.array : acopy;

        auto lengthNeeded = count + items.length;
        if (lengthNeeded > buffer.length)
        {
            auto result = Policy.increaseBuffer!T(buffer, lengthNeeded, count);
            if (result.length < lengthNeeded)
                return MemoryResult.outOfMemory;
            this.buffer = result;
        }
        acopy(buffer.ptr + count, items);
        count += items.length;
        return MemoryResult.success;
    }

    void free()
    {
        Policy.free(buffer);
        buffer = null;
        count = 0;
    }
}

unittest
{
    import mar.array : aequals;

    {
        auto builder = ArrayBuilder!int();
        assert(builder.data.length == 0);
        assert(builder.tryPut(400).passed);
        assert(builder.data.length == 1);
        assert(builder.data[0] == 400);
        builder.free();
        assert(builder.data is null);
    }
    {
        auto builder = ArrayBuilder!int();
        assert(builder.data.length == 0);
        foreach (i; 0 .. 600)
        {
            assert(builder.tryPut(i).passed);
            assert(builder.data.length == i + 1);
            foreach (j; 0 .. i)
            {
                assert(builder.data[j] == j);
            }
        }
        builder.free();
        assert(builder.data is null);
    }
    {
        auto builder = ArrayBuilder!char();
        assert(builder.data.length == 0);
        assert(builder.tryPutRange("hello").passed);
        assert(aequals(builder.data, "hello"));
        assert(builder.tryPut('!').passed);
        assert(aequals(builder.data, "hello!"));
        builder.free();
        assert(builder.data is null);
    }
}
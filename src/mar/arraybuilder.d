module mar.arraybuilder;

import mar.expect : MemoryResult;

struct ArrayBuilder(T, Policy = MallocArrayBuilderPolicy!32)
{
    private T[] buffer;
    private size_t _length;

    auto ref opIndex(size_t index) inout { return buffer[index]; }
    T[] data() const { pragma(inline, true); return (cast(T[])buffer)[0 .. _length]; }
    size_t length() const { return _length; }

    void shrinkTo(size_t newLength)
    in { assert(newLength <= _length); } do
    {
        this._length = newLength;
    }

    MemoryResult tryPut(T item)
    {
        if (_length == buffer.length)
        {
            auto result = Policy.increaseBuffer!T(buffer, _length + 1, _length);
            if (result.length < _length + 1)
                return MemoryResult.outOfMemory;
            this.buffer = result;
        }
        buffer[_length++] = item;
        return MemoryResult.success;
    }
    MemoryResult tryPutRange(U)(U[] items)
    {
        import mar.array : acopy;

        auto lengthNeeded = _length + items.length;
        if (lengthNeeded > buffer.length)
        {
            auto result = Policy.increaseBuffer!T(buffer, lengthNeeded, _length);
            if (result.length < lengthNeeded)
                return MemoryResult.outOfMemory;
            this.buffer = result;
        }
        acopy(buffer.ptr + _length, items);
        _length += items.length;
        return MemoryResult.success;
    }
    void removeAt(size_t index)
    {
        for (size_t i = index; i + 1 < _length; i++)
        {
            buffer[i] = buffer[i+1];
        }
        _length--;
    }

    auto pop()
    {
        auto result = buffer[_length-1];
        _length--;
        return result;
    }

    void free()
    {
        Policy.free(buffer);
        buffer = null;
        _length = 0;
    }
}

struct MallocArrayBuilderPolicy(size_t InitialItemCount)
{
    static import mar.mem;

    /** Returns: null if out of memory */
    static T[] increaseBuffer(T)(T[] buffer, size_t minNewLength, size_t preserveLength)
    {
        pragma(inline, true);
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
    static void free(T)(T[] buffer)
    {
        pragma(inline, true);
        mar.mem.free(buffer.ptr);
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
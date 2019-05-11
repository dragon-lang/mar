module mar.serialize;

T deserializeBE(T, U)(U* bytes) if (U.sizeof == 1)
{
    pragma(inline, true);
    version (BigEndian)
        return deserializeInOrder!T(bytes);
    else
        return deserializeSwap!T(bytes);
}
T deserializeLE(T, U)(U* bytes) if (U.sizeof == 1)
{
    pragma(inline, true);
    version (BigEndian)
        return deserializeSwap!T(bytes);
    else
        return deserializeInOrder!T(bytes);
}
/*
T deserialize(T, bool bigEndian, U)(U* bytes) if (U.sizeof == 1)
{
    static if (T.sizeof == 1)
    {
        pragma(inline, true);
        return cast(T)bytes[0];
    }
    else static if (T.sizeof == 2)
    {
        return cast(T)(
            cast(ushort)bytes[EndianIndex!(bigEndian, T.sizeof, 0)] << 0 |
            cast(ushort)bytes[EndianIndex!(bigEndian, T.sizeof, 1)] << 8 );
    }
    else static if (T.sizeof == 4)
    {
        return cast(T)(
            cast(uint)bytes[EndianIndex!(bigEndian, T.sizeof, 0)] <<  0 |
            cast(uint)bytes[EndianIndex!(bigEndian, T.sizeof, 1)] <<  8 |
            cast(uint)bytes[EndianIndex!(bigEndian, T.sizeof, 2)] << 16 |
            cast(uint)bytes[EndianIndex!(bigEndian, T.sizeof, 3)] << 24 );
    }
    else static if (T.sizeof == 8)
    {
        return cast(T)(
            cast(uint)bytes[EndianIndex!(bigEndian, T.sizeof, 0)] <<  0 |
            cast(uint)bytes[EndianIndex!(bigEndian, T.sizeof, 1)] <<  8 |
            cast(uint)bytes[EndianIndex!(bigEndian, T.sizeof, 2)] << 16 |
            cast(uint)bytes[EndianIndex!(bigEndian, T.sizeof, 3)] << 24 |
            cast(uint)bytes[EndianIndex!(bigEndian, T.sizeof, 4)] << 32 |
            cast(uint)bytes[EndianIndex!(bigEndian, T.sizeof, 5)] << 40 |
            cast(uint)bytes[EndianIndex!(bigEndian, T.sizeof, 6)] << 48 |
            cast(uint)bytes[EndianIndex!(bigEndian, T.sizeof, 7)] << 56 );
    }
    else static assert(0, "don't know how to deserialize a type of this size");
}
*/

T deserializeInOrder(T, U)(U* bytes) if (U.sizeof == 1 && !is(U == ubyte))
{
    pragma(inline, true);
    return deserializeInOrder!T(cast(ubyte*)bytes);
}
T deserializeInOrder(T)(ubyte* bytes)
{
    pragma(inline, true);
    import mar.mem : memcpy;

    T value;
    memcpy(&value, bytes, T.sizeof);
    return value;
}

T deserializeSwap(T, U)(U* bytes) if (U.sizeof == 1 && !is(U == ubyte))
{
    pragma(inline, true);
    return deserializeSwap!T(cast(ubyte*)bytes);
}
T deserializeSwap(T)(ubyte* bytes)
{
    T value;
    auto dst = cast(ubyte*)&value;
    foreach (i; 0 .. T.sizeof)
    {
        dst[i] = bytes[T.sizeof - 1 - i];
    }
    return value;
}

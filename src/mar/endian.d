module mar.endian;

import mar.flag;

version (BigEndian)
{
    alias BigEndianOf(T)    = EndianOf!(T, No.flip);
    alias LittleEndianOf(T) = EndianOf!(T, Yes.flip);
}
else // LittleEndian
{
    alias BigEndianOf(T)    = EndianOf!(T, Yes.flip);
    alias LittleEndianOf(T) = EndianOf!(T, No.flip);
}

struct EndianOf(T, Flag!"flip" flip)
{
    union
    {
        private ubyte[T.sizeof] bytes;
        private T value;
    }
    this(T value) { this.value = value; }

    T getRawValue() const { return value; }

    pragma(inline)
    T toHostEndian() const
    {
        static if (flip)
            return cast(T)swapEndian(value);
        else
            return cast(T)value;
    }

    import mar.wrap;
    mixin WrapperFor!("value");
    mixin WrapOpEquals!(No.includeWrappedType);
    // Note: do not use OpCmpIntegral because it assumes
    //       the values are in native endian.
    //       I could use it if I wrap the toHostEndian field
    //       instead of "value" though.
}

pragma(inline)
BigEndianOf!T toBigEndian(T)(T value) pure nothrow @nogc
{
    version (BigEndian)
        return BigEndianOf!T(value);
    else
        return BigEndianOf!T(swapEndian(value));
}
pragma(inline)
LittleEndianOf!T toLittleEndian(T)(T value) pure nothrow @nogc
{
    version (LittleEndian)
        return LittleEndianOf!T(value);
    else
        return LittleEndianOf!T(swapEndian(value));
}

ushort swapEndian(ushort val) pure nothrow @nogc
{
    return ((val & 0xff00U) >> 8) |
           ((val & 0x00ffU) << 8);
}
uint swapEndian(uint val) pure nothrow @nogc
{
    return ((val >> 24U) & 0x000000ff) |
           ((val <<  8U) & 0x00ff0000) |
           ((val >>  8U) & 0x0000ff00) |
           ((val << 24U) & 0xff000000);
}
module mar.math;

version (NoStdc)
{
    // sin function not implemented yet
}
else
{
    extern (C) double sin(double x) @safe pure nothrow @nogc;
    private extern (C) float sinf(float x) @safe pure nothrow @nogc;
    float sin(float x) @safe pure nothrow @nogc { pragma(inline, true); return sinf(x); }
}

auto squared(T)(T value) { pragma(inline, true); return value * value; }

auto abs(T)(T value)
{
    pragma(inline, true);

    static if (__traits(isUnsigned, T))
        return value;
    else
        return (value < 0) ? -value : value;
}

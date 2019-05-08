module src.mar.math;

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

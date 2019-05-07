module src.mar.math;

/// intrinsic
extern (C) real sin(real x) @safe pure nothrow @nogc;
double sin(double x) @safe pure nothrow @nogc { return sin(cast(real) x); }
float sin(float x) @safe pure nothrow @nogc { return sin(cast(real) x); }

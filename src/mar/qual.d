module mar.qual;

immutable(T)[] asImmutable(T)(T[] array) pure nothrow
{
    pragma(inline, true);
    return .asImmutable(array);    // call ref version
}
immutable(T)[] asImmutable(T)(ref T[] array) pure nothrow
{
    pragma(inline, true);
    auto result = cast(immutable(T)[]) array;
    array = null;
    return result;
}
immutable(T[U]) asImmutable(T, U)(ref T[U] array) pure nothrow
{
    pragma(inline, true);
    auto result = cast(immutable(T[U])) array;
    array = null;
    return result;
}

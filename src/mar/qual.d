module mar.qual;

pragma(inline);
immutable(T)[] asImmutable(T)(T[] array) pure nothrow
{
    return .asImmutable(array);    // call ref version
}
pragma(inline);
immutable(T)[] asImmutable(T)(ref T[] array) pure nothrow
{
    auto result = cast(immutable(T)[]) array;
    array = null;
    return result;
}
pragma(inline);
immutable(T[U]) asImmutable(T, U)(ref T[U] array) pure nothrow
{
    auto result = cast(immutable(T[U])) array;
    array = null;
    return result;
}

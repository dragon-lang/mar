module mar.traits;

template isArithmetic(T)
{
    // TODO: handle wrapped arithmetic types
    enum isArithmetic = __traits(isArithmetic, T);
}
/*
template isIntegral(T)
{
    enum isIntegral =
        is(typeof(T.init == 0)) // equatable to 0
        ;
}
*/

/*
template Unconst(T)
{
         static if (is(T U ==   immutable U)) alias Unconst = U;
    else static if (is(T U == inout const U)) alias Unconst = U;
    else static if (is(T U == inout       U)) alias Unconst = U;
    else static if (is(T U ==       const U)) alias Unconst = U;
    else                                      alias Unconst = T;
}
*/

/**
Removes all qualifiers, if any, from type `T`.
 */
template Unqual(T)
{
    version (none) // Error: recursive alias declaration @@@BUG1308@@@
    {
             static if (is(T U ==     const U)) alias Unqual = Unqual!U;
        else static if (is(T U == immutable U)) alias Unqual = Unqual!U;
        else static if (is(T U ==     inout U)) alias Unqual = Unqual!U;
        else static if (is(T U ==    shared U)) alias Unqual = Unqual!U;
        else                                    alias Unqual =        T;
    }
    else // workaround
    {
             static if (is(T U ==          immutable U)) alias Unqual = U;
        else static if (is(T U == shared inout const U)) alias Unqual = U;
        else static if (is(T U == shared inout       U)) alias Unqual = U;
        else static if (is(T U == shared       const U)) alias Unqual = U;
        else static if (is(T U == shared             U)) alias Unqual = U;
        else static if (is(T U ==        inout const U)) alias Unqual = U;
        else static if (is(T U ==        inout       U)) alias Unqual = U;
        else static if (is(T U ==              const U)) alias Unqual = U;
        else                                             alias Unqual = T;
    }
}
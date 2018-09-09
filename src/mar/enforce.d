module mar.enforce;

template ResultExpression(string Mixin)
{
    private struct Value
    {
        enum ResultExpressionMixin = Mixin;
    }
    enum ResultExpression = Value();
}

/**
Use to represent the result in an enforce error message.

Example:
---
result.enforce("this result failed: it is ", Result.val);
result.enforce("this result failed: it is ", Result.errorCode.subField);
---
*/
struct Result
{
    template opDispatch(string name)
    {
        static if (name == "val")
            enum opDispatch = ResultExpression!"result";
        else
            enum opDispatch = ResultExpression!("result." ~ name);
    }
}

// TODO: probably move this
private template Aliases(T...)
{
    alias Aliases = T;
}
// Create a tuple of aliases that does not expand
private struct SubAliases(T...)
{
    alias Expand = T;
}

// TODO: is it faster to process args forwards or backwards?
private template Replace(size_t Index, alias With, Types, Values...)
{
    static if (Index == Values.length)
    {
        alias Replace = Values[$ .. $];
    }
    else static if (is(typeof(Types.Expand[Index].ResultExpressionMixin)))
    {
        alias result = With; // result is used in the expression mixin
        alias Replace = Aliases!(mixin(Types.Expand[Index].ResultExpressionMixin),
            Replace!(Index + 1, With, Types, Values));
    }
    else
    {
        alias Replace = Aliases!(Values[Index],
            Replace!(Index + 1, With, Types, Values));
    }
}


pragma(inline)
void enforce(E...)(bool cond, E errorMsgValues)
{
    if (!cond)
    {
        import mar.process : exit;
        import mar.file : stderr;
        static if (E.length == 0)
            stderr.writeln("An error occurred");
        else
            stderr.writeln("Error: ",  errorMsgValues);
        exit(1);
    }
}
pragma(inline)
void enforce(T, E...)(T result, E errorMsgValues) if (__traits(hasMember, T, "failed"))
{
    if (result.failed)
    {
        import mar.process : exit;
        import mar.file : stderr;
        static if (E.length == 0)
            stderr.writeln("An error occurred");
        else
            stderr.writeln("Error: ",  Replace!(0, result, SubAliases!E, errorMsgValues));
        exit(1);
    }
}

unittest
{
    import mar.passfail;
    import mar.expect;
    {
        enforce(passfail.pass);
        if (false)
            enforce(passfail.fail);
    }
    {
        enforce(MemoryResult.success);
        if (false)
            enforce(MemoryResult.outOfMemory);
    }
    {
        enforce(passfail.pass, "something failed!");
        if (false)
            enforce(passfail.fail, "something failed!");
    }
    {
        enforce(MemoryResult.success, Result.val);
        if (false)
            enforce(MemoryResult.outOfMemory, Result.val);
    }
    {
        enforce(MemoryResult.success, "and the error is...", Result.val);
        if (false)
            enforce(MemoryResult.outOfMemory, "and the error is...", Result.val);
    }
}
module mar.enforce;

import mar.passfail;

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

void enforce(E...)(bool cond, E errorMsgValues)
{
    if (!cond)
    {
        import mar.process : exit;
        import mar.io : stderr;
        static if (E.length == 0)
            stderr.writeln("An error occurred");
        else
            stderr.writeln("Error: ",  errorMsgValues);
        exit(1);
    }
}
void enforce(T, E...)(T result, E errorMsgValues) if (__traits(hasMember, T, "failed"))
{
    if (result.failed)
    {
        import mar.process : exit;
        import mar.io : stderr;
        static if (E.length == 0)
            stderr.writeln("An error occurred");
        else
            stderr.writeln("Error: ",  Replace!(0, result, SubAliases!E, errorMsgValues));
        exit(1);
    }
}

passfail reportFail(E...)(bool cond, E errorMsgValues)
{
    if (!cond)
    {
        import mar.io : stderr;
        static if (E.length == 0)
            stderr.writeln("An error occurred");
        else
            stderr.writeln("Error: ",  errorMsgValues);
        return passfail.fail;
    }
    return passfail.pass;
}
passfail reportFail(T, E...)(T result, E errorMsgValues) if (__traits(hasMember, T, "failed"))
{
    if (result.failed)
    {
        import mar.io : stderr;
        static if (E.length == 0)
            stderr.writeln("An error occurred");
        else
            stderr.writeln("Error: ",  Replace!(0, result, SubAliases!E, errorMsgValues));
        return passfail.fail;
    }
    return passfail.pass;
}

unittest
{
    import mar.expect;
    {
        enforce(passfail.pass);
        if (false)
            enforce(passfail.fail);
        assert(!reportFail(passfail.pass).failed);
        assert(reportFail(passfail.fail).failed);
    }
    {
        enforce(MemoryResult.success);
        if (false)
            enforce(MemoryResult.outOfMemory);
        assert(!reportFail(MemoryResult.success).failed);
        assert(reportFail(MemoryResult.outOfMemory).failed);
    }
    {
        enforce(passfail.pass, "something failed!");
        if (false)
            enforce(passfail.fail, "something failed!");
        assert(!reportFail(passfail.pass, "something failed!").failed);
        assert(reportFail(passfail.fail, "something failed!").failed);
    }
    {
        enforce(MemoryResult.success, Result.val);
        if (false)
            enforce(MemoryResult.outOfMemory, Result.val);
        assert(!reportFail(MemoryResult.success, Result.val).failed);
        assert(reportFail(MemoryResult.outOfMemory, Result.val).failed);
    }
    {
        enforce(MemoryResult.success, "and the error is...", Result.val);
        if (false)
            enforce(MemoryResult.outOfMemory, "and the error is...", Result.val);
        assert(!reportFail(MemoryResult.success, "and the error is...", Result.val).failed);
        assert(reportFail(MemoryResult.outOfMemory, "and the error is...", Result.val).failed);
    }
}
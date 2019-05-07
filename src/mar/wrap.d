/**
Contains code to create type wrappers.
*/
module mar.wrap;

import mar.flag;

mixin template WrapperFor(string fieldName)
{
    alias WrapType = typeof(__traits(getMember, typeof(this), fieldName));
    static assert(typeof(this).sizeof == WrapType.sizeof,
        "WrapperType '" ~ typeof(this).stringof ~ "' must be the same size as it's WrapType '" ~
        WrapType.stringof ~ "'");

    private ref auto wrappedValueRef() inout
    {
        pragma(inline, true);
        return __traits(getMember, typeof(this), fieldName);
    }
}

mixin template WrapOpCast()
{
    auto opCast(T)() inout
    if (is(typeof(cast(T)wrappedValueRef)))
    {
        pragma(inline, true);
        return cast(T)wrappedValueRef;
    }
}

mixin template WrapOpUnary()
{
    auto opUnary(string op)() inout if (op == "-")
    {
        pragma(inline, true);
        return inout typeof(this)(mixin(op ~ "wrappedValueRef"));
    }
    void opUnary(string op)() if (op == "++" || op == "--")
    {
        pragma(inline, true);
        mixin("wrappedValueRef" ~ op ~ ";");
    }
}

mixin template WrapOpIndex()
{
    auto ref opIndex(T)(T index) inout
    {
        pragma(inline, true);
        return wrappedValueRef[index];
    }
    auto opIndexAssign(T, U)(T value, U index)
    {
        pragma(inline, true);
        wrappedValueRef[index] = value;
    }
}

mixin template WrapOpSlice()
{
    auto opSlice(T, U)(T first, U second) inout
    {
        pragma(inline, true);
        return wrappedValueRef[first .. second];
    }
}

mixin template WrapOpBinary(Flag!"includeWrappedType" includeWrappedType)
{
    auto opBinary(string op)(const typeof(this) rhs) inout
    {
        pragma(inline, true);
        return inout typeof(this)(mixin("wrappedValueRef " ~ op ~ " rhs.wrappedValueRef"));
    }
    static if (includeWrappedType)
    {
        auto opBinary(string op)(const WrapType rhs) inout
        {
            pragma(inline, true);
            return inout typeof(this)(mixin("wrappedValueRef " ~ op ~ " rhs"));
        }
    }
}

mixin template WrapOpEquals(Flag!"includeWrappedType" includeWrappedType)
{
    bool opEquals(const typeof(this) rhs) const
    {
        pragma(inline, true);
        return wrappedValueRef == rhs.wrappedValueRef;
    }
    static if (includeWrappedType)
    {
        bool opCmp(const WrapType rhs) const
        {
            pragma(inline, true);
            return wrappedValueRef == rhs;
        }
    }
}

mixin template WrapOpCmp(Flag!"includeWrappedType" includeWrappedType)
{
    int opCmp(const typeof(this) rhs) const
    {
        pragma(inline, true);
        return wrappedValueRef.opCmp(rhs.wrappedValueRef);
    }
    static if (includeWrappedType)
    {
        int opCmp(const typeof(` ~ field ~ `) rhs) const
        {
            pragma(inline, true);
            return wrappedValueRef.opCmp(rhs);
        }
    }
}
mixin template WrapOpCmpIntegral(Flag!"includeWrappedType" includeWrappedType)
{
    int opCmp(const typeof(this) rhs) const
    {
        pragma(inline, true);
        const result = wrappedValueRef - rhs.wrappedValueRef;
        if (result < 0) return -1;
        if (result > 0) return 1;
        return 0;
    }
    static if (includeWrappedType)
    {
        int opCmp(const typeof(` ~ field ~ `) rhs) const
        {
            pragma(inline, true);
            const result = wrappedValueRef - rhs;
            if (result < 0) return -1;
            if (result > 0) return 1;
            return 0;
        }
    }
}

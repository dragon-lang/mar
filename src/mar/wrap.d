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

    pragma(inline)
    private ref auto wrappedValueRef() inout
    {
        return __traits(getMember, typeof(this), fieldName);
    }
}

mixin template WrapOpCast()
{
    pragma(inline)
    auto opCast(T)() inout
    if (is(typeof(cast(T)wrappedValueRef)))
    {
        return cast(T)wrappedValueRef;
    }
}

mixin template WrapOpUnary()
{
    pragma(inline)
    auto opUnary(string op)() inout if (op == "-")
    {
        return inout typeof(this)(mixin(op ~ "wrappedValueRef"));
    }
    pragma(inline)
    void opUnary(string op)() if (op == "++" || op == "--")
    {
        mixin("wrappedValueRef" ~ op ~ ";");
    }
}

mixin template WrapOpIndex()
{
    pragma(inline)
    auto ref opIndex(T)(T index) inout
    {
        return wrappedValueRef[index];
    }
    pragma(inline)
    auto opIndexAssign(T, U)(T value, U index)
    {
        wrappedValueRef[index] = value;
    }
}

mixin template WrapOpSlice()
{
    pragma(inline)
    auto opSlice(T, U)(T first, U second) inout
    {
        return wrappedValueRef[first .. second];
    }
}

mixin template WrapOpBinary(Flag!"includeWrappedType" includeWrappedType)
{
    pragma(inline)
    auto opBinary(string op)(const typeof(this) rhs) inout
    {
        return inout typeof(this)(mixin("wrappedValueRef " ~ op ~ " rhs.wrappedValueRef"));
    }
    static if (includeWrappedType)
    {
        pragma(inline)
        auto opBinary(string op)(const WrapType rhs) inout
        {
            return inout typeof(this)(mixin("wrappedValueRef " ~ op ~ " rhs"));
        }
    }
}

mixin template WrapOpEquals(Flag!"includeWrappedType" includeWrappedType)
{
    pragma(inline)
    bool opEquals(const typeof(this) rhs) const
    {
        return wrappedValueRef == rhs.wrappedValueRef;
    }
    static if (includeWrappedType)
    {
        pragma(inline)
        bool opCmp(const WrapType rhs) const
        {
            return wrappedValueRef == rhs;
        }
    }
}

mixin template WrapOpCmp(Flag!"includeWrappedType" includeWrappedType)
{
    pragma(inline)
    int opCmp(const typeof(this) rhs) const
    {
        return wrappedValueRef.opCmp(rhs.wrappedValueRef);
    }
    static if (includeWrappedType)
    {
        pragma(inline)
        int opCmp(const typeof(` ~ field ~ `) rhs) const
        {
            return wrappedValueRef.opCmp(rhs);
        }
    }
}
mixin template WrapOpCmpIntegral(Flag!"includeWrappedType" includeWrappedType)
{
    pragma(inline)
    int opCmp(const typeof(this) rhs) const
    {
        const result = wrappedValueRef - rhs.wrappedValueRef;
        if (result < 0) return -1;
        if (result > 0) return 1;
        return 0;
    }
    static if (includeWrappedType)
    {
        pragma(inline)
        int opCmp(const typeof(` ~ field ~ `) rhs) const
        {
            const result = wrappedValueRef - rhs;
            if (result < 0) return -1;
            if (result > 0) return 1;
            return 0;
        }
    }
}

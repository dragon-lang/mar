module mar.conv;

import mar.passfail;
import mar.flag;
import mar.traits : isArithmetic;
import mar.typecons : Nullable, nullable;

auto staticCast(T, U)(auto ref U value)
{
    pragma(inline, true);
    return *cast(T*)&value;
}

string asString(Enum)(Enum enumValue, string missingValue = null) if ( is(Enum == enum) )
{
    switch (enumValue)
    {
        foreach (member; __traits(allMembers, Enum))
        {
            case __traits(getMember, Enum, member): return member;
        }
        default: return missingValue;
    }
}

Nullable!Enum tryParseEnum(Enum)(const(char)[] str)
{
    foreach (member; __traits(allMembers, Enum))
    {
        if (str == member)
            return nullable(__traits(getMember, Enum, member));
    }
    return Nullable!Enum.init;
}


passfail tryTo(To,From)(From from, To* to)
{
    static if (is(From == string))
    {
        static if (isArithmetic!To)
        {
            return charRangeToArithmetic!To(from, to);
        }
        else static assert(0, "tryTo From=" ~ From.stringof ~ " To=" ~ To.stringof ~ " not implemented");
    }
    else static if (__traits(hasMember, From, "SentinelPtrFor") &&
                    is (From.SentinelPtrFor == char))
    {
        static if (isArithmetic!To)
        {
            return charRangeToArithmetic!To(from.rangeCopy, to);
        }
        else static assert(0, "tryTo From=" ~ From.stringof ~ " To=" ~ To.stringof ~ " not implemented");
    }
    else static assert(0, "tryTo From=" ~ From.stringof ~ " not implemented");
}

passfail charRangeToArithmetic(T, U)(U charRange, T* outValue)
{
    if (charRange.empty)
        return passfail.fail;

    T val = void;
    {
        auto next = charRange.front;
        if (next > '9' || next < '0')
            return passfail.fail;
        val = cast(T)(next - '0');
    }
    for (;;)
    {
        charRange.popFront();
        if (charRange.empty)
        {
            *outValue = val;
            return passfail.pass;
        }
        auto next = charRange.front;
        if (next > '9' || next < '0')
            return passfail.fail;
        val *= 10;
        val += cast(T)(next - '0');
    }
}


template to(T)
{
    T to(A...)(A args) { return toImpl!T(args); }
}

private T toImpl(T, S)(S value)
{
     // TODO: support char[] as well
     static if (is(T == string))
     {
         static assert(0, "not implemented");
     }
     else static assert(0, "to " ~ T.stringof ~ " not implemented");
}


/+
Not sure these functions are necessary, since I have mar.print.sprint and family.
All the logic to print a value is in that module, having that duplicated in this
API seems to just add complexity.

/***************************************************************
 * Convenience functions for converting one or more arguments
 * of any type into _text (the three character widths).
 */
string text(T...)(T args)
if (T.length > 0) { return textImpl!string(args); }

///ditto
wstring wtext(T...)(T args)
if (T.length > 0) { return textImpl!wstring(args); }

///ditto
dstring dtext(T...)(T args)
if (T.length > 0) { return textImpl!dstring(args); }

private S textImpl(S, U...)(U args)
{
    static if (U.length == 0)
    {
        return null;
    }
    else static if (U.length == 1)
    {
        return to!S(args[0]);
    }
    else
    {
        static if (is(T == string))
        {
            import mar.print : sprintMalloc;
            return sprintMallocNoSentinel(args);
        }
    }
}
+/
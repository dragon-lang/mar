module mar.format;

import mar.traits : Unqual, isArithmetic;

// TODO: make an snprint
char* sprint(T...)(char* dst, T args)
{
    import mar.array : acopy;
    import mar.string : isStringLike;

    foreach (arg; args)
    {
        static if (is(typeof(arg.FormatAsHex)))
        {
            alias argType = typeof(arg.value);
            auto argValue = arg.value;
            enum formatHex = true;
        }
        else
        {
            alias argType = typeof(arg);
            auto argValue = arg;
            enum formatHex = false;
        }
        //pragma(msg, argType.stringof, " hex=", formatHex);

        static if (isStringLike!(argType))
        {
            //pragma(msg, "  isStringLike");
            acopy(dst, argValue);
            dst += argValue.length;
        }
        else static if (is(argType == char))
        {
            //pragma(msg, "  is a char");
            dst[0] = argValue;
            dst++;
        }
        else static if (isArithmetic!argType)
        {
            //pragma(msg, "  integral");
            static if (formatHex)
                dst = sprintNumberHex(dst, argValue);
            else
                dst = sprintNumberDecimal(dst, argValue);
        }
        else static if (is(argType == void*))
        {
            //pragma(msg, "  void*");
            static if (formatHex)
                dst = sprintNumberHex(dst, cast(size_t)argValue);
            else
                dst = sprintNumberDecimal(dst, cast(size_t)argValue);
        }
        else static if (is(typeof(argValue.toString(dst))))
        {
            dst = argValue.toString(dst);
        }
        else static if (is(typeof(argValue.asCString)))
        {
            import mar.string : strlen;
            auto cString = argValue.asCString;
            size_t size = strlen(cString);
            acopy(dst, cString[0 .. size]);
            dst += size;
        }
        else static assert(0, "don't know how to print type " ~ argType.stringof);
    }
    return dst;
}

// TODO: add formatWidth(num, spacer)

struct FormatHexWrapper(T)
{
    enum FormatAsHex = true;
    T value;
}
auto formatHex(T)(T value)
{
    return FormatHexWrapper!T(value);
}

pragma(inline)
char* sprintNumberDecimal(T)(char* dst, T value) if (!is(T == Unqual!T))
{
    return sprintNumberDecimal!(Unqual!T)(dst, value);
}
char* sprintNumberDecimal(T)(char* dst, T value) if (is(T == Unqual!T))
{
    import mar.array : areverse;

    if (value == 0)
    {
        *dst = '0';
        return dst + 1;
    }
    static if (T.min < 0)
    {
        if (value < 0)
        {
            *dst = '-';
            dst++;
            value *= -1; // NOTE: this won't always work
        }
    }
    auto saveDigitStart = dst;
    for (;;)
    {
        *dst = (value % 10) + '0';
        dst++;
        value /= 10;
        if (value == 0)
        {
            areverse(saveDigitStart, dst);
            return dst;
        }
    }
}
private immutable hexTable = "0123456789abcdef";
char* sprintNumberHex(T)(char* dst, T value)
{
    import mar.array : areverse;

    auto saveDigitStart = dst;
    for (;;)
    {
        *dst = hexTable[value & 0b1111];
        dst++;
        value >>= 4;
        if (value == 0)
        {
            areverse(saveDigitStart, dst);
            return dst;
        }
    }
}

unittest
{
    char[100] buf;
    sprintNumberDecimal(buf.ptr, 12345);
}

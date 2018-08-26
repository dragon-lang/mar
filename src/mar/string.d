module mar.string;

import mar.c : cstring;

template isStringLike(T)
{
    import mar.array : isArrayLike;

    static if (isArrayLike!T)
        enum isStringLike = (T.init[0].sizeof == 1);
    else
        enum isStringLike = false;
}

version (NoStdc)
{
}
else
{
    static import core.stdc.string;
}

size_t strlen(cstring str)
{
    version (NoStdc)
    {
        for (size_t i = 0; ;i++)
        {
            if (str.raw[i] == '\0')
                return i;
        }
    }
    else
        return core.stdc.string.strlen(str.raw);
}

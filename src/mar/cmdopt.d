module maros.cmdopt;

import mar.c : cstring;

/**
Get the value of a command line option argument and increments
the counter.
On errors, prints a message to stderr and exits.
*/
auto getOptArg(T)(T args, uint* i)
{
    import mar.enforce;
    import mar.io : stderr;

    (*i)++;
    static if (__traits(hasMember, args, "length"))
    {
        enforce((*i) < args.length, "Error: option '", args[(*i)-1], "' requires an argument");
    }
    auto arg = args[*i];
    static if (!__traits(hasMember, args, "length"))
    {
        enforce(arg != arg.nullValue, "Error: option '", args[(*i)-1], "' requires an argument");
    }
    return arg;
}
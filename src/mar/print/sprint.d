module mar.print.sprint;

import mar.sentinel : SentinelArray;

version (NoExit) { } else
{
    /**
    Does not return errors, asserts if the given `buffer` is too small. This means
    that these functions are not available if NoExit is specified.

    The "Sentinel" variants will append a terminating null to the end of the
    character buffer, but return a size or array length not including the terminating null.

    The "JustReturnSize" variants will just return the size of the printed string (not including
    the terminating null) with the rest returning the given buffer with the length of the
    printed string.
    */
    char[] sprint(T...)(char[] buffer, T args)
    {
        pragma(inline, true);
        return buffer[0 .. sprintJustReturnSize(buffer, args)];
    }
    /// ditto
    SentinelArray!char sprintSentinel(T...)(char[] buffer, T args)
    {
        pragma(inline, true);
        import mar.sentinel : assumeSentinel;
        return buffer[0 .. sprintSentinelJustReturnSize(buffer, args)].assumeSentinel;
    }
    /// ditto
    size_t sprintJustReturnSize(T...)(char[] buffer, T args)
    {
        import mar.print : printArgs;
        import mar.print.printers : FixedSizeStringPrinter;

        auto printer = FixedSizeStringPrinter(buffer, 0);
        printArgs(&printer, args);
        return printer.getLength;
    }
    /// ditto
    size_t sprintSentinelJustReturnSize(T...)(char[] buffer, T args)
    {
        import mar.print : printArgs;
        import mar.print.printers : FixedSizeStringPrinter;

        auto printer = FixedSizeStringPrinter(buffer, 0);
        printArgs(&printer, args, '\0');
        return printer.getLength - 1;
    }

    /**
    These functions will pre-calculate the size needed to create a string with
    the given arguments, allocate then memory for it, then print the string
    and return it.

    The "Sentinel" variant will append a terminating null whereas the "NoSentinel" will not.
    The length of the array returned by the "Sentinel" variant will not include the terminating null.
 
    These functions will assert on error, they will never return null.
    This is the simpler versions of the functions where they assert if the pre-calulated size
    does not match the actual printed size.  Since it asserts in this case, we also decide to
    assert when malloc fails.
    (TODO: will probably create variants that return an error instead).

    */
    char[] sprintMallocNoSentinel(T...)(T args)
    {
        import mar.mem : malloc;
        import mar.print : getPrintSize;

        auto totalSize = getPrintSize(args);
        auto buffer = cast(char*)malloc(totalSize);
        if (!buffer)
        {
             // might as well assert, because we have to assert when printedSize != totalSize
            assert(0, "malloc failed");
        }
        const printedSize = sprintJustReturnSize(buffer[0 .. totalSize], args);
        assert(printedSize == totalSize, "codebug: precalculated print size differed from actual size");
        return buffer[0 .. totalSize];
    }
    /// ditto
    SentinelArray!char sprintMallocSentinel(T...)(T args)
    {
        import mar.mem : malloc;
        import mar.sentinel : assumeSentinel;
        import mar.print : getPrintSize;

        const totalSize = getPrintSize(args);
        auto buffer = cast(char*)malloc(totalSize + 1);
        if (!buffer)
        {
             // might as well assert, because we have to assert when printedSize != totalSize
            assert(0, "malloc failed");
        }
        const printedSize = sprintSentinelJustReturnSize(buffer[0 .. totalSize + 1], args);
        assert(printedSize == totalSize, "codebug: precalculated print size differed from actual size");
        return buffer[0 .. totalSize].assumeSentinel;
    }
}

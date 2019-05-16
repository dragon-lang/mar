module mar.expect;

template ErrorCase(string Name, string ErrorMessageFormat, ErrorFieldTypes...)
{
    struct ErrorCase
    {
        alias name = Name;
        alias errorMessageFormat = ErrorMessageFormat;
        alias errorFieldTypes = ErrorFieldTypes;
    }
}

// It's a bit odd but this works with -betterC
private template ctfeToString(size_t num)
{
    enum ctfeToString = mixin(function() {
        import mar.print : maxDecimalDigits, printDecimalSizet;
        auto result = new char[3 + maxDecimalDigits!size_t];
        result[0] = '"';
        auto end = printDecimalSizet(&result.ptr[1], num);
        end[0] = '"';
        end[1] = '\0';


        // can't subtract pointers in ctfe, so we have to count to the end
        // size_t length = end - result;
        size_t length = 1;
        for (; result[length] != '"'; length++)
        { }

        return result[0 .. length + 1];
    }());
}

mixin template ExpectMixin(string TypeName, SuccessType, ErrorCases...)
{
    private enum mixinCode = function() {
        import mar.expect : ExpectFormatRange, PrintErrorCaseMixin;
        import mar.print : maxDecimalDigits;

        char[maxDecimalDigits!size_t + 1] numBuffer;
        char[] str(size_t num)
        {
            import mar.print : sprint;
            return numBuffer[0 .. sprint(numBuffer, num)];
        }

        string code = "static struct " ~ TypeName ~ "\n";
        code ~= "{\n";
        code ~= "    enum State\n";
        code ~= "    {\n";
        code ~= "        success,\n";
        static foreach (errorCase; ErrorCases)
        {
            code ~= "        " ~ errorCase.name ~ ",\n";
        }
        code ~= "    }\n";
        static if (is(SuccessType == void) )
        {
            code ~= q{    static auto success() { return typeof(this)(State.success); }
};
        }
        else
        {
            code ~= q{
    static auto success(SuccessType val)
    {
        auto result = typeof(this)(State.success);
        result.val = val;
        return result;
    }
};
        }
        static foreach (i, errorCase; ErrorCases)
        {
            code ~= "    static auto " ~ errorCase.name ~ "(ErrorCases[" ~ str(i) ~ "].errorFieldTypes fields)\n";
            code ~= "    {\n";
            if (errorCase.errorFieldTypes.length == 0)
            {
                code ~= "        return typeof(this)(State." ~ errorCase.name ~ ");\n";
            }
            else
            {
                code ~= "        auto result = typeof(this)(State." ~ errorCase.name ~ ");\n";
                code ~= "        result." ~ errorCase.name ~ "Fields = fields;\n";
                code ~= "        return result;\n";
            }
            code ~= "    }\n";
        }
        code ~= "\n";
        code ~= "    private State state;\n";
        code ~= "    union\n";
        code ~= "    {\n";
        static if (!is(SuccessType == void))
        {
            code ~= "        SuccessType val;\n";
        }
        static foreach (i, errorCase; ErrorCases)
        {
            if (errorCase.errorFieldTypes.length > 0)
            {
                code ~= "        struct\n";
                code ~= "        {\n";
                code ~= "            ErrorCases[" ~ str(i) ~ "].errorFieldTypes " ~
                    errorCase.name ~ "Fields;\n";
                code ~= "        }\n";
            }
        }
        code ~= "    }";
        code ~= q{
    private this(State state) { this.state = state; }
    bool failed() const { pragma(inline, true); return state != State.success; }
    bool passed() const { pragma(inline, true); return state == State.success; }

    bool reportFail() const
    {
        if (failed)
        {
            import mar.stdio : stderr;
            stderr.writeln("Error: ", this);
            return true;
        }
        return false;
    }
    version (NoExit) { } else
    {
        void enforce() const
        {
            if (failed)
            {
                import mar.process : exit;
                import mar.stdio : stderr;
                stderr.writeln("Error: ", this);
                exit(1);
            }
        }
    }
};
        code ~= "    auto print(P)(P printer) const\n";
        code ~= "    {\n";
        code ~= "        import mar.print : printArgs;";
        code ~= "        switch (state)\n";
        code ~= "        {\n";
        code ~= "        case State.success: return printer.put(\"no error\"); break;\n";
        static foreach (i, errorCase; ErrorCases)
        {
            code ~= "        case State." ~ errorCase.name ~ ": return printArgs(printer\n";
            //
            // I would just use a static foreach here but I can't get it to work with -betterC
            //
            code ~= PrintErrorCaseMixin!(errorCase.name, errorCase.errorMessageFormat, 0, errorCase.errorFieldTypes);
            code ~= "            );\n";
        }
        code ~= "        default:\n";
        code ~= "            // we assert here instead of using final switch\n";
        code ~= "            // because final switch requires exceptions which don't\n";
        code ~= "            // work with -betterC\n";
        code ~= "            assert(0, \"codebug: invalid state\");\n";
        code ~= "        }\n";
        code ~= "        return printer.success;\n";
        code ~= "    }\n";
        code ~= "}\n";
        return code;
    }();
    //pragma(msg, mixinCode);
    mixin(mixinCode);
}

// Need to use a recursive template here because I just can't get it to
// work without it in -betterC mode
template PrintErrorCaseMixin(string name, string Format, size_t nextFieldIndex, ErrorFieldTypes...)
{
     import mar.array : indexOrLength;
     //pragma(msg, "Format '" ~ Format ~ "', fields: " ~ ErrorFieldTypes.stringof);
     private enum PercentIndex = indexOrLength(Format, '%');
     static if (PercentIndex == 0)
     {
         static if (Format.length == 0)
         {
             static assert(ErrorFieldTypes.length == 0, "Too many types in ErrorCase " ~ name ~ " for format string.");
             enum PrintErrorCaseMixin = "";
         }
         else
         {
             static assert(ErrorFieldTypes.length > 0, "Not enough types in ErrorCase " ~ name ~ " for format string");
             enum PrintErrorCaseMixin =
                 "            , " ~ name ~ "Fields[" ~ ctfeToString!nextFieldIndex ~ "]\n"
                 ~ PrintErrorCaseMixin!(name, Format[1 .. $], nextFieldIndex + 1, ErrorFieldTypes[1 .. $]);
         }
     }
     else
     {
         enum PrintErrorCaseMixin =
             "            , \"" ~ Format[0 .. PercentIndex] ~ "\"\n"
             ~ PrintErrorCaseMixin!(name, Format[PercentIndex .. $], nextFieldIndex, ErrorFieldTypes);
     }
}

// Was using this to print error cases, but I can't get it to work with -betterC
struct ExpectFormatRange
{
    // Since this needs to run at compile time, can't really use pointers much.
    // So I went with offsets instead.
    string format;
    struct OffsetLimit { size_t offset; size_t limit;}
    OffsetLimit current;
    size_t argIndex;
    this(string format)
    {
        this.format = format;
        this.current = OffsetLimit(0, 0);
        this.argIndex = size_t.max;
        popFront();
    }
    final bool empty() const { return current.offset == current.limit; }

    final auto front() const { return format[current.offset .. current.limit]; }
    /*
    // This doesn't seem to work in -betterC mode because it requires TypeInfo be pulled in
    struct Result
    {
        import mar.aliasseq;
        AliasSeq!(size_t, string) expand;
        alias expand this;
    }
    final auto front() const { return Result(argIndex, format[current.offset .. current.limit]); }
    */
    final void popFront()
    {
        current.offset = current.limit;
        if (current.limit >= format.length)
            return;
        current.limit++;
        if (format[current.limit - 1] == '%')
            argIndex++;
        else
        {
            for (;current.limit != format.length && format[current.limit] != '%'
                 ;current.limit++)
            { }
        }
    }
}

unittest
{
    static void test(string fmt, const string[] parts)
    {
        size_t index = 0;
        //size_t nextArgIndex = 0;
        foreach (/*argIndex,*/ part; ExpectFormatRange(fmt))
        {
            assert(index < parts.length);
            assert(parts[index] == part);
            if (part[0] == '%')
            {
                //assert(argIndex == nextArgIndex);
                //nextArgIndex++;
            }
            index++;
        }
        assert(index == parts.length);
    }
    // With -betterC I have to assign array literals to a static immutable
    // variable or it will pull in TypeInfo.
    // Also, static variabes names in the same function must be unique even if they are
    // in different scopes.
    {static immutable parts1 = cast(string[])[]; test("", parts1); }
    {static immutable parts2 = ["a"]; test("a", parts2); }
    {static immutable parts3 = ["abc"]; test("abc", parts3); }
    {static immutable parts4 = ["a","%"]; test("a%", parts4); }
    {static immutable parts5 = ["a","%","b"]; test("a%b", parts5); }
    {static immutable parts6 = ["%","a","%","b"]; test("%a%b", parts6); }
    {static immutable parts7 = ["%","%"]; test("%%", parts7); }
    {static immutable parts8 = ["%","%","abc","%","%","%","foo","%"]; test("%%abc%%%foo%", parts8); }
}


unittest
{
    {
        mixin ExpectMixin!("ReadLineResult", int,
            ErrorCase!("outOfMemory", "out of memory"),
            ErrorCase!("readFailed", "read failed, returned %", ptrdiff_t));
        {
            auto result = ReadLineResult.success(0);
            import mar.stdio; stdout.write("result: ", result, "\n");
        }
        {
            auto result = ReadLineResult.outOfMemory();
            import mar.stdio; stdout.write("result: ", result, "\n");
        }
        {
            auto result = ReadLineResult.readFailed(100);
            import mar.stdio; stdout.write("result: ", result, "\n");
        }
    }
}

mixin ExpectMixin!("MemoryResult", void,
    ErrorCase!("outOfMemory", "out of memory"));

module mar.expect;

mixin template ExpectMixin(string TypeName, SuccessType, ErrorCases...)
{
    private enum mixinCode = function() {
        char[50] numBuffer;
        char[] str(size_t num)
        {
            import mar.format : sprint;
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
        code ~= "    }";
        static if (is(SuccessType == void) )
        {
            code ~= q{ static auto success() { return typeof(this)(State.success); } };
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
    pragma(inline)
    bool failed() const { return state != State.success; }
    pragma(inline)
    bool passed() const { return state == State.success; }
    void enforce() const
    {
        if (failed)
        {
            import mar.process : exit;
            import mar.file : stderr, print;
            print(stderr, "Error: ", this, "\n");
            exit(1);
        }
    }
};
        code ~= "    void toString(Printer)(Printer printer) const\n";
        code ~= "    {\n";
        code ~= "        final switch (state)\n";
        code ~= "        {\n";
        code ~= "        case State.success: printer.put(\"no error\"); break;\n";
        static foreach (i, errorCase; ErrorCases)
        {
            // TODO: interpolate error message and data
            code ~= "        case State." ~ errorCase.name ~ ": printer.put(\"" ~
                errorCase.errorMessageFormat ~ "\"); break;\n";
        }
        code ~= "        }\n";
        code ~= "    }\n";
        code ~= "}\n";
        return code;
    }();
    //pragma(msg, mixinCode);
    mixin(mixinCode);
}


template ErrorCase(string Name, string ErrorMessageFormat, ErrorFieldTypes...)
{
    struct ErrorCase
    {
        alias name = Name;
        alias errorMessageFormat = ErrorMessageFormat;
        alias errorFieldTypes = ErrorFieldTypes;
    }
}

unittest
{
    {
        mixin ExpectMixin!("ReadLineResult", int,
            ErrorCase!("outOfMemory", "out of memory"),
            ErrorCase!("readFailed", "read failed, returned %", ptrdiff_t));
        {
            auto result = ReadLineResult.success(0);
            //import mar.file; print(stdout, "result: ", result, "\n");
        }
        {
            auto result = ReadLineResult.outOfMemory();
            //import mar.file; print(stdout, "result: ", result, "\n");
        }
        {
            auto result = ReadLineResult.readFailed(100);
            //import mar.file; print(stdout, "result: ", result, "\n");
        }
    }
}

mixin ExpectMixin!("MemoryResult", void,
    ErrorCase!("outOfMemory", "out of memory"));

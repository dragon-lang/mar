module mar.windows.kernel32.nolink;

/**
Represents semantics of the windows BOOL return type.
*/
struct BoolExpectNonZero
{
    import mar.c : cint;

    private cint _value;
    bool failed() const { pragma(inline, true); return _value == 0; }
    bool passed() const { pragma(inline, true); return _value != 0; }

    auto print(P)(P printer) const
    {
        return printer.put(passed ? "TRUE" : "FALSE");
    }
}

struct FileAttributesOrError
{
    import mar.windows : FileAttributes;

    private static FileAttributes invalidEnumValue() { pragma(inline, true); return cast(FileAttributes)-1; }
    static FileAttributesOrError invalidValue() { pragma(inline, true); return FileAttributesOrError(invalidEnumValue); }

    private FileAttributes _attributes;
    bool isValid() const { return _attributes != invalidEnumValue; }
    FileAttributes val() const { return _attributes; }
}

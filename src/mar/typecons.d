module mar.typecons;

/+
ref T unconst(T)(ref const(T) value)
{
    pragma(inline, true);
    return cast(T)value;
}
T unconst(T)(const(T) value)
{
    pragma(inline, true);
    return cast(T)value;
}
+/
T unconst(T)(const(T) obj)
{
    pragma(inline, true);
    return cast(T)obj;
}

template unsignedType(size_t size)
{
    static if (size == 1)
        alias unsignedType = ubyte;
    static if (size == 2)
        alias unsignedType = ushort;
    static if (size == 4)
        alias unsignedType = uint;
    static if (size == 8)
        alias unsignedType = ulong;
    else static assert(0, "no unsignedType for this size");
}

template defaultNullValue(T)
{
    static if (is(T == enum))
    {
             static if (T.min - 1 < T.min) enum defaultNullValue = cast(T)(T.min - 1);
        else static if (T.max + 1 > T.max) enum defaultNullValue = cast(T)(T.max + 1);
        else static assert(0, "cannot find a default null value for " ~ T.stringof);
    }
    else static assert(0, "cannot find a default null value for " ~ T.stringof);
}

struct Nullable(T, T nullValue = defaultNullValue!T)
{
    private T value = nullValue;
    T unsafeGetValue() inout { pragma(inline, true); return cast(T)value; }
    T get() inout in { assert(value !is nullValue); } do { return cast(T)value; }
    bool isNull() const { return value is nullValue; }
    void opAssign(T value)
    {
        this.value = value;
    }
}

auto nullable(T)(T value) { return Nullable!T(value); }

version (NoStdc) { } else
{
    template ErrnoOrValue(T)
    {
        struct ErrnoOrValue
        {
            static ErrnoOrValue error()
            {
                return ErrnoOrValue.init;
            }

            private T _value = void;
            private bool _isError = true; // TODO: some types may not need an error field

            this(T value)
            {
                this._value = value;
                this._isError = false;
            }

            bool isError() const { return _isError; }
            auto errorCode() const
            {
                import core.stdc.errno : errno;
                return errno;
            }
            T value() const { return cast(T)_value; }
        }
    }
}

struct ValueOrErrorCode(Value, ErrorCode)
{
    static ValueOrErrorCode!(Value, ErrorCode) error(ErrorCode errorCode)
    in { assert(errorCode != ErrorCode.init); } do
    {
        ValueOrErrorCode!(Value, ErrorCode) result;
        result._errorCode = errorCode;
        return result;
    }

    private Value _value = void;
    private ErrorCode _errorCode;

    this(Value value)
    {
        this._value = value;
    }

    bool failed() const { pragma(inline, true); return _errorCode != ErrorCode.init; }
    bool passed() const { pragma(inline, true); return _errorCode == ErrorCode.init; }
    ErrorCode errorCode() const { pragma(inline, true); return cast(ErrorCode)_errorCode; }

    void set(Value value) { pragma(inline, true); this._value = value; }
    Value val() const { pragma(inline, true); return cast(Value)_value; }
}

auto enforce(T, U...)(T value, U errorMsgArgs)
{
    pragma(inline, true);
    if (value.failed)
    {
        import mar.process : exit;
        import mar.file : stderr;
        stderr.write(errorMsgArgs);
        exit(1);
    }
    return value.val;
}
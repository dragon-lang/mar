/**
Contains types to differentiate arrays with sentinel values.
*/
module mar.sentinel;

/**
Selects the default sentinel value for a type `T`.

It has a special case for the char types, and also allows
the type to define its own default sentinel value if it
has the member `defaultSentinel`. Otherwise, it uses `T.init`.
*/
private template defaultSentinel(T)
{
         static if (is(Unqual!T ==  char)) enum defaultSentinel = '\0';
    else static if (is(Unqual!T == wchar)) enum defaultSentinel = cast(wchar)'\0';
    else static if (is(Unqual!T == dchar)) enum defaultSentinel = cast(dchar)'\0';
    else static if (__traits(hasMember, T, "defaultSentinel")) enum defaultSentinel = T.defaultSentinel;
    else                                   enum defaultSentinel = T.init;
}

// NOTE: T should be unqalified (not const/immutable etc)
//       This "unqualification" of T is done by the `SentinelPtr` and `SentinelArray` templates.
private template SentinelTemplate(T, immutable T sentinelValue)
{
/*
    static if (__traits(hasMember, T, "SentinelPtrFor"))
    {
        pragma(msg, "SentinelTemplate!(SentinelTemplate!(" ~ T.SentinelPtrFor.stringof ~ "))");
        alias SentinelPtrPtr = SentinelTemplate!(T.SentinelPtrFor, T.SentinelValue);
    }
    else
    {
        pragma(msg, "SentinelTemplate!(" ~ T.stringof ~ ")");
    }
*/
    private enum CommonPtrMembers = q{

        // this allows code to tell if it is a SentinelPtr and also
        // provides external access the "pointed to" type.
        alias SentinelPtrFor = T;

        // defined so you can access it externally
        enum SentinelValue = sentinelValue;

        static auto nullValue() { pragma(inline, true); return typeof(this)(null); }
        bool isNull() const { pragma(inline, true); return _ptr is null; }

        /**
        Interpret a raw pointer `ptr` as a `SentinelPtr` without checking that
        the array it is pointing to has a sentinel value.
        Params:
            ptr = the raw pointer to be converted
        Returns:
            the given `ptr` interpreted as a `SentinelPtr`
        */
        static auto assume(SpecificT* ptr) pure
        {
            pragma(inline, true);
            return typeof(this)(ptr);
        }

        private SpecificT* _ptr;
        private this(SpecificT* ptr) pure { this._ptr = ptr; }
        this(typeof(this) other) pure { this._ptr = other._ptr; }

        import mar.wrap;
        mixin WrapperFor!"_ptr";
        mixin WrapOpCast;
        mixin WrapOpIndex;
        mixin WrapOpSlice;
        mixin WrapOpUnary;

        ConstPtr asConst() inout
        {
            pragma(inline, true);
            return ConstPtr(cast(const(T)*)_ptr);
        }
        ConstPtr asImmutable() inout
        {
            pragma(inline, true);
            return ImmutablePtr(cast(immutable(T)*)_ptr);
        }

        auto withConstPtr() inout
        {
            pragma(inline, true);
            static if (is(typeof(_ptr.asConst)))
            {
                return SentinelPtr!(typeof(_ptr.asConst()), typeof(_ptr.asConst()).init/*(sentinelValue)*/)(
                    cast(typeof(_ptr.asConst())*)_ptr);
            }
            else
            {
                return asConst();
            }
        }

        /**
        Converts the ptr to an array by "walking" it for the sentinel value to determine its length.

        Returns:
            the ptr as a SentinelArray
        */
        SentinelArray walkToArray() inout
        {
            pragma(inline, true);
            return SentinelArray((cast(SpecificT*)_ptr)[0 .. asConst.walkLength()]);
        }

        SpecificT* raw() const { pragma(inline, true); return cast(SpecificT*)_ptr; }

        typeof(this) rangeCopy() const
        {
            pragma(inline, true);
            return typeof(return)(cast(SpecificT*)_ptr);
        }

        /**
        Return the current value pointed to by `ptr`.
        */
        auto front() inout { pragma(inline, true); return *_ptr; }

        /**
        Move ptr to the next value.
        */
        void popFront() { pragma(inline, true); _ptr++; }

        static if (is(T == char))
        {
            static if(sentinelValue == '\0')
            {
                import mar.c : cstring;
                auto asCString() const { pragma(inline, true); return cast(typeof(this))this; }
            }
            auto print(P)(P printer) const
            {
                return printer.put(_ptr[0 .. walkLength()]);
            }
        }
        bool contains(U)(U value)
        {
            return size_t.max != indexOf(value);
        }
        size_t indexOf(U)(U value)
        {
            for (size_t i = 0; ;i++)
            {
                if (_ptr[i] == value)
                    return i;
                if (_ptr[i] == sentinelValue)
                    return size_t.max;
            }
        }
        bool startsWith(U)(U value)
        {
            foreach (i; 0 .. value.length)
            {
                if (_ptr[i] == sentinelValue || value[i] != _ptr[i])
                    return false;
            }
            return true;
        }
    };
    struct MutablePtr
    {
        private alias SpecificT = T;
        private alias SentinelArray = MutableArray;

        mixin(CommonPtrMembers);

        alias asConst this; // facilitates implicit conversion to const type
        // alias raw this; // NEED MULTIPLE ALIAS THIS!!!
    }
    struct ImmutablePtr
    {
        private alias SpecificT = immutable(T);
        private alias SentinelArray = ImmutableArray;

        mixin(CommonPtrMembers);

        alias asConst this; // facilitates implicit conversion to const type
        // alias raw this; // NEED MULTIPLE ALIAS THIS!!!
    }
    struct ConstPtr
    {
        private alias SpecificT = const(T);
        private alias SentinelArray = ConstArray;

        mixin(CommonPtrMembers);

        //alias raw this;

        /**
        Returns true if `ptr` is pointing at the sentinel value.
        */
        @property bool empty() const { pragma(inline, true); return *raw == sentinelValue; }

        /**
        Walks the array to determine its length.
        Returns:
            the length of the array
        */
        size_t walkLength() const
        {
            static if ( is(T == char) )
            {
                static if ( sentinelValue == '\0')
                {
                    enum useLoop = false;
                    import mar.string : strlen;
                    return strlen(cast(ConstPtr)this);
                }
                else
                    enum useLoop = true;
            }
            else
                enum useLoop = true;

            static if (useLoop)
            {
                for (size_t i = 0; ;i++)
                {
                    if (_ptr[i] == sentinelValue)
                    {
                        return i;
                    }
                }
            }
        }
    }

    private enum CommonArrayMembers = q{
        static auto nullValue() { pragma(inline, true); return typeof(this)(null); }
        bool isNull() const { pragma(inline, true); return array.ptr == null; }

        /**
        Interpret `array` as a `SentinalArray` without checking that
        the array it is pointing to has a sentinel value.
        Params:
            array = the array to be converted
        Returns:
            the given `array` interpreted as a `SentinelArray`
        */
        static auto assume(SpecificT[] array) pure
        {
            pragma(inline, true);
            return typeof(this)(array);
        }

        /**
        Interpret `array`` as a `SentinalArray` checking that the array it
        is pointing to ends with a sentinel value.
        Params:
            array = the array to be converted
        Returns:
            the given `array` interpreted as a `SentinelArray`
        */
        static auto verify(SpecificT[] array)
        in { assert(array.ptr[array.length] == sentinelValue, "array does not end with sentinel value"); } do
        {
            return typeof(this)(array);
        }

        SpecificT[] array;
        private this(SpecificT[] array) pure { this.array = array; }
        this(typeof(this) other) pure { this.array = other.array; }

        size_t length() const { return array.length; }

        import mar.wrap;
        mixin WrapperFor!"array";
        mixin WrapOpCast;
        mixin WrapOpIndex;
        mixin WrapOpSlice;
        mixin WrapOpUnary;

        SentinelPtr ptr() const { pragma(inline, true); return SentinelPtr(cast(SpecificT*)array.ptr); }
        auto opDollar() const { pragma(inline, true); return array.length; }

        ConstArray     asConst()     inout { pragma(inline, true); return ConstArray(cast(const(T)[])array); }
        ImmutableArray asImmutable() inout { pragma(inline, true); return ImmutableArray(cast(immutable(T)[])array); }

        /**
        A no-op that just returns the array as is.  This is to be useful for templates that can accept
        normal arrays an sentinel arrays. The function is marked as `@system` not because it is unsafe
        but because it should only be called in unsafe code, mirroring the interface of the free function
        version of asSentinelArray.

        Returns:
            this
        */
        auto asSentinelArray() @system inout { pragma(inline, true); return this; }
        /// ditto
        auto asSentinelArrayUnchecked() @system inout { pragma(inline, true); return this; }

        static if (is(T == char) && sentinelValue == '\0')
        {
            import mar.c : cstring;
            auto asCString() const { return ptr; }
        }
    };
    struct MutableArray
    {
        private alias SpecificT = T;
        private alias SentinelPtr = MutablePtr;

        mixin(CommonArrayMembers);
        alias asConst this; // facilitates implicit conversion to const type
        // alias array this; // NEED MULTIPLE ALIAS THIS!!!
    }
    struct ImmutableArray
    {
        private alias SpecificT = immutable(T);
        private alias SentinelPtr = ImmutablePtr;

        mixin(CommonArrayMembers);
        alias asConst this; // facilitates implicit conversion to const type
        // alias array this; // NEED MULTIPLE ALIAS THIS!!!
    }
    struct ConstArray
    {
        private alias SpecificT = const(T);
        private alias SentinelPtr = ConstPtr;

        mixin(CommonArrayMembers);
        //alias array this;
/*
        bool opEquals(const(T)[] other) const
        {
            return array == other;
        }
        */
    }
}

/**
A pointer to an array with a sentinel value.
*/
template SentinelPtr(T, T sentinelValue = defaultSentinel!T)
{
         static if (is(T U ==     const U)) alias SentinelPtr = SentinelTemplate!(U, sentinelValue).ConstPtr;
    else static if (is(T U == immutable U)) alias SentinelPtr = SentinelTemplate!(U, sentinelValue).ImmutablePtr;
    else                                    alias SentinelPtr = SentinelTemplate!(T, sentinelValue).MutablePtr;
}
/**
An array with the extra requirement that it ends with a sentinel value at `ptr[length]`.
*/
template SentinelArray(T, T sentinelValue = defaultSentinel!T)
{
         static if (is(T U ==     const U)) alias SentinelArray = SentinelTemplate!(U, sentinelValue).ConstArray;
    else static if (is(T U == immutable U)) alias SentinelArray = SentinelTemplate!(U, sentinelValue).ImmutableArray;
    else                                    alias SentinelArray = SentinelTemplate!(T, sentinelValue).MutableArray;
}

/**
Create a SentinelPtr from a normal pointer without checking
that the array it is pointing to contains the sentinel value.
*/
@property auto assumeSentinel(T)(T* ptr) @system
{
    return SentinelPtr!T.assume(ptr);
}
@property auto assumeSentinel(alias sentinelValue, T)(T* ptr) @system
    if (is(typeof(sentinelValue) == typeof(T.init)))
{
    return SentinelPtr!(T, sentinelValue).assume(ptr);
}

/**
Coerce the given `array` to a `SentinelPtr`. It checks and asserts
if the given array does not contain the sentinel value at `array.ptr[array.length]`.
*/
@property auto verifySentinel(T)(T[] array) @system
{
    return SentinelArray!T.verify(array);
}
/// ditto
@property auto verifySentinel(alias sentinelValue, T)(T[] array) @system
    if (is(typeof(sentinelValue == T.init)))
{
    return SentinelArray!(T, sentinelValue).verify(array);
}

/**
Coerce the given `array` to a `SentinelArray` without verifying that it
contains the sentinel value at `array.ptr[array.length]`.
*/
@property auto assumeSentinel(T)(T[] array) @system
{
    return SentinelArray!T.assume(array);
}
@property auto assumeSentinel(alias sentinelValue, T)(T[] array) @system
    if (is(typeof(sentinelValue == T.init)))
{
    return SentinelArray!(T, sentinelValue).assume(array);
}
unittest
{
    auto s1 = "abcd".verifySentinel;
    auto s2 = "abcd".assumeSentinel;
    auto s3 = "abcd".ptr.assumeSentinel;

    auto full = "abcd-";
    auto s = full[0..4];
    auto s4 = s.verifySentinel!'-';
    auto s5 = s.assumeSentinel!'-';
}
unittest
{
    auto s1 = "abcd".verifySentinel;
    auto s2 = "abcd".assumeSentinel;

    auto full = "abcd-";
    auto s = full[0..4];
    auto s3 = s.verifySentinel!'-';
    auto s4 = s.assumeSentinel!'-';
}

/*
// test as ranges (NOT WORKING!!!)
unittest
{
    {
        auto s = "abcd".verifySentinel;
        size_t count = 0;
        foreach(c; s) { count++; }
        assert(count == 4);
    }
    {
        auto s = "abcd".verifySentinel;
        size_t count = 0;
        foreach(c; s) { count++; }
        assert(count == 4);
    }
    auto abcd = "abcd";
    {
        auto s = abcd[0..3].verifySentinel!'d'.ptr;
        size_t count = 0;
        foreach(c; s) { count++; }
        assert(count == 3);
    }
    {
        auto s = abcd[0..3].verifySentinel!'d'.ptr;
        size_t count = 0;
        foreach(c; s) { count++; }
        assert(count == 3);
    }
}
*/

unittest
{
    auto p1 = "hello".verifySentinel.ptr;
    auto p2 = "hello".assumeSentinel.ptr;
    assert(p1.walkLength() == 5);
    assert(p2.walkLength() == 5);

    assert(p1.walkToArray().array == "hello");
    assert(p2.walkToArray().array == "hello");
}

// Check that sentinel types can be passed to functions
// with mutable/immutable implicitly converting to const
unittest
{
    import mar.c : cstring;

    static void immutableFooString(SentinelString str) { }
    immutableFooString("hello".verifySentinel);
    immutableFooString(lit!"hello");
    // NOTE: this only works if type of string literals is changed to SentinelString
    //immutableFooString("hello");

    static void mutableFooArray(SentinelArray!char str) { }
    mutableFooArray((cast(char[])"hello").verifySentinel);

    static void constFooArray(SentinelArray!(const(char)) str) { }
    constFooArray("hello".verifySentinel);
    constFooArray(lit!"hello");
    constFooArray((cast(const(char)[])"hello").verifySentinel);
    constFooArray((cast(char[])"hello").verifySentinel);

    // NOTE: this only works if type of string literals is changed to SentinelString
    //constFooArray("hello");

    static void immutableFooCString(cstring str) { }
    immutableFooCString("hello".verifySentinel.ptr);
    immutableFooCString(lit!"hello".ptr);

    static void mutableFooPtr(SentinelPtr!char str) { }
    mutableFooPtr((cast(char[])"hello").verifySentinel.ptr);

    static void fooPtr(cstring str) { }
    fooPtr("hello".verifySentinel.ptr);
    fooPtr(lit!"hello".ptr);
    fooPtr((cast(const(char)[])"hello").verifySentinel.ptr);
    fooPtr((cast(char[])"hello").verifySentinel.ptr);
}

// Check that sentinel array/ptr implicitly convert to non-sentinel array/ptr
unittest
{
    static void mutableFooArray(char[] str) { }
    // NEED MULTIPLE ALIAS THIS !!!
    //mutableFooArray((cast(char[])"hello").verifySentinel);

    static void immutableFooArray(string str) { }
    // NEED MULTIPLE ALIAS THIS !!!
    //immutableFooArray("hello".verifySentinel);
    //immutableFooArray(lit!"hello");

    static void constFooArray(const(char)[] str) { }
    constFooArray((cast(char[])"hello").verifySentinel.array);
    constFooArray((cast(const(char)[])"hello").verifySentinel.array);
    constFooArray("hello".verifySentinel.array);
    constFooArray(lit!"hello".array);

    static void mutableFooPtr(char* str) { }
    // NEED MULTIPLE ALIAS THIS !!!
    //mutableFooPtr((cast(char[])"hello").verifySentinel.ptr);

    static void immutableFooPtr(immutable(char)* str) { }
    // NEED MULTIPLE ALIAS THIS !!!
    //immutableFooPtr("hello".verifySentinel.ptr);
    //immutableFooPtr(lit!"hello");

    static void constFooPtr(const(char)* str) { }
    constFooPtr((cast(char[])"hello").verifySentinel.ptr.raw);
    constFooPtr((cast(const(char)[])"hello").verifySentinel.ptr.raw);
    constFooPtr("hello".verifySentinel.ptr.raw);
    constFooPtr(lit!"hello".ptr.raw);
}

/**
An array of characters that contains a null-terminator at the `length` index.

NOTE: the type of string literals could be changed to SentinelString
*/
alias SentinelString = SentinelArray!(immutable(char));
alias SentinelWstring = SentinelArray!(immutable(wchar));
alias SentinelDstring = SentinelArray!(immutable(dchar));

unittest
{
    {
        auto s1 = "hello".verifySentinel;
        auto s2 = "hello".assumeSentinel;
    }
    {
        SentinelString s = "hello";
    }
}

/**
A template that coerces a string literal to a SentinelString.
Note that this template becomes unnecessary if the type of string literal
is changed to SentinelString.
*/
@property SentinelString lit(string s)() @trusted
{
    pragma(inline, true);
    SentinelString ss = void;
    ss.array = s;
    return ss;
}
/// ditto
@property SentinelWstring lit(wstring s)() @trusted
{
    pragma(inline, true);
    SentinelWstring ss = void;
    ss.array = s;
    return ss;
}
/// ditto
@property SentinelDstring lit(dstring s)() @trusted
{
    pragma(inline, true);
    SentinelDstring ss = void;
    ss.array = s;
    return ss;
}
@property SentinelPtr!(immutable(char)) litPtr(string s)() @trusted
{
    pragma(inline, true);
    SentinelPtr!(immutable(char)) p = void;
    p._ptr = s.ptr;
    return p;
}

unittest
{
    // just instantiate for now to make sure they compile
    auto sc = lit!"hello";
    auto sw = lit!"hello"w;
    auto sd = lit!"hello"d;
}

/**
This function converts an array to a SentinelArray.  It requires that the last element `array[$-1]`
be equal to the sentinel value. This differs from the function `asSentinelArray` which requires
the first value outside of the bounds of the array `array[$]` to be equal to the sentinel value.
This function does not require the array to "own" elements outside of its bounds.
*/
@property auto reduceSentinel(T)(T[] array) @trusted
in {
    assert(array.length > 0);
    assert(array[$ - 1] == defaultSentinel!T);
   } do
{
    return array[0 .. $-1].assumeSentinel;
}
/// ditto
@property auto reduceSentinel(alias sentinelValue, T)(T[] array) @trusted
    if (is(typeof(sentinelValue == T.init)))
    in {
        assert(array.length > 0);
        assert(array[$ - 1] == sentinelValue);
    } do
{
    return array[0 .. $ - 1].assumeSentinel!sentinelValue;
}

///
@safe unittest
{
    auto s1 = "abc\0".reduceSentinel;
    assert(s1.length == 3);
    () @trusted {
        assert(s1.ptr[s1.length] == '\0');
    }();

    auto s2 = "foobar-".reduceSentinel!'-';
    assert(s2.length == 6);
    () @trusted {
        assert(s2.ptr[s2.length] == '-');
    }();
}

// poor mans Unqual
private template Unqual(T)
{
         static if (is(T U ==     const U)) alias Unqual = U;
    else static if (is(T U == immutable U)) alias Unqual = U;
    else                                    alias Unqual = T;
}

/**
This function creates a sentinel array from a normal array.  It does
this by appending the sentinel value, and then returning a SentinelArray
type.
*/
@property auto makeSentinel(T)(T[] array) @trusted
{
    return (array ~ defaultSentinel!T)[0 .. $-1].assumeSentinel;
}

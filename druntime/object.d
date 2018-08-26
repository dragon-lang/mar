module object;

version (D_LP64)
{
    alias size_t = ulong;
    alias ptrdiff_t = long;
}
else
{
    alias size_t = uint;
    alias ptrdiff_t = int;
}

alias string = immutable(char)[];
alias wstring = immutable(wchar)[];
alias dstring = immutable(dchar)[];

extern (C) void __assert(bool cond, const(char)[] msg)
{
    // would be nice to get a stack trace
    if (!cond)
    {
        version (linux)
        {
            import mar.linux.file : stderr, write;
            import mar.linux.process : exit;
        }
        else static assert(0, __FUNCTION__ ~ " not implemented on this platform");
        write(stderr, "assert failed: ");
        write(stderr, msg);
        write(stderr, "\n");
        exit(1);
    }
}

version (D_BetterC) { } else {

public @trusted @nogc nothrow pure extern (C) void _d_delThrowable(scope Throwable)
{
    assert(0, "_d_delThrowabe not implemented");
}

/**
 * All D class objects inherit from Object.
 */
class Object
{
/+
    /**
     * Convert Object to a human readable string.
     */
    string toString()
    {
        //return typeid(this).name;
        return "this class as no toString implementation"
    }
    +/

    /**
     * Compute hash function for Object.
     */
    size_t toHash() @trusted nothrow
    {
        // BUG: this prevents a compacting GC from working, needs to be fixed
        return cast(size_t)cast(void*)this;
    }

/+
    /**
     * Compare with another Object obj.
     * Returns:
     *  $(TABLE
     *  $(TR $(TD this &lt; obj) $(TD &lt; 0))
     *  $(TR $(TD this == obj) $(TD 0))
     *  $(TR $(TD this &gt; obj) $(TD &gt; 0))
     *  )
     */
    int opCmp(Object o)
    {
        // BUG: this prevents a compacting GC from working, needs to be fixed
        //return cast(int)cast(void*)this - cast(int)cast(void*)o;

        //throw new Exception("need opCmp for class " ~ typeid(this).name);
        //return this !is o;
    }
    +/

    /**
     * Test whether $(D this) is equal to $(D o).
     * The default implementation only compares by identity (using the $(D is) operator).
     * Generally, overrides for $(D opEquals) should attempt to compare objects by their contents.
     */
    bool opEquals(Object o)
    {
        return this is o;
    }

/*
    interface Monitor
    {
        void lock();
        void unlock();
    }
*/

/+
    /**
     * Create instance of class specified by the fully qualified name
     * classname.
     * The class must either have no constructors or have
     * a default constructor.
     * Returns:
     *   null if failed
     * Example:
     * ---
     * module foo.bar;
     *
     * class C
     * {
     *     this() { x = 10; }
     *     int x;
     * }
     *
     * void main()
     * {
     *     auto c = cast(C)Object.factory("foo.bar.C");
     *     assert(c !is null && c.x == 10);
     * }
     * ---
     */
    static Object factory(string classname)
    {
    /*
        auto ci = TypeInfo_Class.find(classname);
        if (ci)
        {
            return ci.create();
        }
        */
        assert(0, "Object.factory not implemented");
        return null;
    }
    +/
}

/**
 * The base class of all thrown objects.
 *
 * All thrown objects must inherit from Throwable. Class $(D Exception), which
 * derives from this class, represents the category of thrown objects that are
 * safe to catch and handle. In principle, one should not catch Throwable
 * objects that are not derived from $(D Exception), as they represent
 * unrecoverable runtime errors. Certain runtime guarantees may fail to hold
 * when these errors are thrown, making it unsafe to continue execution after
 * catching them.
 */
class Throwable : Object
{
    interface TraceInfo
    {
        int opApply(scope int delegate(ref const(char[]))) const;
        int opApply(scope int delegate(ref size_t, ref const(char[]))) const;
        string toString() const;
    }

    string      msg;    /// A message describing the error.

    /**
     * The _file name of the D source code corresponding with
     * where the error was thrown from.
     */
    string      file;
    /**
     * The _line number of the D source code corresponding with
     * where the error was thrown from.
     */
    size_t      line;

    /**
     * The stack trace of where the error happened. This is an opaque object
     * that can either be converted to $(D string), or iterated over with $(D
     * foreach) to extract the items in the stack trace (as strings).
     */
    TraceInfo   info;

    /**
     * A reference to the _next error in the list. This is used when a new
     * $(D Throwable) is thrown from inside a $(D catch) block. The originally
     * caught $(D Exception) will be chained to the new $(D Throwable) via this
     * field.
     */
    private Throwable   nextInChain;

    private uint _refcount;     // 0 : allocated by GC
                                // 1 : allocated by _d_newThrowable()
                                // 2.. : reference count + 1

    /**
     * Returns:
     * A reference to the _next error in the list. This is used when a new
     * $(D Throwable) is thrown from inside a $(D catch) block. The originally
     * caught $(D Exception) will be chained to the new $(D Throwable) via this
     * field.
     */
    @property inout(Throwable) next() @safe inout return scope pure nothrow @nogc { return nextInChain; }

    /**
     * Replace next in chain with `tail`.
     * Use `chainTogether` instead if at all possible.
     */
    @property void next(Throwable tail) @safe scope pure nothrow @nogc
    {
        if (tail && tail._refcount)
            ++tail._refcount;           // increment the replacement *first*

        auto n = nextInChain;
        nextInChain = null;             // sever the tail before deleting it

        if (n && n._refcount)
            _d_delThrowable(n);         // now delete the old tail

        nextInChain = tail;             // and set the new tail
    }

    /**
     * Returns:
     *  mutable reference to the reference count, which is
     *  0 - allocated by the GC, 1 - allocated by _d_newThrowable(),
     *  and >=2 which is the reference count + 1
     */
    @system @nogc final pure nothrow ref uint refcount() return scope { return _refcount; }

    /**
     * Loop over the chain of Throwables.
     */
    int opApply(scope int delegate(Throwable) dg)
    {
        int result = 0;
        for (Throwable t = this; t; t = t.nextInChain)
        {
            result = dg(t);
            if (result)
                break;
        }
        return result;
    }

    /**
     * Append `e2` to chain of exceptions that starts with `e1`.
     * Params:
     *  e1 = start of chain (can be null)
     *  e2 = second part of chain (can be null)
     * Returns:
     *  Throwable that is at the start of the chain; null if both `e1` and `e2` are null
     */
    static @__future @system @nogc pure nothrow Throwable chainTogether(return scope Throwable e1, return scope Throwable e2)
    {
        if (e2 && e2.refcount())
            ++e2.refcount();
        if (!e1)
            return e2;
        if (!e2)
            return e1;
        for (auto e = e1; 1; e = e.nextInChain)
        {
            if (!e.nextInChain)
            {
                e.nextInChain = e2;
                break;
            }
        }
        return e1;
    }

    @nogc @safe pure nothrow this(string msg, Throwable nextInChain = null)
    {
        this.msg = msg;
        this.nextInChain = nextInChain;
        //this.info = _d_traceContext();
    }

    @nogc @safe pure nothrow this(string msg, string file, size_t line, Throwable nextInChain = null)
    {
        this(msg, nextInChain);
        this.file = file;
        this.line = line;
        //this.info = _d_traceContext();
    }

    @trusted nothrow ~this()
    {
        if (nextInChain && nextInChain._refcount)
            _d_delThrowable(nextInChain);
    }

/+
    /**
     * Overrides $(D Object.toString) and returns the error message.
     * Internally this forwards to the $(D toString) overload that
     * takes a $(D_PARAM sink) delegate.
     */
    override string toString()
    {
        string s;
        toString((buf) { s ~= buf; });
        return s;
    }
    +/

/+
    /**
     * The Throwable hierarchy uses a toString overload that takes a
     * $(D_PARAM _sink) delegate to avoid GC allocations, which cannot be
     * performed in certain error situations.  Override this $(D
     * toString) method to customize the error message.
     */
    void toString(scope void delegate(in char[]) sink) const
    {
        import core.internal.string : unsignedToTempString;

        char[20] tmpBuff = void;

        sink(typeid(this).name);
        sink("@"); sink(file);
        sink("("); sink(unsignedToTempString(line, tmpBuff, 10)); sink(")");

        if (msg.length)
        {
            sink(": "); sink(msg);
        }
        if (info)
        {
            try
            {
                sink("\n----------------");
                foreach (t; info)
                {
                    sink("\n"); sink(t);
                }
            }
            catch (Throwable)
            {
                // ignore more errors
            }
        }
    }
    +/

    /**
     * Get the message describing the error.
     * Base behavior is to return the `Throwable.msg` field.
     * Override to return some other error message.
     *
     * Returns:
     *  Error message
     */
    @__future const(char)[] message() const
    {
        return this.msg;
    }
}


/**
 * The base class of all errors that are safe to catch and handle.
 *
 * In principle, only thrown objects derived from this class are safe to catch
 * inside a $(D catch) block. Thrown objects not derived from Exception
 * represent runtime errors that should not be caught, as certain runtime
 * guarantees may not hold, making it unsafe to continue program execution.
 */
class Exception : Throwable
{

    /**
     * Creates a new instance of Exception. The nextInChain parameter is used
     * internally and should always be $(D null) when passed by user code.
     * This constructor does not automatically throw the newly-created
     * Exception; the $(D throw) statement should be used for that purpose.
     */
    @nogc @safe pure nothrow this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable nextInChain = null)
    {
        super(msg, file, line, nextInChain);
    }

    @nogc @safe pure nothrow this(string msg, Throwable nextInChain, string file = __FILE__, size_t line = __LINE__)
    {
        super(msg, file, line, nextInChain);
    }
}

}


// `lhs == rhs` lowers to `__equals(lhs, rhs)` for dynamic arrays
bool __equals(T1, T2)(T1[] lhs, T2[] rhs)
{
    import mar.traits : Unqual;
    alias U1 = Unqual!T1;
    alias U2 = Unqual!T2;

    static @trusted ref R at(R)(R[] r, size_t i) { return r.ptr[i]; }
    static @trusted R trustedCast(R, S)(S[] r) { return cast(R) r; }

    if (lhs.length != rhs.length)
        return false;

    if (lhs.length == 0 && rhs.length == 0)
        return true;

    static if (is(U1 == void) && is(U2 == void))
    {
        return __equals(trustedCast!(ubyte[])(lhs), trustedCast!(ubyte[])(rhs));
    }
    else static if (is(U1 == void))
    {
        return __equals(trustedCast!(ubyte[])(lhs), rhs);
    }
    else static if (is(U2 == void))
    {
        return __equals(lhs, trustedCast!(ubyte[])(rhs));
    }
    else static if (!is(U1 == U2))
    {
        // This should replace src/object.d _ArrayEq which
        // compares arrays of different types such as long & int,
        // char & wchar.
        // Compiler lowers to __ArrayEq in dmd/src/opover.d
        foreach (const u; 0 .. lhs.length)
        {
            if (at(lhs, u) != at(rhs, u))
                return false;
        }
        return true;
    }
    else static if (__traits(isIntegral, U1))
    {
        if (!__ctfe)
        {
            import mar.array : aequals;
            return () @trusted {
                return aequals(lhs.ptr[0 .. lhs.length * U1.sizeof], rhs.ptr);
            }();
        }
        else
        {
            foreach (const u; 0 .. lhs.length)
            {
                if (at(lhs, u) != at(rhs, u))
                    return false;
            }
            return true;
        }
    }
    else
    {
        foreach (const u; 0 .. lhs.length)
        {
            static if (__traits(compiles, __equals(at(lhs, u), at(rhs, u))))
            {
                if (!__equals(at(lhs, u), at(rhs, u)))
                    return false;
            }
            else static if (__traits(isFloating, U1))
            {
                if (at(lhs, u) != at(rhs, u))
                    return false;
            }
            else static if (is(U1 : Object) && is(U2 : Object))
            {
                if (!(cast(Object)at(lhs, u) is cast(Object)at(rhs, u)
                    || at(lhs, u) && (cast(Object)at(lhs, u)).opEquals(cast(Object)at(rhs, u))))
                    return false;
            }
            else static if (__traits(hasMember, U1, "opEquals"))
            {
                if (!at(lhs, u).opEquals(at(rhs, u)))
                    return false;
            }
            else static if (is(U1 == delegate))
            {
                if (at(lhs, u) != at(rhs, u))
                    return false;
            }
            else static if (is(U1 == U11*, U11))
            {
                if (at(lhs, u) != at(rhs, u))
                    return false;
            }
            else static if (__traits(isAssociativeArray, U1))
            {
                if (at(lhs, u) != at(rhs, u))
                    return false;
            }
            else
            {
                if (at(lhs, u).tupleof != at(rhs, u).tupleof)
                    return false;
            }
        }

        return true;
    }
}

// Compiler lowers final switch default case to this (which is a runtime error)
// Old implementation is in core/exception.d
void __switch_error()(string file = __FILE__, size_t line = __LINE__)
{
    //import core.exception : __switch_errorT;
    //__switch_errorT(file, line);
    assert(0, "switch error!");
}


version (D_BetterC) { } else
{


/**
 * Array of pairs giving the offset and type information for each
 * member in an aggregate.
 */
struct OffsetTypeInfo
{
    size_t   offset;    /// Offset of member from start of object
    TypeInfo ti;        /// TypeInfo for this member
}


class TypeInfo
{
    /*override*/ string toString() const pure @safe nothrow
    {
        return typeid(this).name;
    }

    override size_t toHash() @trusted const nothrow
    {
        /*
        import core.internal.traits : externDFunc;
        alias hashOf = externDFunc!("rt.util.hash.hashOf",
                                    size_t function(const(void)[], size_t) @trusted pure nothrow @nogc);
        return hashOf(this.toString(), 0);
        */
        assert(0, "TypeInfo.toHash not implemented");
    }

    /*override*/ int opCmp(Object o)
    {
        //import core.internal.string : dstrcmp;
        import mar.array : aequals;

        if (this is o)
            return 0;
        TypeInfo ti = cast(TypeInfo)o;
        if (ti is null)
            return 1;
        return aequals(this.toString(), ti.toString());
    }

    override bool opEquals(Object o)
    {
        /* TypeInfo instances are singletons, but duplicates can exist
         * across DLL's. Therefore, comparing for a name match is
         * sufficient.
         */
        if (this is o)
            return true;
        auto ti = cast(const TypeInfo)o;
        return ti && this.toString() == ti.toString();
    }

    /**
     * Computes a hash of the instance of a type.
     * Params:
     *    p = pointer to start of instance of the type
     * Returns:
     *    the hash
     * Bugs:
     *    fix https://issues.dlang.org/show_bug.cgi?id=12516 e.g. by changing this to a truly safe interface.
     */
    size_t getHash(scope const void* p) @trusted nothrow const { return cast(size_t)p; }

    /// Compares two instances for equality.
    bool equals(in void* p1, in void* p2) const { return p1 == p2; }

    /// Compares two instances for &lt;, ==, or &gt;.
    int compare(in void* p1, in void* p2) const { return _xopCmp(p1, p2); }

    /// Returns size of the type.
    @property size_t tsize() nothrow pure const @safe @nogc { return 0; }

    /// Swaps two instances of the type.
    void swap(void* p1, void* p2) const
    {
        immutable size_t n = tsize;
        for (size_t i = 0; i < n; i++)
        {
            byte t = (cast(byte *)p1)[i];
            (cast(byte*)p1)[i] = (cast(byte*)p2)[i];
            (cast(byte*)p2)[i] = t;
        }
    }

    /** Get TypeInfo for 'next' type, as defined by what kind of type this is,
    null if none. */
    @property inout(TypeInfo) next() nothrow pure inout @nogc { return null; }

    /**
     * Return default initializer.  If the type should be initialized to all
     * zeros, an array with a null ptr and a length equal to the type size will
     * be returned. For static arrays, this returns the default initializer for
     * a single element of the array, use `tsize` to get the correct size.
     */
    abstract const(void)[] initializer() nothrow pure const @safe @nogc;

    /** Get flags for type: 1 means GC should scan for pointers,
    2 means arg of this type is passed in XMM register */
    @property uint flags() nothrow pure const @safe @nogc { return 0; }

    /// Get type information on the contents of the type; null if not available
    const(OffsetTypeInfo)[] offTi() const { return null; }
    /// Run the destructor on the object and all its sub-objects
    void destroy(void* p) const {}
    /// Run the postblit on the object and all its sub-objects
    void postblit(void* p) const {}


    /// Return alignment of type
    @property size_t talign() nothrow pure const @safe @nogc { return tsize; }

    /** Return internal info on arguments fitting into 8byte.
     * See X86-64 ABI 3.2.3
     */
    version (X86_64) int argTypes(out TypeInfo arg1, out TypeInfo arg2) @safe nothrow
    {
        arg1 = this;
        return 0;
    }

    /** Return info used by the garbage collector to do precise collection.
     */
    @property immutable(void)* rtInfo() nothrow pure const @safe @nogc { return null; }
}

bool _xopEquals(in void*, in void*) { throw new Exception("TypeInfo.equals not implemented"); }
bool _xopCmp(in void*, in void*) { throw new Exception("TypeInfo.compare is not implemented"); }

class TypeInfo_Struct : TypeInfo
{
    override string toString() const { return name; }

    override bool opEquals(Object o)
    {
        if (this is o)
            return true;
        auto s = cast(const TypeInfo_Struct)o;
        return s && this.name == s.name &&
                    this.initializer().length == s.initializer().length;
    }

    override size_t getHash(scope const void* p) @trusted pure nothrow const
    {
        assert(p);
        if (xtoHash)
        {
            return (*xtoHash)(p);
        }
        else
        {
            import core.internal.traits : externDFunc;
            alias hashOf = externDFunc!("rt.util.hash.hashOf",
                                        size_t function(const(void)[], size_t) @trusted pure nothrow @nogc);
            return hashOf(p[0 .. initializer().length], 0);
        }
    }

    override bool equals(in void* p1, in void* p2) @trusted pure nothrow const
    {
        import core.stdc.string : memcmp;

        if (!p1 || !p2)
            return false;
        else if (xopEquals)
            return (*xopEquals)(p1, p2);
        else if (p1 == p2)
            return true;
        else
            // BUG: relies on the GC not moving objects
            return memcmp(p1, p2, initializer().length) == 0;
    }

    override int compare(in void* p1, in void* p2) @trusted pure nothrow const
    {
        import core.stdc.string : memcmp;

        // Regard null references as always being "less than"
        if (p1 != p2)
        {
            if (p1)
            {
                if (!p2)
                    return true;
                else if (xopCmp)
                    return (*xopCmp)(p2, p1);
                else
                    // BUG: relies on the GC not moving objects
                    return memcmp(p1, p2, initializer().length);
            }
            else
                return -1;
        }
        return 0;
    }

    override @property size_t tsize() nothrow pure const
    {
        return initializer().length;
    }

    override const(void)[] initializer() nothrow pure const @safe
    {
        return m_init;
    }

    override @property uint flags() nothrow pure const { return m_flags; }

    override @property size_t talign() nothrow pure const { return m_align; }

    final override void destroy(void* p) const
    {
        if (xdtor)
        {
            if (m_flags & StructFlags.isDynamicType)
                (*xdtorti)(p, this);
            else
                (*xdtor)(p);
        }
    }

    override void postblit(void* p) const
    {
        if (xpostblit)
            (*xpostblit)(p);
    }

    string name;
    void[] m_init;      // initializer; m_init.ptr == null if 0 initialize

  @safe pure nothrow
  {
    size_t   function(in void*)           xtoHash;
    bool     function(in void*, in void*) xopEquals;
    int      function(in void*, in void*) xopCmp;
    string   function(in void*)           xtoString;

    enum StructFlags : uint
    {
        hasPointers = 0x1,
        isDynamicType = 0x2, // built at runtime, needs type info in xdtor
    }
    StructFlags m_flags;
  }
    union
    {
        void function(void*)                xdtor;
        void function(void*, const TypeInfo_Struct ti) xdtorti;
    }
    void function(void*)                    xpostblit;

    uint m_align;

    override @property immutable(void)* rtInfo() const { return m_RTInfo; }

    version (X86_64)
    {
        override int argTypes(out TypeInfo arg1, out TypeInfo arg2)
        {
            arg1 = m_arg1;
            arg2 = m_arg2;
            return 0;
        }
        TypeInfo m_arg1;
        TypeInfo m_arg2;
    }
    immutable(void)* m_RTInfo;                // data for precise GC
}

/**
 * Information about an interface.
 * When an object is accessed via an interface, an Interface* appears as the
 * first entry in its vtbl.
 */
struct Interface
{
    TypeInfo_Class   classinfo;  /// .classinfo for this interface (not for containing class)
    void*[]     vtbl;
    size_t      offset;     /// offset to Interface 'this' from Object 'this'
}

/**
 * Runtime type information about a class.
 * Can be retrieved from an object instance by using the
 * $(DDSUBLINK spec/property,classinfo, .classinfo) property.
 */
class TypeInfo_Class : TypeInfo
{
    override string toString() const { return info.name; }

    override bool opEquals(Object o)
    {
        if (this is o)
            return true;
        auto c = cast(const TypeInfo_Class)o;
        return c && this.info.name == c.info.name;
    }

    override size_t getHash(scope const void* p) @trusted const
    {
        auto o = *cast(Object*)p;
        return o ? o.toHash() : 0;
    }

    override bool equals(in void* p1, in void* p2) const
    {
        Object o1 = *cast(Object*)p1;
        Object o2 = *cast(Object*)p2;

        return (o1 is o2) || (o1 && o1.opEquals(o2));
    }

    override int compare(in void* p1, in void* p2) const
    {
        Object o1 = *cast(Object*)p1;
        Object o2 = *cast(Object*)p2;
        int c = 0;

        // Regard null references as always being "less than"
        if (o1 !is o2)
        {
            if (o1)
            {
                if (!o2)
                    c = 1;
                else
                    c = o1.opCmp(o2);
            }
            else
                c = -1;
        }
        return c;
    }

    override @property size_t tsize() nothrow pure const
    {
        return Object.sizeof;
    }

    override const(void)[] initializer() nothrow pure const @safe
    {
        return m_init;
    }

    override @property uint flags() nothrow pure const { return 1; }

    override @property const(OffsetTypeInfo)[] offTi() nothrow pure const
    {
        return m_offTi;
    }

    @property auto info() @safe nothrow pure const { return this; }
    @property auto typeinfo() @safe nothrow pure const { return this; }

    byte[]      m_init;         /** class static initializer
                                 * (init.length gives size in bytes of class)
                                 */
    string      name;           /// class name
    void*[]     vtbl;           /// virtual function pointer table
    Interface[] interfaces;     /// interfaces this class implements
    TypeInfo_Class   base;           /// base class
    void*       destructor;
    void function(Object) classInvariant;
    enum ClassFlags : uint
    {
        isCOMclass = 0x1,
        noPointers = 0x2,
        hasOffTi = 0x4,
        hasCtor = 0x8,
        hasGetMembers = 0x10,
        hasTypeInfo = 0x20,
        isAbstract = 0x40,
        isCPPclass = 0x80,
        hasDtor = 0x100,
    }
    ClassFlags m_flags;
    void*       deallocator;
    OffsetTypeInfo[] m_offTi;
    void function(Object) defaultConstructor;   // default Constructor

    immutable(void)* m_RTInfo;        // data for precise GC
    override @property immutable(void)* rtInfo() const { return m_RTInfo; }

    /**
     * Search all modules for TypeInfo_Class corresponding to classname.
     * Returns: null if not found
     */
    static const(TypeInfo_Class) find(in char[] classname)
    {
        foreach (m; ModuleInfo)
        {
            if (m)
            {
                //writefln("module %s, %d", m.name, m.localClasses.length);
                foreach (c; m.localClasses)
                {
                    if (c is null)
                        continue;
                    //writefln("\tclass %s", c.name);
                    if (c.name == classname)
                        return c;
                }
            }
        }
        return null;
    }

    /**
     * Create instance of Object represented by 'this'.
     */
    Object create() const
    {
        if (m_flags & 8 && !defaultConstructor)
            return null;
        if (m_flags & 64) // abstract
            return null;
        Object o = _d_newclass(this);
        if (m_flags & 8 && defaultConstructor)
        {
            defaultConstructor(o);
        }
        return o;
    }
}

class TypeInfo_Const : TypeInfo
{
    override string toString() const
    {
        return cast(string) ("const(" ~ base.toString() ~ ")");
    }

    //override bool opEquals(Object o) { return base.opEquals(o); }
    override bool opEquals(Object o)
    {
        if (this is o)
            return true;

        if (typeid(this) != typeid(o))
            return false;

        auto t = cast(TypeInfo_Const)o;
        return base.opEquals(t.base);
    }

    override size_t getHash(scope const void *p) const { return base.getHash(p); }
    override bool equals(in void *p1, in void *p2) const { return base.equals(p1, p2); }
    override int compare(in void *p1, in void *p2) const { return base.compare(p1, p2); }
    override @property size_t tsize() nothrow pure const { return base.tsize; }
    override void swap(void *p1, void *p2) const { return base.swap(p1, p2); }

    override @property inout(TypeInfo) next() nothrow pure inout { return base.next; }
    override @property uint flags() nothrow pure const { return base.flags; }

    override const(void)[] initializer() nothrow pure const
    {
        return base.initializer();
    }

    override @property size_t talign() nothrow pure const { return base.talign; }

    version (X86_64) override int argTypes(out TypeInfo arg1, out TypeInfo arg2)
    {
        return base.argTypes(arg1, arg2);
    }

    TypeInfo base;
}

} // end of version (D_BetterC)

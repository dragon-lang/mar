module mar.passfail;

// Example:
// ---
// return boolstatus.pass;
// return boolstatus.fail;
// if(status.failed) ...
// if(status.passed) ...
struct passfail
{
    private bool _passed;
    @property static passfail pass() pure nothrow @nogc { return passfail(true); }
    @property static passfail fail() pure nothrow @nogc { return passfail(false); }
    @disable this();
    private this(bool _passed) pure nothrow @nogc { this._passed = _passed; }
    /*
    pragma(inline) @property bool asBool() { return _passed; }
    alias asBool this;
    */
    auto print(P)(P printer) { return printer.put(_passed ? "pass" : "fail"); }

    @property auto passed() const pure nothrow @nogc { return _passed; }
    @property auto failed() const pure nothrow @nogc { return !_passed; }

    passfail opBinary(string op)(const(passfail) right) const pure nothrow @nogc
    {
        mixin("return passfail(this._passed " ~ op ~ " right._passed);");
    }
    passfail opBinary(string op)(const(bool) right) const pure nothrow @nogc
    {
        mixin("return passfail(this._passed " ~ op ~ " right);");
    }
    passfail opBinaryRight(string op)(const(bool) left) const pure nothrow @nogc
    {
        mixin("return passfail(left " ~ op ~ " this._passed);");
    }
}

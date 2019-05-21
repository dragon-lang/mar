module mar.cannotfail;

struct CannotFail
{
    enum failed = false;
    //static bool failed() { pragma(inline, true); return false; }
}

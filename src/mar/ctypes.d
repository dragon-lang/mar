module mar.ctypes;

version (linux)
{
    public import mar.linux.cthunk;
}
else version (Windows)
{
    alias off_t = uint;
}
else static assert(0, "unsupported platform");
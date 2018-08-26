module mar.file;

version (linux)
{
    public import mar.linux.file;
    //static import mar.linux.file;
    //alias FileD = mar.linux.file.FileD;
}
else version (Windows)
{
    alias FileD = uint;
    auto getFileSize(T)(T filename)
    {
        assert(0, "getFileSize not implemented on Windows");
        return ulong.min;
    }
}
else static assert(0, __MODULE__ ~ " is not supported on this platform");

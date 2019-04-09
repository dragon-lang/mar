module mar.mmap;

version (linux)
{
    public import mar.linux.mmap;
}
else version (Windows)
{
    public import mar.windows.mmap;
}
else static assert(0, "unsupported platform");
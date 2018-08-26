module mar.filesys;

version (linux)
{
    public import mar.linux.filesys;
}
else version (Windows)
{
}
else static assert(0, __MODULE__ ~ " is not supported on this platform");

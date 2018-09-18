module mar.file.perm;

version (linux)
{
    public import mar.linux.file.perm;
}
else version (Windows)
{
    public import mar.windows.file.perm;
}
else static assert(0, __MODULE__ ~ " is not supported on this platform");

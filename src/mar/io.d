module mar.io;

version (linux)
{
    public import mar.linux.io;
}
else version (Windows)
{
    public import mar.windows.io;
}
else static assert(0, __MODULE__ ~ " is not supported on this platform");

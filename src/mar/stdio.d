module mar.stdio;

version (linux)
{
    public import mar.linux.stdio;
}
else version (Windows)
{
    public import mar.windows.stdio;
}
else static assert(0, __MODULE__ ~ " is not supported on this platform");

module mar.file;

import mar.c : cstring;

version (linux)
{
    public import mar.linux.file;
}
else version (Windows)
{
    public import mar.windows.file;
}
else static assert(0, __MODULE__ ~ " is not supported on this platform");

/**
Platform independent open file configuration
*/
struct OpenFileConfig
{
    version (linux)
    {
        import mar.linux.file : OpenFlags;
        OpenFlags getPosixFlags() const
        {
            assert(0, "not impl");
        }
        uint getPosixMode() const
        {
            assert(0, "not impl");
        }
    }
}

/**
Platform independent open file function
*/
FileD openFile(cstring filename, OpenFileConfig config)
{
    version (linux)
    {
        return open(filename, config.getPosixFlags, config.getPosixMode);
    }
    else version (Windows)
    {
        assert(0, "not impl");
    }
    else static assert(0, __FUNCTION__ ~ " is not supported on this platform");
}
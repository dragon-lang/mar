module mar.filesys;

version (linux)
{
    public import mar.linux.filesys;
    static import mar.linux.filesys;
}
else version (Windows)
{
    public import mar.windows.filesys;
    static import mar.windows.filesys;
}
else static assert(0, __MODULE__ ~ " is not supported on this platform");

import mar.c : cstring;

struct MkdirConfig
{
    version (linux)
    {
        import mar.linux.cthunk : mode_t;

        private mode_t mode;
        void setPosixMode(mode_t mode)
        {
            this.mode = mode;
        }
        mode_t getPosixMode() const
        {
            return mode;
        }
    }
}
auto mkdir(cstring pathname, MkdirConfig config)
{
    version (linux)
    {
        return mar.linux.filesys.mkdir(pathname, config.getPosixMode);
    }
    else version (Windows)
    {
        import mar.windows.kernel32 : CreateDirectoryA;
        return CreateDirectoryA(pathname, null);
    }
    else static assert(0, __FUNCTION__ ~ " is not supported on this platform");
}

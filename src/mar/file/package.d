module mar.file;

import mar.c : cstring;

version (linux)
{
    public import mar.linux.file;
}
else version (Windows)
{
    public import mar.windows.file;
    import mar.windows.kernel32 : CloseHandle;
    // dummy mode flags for windows
    enum ModeFlags
    {
        execOther  = 0,
        writeOther = 0,
        readOther  = 0,
        execGroup  = 0,
        writeGroup = 0,
        readGroup  = 0,
        execUser   = 0,
        writeUser  = 0,
        readUser   = 0,
        isFifo     = 0,
        isCharDev  = 0,
        isDir      = 0,
        isRegFile  = 0,
    }
}
else static assert(0, __MODULE__ ~ " is not supported on this platform");

static struct ModeSet
{
    enum rwxOther = ModeFlags.readOther | ModeFlags.writeOther | ModeFlags.execOther;
    enum rwxGroup = ModeFlags.readGroup | ModeFlags.writeGroup | ModeFlags.execGroup;
    enum rwxUser  = ModeFlags.readUser  | ModeFlags.writeUser  | ModeFlags.execUser;

    enum rwOther = ModeFlags.readOther | ModeFlags.writeOther;
    enum rwGroup = ModeFlags.readGroup | ModeFlags.writeGroup;
    enum rwUser  = ModeFlags.readUser  | ModeFlags.writeUser ;
}

/**
Platform independent open file configuration
*/
struct OpenFileOpt
{
    version (linux)
    {
        import mar.linux.cthunk : mode_t;
        import mar.linux.file.perm : ModeFlags;

        private OpenFlags flags;
        private mode_t _mode;
    }
    else version (Windows)
    {
        private OpenAccess access;
        private FileShareMode shareMode;
        private FileCreateMode createMode;
    }

    this(OpenAccess access)
    {
        version (linux)
        {
            this.flags = OpenFlags(access);
        }
        else version (Windows)
        {
            this.access = access;
            this.createMode = FileCreateMode.openExisting;
        }
        else static assert(0, __MODULE__ ~ " is not supported on this platform");
    }

    /// create a new file if it doesn't exist, otherwise, fail
    auto ref createOnly()
    {
        pragma(inline, true);
        version (linux)
            this.flags.val |= OpenCreateFlags.creat | OpenCreateFlags.excl;
        else version (Windows)
            this.createMode = FileCreateMode.createNew;
        return this;
    }
    // create a new file, truncate it if it already exists
    auto ref createOrTruncate()
    {
        pragma(inline, true);
        version (linux)
            this.flags.val |= OpenCreateFlags.creat | OpenCreateFlags.trunc;
        else version (Windows)
            this.createMode = FileCreateMode.createAlways;
        return this;
    }
    // create a new file or open the existing file
    auto ref createOrOpen()
    {
        pragma(inline, true);
        version (linux)
            this.flags.val |= OpenCreateFlags.creat;
        else version (Windows)
            this.createMode = FileCreateMode.openExisting;
        return this;
    }

    auto ref shareDelete()
    {
        pragma(inline, true);
        version (Windows)
            shareMode |= FileShareMode.delete_;
        return this;
    }
    auto ref shareRead()
    {
        pragma(inline, true);
        version (Windows)
            shareMode |= FileShareMode.read;
        return this;
    }
    auto ref shareWrite()
    {
        pragma(inline, true);
        version (Windows)
            shareMode |= FileShareMode.write;
        return this;
    }

    auto ref mode(ModeFlags modeFlags)
    {
        pragma(inline, true);
        version (linux)
            this._mode = modeFlags;
        // ignore on windows
        return this;
    }
}

/**
Platform independent open file function
*/
FileD tryOpenFile(cstring filename, OpenFileOpt opt)
{
    version (linux)
    {
        return open(filename, opt.flags, opt._mode);
    }
    else version (Windows)
    {
        import mar.windows.types : Handle;
        import mar.windows.kernel32 : CreateFileA;

        return CreateFileA(filename, opt.access, opt.shareMode, null, opt.createMode, 0, Handle.nullValue);
    }
    else static assert(0, __FUNCTION__ ~ " is not supported on this platform");
}

/+
version (linux)
    alias closeFile = close;
else version (Windows)

{
    alias closeFile = CloseHandle;
    auto closeFile(FileD)
}
+/


/*
FileD createFile(cstring filename)
{

}
*/
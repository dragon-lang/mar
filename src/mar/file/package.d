module mar.file;

import mar.c : cstring;
import mar.expect;

version (linux)
{
    public import mar.linux.file;
}
else version (Windows)
{
    public import mar.windows.file;
    import mar.windows : Handle;
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
version (Windows)
{
    // Use contiguous values
    enum MMapAccess : uint
    {
        readOnly      = 0,
        readWrite     = 1,
        readWriteCopy = 2,
        readExecute   = 3,
        /*

        readOnly      = 2, // PAGE_READONLY
        readWrite     = 4, // PAGE_READWRITE
        readWriteCopy = 8, // PAGE_WRITECOPY
        //readExecute
        */
    }
    immutable uint[MMapAccess.max+1] mmapAccessToFileMapping = [
        MMapAccess.readOnly      : 2, // PAGE_READONLY
        MMapAccess.readWrite     : 4, // PAGE_READWRITE
        MMapAccess.readWriteCopy : 8, // PAGE_WRITECOPY
        MMapAccess.readExecute   : 32, // PAGE_EXECUTE_READ
    ];
    private enum FILE_MAP_COPY    = 0x01;
    private enum FILE_MAP_WRITE   = 0x02;
    private enum FILE_MAP_READ    = 0x04;
    private enum FILE_MAP_EXECUTE = 0x20;
    immutable uint[MMapAccess.max+1] mmapAccessToMapViewOfFile = [
        MMapAccess.readOnly      : FILE_MAP_READ,
        MMapAccess.readWrite     : FILE_MAP_WRITE,
        MMapAccess.readWriteCopy : FILE_MAP_COPY,
        MMapAccess.readExecute   : FILE_MAP_EXECUTE,
    ];
}
else
{
    enum MMapAccess
    {
        // placeholders
        readOnly = 0,
        readWrite = 0,
        readWriteCopy = 0,
    }
}


version (Windows)
{
    struct MappedFile
    {
        private Handle fileMapping;
        ubyte[] mem;
        mixin ExpectMixin!("CloseResult", void,
            ErrorCase!("unmapViewOfFileFailed", "UnmapViewOfFile failed, error=%", uint),
            ErrorCase!("closeFileMappingFailed", "CloseHandle on file mapping failed, error=%", uint));
        CloseResult close()
        {
            import mar.windows.kernel32 : GetLastError, UnmapViewOfFile, CloseHandle;
            if (UnmapViewOfFile(mem.ptr).failed)
                return CloseResult.unmapViewOfFileFailed(GetLastError());
            if (CloseHandle(fileMapping).failed)
                return CloseResult.closeFileMappingFailed(GetLastError());
            return CloseResult.success();
        }
    }
    mixin ExpectMixin!("MMapResult", MappedFile,
        ErrorCase!("getFileSizeFailed", "GetFileSize failed, error=%", uint),
        ErrorCase!("fileTooBig", "The file is too big to be mapped in one buffer"),
        ErrorCase!("createFileMappingFailed", "CreateFileMapping failed, error=%", uint),
        ErrorCase!("mapViewOfFileFailed", "MapViewOfFile failed, error=%", uint));
    // TODO: move this function somewhere else
    uint high32(T)(T value)
    {
        pragma(inline, true);
        static if (T.sizeof >=8)
            return cast(uint)(value >> 32);
        return 0;
    }
}
auto mmap(FileD file, MMapAccess access, ulong offset, size_t size)
{
    version (Windows)
    {
        import mar.windows : INVALID_FILE_SIZE;
        import mar.windows.kernel32 : GetLastError,
            GetFileSize, CreateFileMappingA, MapViewOfFile;

        if (size == 0)
        {
            uint high = 0;
            auto low = GetFileSize(file.asHandle, &high);
            if (low == INVALID_FILE_SIZE)
                return MMapResult.getFileSizeFailed(GetLastError());
            ulong total = ((cast(ulong)high) << 32) | cast(ulong)low;
            static if (ulong.sizeof > size_t.sizeof)
            {
                if (total > size_t.max)
                    return MMapResult.fileTooBig();
            }
            size = cast(size_t)total;
        }

        auto fileMapping = CreateFileMappingA(file.asHandle, null, mmapAccessToFileMapping[access],
            high32(size), cast(uint)size, cstring.nullValue);
        if (fileMapping.isNull)
            return MMapResult.createFileMappingFailed(GetLastError());
        auto ptr = MapViewOfFile(fileMapping, mmapAccessToMapViewOfFile[access],
            high32(offset), cast(uint)offset, size);
        if (ptr is null)
            return MMapResult.mapViewOfFileFailed(GetLastError());
        return MMapResult.success(MappedFile(fileMapping, (cast(ubyte*)ptr)[0 .. size]));
    }
    else
    {
        assert(0, "mmap not impl here");
    }
}
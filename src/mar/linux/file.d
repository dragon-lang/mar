module mar.linux.file;

import mar.typecons : ValueOrErrorCode;
import mar.wrap;
import mar.c;
import mar.linux.cthunk;
import mar.linux.syscall;

alias open = sys_open;
alias openat = sys_openat;
alias close = sys_close;
alias read = sys_read;
alias write = sys_write;
alias lseek = sys_lseek;
alias access = sys_access;
alias dup2 = sys_dup2;
alias fstatat = sys_newfstatat;
alias stat = sys_stat;
alias fstat = sys_fstat;
alias lstat = sys_lstat;

struct FileD
{
    private ptrdiff_t _value = -1;
    this(typeof(_value) value) pure nothrow @nogc
    {
        this._value = value;
    }
    bool isValid() const { return _value >= 0; }
    pragma(inline) auto numval() const { return _value; }
    void setInvalid() { this._value = -1; }
    mixin WrapperFor!"_value";
    mixin WrapOpCast;

    void toString(Printer)(Printer printer) const
    {
        import mar.format : printDecimal;
        printDecimal(printer, _value);
    }

    /*
    A convenience function, however, it bloats the API by creating multiple ways to
    do the same thing (i.e. print(stdout, ...) or stdout.print(...)).  Leaving this out
    for now.

    pragma(inline)
    void print(T...)(T args)
    {
        filePrint(this, args);
    }
    */
}

pragma(inline) const(FileD) stdin() pure nothrow @nogc { return FileD(0); }
pragma(inline) const(FileD) stdout() pure nothrow @nogc { return FileD(1); }
pragma(inline) const(FileD) stderr() pure nothrow @nogc { return FileD(2); }

pragma(inline)
auto write(T)(FileD fd, T[] buffer) if (T.sizeof == 1)
{
    return sys_write(fd, cast(const(void)*)buffer.ptr, buffer.length);
}

void print(T...)(FileD fd, T args)
{
    import mar.format : DefaultBufferedFilePrinterPolicy, BufferedFilePrinter, argsToPrinter;
    alias Printer = BufferedFilePrinter!DefaultBufferedFilePrinterPolicy;

    char[DefaultBufferedFilePrinterPolicy.bufferLength] buffer;
    auto printer = Printer(fd, buffer.ptr, 0);
    argsToPrinter(&printer, args);
    printer.flush();
}


pragma(inline)
auto read(T)(FileD fd, T[] buffer) if (T.sizeof == 1)
{
    return sys_read(fd, cast(void*)buffer.ptr, buffer.length);
}

enum OpenAccess : ubyte
{
    readOnly  = 0b00, // O_RDONLY
    writeOnly = 0b01, // O_WRONLY
    readWrite = 0b10, // O_RDWR
}
enum OpenCreateFlags : uint
{
    none         = 0,
    creat       = 0x00040, // O_CREAT
    excl        = 0x00080, // O_EXCL
    noCtty      = 0x00100, // O_NOCTTY
    trunc       = 0x00200, // O_TRUNC
    dir         = 0x10000, // O_DIRECTORY
    noFollow    = 0x20000, // O_NOFOLLOW
    closeOnExec = 0x80000, // O_CLOEXEC,
}
enum OpenStatusFlags : uint
{
    __,
}
struct OpenFlags
{
    uint value;
    mixin WrapperFor!"value";
    mixin WrapOpCast;

    this(OpenAccess access, OpenCreateFlags flags = OpenCreateFlags.none)
    {
        this.value = cast(uint)flags | cast(uint)access;
    }
}

pragma(inline) auto open(T)(T pathname, OpenFlags flags) if (!is(pathname : cstring))
{
    mixin tempCString!("pathnameCStr", "pathname");
    return sys_open(pathnameCStr, flags);
}

enum AccessMode
{
    exists = 0,
    exec   = 0b001,
    write  = 0b010,
    read   = 0b100,
}

enum ModeFlags : mode_t
{
    execOther  = 0b000_000_000_000_000_001,
    writeOther = 0b000_000_000_000_000_010,
    readOther  = 0b000_000_000_000_000_100,
    execGroup  = 0b000_000_000_000_001_000,
    writeGroup = 0b000_000_000_000_010_000,
    readGroup  = 0b000_000_000_000_100_000,
    execUser   = 0b000_000_000_001_000_000,
    writeUser  = 0b000_000_000_010_000_000,
    readUser   = 0b000_000_000_100_000_000,
    isFifo     = 0b000_001_000_000_000_000,
    isCharDev  = 0b000_010_000_000_000_000,
    isDir      = 0b000_100_000_000_000_000,
    isRegFile  = 0b001_000_000_000_000_000,
}

private enum ModeTypeMask = (
    ModeFlags.isFifo |
    ModeFlags.isCharDev |
    ModeFlags.isDir |
    ModeFlags.isRegFile);
private enum ModeTypeLink = ModeFlags.isCharDev | ModeFlags.isRegFile;
private enum ModeTypeDir  = ModeFlags.isDir;

pragma(inline)
bool isLink(const mode_t mode)
{
    return (mode & ModeTypeMask) == ModeTypeLink;
}
pragma(inline)
bool isDir(const mode_t mode)
{
    return (mode & ModeTypeMask) == ModeTypeDir;
}

enum SeekFrom
{
    start = 0,
    current = 1,
    end = 2,
}

/*
#define S_ISLNK(m)    (((m) & S_IFMT) == S_IFLNK)
#define S_ISREG(m)    (((m) & S_IFMT) == S_IFREG)
#define S_ISDIR(m)    (((m) & S_IFMT) == S_IFDIR)
#define S_ISCHR(m)    (((m) & S_IFMT) == S_IFCHR)
#define S_ISBLK(m)    (((m) & S_IFMT) == S_IFBLK)
#define S_ISFIFO(m)    (((m) & S_IFMT) == S_IFIFO)
#define S_ISSOCK(m)    (((m) & S_IFMT) == S_IFSOCK)
*/

auto formatMode(mode_t mode)
{
    static struct Formatter
    {
        mode_t mode;
        void toString(Printer)(Printer printer) const
        {
            auto buffer = printer.getTempBuffer!10;
            scope (exit) printer.commitBuffer(buffer.commitValue);

            if (mode.isLink)
                buffer.putc('l');
            else if (mode.isDir)
                buffer.putc('d');
            else
                buffer.putc('-');
            buffer.putc((mode & ModeFlags.readUser)  ? 'r' : '-');
            buffer.putc((mode & ModeFlags.writeUser) ? 'w' : '-');
            buffer.putc((mode & ModeFlags.execUser)  ? 'x' : '-');
            buffer.putc((mode & ModeFlags.readGroup)  ? 'r' : '-');
            buffer.putc((mode & ModeFlags.writeGroup) ? 'w' : '-');
            buffer.putc((mode & ModeFlags.execGroup)  ? 'x' : '-');
            buffer.putc((mode & ModeFlags.readOther)  ? 'r' : '-');
            buffer.putc((mode & ModeFlags.writeOther) ? 'w' : '-');
            buffer.putc((mode & ModeFlags.execOther)  ? 'x' : '-');
        }
    }
    return Formatter(mode);
}

enum S_IXOTH = ModeFlags.execOther;
enum S_IWOTH = ModeFlags.writeOther;
enum S_IROTH = ModeFlags.readOther;
enum S_IRWXO = ModeFlags.readOther | ModeFlags.writeOther | ModeFlags.execOther;

enum S_IXGRP = ModeFlags.execGroup;
enum S_IWGRP = ModeFlags.writeGroup;
enum S_IRGRP = ModeFlags.readGroup;
enum S_IRWXG = ModeFlags.readGroup | ModeFlags.writeGroup | ModeFlags.execGroup;

enum S_IXUSR = ModeFlags.execUser;
enum S_IWUSR = ModeFlags.writeUser;
enum S_IRUSR = ModeFlags.readUser;
enum S_IRWXU = ModeFlags.readUser | ModeFlags.writeUser | ModeFlags.execUser;

struct stat_t {
    union
    {
        struct
        {
            dev_t     st_dev;     // ID of device containing file
            ino_t     st_ino;     // inode number
            nlink_t   st_nlink;   // number of hard links
            mode_t    st_mode;    // protection
            uid_t     st_uid;     // user ID of owner
            gid_t     st_gid;     // group ID of owner
            dev_t     st_rdev;    // device ID (if special file)
            off_t     st_size;    // total size, in bytes
            blksize_t st_blksize; // blocksize for file system I/O
            blkcnt_t  st_blocks;  // number of 512B blocks allocated
            time_t    st_atime;   // time of last access
            time_t    st_mtime;   // time of last modification
            time_t    st_ctime;   // time of last status change
        }
        ubyte[sizeofStructStat] _reserved;
    }
};

enum AT_SYMLINK_NOFOLLOW = 0x100; // Do not follow symbolic links


//pragma(inline)
//ValueOrErrorCode!(size_t, SyscallResult) readlinkat(FileD dirFd, cstring pathname, char[] buffer)
pragma(inline)
auto readlinkat(FileD dirFd, cstring pathname, char[] buffer)
{
    return sys_readlinkat(dirFd, pathname, buffer.ptr, buffer.length);
    /*
    auto result = syscall(Syscall.readlinkat, dirFd, pathname, buffer.ptr, buffer.length);
    return (result > 0) ?
        ValueOrErrorCode!(size_t, SyscallResult)(result):
        ValueOrErrorCode!(size_t, SyscallResult).error(result);
        */
}

version (D_BetterC) { } else {

    class FileException : Exception
    {
    /*
        private bool nameIsArray;
        union
        {
            private const(char)[] nameArray;
            private cstring nameCString;
        }
        */
        this(string msg, string file = __FILE__,
            size_t line = cast(size_t)__LINE__)
        {
            super(msg, file, line);
        }
        this(const(char)[] name, string msg, string file = __FILE__,
            size_t line = cast(size_t)__LINE__)
        {
            super(msg, file, line);
            //this.nameIsArray = true;
            //this.nameArray = name;
        }
        this(cstring name, string msg, string file = __FILE__,
            size_t line = cast(size_t)__LINE__)
        {
            import mar.string : strlen;
            super(msg, file, line);
            //auto namelen = strlen(name);
            //this.nameIsArray = true;
            //this.nameArray = name.ptr[0 .. namelen].idup;
        }
    }
}

bool fileExists(cstring filename)
{
    // TODO: check if the error code is appropriate (file does not exist)
    return access(filename, AccessMode.exists).passed;
}

bool isDir(cstring path)
{
    stat_t status = void;
    auto result = sys_stat(path, &status);
    return result.passed && status.st_mode.isDir;
}

ValueOrErrorCode!(off_t, short) tryGetFileSize(cstring filename)
{
    stat_t status = void;
    auto result =  sys_stat(filename, &status);
    return result.passed ? typeof(return)(status.st_size) :
        typeof(return).error(cast(short)result.numval);

}
pragma(inline)
auto tryGetFileSize(T)(T filename)
{
    mixin tempCString!("filenameCStr", "filename");
    return tryGetFileSize(filenameCStr.str);
}

ValueOrErrorCode!(mode_t, short) tryGetFileMode(cstring filename)
{
    stat_t status = void;
    auto result =  sys_stat(filename, &status);
    return result.passed ? typeof(return)(status.st_mode) :
        typeof(return).error(cast(short)result.numval);
}

// TODO: move this somewhere
void unreportableError(string Ex, T)(T msg, string file = __FILE__, size_t line = cast(size_t)__LINE__)
{
    version (D_BetterC)
    {
        import mar.linux.process : exit;
        // write error to stderr
        write(stderr, "unreportable error: ");
        write(stderr, file);
        // todo: write the line number as well
        write(stderr, ": ");
        write(stderr, msg);
        write(stderr, "\n");
        exit(1);
    }
    else
    {
        mixin("throw new " ~ Ex ~ "(msg, file, line);");
    }
}

off_t getFileSize(cstring filename)
{
    auto result = tryGetFileSize(filename);
    if (result.failed)
        unreportableError!"FileException"("stat function failed");
    //if (result.failed) throw new FileException(filename, text(
    //    "stat function failed (file='", filename, " e=", result.errorCode));
    //if (result.failed) throw new FileException(filename, "stat failed");
    return result.val;
}
pragma(inline)
auto getFileSize(T)(T filename)
{
    mixin tempCString!("filenameCStr", "filename");
    return getFileSize(filenameCStr.str);
}

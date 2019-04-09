module mar.linux.file;

public import mar.linux.file.perm;

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
alias pipe = sys_pipe;
alias lseek = sys_lseek;
alias access = sys_access;
alias dup2 = sys_dup2;
alias fstatat = sys_newfstatat;
alias stat = sys_stat;
alias fstat = sys_fstat;
alias lstat = sys_lstat;

struct WriteResult
{
    ptrdiff_t _value;

    pragma(inline) bool failed() const { return _value != 0; }
    pragma(inline) bool passed() const { return _value == 0; }

    pragma(inline) size_t onFailWritten() const in { assert(_value != 0, "code bug"); } do
    { return (_value > 0) ? _value : 0; }

    pragma(inline) short errorCode() const in { assert(_value != 0, "code bug"); } do
    // TODO: replace -5 with -EIO
    { return (_value > 0) ? -5 : cast(short)_value; }
}
extern (C) WriteResult tryWrite(FileD handle, const(void)* ptr, size_t n)
{
    size_t initialSize = n;
    auto result = write(handle, ptr, n);
    return (result.val == n) ? WriteResult(0) : WriteResult(result.numval);
}

struct FileD
{
    private int _value = -1;
    this(typeof(_value) value) pure nothrow @nogc
    {
        this._value = value;
    }
    bool isValid() const { return _value >= 0; }
    pragma(inline) auto numval() const { return _value; }
    void setInvalid() { this._value = -1; }
    mixin WrapperFor!"_value";
    mixin WrapOpCast;

    auto print(P)(P printer) const
    {
        import mar.print : printDecimal;
        return printDecimal(printer, _value);
    }

    pragma(inline)
    WriteResult tryWrite(const(void)* ptr, size_t length) { return .tryWrite(this, ptr, length); }
    pragma(inline)
    WriteResult tryWrite(const(void)[] array) { return .tryWrite(this, array.ptr, array.length); }

    void write(T...)(T args) const
    {
        import mar.print : DefaultBufferedFilePrinterPolicy, BufferedFilePrinter, printArgs;
        alias Printer = BufferedFilePrinter!DefaultBufferedFilePrinterPolicy;

        char[DefaultBufferedFilePrinterPolicy.bufferLength] buffer;
        auto printer = Printer(this, buffer.ptr, 0);
        printArgs(&printer, args);
        printer.flush();
    }

    pragma(inline)
    void writeln(T...)(T args) const
    {
        write(args, '\n');
    }
}

pragma(inline)
auto write(T)(FileD fd, T[] buffer) if (T.sizeof == 1)
{
    return sys_write(fd, cast(const(void)*)buffer.ptr, buffer.length);
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

enum SeekFrom
{
    start = 0,
    current = 1,
    end = 2,
}

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
    return result.passed && mar.linux.file.perm.isDir(status.st_mode);
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


// TODO: move this somewhere else
void unreportableError(string Ex, T)(T msg, string file = __FILE__, size_t line = cast(size_t)__LINE__)
{
    version (D_BetterC)
    {
        version (NoExit)
            static assert(0, "unreportableError cannot be called with BetterC and version=NoExit");

        import mar.linux.process : exit;
        import mar.stdio;
        // write error to stderr
        stderr.writeln("unreportable error: ", file, ": ", msg);
        exit(1);
    }
    else
    {
        mixin("throw new " ~ Ex ~ "(msg, file, line);");
    }
}

mixin template GetFileSizeFuncs()
{
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
}

// TODO: support NoExit
version (NoExit)
{
    version (D_BetterC) { } else
    {
        mixin GetFileSizeFuncs;
    }
}
else
{
    mixin GetFileSizeFuncs;
}

struct PipeFds
{
    FileD read;
    FileD write;
}

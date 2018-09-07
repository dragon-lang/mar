/**
 NOTE: I add the "sys_" prefix to all these functions to distinguish them
       with the C versions.  This is especially important if this library
       is being linked alongside the standard C library so that these symbols
       do not clash.
*/
module mar.linux.syscall;

import mar.sentinel : SentinelPtr;
import mar.c : cstring;
import mar.linux.cthunk : kernel, mode_t, off_t, loff_t, gid_t, uid_t;
import mar.linux.file : FileD, stat_t, OpenFlags, AccessMode, SeekFrom;
import mar.linux.filesys : linux_dirent;
import mar.linux.signals : siginfo_t, sigaction_t;
import mar.linux.process : pid_t, idtype_t, rusage;
import mar.linux.capability : cap_user_header_t, cap_user_data_t;

// TODO: do I need this?
//version (Windows)
//    static assert(0, "module " ~ __MODULE__ ~ " is not supported on windows");

enum Syscall : size_t
{
    read = 0,
    write = 1,
    open = 2,
    close = 3,
    stat = 4,
    fstat = 5,
    lstat = 6,
    poll = 7,
    lseek = 8,
    mmap = 9,
    mprotect = 10,
    munmap = 11,
    brk = 12,
    rt_sigaction = 13,
    rt_sigprocmask = 14,
    rt_sigreturn = 15,
    ioctl = 16,
    pread64 = 17,
    pwrite64 = 18,
    readv = 19,
    writev = 20,
    access = 21,
    pipe = 22,
    select = 23,
    sched_yield = 24,
    mremap = 25,
    msync = 26,
    mincore = 27,
    madvise = 28,
    shmget = 29,
    shmat = 30,
    shmctl = 31,
    dup = 32,
    dup2 = 33,
    pause = 34,
    nanosleep = 35,
    getitimer = 36,
    alarm = 37,
    setitimer = 38,
    getpid = 39,
    sendfile = 40,
    socket = 41,
    // ...
    socketpair = 53,
    setsockopt = 54,
    getsockopt = 55,
    clone = 56,
    fork = 57,
    vfork = 58,
    execve = 59,
    exit = 60,
    // ...
    getdents = 78,
    getcwd = 79,
    chdir = 80,
    fchdir = 81,
    rename = 82,
    mkdir = 83,
    rmdir = 84,
    create = 85,
    link = 86,
    unlink = 87,
    symlink = 88,
    readlink = 89,
    chmod = 90,
    fchmod = 91,
    chown = 92,
    fchown = 93,
    lchown = 94,
    umask = 95,
    gettimeofday = 96,
    getrlimit = 97,
    getrusage = 98,
    sysinfo = 99,
    times = 100,
    ptrace = 101,
    getuid = 102,
    syslog = 103,
    getgid = 104,
    setuid = 105,
    setgid = 106,
    geteuid = 107,
    getegid = 108,
    setpgid = 109,
    getppid = 110,
    getpgrp = 111,
    setsid = 112,
    setreuid = 113,
    setregid = 114,
    getgroups = 115,
    setgroups = 116,
    setresuid = 117,
    getresuid = 118,
    setresgid = 119,
    getresgid = 120,
    getpgid = 121,
    setfsuid = 122,
    setfsgid = 123,
    getsid = 124,
    capget = 125,
    capset = 126,
    // ...
    chroot = 161,
    sync = 162,
    acct = 163,
    settimeofday = 164,
    mount = 165,
    umount2 = 166,
    swapon = 167,
    swapoff = 168,
    reboot = 169,
    sethostname = 170,
    setdomainname = 171,
    iopl = 172,
    ioperm = 173,
    create_module = 174, // removed in linux 2.6
    init_module = 175,
    delete_module = 176,
    get_kernel_syms = 177, // removed in linux 2.6
    query_module = 178, // removed in linux 2.6
    // ...
    waitid = 247,
    add_key = 248,
    request_key = 249,
    keyctl = 250,
    ioprio_set = 251,
    ioprio_get = 252,
    inotify_init = 253,
    inotify_add_watch = 254,
    inotify_rm_watch = 255,
    migrate_pages = 256,
    openat = 257,
    mkdirat = 258,
    mknodat = 259,
    fchownat = 260,
    futimesat = 261,
    newfstatat = 262,
    unlinkat = 263,
    renameat = 264,
    linkat = 265,
    symlinkat = 266,
    readlinkat = 267,
    fchmodat = 268,
    faccessat = 269,
    pselect6 = 270,
    ppoll = 271,
    unshare = 272,
    // ...
    fallocate = 285,
    // ...
    finit_module = 313,
}

struct SyscallValueResult(T)
{
    private ptrdiff_t _value;
    pragma(inline) ptrdiff_t numval() const { return _value; }
    pragma(inline) bool failed() const { return _value < 0 && _value >= -4095; }
    pragma(inline) bool passed() const { return _value >= 0 || _value < -4095; }

    pragma(inline) void set(const T value) { this._value = cast(ptrdiff_t)value; }
    pragma(inline) T val() const { return cast(T)_value; }
}

struct SyscallExpectZero
{
    private ptrdiff_t _value;
    pragma(inline) ptrdiff_t numval() const { return _value; }
    pragma(inline) bool failed() const { return _value != 0; }
    pragma(inline) auto passed() const { return _value == 0; }
}

auto getSysName(inout(char)[] s)
{
    for (size_t i = s.length; ;)
    {
        i--;
        if (s[i] == '.')
        {
            if (s[i + 1 .. i + 5] != "sys_")
                break;
            return s[i + 5 .. $];
        }
        if (i == 0)
            break;
    }
    //assert(0, "invalid syscall name '" ~ s ~ "`");
    assert(0, "invalid syscall name");
}

enum passthroughSyscall =
q{
    enum syscallNum = __traits(getMember, Syscall, __FUNCTION__.getSysName);
    asm
    {
        naked;
        mov EAX, syscallNum;
        // NOTE: not sure if it's better to include these 2 instructions
        //       in each syscall, or jump to an assembly location that
        //       executes them
        syscall;
        ret;
    }
};
enum passthroughSyscall4 =
q{
    enum syscallNum = __traits(getMember, Syscall, __FUNCTION__.getSysName);
    asm
    {
        naked;
        mov EAX, syscallNum;
        // NOTE: not sure if it's better to include these 3 instructions
        //       in each syscall, or jump to an assembly location that
        //       executes them
        mov R10, RCX;
        syscall;
        ret;
    }
};

extern (C) SyscallValueResult!size_t sys_read(FileD fd, void* buf, size_t n)
{
    mixin(passthroughSyscall);
}
extern (C) SyscallValueResult!size_t sys_write(FileD fd, const(void)* buf, size_t n)
{
    mixin(passthroughSyscall);
}

// TODO: should probably return SyscallValueResult!FileD?
extern (C) FileD sys_open(cstring pathname, OpenFlags flags, uint mode = 0)
{
    mixin(passthroughSyscall);
}
extern (C) FileD sys_openat(FileD dirFd, cstring pathname, OpenFlags flags, uint mode = 0)
{
    mixin(passthroughSyscall4);
}

extern (C) SyscallExpectZero sys_close(FileD fd)
{
    mixin(passthroughSyscall);
}

extern (C) SyscallValueResult!off_t sys_lseek(FileD fd, off_t offset, SeekFrom whence)
{
    mixin(passthroughSyscall);
}

extern (C) FileD sys_dup2(FileD oldfd, FileD newfd)
{
    mixin(passthroughSyscall);
}

extern (C) SyscallValueResult!pid_t sys_getpid()
{
    mixin(passthroughSyscall);
}

extern (C) SyscallValueResult!ptrdiff_t sys_ioctl(FileD fd, size_t request, void* arg)
{
    mixin(passthroughSyscall);
}

extern (C) SyscallExpectZero sys_access(cstring filename, AccessMode mode)
{
    mixin(passthroughSyscall);
}

extern (C) SyscallExpectZero sys_stat(cstring filename, stat_t* buf)
{
    mixin(passthroughSyscall);
}
extern (C) SyscallExpectZero sys_lstat(cstring filename, stat_t* buf)
{
    mixin(passthroughSyscall);
}
extern (C) SyscallExpectZero sys_fstat(FileD filedesc, stat_t* buf)
{
    mixin(passthroughSyscall);
}
extern (C) SyscallExpectZero sys_newfstatat(FileD dirFd, cstring pathname, stat_t* buf, int flags)
{
    mixin(passthroughSyscall4);
}
extern (C) SyscallValueResult!size_t sys_readlinkat(FileD dirFd, cstring pathname, char* buffer, size_t bufferLength)
{
    mixin(passthroughSyscall4);
}
extern (C) SyscallExpectZero sys_mkdir(cstring pathname, mode_t mode)
{
    mixin(passthroughSyscall);
}
extern (C) SyscallExpectZero sys_rmdir(cstring pathname)
{
    mixin(passthroughSyscall);
}
extern (C) SyscallValueResult!size_t sys_getcwd(char* buffer, size_t size)
{
    mixin(passthroughSyscall);
}
extern (C) SyscallExpectZero sys_link(cstring oldname, cstring newname)
{
    mixin(passthroughSyscall);
}
extern (C) SyscallExpectZero sys_unlink(cstring pathname)
{
    mixin(passthroughSyscall);
}
extern (C) SyscallExpectZero sys_chdir(cstring path)
{
    mixin(passthroughSyscall);
}

extern (C) SyscallValueResult!(ubyte*) sys_mmap(void* addr, size_t length,
    int prot, int flags, FileD fd, off_t fdOffset)
{
    mixin(passthroughSyscall4);
}
extern (C) SyscallValueResult!(ubyte*) sys_mremap(void* addr, size_t oldSize,
    size_t newSize, uint flags)
{
    mixin(passthroughSyscall4);
}

extern (C) SyscallExpectZero sys_munmap(ubyte* addr, size_t length)
{
    mixin(passthroughSyscall);
}

extern (C) SyscallValueResult!size_t sys_getdents(FileD fd, linux_dirent* dirp, kernel.unsigned_int count)
{
    mixin(passthroughSyscall);
}
/*
extern (C) SyscallValueResult!size_t sys_getdents64(FileD fd, linux_dirent64* dirp, kernel.unsigned_int count)
{
    mixin(passthroughSyscall);
}
*/

extern (C) SyscallExpectZero sys_chown(cstring filename, uid_t user, gid_t group)
{
    mixin(passthroughSyscall);
}
extern (C) SyscallExpectZero sys_fchown(FileD fd, uid_t user, gid_t group)
{
    mixin(passthroughSyscall);
}
extern (C) SyscallExpectZero sys_lchown(cstring filename, uid_t user, gid_t group)
{
    mixin(passthroughSyscall);
}
extern (C) uint sys_umask(uint mask)
{
    mixin(passthroughSyscall);
}

extern (C) SyscallValueResult!uid_t sys_getuid()
{
    mixin(passthroughSyscall);
}
extern (C) SyscallValueResult!gid_t sys_getgid()
{
    mixin(passthroughSyscall);
}
extern (C) SyscallExpectZero sys_setuid(uid_t uid)
{
    mixin(passthroughSyscall);
}
extern (C) SyscallExpectZero sys_setgid(gid_t gid)
{
    mixin(passthroughSyscall);
}


extern (C) SyscallExpectZero sys_chroot(cstring path)
{
    mixin(passthroughSyscall);
}
/**
 TODO: maybe provide an api to get the filesystem types?
       they would be found in /proc/filesystems (i.e. "btrfs", "extf", ...)
       run "cat /proc/filesystems" to see them, here is example output:
---
nodev	pipefs
nodev	devpts
nodev	hugetlbfs
nodev	pstore
nodev	mqueue
	ext3
	ext2
---
first column signifies whether the file system is mounted on a block device.
"nodev" means they are not mounted on a device.  Second column is the name.

Note: if no filesystemtype is specified, mount could cycle through these values.
Note: I'd like mounts to wrap this function and fail if the target directory
      has files by default.

Params:
    source = pathname of the blockdevice to mount
    target = the location to mount the device
    data = argument to the filesystem, typically a string of comma-separated options
*/
extern (C) SyscallExpectZero sys_mount(cstring source, cstring target, cstring filesystemtype,
     ulong mountFlags, const(void)* data)
{
    mixin(passthroughSyscall4);
}
extern (C) SyscallExpectZero sys_umount2(cstring target, uint flags)
{
    mixin(passthroughSyscall);
}

extern (C) SyscallValueResult!pid_t sys_setsid()
{
    mixin(passthroughSyscall);
}

extern (C) void sys_exit(ptrdiff_t status)
{
    mixin(passthroughSyscall);
}

extern (C) SyscallValueResult!pid_t sys_vfork()
{
    mixin(passthroughSyscall);
}
extern (C) SyscallValueResult!pid_t sys_fork()
{
    mixin(passthroughSyscall);
}

extern (C) SyscallExpectZero sys_capget(cap_user_header_t header, cap_user_data_t dataptr)
{
    mixin(passthroughSyscall);
}
extern (C) SyscallExpectZero sys_capset(cap_user_header_t header, const cap_user_data_t dataptr)
{
    mixin(passthroughSyscall);
}

extern (C) SyscallValueResult!pid_t sys_clone(size_t flags, void* childStack, void* parentTid, void* childTid)
{
    mixin(passthroughSyscall4);
}

extern (C) SyscallExpectZero sys_execve(cstring filename, SentinelPtr!cstring argv, SentinelPtr!cstring envp)
{
    mixin(passthroughSyscall);
}

extern (C) SyscallValueResult!pid_t sys_waitid(idtype_t idtype, pid_t pid, siginfo_t* infop, int options, rusage* ru = null)
{
    mixin(passthroughSyscall4);
}

extern (C) SyscallExpectZero sys_rt_sigaction(int signum, const(sigaction_t)* act, sigaction_t* oldact, size_t sigsetsize)
{
    mixin(passthroughSyscall4);
}

extern (C) SyscallExpectZero sys_unshare(uint flags)
{
    mixin(passthroughSyscall);
}

extern (C) SyscallExpectZero sys_fallocate(FileD fd, size_t mode, loff_t offset, off_t len)
{
    mixin(passthroughSyscall4);
}

extern (C) SyscallExpectZero sys_init_module(void* moduleImage, size_t len, cstring params)
{
    mixin(passthroughSyscall);
}
extern (C) SyscallExpectZero sys_finit_module(FileD fd, cstring params, uint flags)
{
    mixin(passthroughSyscall);
}

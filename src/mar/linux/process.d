module mar.linux.process;

import mar.sentinel : SentinelPtr;
import mar.c : cstring;
import mar.linux.syscall;

alias exit = sys_exit;
alias getpid = sys_getpid;
alias fork = sys_fork;
alias vfork = sys_vfork;
alias waitid = sys_waitid;
alias setsid = sys_setsid;
alias execve = sys_execve;
alias clone = sys_clone;
alias unshare = sys_unshare;

alias pid_t = ptrdiff_t;
alias uid_t = ptrdiff_t;

alias __kernel_long_t      = int;
alias __kernel_time_t      = __kernel_long_t;
alias __kernel_suseconds_t = int;
struct timeval
{
    __kernel_time_t      tv_sec;
    __kernel_suseconds_t tv_usec;
}
struct rusage
{
    timeval ru_utime;
    timeval ru_stime;
    __kernel_long_t ru_maxrss;
    __kernel_long_t ru_ixrss;
    __kernel_long_t ru_idrss;
    __kernel_long_t ru_isrss;
    __kernel_long_t ru_minflt;
    __kernel_long_t ru_majflt;
    __kernel_long_t ru_nswap;
    __kernel_long_t ru_inblock;
    __kernel_long_t ru_outblock;
    __kernel_long_t ru_msgsnd;
    __kernel_long_t ru_msgrcv;
    __kernel_long_t ru_nsignals;
    __kernel_long_t ru_nvcsw;
    __kernel_long_t ru_nivcsw;
}

enum idtype_t
{
    all = 0,
    pid = 1,
    pgid = 2,
}
enum WNOHANG      = 0x00000001;
enum WUNTRACED    = 0x00000002;
enum WSTOPPED     = WUNTRACED;
enum WEXITED      = 0x00000004;
enum WCONTINUED   = 0x00000008;
enum WNOWAIT      = 0x01000000;

enum __WNOTHREAD  = 0x20000000;
enum __WALL       = 0x40000000;
enum __WCLONE     = 0x80000000;

enum CSIGNAL              = 0x000000ff; // signal mask to be sent at exit
enum CLONE_VM             = 0x00000100; // set if VM shared between processes
enum CLONE_FS             = 0x00000200; // set if fs info shared between processes
enum CLONE_FILES          = 0x00000400; // set if open files shared between processes
enum CLONE_SIGHAND        = 0x00000800; // set if signal handlers and blocked signals shared
enum CLONE_PTRACE         = 0x00002000; // set if we want to let tracing continue on the child too
enum CLONE_VFORK          = 0x00004000; // set if the parent wants the child to wake it up on mm_release
enum CLONE_PARENT         = 0x00008000; // set if we want to have the same parent as the cloner
enum CLONE_THREAD         = 0x00010000; // Same thread group?
enum CLONE_NEWNS          = 0x00020000; // New mount namespace group
enum CLONE_SYSVSEM        = 0x00040000; // share system V SEM_UNDO semantics
enum CLONE_SETTLS         = 0x00080000; // create a new TLS for the child
enum CLONE_PARENT_SETTID  = 0x00100000; // set the TID in the parent
enum CLONE_CHILD_CLEARTID = 0x00200000; // clear the TID in the child
enum CLONE_DETACHED       = 0x00400000; // Unused, ignored
enum CLONE_UNTRACED       = 0x00800000; // set if the tracing process can't force CLONE_PTRACE on this clone
enum CLONE_CHILD_SETTID   = 0x01000000; // set the TID in the child
enum CLONE_NEWCGROUP      = 0x02000000; // New cgroup namespace
enum CLONE_NEWUTS         = 0x04000000; // New utsname namespace
enum CLONE_NEWIPC         = 0x08000000; // New ipc namespace
enum CLONE_NEWUSER        = 0x10000000; // New user namespace
enum CLONE_NEWPID         = 0x20000000; // New pid namespace
enum CLONE_NEWNET         = 0x40000000; // New network namespace
enum CLONE_IO             = 0x80000000; // Clone io context

//
// Scheduling policies
//
enum SCHED_NORMAL   = 0;
enum SCHED_FIFO     = 1;
enum SCHED_RR       = 2;
enum SCHED_BATCH    = 3;
// SCHED_ISO: reserved but not implemented yet
//enum SCHED_IDLE     = 5;
//enum SCHED_DEADLINE = 6;

// Can be ORed in to make sure the process is reverted back to SCHED_NORMAL on fork
enum SCHED_RESET_ON_FORK = 0x40000000;

//
// For the sched_{set,get}attr() calls
//

enum SCHED_FLAG_RESET_ON_FORK = 0x01;
enum SCHED_FLAG_RECLAIM       = 0x02;
enum SCHED_FLAG_DL_OVERRUN    = 0x04;

enum SCHED_FLAG_ALL = (SCHED_FLAG_RESET_ON_FORK |
                       SCHED_FLAG_RECLAIM       |
                       SCHED_FLAG_DL_OVERRUN);

module mar.linux.signals;

import mar.linux.syscall;
import mar.linux.process : pid_t, uid_t;

enum SIGHUP     =   1;
enum SIGINT     =   2;
enum SIGQUIT    =   3;
enum SIGILL     =   4;
enum SIGTRAP    =   5;
enum SIGABRT    =   6;
enum SIGIOT     =   6;
enum SIGBUS     =   7;
enum SIGFPE     =   8;
enum SIGKILL    =   9;
enum SIGUSR1    =  10;
enum SIGSEGV    =  11;
enum SIGUSR2    =  12;
enum SIGPIPE    =  13;
enum SIGALRM    =  14;
enum SIGTERM    =  15;
enum SIGSTKFLT  =  16;
enum SIGCHLD    =  17;
enum SIGCONT    =  18;
enum SIGSTOP    =  19;
enum SIGTSTP    =  20;
enum SIGTTIN    =  21;
enum SIGTTOU    =  22;
enum SIGURG     =  23;
enum SIGXCPU    =  24;
enum SIGXFSZ    =  25;
enum SIGVTALRM  =  26;
enum SIGPROF    =  27;
enum SIGWINCH   =  28;
enum SIGIO      =  29;
enum SIGPOLL    =  SIGIO;
enum SIGPWR     =  30;
enum SIGSYS     =  31;
enum SIGUNUSED  =  31;

// These should not be considered constants from userland. 
enum SIGRTMIN   = 32;
enum SIGRTMAX   = _NSIG;

/*
SA_FLAGS values:

SA_ONSTACK indicates that a registered stack_t will be used.
SA_RESTART flag to get restarting signals (which were the default long ago)
SA_NOCLDSTOP flag to turn off SIGCHLD when children stop.
SA_RESETHAND clears the handler when the signal is delivered.
SA_NOCLDWAIT flag on SIGCHLD to inhibit zombies.
SA_NODEFER prevents the current signal from being masked in the handler.

SA_ONESHOT and SA_NOMASK are the historical Linux names for the Single
Unix names RESETHAND and NODEFER respectively.
*/
enum SA_NOCLDSTOP = 0x00000001;
enum SA_NOCLDWAIT = 0x00000002;
enum SA_SIGINFO   = 0x00000004;
enum SA_ONSTACK   = 0x08000000;
enum SA_RESTART   = 0x10000000;
enum SA_NODEFER   = 0x40000000;
enum SA_RESETHAND = 0x80000000;

enum SA_NOMASK    = SA_NODEFER;
enum SA_ONESHOT   = SA_RESETHAND;

enum _NSIG        = 64;
struct sigset_t
{
    size_t[_NSIG / (8*size_t.sizeof)] sig;
}

union sigval
{
    int sival_int;
    void* sival_ptr;
}
struct siginfo_t
{
    int si_signo;
    int si_code;
    sigval si_value;
    int si_errno;
    pid_t si_pid;
    uid_t si_uid;
    void* si_addr;
    int si_status;
    int si_band;
}

struct sigaction_t
{
    union
    {
        extern (C) void function(int) sa_handler;
        extern (C) void function(int, siginfo_t*, void*) sa_sigaction;
    }
    ulong sa_flags;
    extern (C) void function() sa_restorer;
    sigset_t sa_mask;
}
/+
struct stack_t
{
    void __user *ss_sp;
    int ss_flags;
    size_t ss_size;
}

enum SS_ONSTACK  = 1;
enum SS_DISABLE  = 2;

// bit-flags
enum SS_AUTODISARM  = (1U << 31);    // disable sas during sighandling
// mask for all SS_xxx flags
enum SS_FLAG_BITS   = SS_AUTODISARM;
+/


enum SIG_BLOCK   = 0;
enum SIG_UNBLOCK = 1;
enum SIG_SETMASK = 2;

enum SIG_DFL = cast(void function(int))0; // default signal handling
enum SIG_IGN = cast(void function(int))1; // ignore signal
enum SIG_ERR = cast(void function(int))2; // error return from signal

private enum SA_RESTORER = 0x04000000;

auto sigaction(int signum, const(sigaction_t)* act, sigaction_t* oldact)
{
    sigaction_t kact;
    if (act)
    {
        kact.sa_handler = act.sa_handler;
        kact.sa_flags = act.sa_flags | SA_RESTORER;
        kact.sa_restorer = &sigreturn;
        kact.sa_mask = act.sa_mask;
    }
    return sys_rt_sigaction(signum, act ? &kact : null, oldact, sigset_t.sizeof);
}

extern (C) void sigreturn()
{
    // version (x86_64)
    asm
    {
        naked;
        mov EAX, 15;
        syscall;
    }
    /*
    version (x86)
    {
        naked
        mov EAX, 119;
        syscall;
    }
    */
}

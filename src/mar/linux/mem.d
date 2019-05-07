module mar.linux.mem;

import mar.linux.syscall;

SyscallValueResult!(void*) sbrk(ptrdiff_t increment)
{
    pragma(inline, true);
    assert(0, "not implemented");
    //import mar.linux.syscall;
    //return SyscallNegativeErrorOrValue!(void*)(syscall(Syscall.brk, increment));
}

module mar.linux.mem;

import mar.linux.syscall;

pragma(inline) SyscallValueResult!(void*) sbrk(ptrdiff_t increment)
{
    assert(0, "not implemented");
    //import mar.linux.syscall;
    //return SyscallNegativeErrorOrValue!(void*)(syscall(Syscall.brk, increment));
}

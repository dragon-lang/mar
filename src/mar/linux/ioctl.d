module mar.linux.ioctl;

import mar.linux.file : FileD;

import mar.linux.syscall;

/**
ioctl command encoding: 32 bits total, command in lower 16 bits,
size of the parameter structure in the lower 14 bits of the
upper 16 bits.
Encoding the size of the parameter structure in the ioctl request
is useful for catching programs compiled with old versions
and to avoid overwriting user space outside the user buffer area.
The highest 2 bits are reserved for indicating the ``access mode''.
NOTE: This limits the max parameter size to 16kB -1 !

The following is for compatibility across the various Linux
platforms.  The generic ioctl numbering scheme doesn't really enforce
a type field.  De facto, however, the top 8 bits of the lower 16
bits are indeed used as a type field, so we might just as well make
this explicit here.  Please be sure to use the decoding macros
below from now on.
*/

enum _IOC_NRBITS   =  8;
enum _IOC_TYPEBITS =  8;
enum _IOC_SIZEBITS = 14;
enum _IOC_DIRBITS  =  2;

enum _IOC_NRMASK   = (1 << _IOC_NRBITS  ) - 1;
enum _IOC_TYPEMASK = (1 << _IOC_TYPEBITS) - 1;
enum _IOC_SIZEMASK = (1 << _IOC_SIZEBITS) - 1;
enum _IOC_DIRMASK  = (1 << _IOC_DIRBITS ) - 1;

enum _IOC_NRSHIFT    = 0;
enum _IOC_TYPESHIFT  = _IOC_NRSHIFT   + _IOC_NRBITS;
enum _IOC_SIZESHIFT  = _IOC_TYPESHIFT + _IOC_TYPEBITS;
enum _IOC_DIRSHIFT   = _IOC_SIZESHIFT + _IOC_SIZEBITS;

enum _IOC_NONE  = 0;
enum _IOC_WRITE = 1;
enum _IOC_READ  = 2;

uint _IOC(uint dir, uint type, uint nr, uint size)
{
    return (dir << _IOC_DIRSHIFT)   |
           (type << _IOC_TYPESHIFT) |
           (type << _IOC_TYPESHIFT) |
           (nr << _IOC_NRSHIFT)     |
           (size << _IOC_SIZESHIFT) ;
}


//#ifndef __KERNEL__
//#define _IOC_TYPECHECK(t) (sizeof(t))
//#endif

// Used to create numbers.
//
// NOTE: _IOW means userland is writing and kernel is reading. _IOR
// means userland is reading and kernel is writing.
uint _IO      (uint type, uint nr)            { return _IOC(_IOC_NONE           , type, nr, 0); }
uint _IOR     (uint type, uint nr, uint size) { return _IOC(_IOC_READ           , type, nr, size/*_IOC_TYPECHECK(size)*/); }
uint _IOW     (uint type, uint nr, uint size) { return _IOC(_IOC_WRITE          , type, nr, size/*_IOC_TYPECHECK(size)*/); }
uint _IOWR    (uint type, uint nr, uint size) { return _IOC(_IOC_READ|_IOC_WRITE, type, nr, size/*_IOC_TYPECHECK(size)*/); }
uint _IOR_BAD (uint type, uint nr, uint size) { return _IOC(_IOC_READ           , type, nr, size); }
uint _IOW_BAD (uint type, uint nr, uint size) { return _IOC(_IOC_WRITE          , type, nr, size); }
uint _IOWR_BAD(uint type, uint nr, uint size) { return _IOC(_IOC_READ|_IOC_WRITE, type, nr, size); }

// used to decode ioctl numbers..
uint _IOC_DIR (uint nr)  { return ((nr >> _IOC_DIRSHIFT ) & _IOC_DIRMASK); }
uint _IOC_TYPE(uint nr)  { return ((nr >> _IOC_TYPESHIFT) & _IOC_TYPEMASK); }
uint _IOC_NR  (uint nr)  { return ((nr >> _IOC_NRSHIFT  ) & _IOC_NRMASK); }
uint _IOC_SIZE(uint nr)  { return ((nr >> _IOC_SIZESHIFT) & _IOC_SIZEMASK); }

/*
// ...and for the drivers/sound files...
uint IOC_IN        (_IOC_WRITE << _IOC_DIRSHIFT)
uint IOC_OUT        (_IOC_READ << _IOC_DIRSHIFT)
uint IOC_INOUT    ((_IOC_WRITE|_IOC_READ) << _IOC_DIRSHIFT)
uint IOCSIZE_MASK    (_IOC_SIZEMASK << _IOC_SIZESHIFT)
uint IOCSIZE_SHIFT    (_IOC_SIZESHIFT)
*/

alias ioctl = sys_ioctl;

pragma(inline)
extern (C) auto ioctl(T)(FileD fd, size_t request, T arg) if (!is(arg : void*))
{
    return sys_ioctl(fd, request, cast(void*)arg);
}

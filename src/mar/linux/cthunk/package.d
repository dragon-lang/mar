/**
File generated from C source to define types in D
*/
module mar.linux.cthunk;

alias mode_t    = uint;
alias ino_t     = ulong;
alias dev_t     = ulong;
alias nlink_t   = ulong;
alias uid_t     = uint;
alias gid_t     = uint;
alias off_t     = ulong;
alias loff_t    = ulong;
alias blksize_t = ulong;
alias blkcnt_t  = ulong;
alias time_t    = long;

// important to make sure the size of the struct matches to prevent
// buffer overlows when padding addresses of stat buffers allocated
// on the stack
enum sizeofStructStat = 144;
struct kernel
{
    alias unsigned_int  = uint;
    alias unsigned_long = ulong;
}

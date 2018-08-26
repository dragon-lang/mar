module mar.linux.capability;

import mar.linux.syscall : sys_capget, sys_capset;

alias capget = sys_capget;
alias capset = sys_capset;

/*
User-level do most of the mapping between kernel and user
capabilities based on the version tag given by the kernel. The
kernel might be somewhat backwards compatible, but don't bet on
it.

Note, cap_t, is defined by POSIX (draft) to be an "opaque" pointer to
a set of three capability sets.  The transposition of 3*the
following structure to such a composite is better handled in a user
library since the draft standard requires the use of malloc/free
etc.
*/

enum _LINUX_CAPABILITY_VERSION_1  = 0x19980330;
enum _LINUX_CAPABILITY_U32S_1     = 1;

enum _LINUX_CAPABILITY_VERSION_2  = 0x20071026;  // deprecated - use v3
enum _LINUX_CAPABILITY_U32S_2     = 2;

enum _LINUX_CAPABILITY_VERSION_3  = 0x20080522;
enum _LINUX_CAPABILITY_U32S_3     = 2;

struct __user_cap_header_struct
{
    uint version_;
    int pid;
}
alias cap_user_header_t = __user_cap_header_struct*;

struct __user_cap_data_struct {
    uint effective;
    uint permitted;
    uint inheritable;
}
alias cap_user_data_t = __user_cap_data_struct*;


enum VFS_CAP_REVISION_MASK    = 0xFF000000;
enum VFS_CAP_REVISION_SHIFT   = 24;
enum VFS_CAP_FLAGS_MASK       = ~VFS_CAP_REVISION_MASK;
enum VFS_CAP_FLAGS_EFFECTIVE  = 0x000001;

enum VFS_CAP_REVISION_1       = 0x01000000;
enum VFS_CAP_U32_1            = 1;
enum XATTR_CAPS_SZ_1          = (uint.sizeof * (1 + 2 * VFS_CAP_U32_1));

enum VFS_CAP_REVISION_2       = 0x02000000;
enum VFS_CAP_U32_2            = 2;
enum XATTR_CAPS_SZ_2          = (uint.sizeof * (1 + 2 * VFS_CAP_U32_2));

enum VFS_CAP_REVISION_3       = 0x03000000;
enum VFS_CAP_U32_3            = 2;
enum XATTR_CAPS_SZ_3          = (uint.sizeof * (2 + 2 * VFS_CAP_U32_3));

enum XATTR_CAPS_SZ            = XATTR_CAPS_SZ_3;
enum VFS_CAP_U32              = VFS_CAP_U32_3;
enum VFS_CAP_REVISION         = VFS_CAP_REVISION_3;


/*
Backwardly compatible definition for source code - trapped in a
32-bit world. If you find you need this, please consider using
libcap to untrap yourself...
*/
enum _LINUX_CAPABILITY_VERSION = _LINUX_CAPABILITY_VERSION_1;
enum _LINUX_CAPABILITY_U32S    = _LINUX_CAPABILITY_U32S_1;


/*
POSIX-draft defined capabilities.
*/

/**
In a system with the [_POSIX_CHOWN_RESTRICTED] option defined, this
overrides the restriction of changing file ownership and group
ownership. */
enum CAP_CHOWN = 0;

/** Override all DAC access, including ACL execute access if
   [_POSIX_ACL] is defined. Excluding DAC access covered by
   CAP_LINUX_IMMUTABLE. */
enum CAP_DAC_OVERRIDE = 1;

/**
Overrides all DAC restrictions regarding read and search on files
and directories, including ACL restrictions if [_POSIX_ACL] is
defined. Excluding DAC access covered by CAP_LINUX_IMMUTABLE. */
enum CAP_DAC_READ_SEARCH = 2;

/**
Overrides all restrictions about allowed operations on files, where
file owner ID must be equal to the user ID, except where CAP_FSETID
is applicable. It doesn't override MAC and DAC restrictions. */
enum CAP_FOWNER = 3;

/**
Overrides the following restrictions that the effective user ID
shall match the file owner ID when setting the S_ISUID and S_ISGID
bits on that file; that the effective group ID (or one of the
supplementary group IDs) shall match the file owner ID when setting
the S_ISGID bit on that file; that the S_ISUID and S_ISGID bits are
cleared on successful return from chown(2) (not implemented). */
enum CAP_FSETID = 4;

/**
Overrides the restriction that the real or effective user ID of a
process sending a signal must match the real or effective user ID
of the process receiving the signal. */
enum CAP_KILL = 5;

/**
Allows setgid(2) manipulation
Allows setgroups(2)
Allows forged gids on socket credentials passing. */
enum CAP_SETGID = 6;

/**
Allows set*uid(2) manipulation (including fsuid).
Allows forged pids on socket credentials passing. */
enum CAP_SETUID = 7;

//
// Linux-specific capabilities
//

/**
Without VFS support for capabilities:
  Transfer any capability in your permitted set to any pid,
  remove any capability in your permitted set from any pid
With VFS support for capabilities (neither of above, but)
  Add any capability from current's capability bounding set
      to the current process' inheritable set
  Allow taking bits out of capability bounding set
  Allow modification of the securebits for a process
*/
enum CAP_SETPCAP = 8;

/**
Allow modification of S_IMMUTABLE and S_APPEND file attributes */
enum CAP_LINUX_IMMUTABLE = 9;

/**
Allows binding to TCP/UDP sockets below 1024
Allows binding to ATM VCIs below 32 */
enum CAP_NET_BIND_SERVICE = 10;

/** Allow broadcasting, listen to multicast */
enum CAP_NET_BROADCAST = 11;

/**
Allow interface configuration
Allow administration of IP firewall, masquerading and accounting
Allow setting debug option on sockets
Allow modification of routing tables
Allow setting arbitrary process / process group ownership on sockets
Allow binding to any address for transparent proxying (also via NET_RAW)
Allow setting TOS (type of service)
Allow setting promiscuous mode
Allow clearing driver statistics
Allow multicasting
Allow read/write of device-specific registers
Allow activation of ATM control sockets
*/
enum CAP_NET_ADMIN = 12;

/**
Allow use of RAW sockets
Allow use of PACKET sockets
Allow binding to any address for transparent proxying (also via NET_ADMIN)
*/
enum CAP_NET_RAW = 13;

/*
Allow locking of shared memory segments
Allow mlock and mlockall (which doesn't really have anything to do with IPC)
*/
enum CAP_IPC_LOCK = 14;

/** Override IPC ownership checks */
enum CAP_IPC_OWNER = 15;

/** Insert and remove kernel modules - modify kernel without limit */
enum CAP_SYS_MODULE = 16;

/**
Allow ioperm/iopl access
Allow sending USB messages to any device via /dev/bus/usb */
enum CAP_SYS_RAWIO = 17;

/** Allow use of chroot() */
enum CAP_SYS_CHROOT = 18;

/** Allow ptrace() of any process */
enum CAP_SYS_PTRACE = 19;

/** Allow configuration of process accounting */
enum CAP_SYS_PACCT = 20;

/**
Allow configuration of the secure attention key
Allow administration of the random device
Allow examination and configuration of disk quotas
Allow setting the domainname
Allow setting the hostname
Allow calling bdflush()
Allow mount() and umount(), setting up new smb connection
Allow some autofs root ioctls
Allow nfsservctl
Allow VM86_REQUEST_IRQ
Allow to read/write pci config on alpha
Allow irix_prctl on mips (setstacksize)
Allow flushing all cache on m68k (sys_cacheflush)
Allow removing semaphores
Used instead of CAP_CHOWN to "chown" IPC message queues, semaphores
   and shared memory
Allow locking/unlocking of shared memory segment
Allow turning swap on/off
Allow forged pids on socket credentials passing
Allow setting readahead and flushing buffers on block devices
Allow setting geometry in floppy driver
Allow turning DMA on/off in xd driver
Allow administration of md devices (mostly the above, but some
   extra ioctls)
Allow tuning the ide driver
Allow access to the nvram device
Allow administration of apm_bios, serial and bttv (TV) device
Allow manufacturer commands in isdn CAPI support driver
Allow reading non-standardized portions of pci configuration space
Allow DDI debug ioctl on sbpcd driver
Allow setting up serial ports
Allow sending raw qic-117 commands
Allow enabling/disabling tagged queuing on SCSI controllers and sending
   arbitrary SCSI commands
Allow setting encryption key on loopback filesystem
Allow setting zone reclaim policy
*/
enum CAP_SYS_ADMIN = 21;

/** Allow use of reboot() */
enum CAP_SYS_BOOT = 22;

/**
Allow raising priority and setting priority on other (different
   UID) processes
Allow use of FIFO and round-robin (realtime) scheduling on own
   processes and setting the scheduling algorithm used by another
   process.
Allow setting cpu affinity on other processes
*/
enum CAP_SYS_NICE = 23;

/*
Override resource limits. Set resource limits.
Override quota limits.
Override reserved space on ext2 filesystem
Modify data journaling mode on ext3 filesystem (uses journaling
   resources)
NOTE: ext2 honors fsuid when checking for resource overrides, so
   you can override using fsuid too
Override size restrictions on IPC message queues
Allow more than 64hz interrupts from the real-time clock
Override max number of consoles on console allocation
Override max number of keymaps
*/
enum CAP_SYS_RESOURCE = 24;

/**
Allow manipulation of system clock
Allow irix_stime on mips
Allow setting the real-time clock */
enum CAP_SYS_TIME = 25;

/**
Allow configuration of tty devices
Allow vhangup() of tty */
enum CAP_SYS_TTY_CONFIG = 26;

/** Allow the privileged aspects of mknod() */
enum CAP_MKNOD = 27;

/** Allow taking of leases on files */
enum CAP_LEASE = 28;

/** Allow writing the audit log via unicast netlink socket */
enum CAP_AUDIT_WRITE = 29;

/** Allow configuration of audit via unicast netlink socket */
enum CAP_AUDIT_CONTROL = 30;

enum CAP_SETFCAP = 31;

/*
Override MAC access.
The base kernel enforces no MAC policy.
An LSM may enforce a MAC policy, and if it does and it chooses
to implement capability based overrides of that policy, this is
the capability it should use to do so. */
enum CAP_MAC_OVERRIDE = 32;

/*
Allow MAC configuration or state changes.
The base kernel requires no MAC configuration.
An LSM may enforce a MAC policy, and if it does and it chooses
to implement capability based checks on modifications to that
policy or the data required to maintain it, this is the
capability it should use to do so. */
enum CAP_MAC_ADMIN = 33;

/** Allow configuring the kernel's syslog (printk behaviour) */
enum CAP_SYSLOG = 34;

/** Allow triggering something that will wake the system */
enum CAP_WAKE_ALARM = 35;

/** Allow preventing system suspends */
enum CAP_BLOCK_SUSPEND = 36;

/** Allow reading the audit log via multicast netlink socket */
enum CAP_AUDIT_READ = 37;

enum CAP_LAST_CAP = CAP_AUDIT_READ;

bool cap_valid(ubyte x) pure { return x >= 0 && x <= CAP_LAST_CAP; }

/**
Bit location of each capability (used by user-space library and kernel)
*/
auto CAP_TO_INDEX(ubyte x) { return x >> 5; } // 1 << 5 == bits in uint
auto CAP_TO_MASK(ubyte x)  { return 1 << (x & 31); } // mask for indexed uint



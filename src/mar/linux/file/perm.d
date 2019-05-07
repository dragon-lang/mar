module mar.file.perm;

import mar.linux.cthunk : mode_t;

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

enum ModeTypeMask = (
    ModeFlags.isFifo |
    ModeFlags.isCharDev |
    ModeFlags.isDir |
    ModeFlags.isRegFile);
enum ModeTypeLink = ModeFlags.isCharDev | ModeFlags.isRegFile;
enum ModeTypeDir  = ModeFlags.isDir;

/*
#define S_ISLNK(m)    (((m) & S_IFMT) == S_IFLNK)
#define S_ISREG(m)    (((m) & S_IFMT) == S_IFREG)
#define S_ISDIR(m)    (((m) & S_IFMT) == S_IFDIR)
#define S_ISCHR(m)    (((m) & S_IFMT) == S_IFCHR)
#define S_ISBLK(m)    (((m) & S_IFMT) == S_IFBLK)
#define S_ISFIFO(m)    (((m) & S_IFMT) == S_IFIFO)
#define S_ISSOCK(m)    (((m) & S_IFMT) == S_IFSOCK)
*/

bool isLink(const mode_t mode)
{
    pragma(inline, true);
    return (mode & ModeTypeMask) == ModeTypeLink;
}
bool isDir(const mode_t mode)
{
    pragma(inline, true);
    return (mode & ModeTypeMask) == ModeTypeDir;
}

auto formatMode(mode_t mode)
{
    static struct Formatter
    {
        mode_t mode;
        auto print(P)(P printer) const
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
            return P.success;
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

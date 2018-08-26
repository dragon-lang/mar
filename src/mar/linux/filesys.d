module mar.linux.filesys;

import mar.typecons : ValueOrErrorCode;
import mar.sentinel : SentinelPtr, assumeSentinel;
import mar.c : cstring, tempCString;
import mar.linux.file : FileD;
import mar.linux.cthunk : kernel, mode_t;
import mar.linux.syscall;

alias mkdir    = sys_mkdir;
alias rmdir    = sys_rmdir;
alias link     = sys_link;
alias getcwd   = sys_getcwd;
alias chdir    = sys_chdir;
alias chroot   = sys_chroot;
alias mount    = sys_mount;
alias umount2  = sys_umount2;
alias getdents = sys_getdents;
alias umask    = sys_umask;

pragma(inline) auto chdir(T)(T path) if (!is(path : cstring))
{
    mixin tempCString!("pathCStr", "path");
    return sys_chdir(pathCStr.str);
}


/**
Taken from http://insanecoding.blogspot.com/2007/11/pathmax-simply-isnt.html
*/
/+
TODO: port to D
void getcwd2()
{
    typedef std::pair<dev_t, ino_t> file_id;
    
    bool success = false;
    int start_fd = open(".", O_RDONLY); //Keep track of start directory, so can jump back to it later
    if (start_fd != -1)
    {
      struct stat sb;
      if (!fstat(start_fd, &sb))
      {
        file_id current_id(sb.st_dev, sb.st_ino);
        if (!stat("/", &sb)) //Get info for root directory, so we can determine when we hit it
        {
          std::vector<std::string> path_components;
          file_id root_id(sb.st_dev, sb.st_ino);

          while (current_id != root_id) //If they're equal, we've obtained enough info to build the path
          {
            bool pushed = false;

            if (!chdir("..")) //Keep recursing towards root each iteration
            {
              DIR *dir = opendir(".");
              if (dir)
              {
                dirent *entry;
                while ((entry = readdir(dir))) //We loop through each entry trying to find where we came from
                {
                  if ((strcmp(entry->d_name, ".") && strcmp(entry->d_name, "..") && !lstat(entry->d_name, &sb)))
                  {
                    file_id child_id(sb.st_dev, sb.st_ino);
                    if (child_id == current_id) //We found where we came from, add its name to the list
                    {
                      path_components.push_back(entry->d_name);
                      pushed = true;
                      break;
                    }
                  }
                }
                closedir(dir);

                if (pushed && !stat(".", &sb)) //If we have a reason to contiue, we update the current dir id
                {
                  current_id = file_id(sb.st_dev, sb.st_ino);
                }
              }//Else, Uh oh, can't read information at this level
            }
            if (!pushed) { break; } //If we didn't obtain any info this pass, no reason to continue
          }

          if (current_id == root_id) //Unless they're equal, we failed above
          {
            //Built the path, will always end with a slash
            path = "/";
            for (std::vector<std::string>::reverse_iterator i = path_components.rbegin(); i != path_components.rend(); ++i)
            {
              path += *i+"/";
            }
            success = true;
          }
          fchdir(start_fd);
        }
      }
      close(start_fd);
    }

    return(success);
}
+/


// taken from the latest kernel...however, this
// structure changes over time
struct linux_dirent
{
align(1):
    ulong             d_ino;    /// inode
    ulong             d_off;    /// offset to next
    ushort            d_reclen; /// length of this dirent
    private char[0]   d_name;
    auto nameCString() inout
    {
        import mar.sentinel : assumeSentinel;
        return (cast(char*)(&d_name)).assumeSentinel;
    }
}
/*
struct linux_dirent64
{
align(1):
    ulong             d_ino;    /// inode
    ulong             d_off;    /// offset to next
    ushort            d_reclen; /// length of this dirent
    //ubyte             d_type;
    private char[0]   d_name;

    auto nameCString() inout
    {
        import mar.sentinel : assumeSentinel;
        return (cast(char*)(&d_name)).assumeSentinel;
    }
}
*/

struct LinuxDirentRange
{
    size_t size;
    linux_dirent* next;
    bool empty() const { return size == 0; }
    auto front() { return next; }
    void popFront()
    {
        import mar.file : print, stderr;
        import mar.process : exit;
        if (next[0].d_reclen > size)
        {
            print(stderr, "Error: invalid linux_dirent, size is ", size, " but d_reclen is ",
                next[0].d_reclen, "\n");
            exit(1);
        }
        size -= next[0].d_reclen;
        next = cast(linux_dirent*)((cast(ubyte*)next) + next[0].d_reclen);
    }
}



// These are the fs-independent mount-flags: up to 32 flags are supported
enum MS_RDONLY      = 1 << 0;   // Mount read-only
enum MS_NOSUID      = 1 << 1;   // Ignore suid and sgid bits
enum MS_NODEV       = 1 << 2;   // Disallow access to device special files
enum MS_NOEXEC      = 1 << 3;   // Disallow program execution
enum MS_SYNCHRONOUS = 1 << 4;   // Writes are synced at once
enum MS_REMOUNT     = 1 << 5;   // Alter flags of a mounted FS
enum MS_MANDLOCK    = 1 << 6;   // Allow mandatory locks on an FS
enum MS_DIRSYNC     = 1 << 7;   // Directory modifications are synchronous
enum MS_NOATIME     = 1 << 10;   // Do not update access times.
enum MS_NODIRATIME  = 1 << 11;   // Do not update directory access times
enum MS_BIND        = 1 << 12;
enum MS_MOVE        = 1 << 13;
enum MS_REC         = 1 << 14;
enum MS_VERBOSE     = 1 << 15;  // War is peace. Verbosity is silence.
                                // MS_VERBOSE is deprecated.
enum MS_SILENT      = 1 << 15;
enum MS_POSIXACL    = 1 << 16;  // VFS does not apply the umask
enum MS_UNBINDABLE  = 1 << 17;  // change to unbindable
enum MS_PRIVATE     = 1 << 18;  // change to private
enum MS_SLAVE       = 1 << 19;  // change to slave
enum MS_SHARED      = 1 << 20;  // change to shared
enum MS_RELATIME    = 1 << 21;  // Update atime relative to mtime/ctime.
enum MS_KERNMOUNT   = 1 << 22;  // this is a kern_mount call
enum MS_I_VERSION   = 1 << 23;  // Update inode I_version field
enum MS_STRICTATIME = 1 << 24;  // Always perform atime updates
enum MS_LAZYTIME    = 1 << 25;  // Update the on-disk [acm]times lazily


enum AT_FDCWD            = -100;   // Special value used to indicate
                                   // openat should use the current
                                   // working directory.
enum AT_SYMLINK_NOFOLLOW = 0x0100; // Do not follow symbolic links.
enum AT_REMOVEDIR        = 0x0200; // Remove directory instead of
                                   //       unlinking file.
enum AT_SYMLINK_FOLLOW   = 0x0400; // Follow symbolic links.
enum AT_NO_AUTOMOUNT     = 0x0800; // Suppress terminal automount traversal
enum AT_EMPTY_PATH       = 0x1000; // Allow empty relative pathname

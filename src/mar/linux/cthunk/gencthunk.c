#include <stdio.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <dirent.h>

#define memberSize(type, member) sizeof(((type*)0)->member)

int errorCount = 0;

const char *getUnsignedType(unsigned size)
{
  switch (size) {
  case 1: return "ubyte";
  case 2: return "ushort";
  case 4: return "uint";
  case 8: return "ulong";
  }
  fprintf(stderr, "Error: unsupported unsigned type size %d\n", size);
  errorCount++;
  return "???";
}
const char *getSignedType(unsigned size)
{
  switch (size) {
  case 1: return "byte";
  case 2: return "short";
  case 4: return "int";
  case 8: return "long";
  }
  fprintf(stderr, "Error: unsupported signed type size %d\n", size);
  errorCount++;
  return "???";
}
int main()
{
  printf("/**\n");
  printf("File generated from C source to define types in D\n");
  printf("*/\n");
  printf("module mar.linux.cthunk;\n");
  printf("\n");
  printf("alias mode_t    = %s;\n", getUnsignedType(sizeof(mode_t)));
  printf("alias ino_t     = %s;\n", getUnsignedType(sizeof(ino_t)));
  printf("alias dev_t     = %s;\n", getUnsignedType(sizeof(dev_t)));
  printf("alias nlink_t   = %s;\n", getUnsignedType(sizeof(nlink_t)));
  printf("alias uid_t     = %s;\n", getUnsignedType(sizeof(uid_t)));
  printf("alias gid_t     = %s;\n", getUnsignedType(sizeof(gid_t)));
  printf("alias off_t     = %s;\n", getUnsignedType(sizeof(off_t)));
  printf("alias loff_t    = %s;\n", getUnsignedType(sizeof(loff_t)));
  printf("alias blksize_t = %s;\n", getUnsignedType(sizeof(blksize_t)));
  printf("alias blkcnt_t  = %s;\n", getUnsignedType(sizeof(blkcnt_t)));
  printf("alias time_t    = %s;\n", getSignedType(sizeof(time_t)));
  printf("\n");
  printf("// important to make sure the size of the struct matches to prevent\n");
  printf("// buffer overlows when padding addresses of stat buffers allocated\n");
  printf("// on the stack\n");
  printf("enum sizeofStructStat = %lu;\n", sizeof(struct stat));
  printf("struct kernel\n");
  printf("{\n");
  printf("    alias unsigned_int  = %s;\n", getUnsignedType(sizeof(unsigned int)));
  printf("    alias unsigned_long = %s;\n", getUnsignedType(sizeof(unsigned long)));
  printf("}\n");
  return errorCount;
}

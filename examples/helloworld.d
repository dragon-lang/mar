#!/usr/bin/env rund
//!importPath ../src
//!importPath ../druntime
//!version NoStdc
//!noConfigFile
//!betterC

/**
This example hello world program will compile without any libraries, no C
standard library, no D runtime, not even the library that contains the `_start`
symbol.

NOTE: only linux x86_64 currently supported
*/
import mar.sentinel;
import mar.c;
import mar.linux.file;

import mar.start;
mixin(startMixin);

extern (C) int main(uint argc, SentinelPtr!cstring argv, SentinelPtr!cstring envp)
{
    print(stdout, "Hello World!\n");
    return 0;
}

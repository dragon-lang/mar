#!/usr/bin/env rund
//!importPath ../src
//!importPath ../druntime
//!version NoStdc
//!noConfigFile
//!betterC
//!debug
//!debugSymbols

/**
This example hello world program will compile without any libraries, no C
standard library, no D runtime, not even the library that contains the `_start`
symbol.

NOTE: only x86_64 is currently supported
*/
import mar.sentinel;
import mar.c;
import mar.stdio;

import mar.start;
mixin(startMixin);

extern (C) int main(uint argc, SentinelPtr!cstring argv, SentinelPtr!cstring envp)
{
    stdout.write("Hello World!\n");
    return 0;
}

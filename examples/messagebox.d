#!/usr/bin/env rund
//!importPath ../src
//!importPath ../druntime
//!version NoStdc
//!noConfigFile
//!betterC
//!debug
//!debugSymbols

import mar.sentinel;
import mar.c;
import mar.windows.types;
import mar.windows.user32;

//import mar.start;
//mixin(startMixin);

extern (C) int main(uint argc, SentinelPtr!cstring argv, SentinelPtr!cstring envp)
{
    MessageBoxA(GetActiveWindow(), "the text", "the caption", MessageBoxType.ok);
    return 0;
}

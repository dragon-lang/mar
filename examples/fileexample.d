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
import mar.file;
import mar.stdio;

import mar.start;
mixin(startMixin);

extern (C) int main(uint argc, SentinelPtr!cstring argv, SentinelPtr!cstring envp)
{
    auto filename = lit!"generatedfile.txt";
    stdout.writeln("Generating '", filename, "'...");
    auto file = tryOpenFile(filename.ptr, OpenFileOpt(OpenAccess.writeOnly)
        .createOrTruncate
        .mode(ModeSet.rwUser | ModeSet.rwGroup | ModeFlags.readOther));
    file.writeln("This file was generated using the mar library");
    file.close();
    return 0;
}

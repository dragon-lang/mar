#!/usr/bin/env rund
//!importPath ../src
//!importPath ../druntime
//!version NoStdc
//!noConfigFile
//!betterC
import mar.array;
import mar.mem;
import mar.sentinel;
import mar.c;
import mar.format;
import mar.file;
import mar.linux.filesys;
import mar.env;
import mar.findprog;
import mar.linux.process;
import mar.linux.signals;

immutable modules = [
    "mar/expect.d",
    "mar/arraybuilder.d",
    "mar/input.d",
    "mar/c.d",
    "mar/mem_mmap.d",
    "mar/octal.d",
    "mar/sentinel.d",
    "mar/findprog.d",
    "mar/process.d",
];

import mar.start;
mixin(startMixin);


__gshared SentinelPtr!cstring envp;
__gshared cstring pathEnv;

void loggy_mkdir(cstring dirname)
{
    print(stdout, "mkdir '", dirname, "'\n");
    auto result = mkdir(dirname, S_IRWXU | S_IRWXG | S_IRWXO);
    if (result.failed)
    {
        logError("mkdir '", dirname, "' failed, returned ", result.numval);
        exit(1);
    }
}

extern (C) int main(int argc, SentinelPtr!cstring argv, SentinelPtr!cstring envp)
{
    argc--;
    argv++;

    .envp = envp;
    pathEnv = getenv(envp, "PATH");

    if (!isDir(litPtr!"out"))
        loggy_mkdir(litPtr!"out");

    if (argc == 0)
    {
        foreach (mod; modules)
        {
            testModule(mod);
        }
    }
    else
    {
        foreach (i; 0 .. argc)
        {
            testModule(argv[i].walkToArray.array);
        }
    }
    return 0;
}

void logError(T...)(T args)
{
    print(stderr, "Error: ", args, "\n");
}

pid_t run(SentinelPtr!cstring argv, SentinelPtr!cstring envp)
{
    if (usePath(argv[0]))
    {
        auto result = findProgram(pathEnv, argv[0].walkToArray.array);
        if (result.isNull)
        {
            logError("cannot find program '", argv[0], "'");
            exit(1);
        }
        argv[0] = result;
    }

    print(stdout, "[EXEC]");
    for(size_t i = 0; ;i++)
    {
        auto arg = argv[i];
        if (!arg) break;
        print(stdout, " \"", arg, "\"");
    }
    print(stdout, "\n");
    auto pidResult = fork();
    if (pidResult.failed)
    {
        logError("fork failed, returned ", pidResult.numval);
        exit(1);
    }
    if (pidResult.val == 0)
    {
        auto result = execve(argv[0], argv, envp);
        logError("execve returned ", result.numval);
        exit(1);
    }
    return pidResult.val;
}

auto wait(pid_t pid)
{
    siginfo_t info;
    auto result = waitid(idtype_t.pid, pid, &info, WEXITED, null);
    if (result.failed)
    {
        logError("waitid failed, returned ", result.numval);
        //exit(result);
        exit(1);
    }
    return info.si_status;
}

void waitEnforceSuccess(pid_t pid)
{
    auto result = wait(pid);
    if (result != 0)
    {
        logError("last program failed (exit code is ", result, ")");
        exit(1);
    }
}

auto getBasename(inout(char)[] file)
{
    return file[file.lastIndexOf('/') + 1 .. $];
}
auto stripExt(inout(char)[] file)
{
    return file[0 .. file.lastIndexOf('.')];
}
auto fileToModuleName(const(char)[] file)
{
    file = stripExt(file);
    auto buffer = cast(char*)malloc(file.length);
    acopy(buffer, file);
    foreach (i; 0 .. file.length)
    {
        if (buffer[i] == '/')
            buffer[i] = '.';
    }
    return buffer[0 .. file.length].assumeSentinel;
}

void testModule(const(char)[] mod)
{
    print(stdout, "--------------------------------------------------------------------------------\n");
    print(stdout, "Testint module: ", mod, "\n");
    print(stdout, "--------------------------------------------------------------------------------\n");
    auto basename = getBasename(mod);
    auto dirname = sprintMallocSentinel("out/", stripExt(basename));
    if (isDir(dirname.ptr))
    {
       cstring[4] rmArgs;
       rmArgs[0] = litPtr!"rm";
       rmArgs[1] = litPtr!"-rf";
       rmArgs[2] = dirname.ptr;
       rmArgs[3] = cstring.nullValue;
       waitEnforceSuccess(run(rmArgs.ptr.assumeSentinel, envp));
    }
    loggy_mkdir(dirname.ptr);

    // We need to put this file in the current directory because when we compile later with -op
    // (perserve output path) we want it to go into the root of the output directory, not a subdirectory of it
    //auto mainSourceName = sprintMallocSentinel(dirname, "/main.d");
    auto mainSourceName = sprintMallocSentinel("main.d");

    print(stdout, "generating '", mainSourceName, "'\n");
    {
        auto mainSource = open(mainSourceName.ptr, OpenFlags(OpenAccess.writeOnly, OpenCreateFlags.creat),
            (S_IRUSR | S_IWUSR) | (S_IRGRP | S_IWGRP) | (S_IROTH));
        if (!mainSource.isValid)
        {
            logError("open '", mainSourceName, "' failed, returned ", mainSource.numval);
            exit(1);
        }
        scope (exit) close(mainSource);

        print(mainSource, "import mar.file;\n");
        print(mainSource, "\n");
        auto modName = fileToModuleName(mod);
        print(mainSource, "// import module we are testing\n");
        print(mainSource, "import modUnderTest = ", modName, ";\n");
        print(mainSource, q{
import mar.start;
mixin(startMixin);
extern (C) int main(uint argc, void* argv, void* envp)
{
    print(stdout, "Running ", __traits(getUnitTests, modUnderTest).length, " Tests...\n");
    foreach (test; __traits(getUnitTests, modUnderTest))
    {
        test();
    }
    return 0;
}
});

    }

    {
       cstring[60] compileArgs;
       auto offset = 0;
       compileArgs[offset++] = litPtr!"dmd";
       compileArgs[offset++] = litPtr!"-betterC";
       compileArgs[offset++] = litPtr!"-conf=";
       compileArgs[offset++] = litPtr!"-version=NoStdc";
       compileArgs[offset++] = litPtr!"-I=../src";
       compileArgs[offset++] = litPtr!"-I=../druntime";
       compileArgs[offset++] = litPtr!"-unittest";
       compileArgs[offset++] = sprintMallocSentinel("-od=", dirname).ptr;
       compileArgs[offset++] = litPtr!"-c";
       compileArgs[offset++] = litPtr!"-op";
       compileArgs[offset++] = litPtr!"-i=object";
       compileArgs[offset++] = litPtr!"-i=mar";
       compileArgs[offset++] = mainSourceName.ptr;
       compileArgs[offset++] = cstring.nullValue;
       waitEnforceSuccess(run(compileArgs.ptr.assumeSentinel, envp));
    }
    print(stdout, "rm '", mainSourceName, "'\n");
    {
        auto result = unlink(mainSourceName.ptr);
        if (result.failed)
        {
            logError("unlink '", mainSourceName, "' failed, returned ", result.numval);
            exit(1);
        }
    }

    auto exeName = sprintMallocSentinel(dirname, "/runtests");
    {
       cstring[100] linkArgs;
       size_t offset = 0;
       linkArgs[offset++] = litPtr!"ld";
       linkArgs[offset++] = litPtr!"-o";
       linkArgs[offset++] = exeName.ptr;
       addObjectFiles(dirname.ptr, linkArgs, &offset);
       linkArgs[offset++] = cstring.nullValue;
       waitEnforceSuccess(run(linkArgs.ptr.assumeSentinel, envp));
    }
    {
       cstring[2] runArgs;
       runArgs[0] = exeName.ptr;
       runArgs[1] = cstring.nullValue;
       waitEnforceSuccess(run(runArgs.ptr.assumeSentinel, envp));
    }
}

void addObjectFiles(cstring dirname, cstring[] args, size_t* offset)
{
    auto dirfd = open(dirname, OpenFlags(OpenAccess.readOnly, OpenCreateFlags.dir));
    if (!dirfd.isValid)
    {
        logError("open \"", dirname , "\" failed ", dirfd);
        exit(1);
    }
    scope(exit) close(dirfd);

    for (;;)
    {
        ubyte[2048] buffer = void;
        auto entries = cast(linux_dirent*)buffer.ptr;
        auto result = getdents(dirfd, entries, buffer.length);
        if (result.numval <= 0)
        {
            if (result.failed)
                logError("getdents failed, it returned ", result.numval);
            break;
        }
        foreach (entry; LinuxDirentRange(result.val, entries))
        {
            auto entryName = entry.nameCString.walkToArray;
            if (aequals(entryName, ".") || aequals(entryName, ".."))
                continue;
            if (entryName.endsWith(".o"))
            {
                args[*offset] = sprintMallocSentinel(dirname, "/", entryName).ptr;
                *offset = *offset + 1;
            }
            {
                stat_t stat;
                auto statResult = fstatat(dirfd, entryName.ptr, &stat, 0);
                if (statResult.failed)
                {
                    logError("fstatat failed, returned ", statResult.numval);
                    exit(1);
                }
                if (isDir(stat.st_mode))
                {
                    addObjectFiles(sprintMallocSentinel(dirname, "/", entryName).ptr, args, offset);
                }
            }
        }
    }
}

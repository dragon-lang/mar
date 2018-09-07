module mar.process;

import mar.expect;

version (linux)
{
    static import mar.linux.process;
    import mar.linux.process : pid_t;
    alias wait = mar.linux.process.wait;
}

void exit(ptrdiff_t exitCode)
{
    version (linux)
    {
        import mar.linux.process : exit;
        exit(exitCode);
    }
    else version (Windows)
    {
        assert(0, "exit not implemented on windows");
    }
    else static assert(0, "unsupported platform");
}

/**
TODO: create api for what environment variables to pass
*/
struct ProcBuilder
{
    import mar.arraybuilder;
    import mar.sentinel : SentinelPtr, SentinelArray, assumeSentinel;
    import mar.c : cstring;
    version (Posix)
    {
        import mar.linux.process : fork, execve;
    }

    static ProcBuilder forExeFile(cstring programFile)
    {
        return ProcBuilder(programFile);
    }
    static ProcBuilder forExeFile(SentinelArray!(const(char)) programFile)
    {
        return ProcBuilder(programFile);
    }

    version (Windows)
    {
        private SentinelArray!(immutable(char)) program;
        ArrayBuilder!(char, MallocArrayBuilderPolicy!300) args;
    }
    else version (Posix)
    {
        ArrayBuilder!(cstring, MallocArrayBuilderPolicy!40) args;
    }
    @disable this();
    private this(cstring program)
    {
        version (Windows)
            this.program = program.walkToArray;
        else version (Posix)
            assert(args.tryPut(program).passed, "out of memory");
    }
    private this(SentinelArray!(const(char)) program)
    {
        version (Windows)
            this.program = program;
        else version (Posix)
            assert(args.tryPut(program.ptr).passed, "out of memory");
    }

    auto tryPut(cstring arg)
    {
        version (Windows)
            // TODO: append to args, make sure it is escaped if necessary
            static assert (0, "not impl");
        else version (Posix)
            return args.tryPut(arg);
    }

    version (Windows)
    {
        auto tryPut(SentinelArray!(const(char)) arg)
        {
            static assert(0, "not impl");
        }
    }
    else version (Posix)
    {
        pragma(inline)
        auto tryPut(SentinelArray!(const(char)) arg)
        {
            return tryPut(arg.ptr);
        }
    }

    mixin ExpectMixin!("StartResult", pid_t,
        ErrorCase!("outOfMemory", "out of memory"),
        ErrorCase!("forkFailed", "fork failed, returned %", ptrdiff_t));

    /** Start the process and clean the data structures created to start the process */
    StartResult startWithClean(SentinelPtr!cstring envp)
    {
        auto result = startImpl(envp);
        version (Windows)
        {
            args.free();
        }
        else version (Posix)
        {
            args.free();
        }
        return result;
    }
    private StartResult startImpl(SentinelPtr!cstring envp)
    {
        version (Windows)
            static assert(0, "not impl");
        else version (Posix)
        {
            if (tryPut(cstring.nullValue).failed)
                return StartResult.outOfMemory();

            // TODO: maybe I'm supposed to use posix_spawn instead of fork/exec?
            auto pidResult = fork();
            if (pidResult.failed)
                return StartResult.forkFailed(pidResult.numval);
            if (pidResult.val == 0)
            {
                auto result = execve(args.data[0], args.data.ptr.assumeSentinel, envp);
                // TODO: how do we handle this error in the new process?
                exit( (result.numval == 0) ? 1 : result.numval);
            }
            return StartResult.success(pidResult.val);
        }
    }

    void print(P)(P printer) const
    {
        version (Windows)
            static assert(0, "not impl");
        else version (Posix)
        {
            // TODO: how to handle args with spaces?
            printer.put(args.data[0].walkToArray.array);
            foreach (arg; args.data[1 .. $])
            {
                printer.putc(' ');
                printer.put(arg.walkToArray.array);
            }
        }
    }
}

unittest
{
    import mar.sentinel;
    import mar.c : cstring;
    {
        auto proc = ProcBuilder.forExeFile(lit!"/bin/ls");
        auto startResult = proc.startWithClean(SentinelPtr!cstring.nullValue);
        if (startResult.failed)
        {
            import mar.file; stdout.write("proc start failed: %s", startResult);
        }
        else
        {
            import mar.linux.process : wait;
            import mar.file; stdout.write("started ls!\n");
            auto waitResult = wait(startResult.val);
            stdout.write("waitResult is ", waitResult, "\n");
            assert(!waitResult.failed);
        }
    }
    {
        auto proc = ProcBuilder.forExeFile(lit!"a");
        assert(proc.tryPut(lit!"b").passed);
        assert(proc.tryPut(litPtr!"b").passed);
    }
}

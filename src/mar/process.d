module mar.process;

import mar.expect;

version (linux)
{
    static import mar.linux.process;
    import mar.linux.process : pid_t;
    alias wait = mar.linux.process.wait;
}

version (NoExit) {} else
{
    version (linux)
    {
        alias exit = mar.linux.process.exit;
    }
    else version (Windows)
    {
        void exit(uint exitCode)
        {
            pragma(inline, true);
            import mar.windows.kernel32 : ExitProcess;
            ExitProcess(exitCode);
        }
    }
}

version (linux)
    alias ProcID = pid_t;
else version (Windows)
    alias ProcID = int; // TODO: this is not right
else static assert(0, "unsupported platform");

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
        {
            assert (0, "mar.process ProcBuilder.ctor:cstring not impl");
            //this.program = program.walkToArray;
        }
        else version (Posix)
            assert(args.tryPut(program).passed, "out of memory");
    }
    private this(SentinelArray!(const(char)) program)
    {
        version (Windows)
        {
            assert (0, "mar.process ProcBuilder.ctor:SentinelArray not impl");
            //this.program = program;
        }
        else version (Posix)
            assert(args.tryPut(program.ptr).passed, "out of memory");
    }

    auto tryPut(cstring arg)
    {
        version (Windows)
        {
            // TODO: append to args, make sure it is escaped if necessary
            assert (0, "mar.process ProcBuilder.tryPut:cstring not impl");
            import mar.passfail;
            return passfail.fail;
        }
        else version (Posix)
            return args.tryPut(arg);
    }

    version (Windows)
    {
        auto tryPut(SentinelArray!(const(char)) arg)
        {
            assert (0, "mar.process ProcBuilder.tryPut:SentinelArray not impl");
            import mar.passfail;
            return passfail.fail;
        }
    }
    else version (Posix)
    {
        auto tryPut(SentinelArray!(const(char)) arg)
        {
            pragma(inline, true);
            return tryPut(arg.ptr);
        }
    }

    mixin ExpectMixin!("StartResult", ProcID,
        ErrorCase!("outOfMemory", "out of memory"),
        ErrorCase!("forkFailed", "fork failed, returned %", ptrdiff_t));

    /** free memory for arguments */
    void free()
    {
        version (Windows)
            args.free();
        else version (Posix)
            args.free();
    }

    /** Start the process and clean the data structures created to start the process */
    StartResult startWithClean(SentinelPtr!cstring envp)
    {
        auto result = startImpl(envp);
        free();
        return result;
    }
    private StartResult startImpl(SentinelPtr!cstring envp)
    {
        import mar.enforce;

        version (Windows)
        {
            assert (0, "mar.process ProcBuilder.startImpl not impl");
        }
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
                enforce(false, "execve failed");
                //exit( (result.numval == 0) ? 1 : result.numval);
            }
            return StartResult.success(pidResult.val);
        }
    }

    auto print(P)(P printer) const
    {
        version (Windows)
        {
            assert(0, "not impl");
            return P.success;
        }
        else version (Posix)
        {
            // TODO: how to handle args with spaces?
            {
                auto result = printer.put(args.data[0].walkToArray.array);
                if (result.failed)
                    return result;
            }
            foreach (arg; args.data[1 .. $])
            {
                {
                    auto result = printer.putc(' ');
                    if (result.failed)
                        return result;
                }
                {
                    auto result = printer.put(arg.walkToArray.array);
                    if (result.failed)
                        return result;
                }
            }
            return P.success;
        }
    }
}

unittest
{
    import mar.sentinel;
    import mar.c : cstring;

    {
        auto proc = ProcBuilder.forExeFile(lit!"/usr/bin/env");
        auto startResult = proc.startWithClean(SentinelPtr!cstring.nullValue);
        if (startResult.failed)
        {
            import mar.stdio; stdout.write("proc start failed: %s", startResult);
        }
        else
        {
            version (posix)
            {
                import mar.linux.process : wait;
                import mar.stdio; stdout.write("started /usr/bin/env\n");
                auto waitResult = wait(startResult.val);
                stdout.write("waitResult is ", waitResult, "\n");
                assert(!waitResult.failed);
            }
        }
    }
    {
        auto proc = ProcBuilder.forExeFile(lit!"a");
        assert(proc.tryPut(lit!"b").passed);
        assert(proc.tryPut(litPtr!"b").passed);
        import mar.stdio; stdout.writeln(proc);
    }
}

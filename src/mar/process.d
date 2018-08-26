module mar.process;

import mar.sentinel : SentinelPtr;
import mar.c : cstring;

void exit(int exitCode)
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

module mar.sync;

struct CriticalSection
{
    version (linux)
        static assert(0, "not implemented");
    version (Windows)
    {
        
    }
}
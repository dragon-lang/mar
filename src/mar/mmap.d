module mar.mmap;

version (linux)
{
    public import mar.linux.mmap;
}
else version (Windows)
{
    import mar.flag;
    import mar.file : FileD;
    alias off_t = size_t; // todo: this goes somewhere else
    struct MemoryMap
    {
        void* _ptr;
        void* ptr() const { return cast(void*)_ptr; }
        ~this() { unmap(); }
        void unmap()
        {
            if (_ptr)
            {
                assert(0, "unmap not implemented on windows");
                //munmap(_ptr, length);
                _ptr = null;
            }
        }
    }
    MemoryMap createMemoryMap(void* addrHint, size_t length,
        Flag!"writeable" writeable, FileD fd, off_t fdOffset)
    {
        assert(0, "createMemoryMap not implemented on Windows");
    }
}
else static assert(0, "unsupported platform");
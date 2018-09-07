/**
Resource: https://wiki.osdev.org/Calling_Conventions
*/
module mar.start;

version (linux)
{
    version (X86_64)
    {
        enum startMixin = q{
            /**
            STACK (Low to High)
            ------------------------------
            RSP  --> | argc              |
            argv --> | argv[0]           |
                     | argv[1]           |
                     | ...               |
                     | argv[argc] (NULL) |
            envp --> | envp[0]           |
                     | envp[1]           |
                     | ...               |
                     | (NULL)            |
            */
            extern (C) void _start()
            {
                asm
                {
                    naked;
                    xor RBP,RBP;  // zero the frame pointer register
                                  // I think this helps backtraces know the call stack is over
                    //
                    // set argc
                    //
                    pop RDI;      // RDI(first arg to 'main') = argc
                    //
                    // set argv
                    //
                    mov RSI,RSP;  // RSI(second arg to 'main) = argv (pointer to stack)
                    //
                    // set envp
                    //
                    mov RDX,RDI;  // first put the argc count into RDX (where envp will go)
                    add RDX,1;    // add 1 to value from argc (handle one NULL pointer after argv)
                    shl RDX, 3;   // multiple argc by 8 (get offset of envp)
                    add RDX,RSP;  // offset this value from the current stack pointer
                    //
                    // prepare stack for main
                    //
                    add RSP,-8;   // move stack pointer below argc
                    and SPL, 0xF8; // align stack pointer on 8-byte boundary
                    call main;
                    //
                    // exit syscall
                    //
                    mov RDI, RAX;  // syscall param 1 = RAX (return value of main)
                    mov RAX, 60;   // SYS_exit
                    syscall;
                }
            }
        };
    }
    else static assert(0, "start not implemented on linux for this processor");
}
else version (Windows)
{
    /*
    version (X86)
    {
        static assert(0, "TODO: implement start on windows x86!!!!");
    }
    else static assert(0, "start not implemented on windows for this processor");
    */
    enum startMixin = q{
        enum STD_OUTPUT_HANDLE = 0xFFFFFFF5;
        struct HANDLE { uint val; }
        extern (Windows) HANDLE GetStdHandle(uint stdHandle);
        extern (Windows) int WriteFile(HANDLE file, const(char)* data, uint length, uint* written, void* overlapped = null);
        extern (Windows) int mainCRTStartup()
        {
            auto result = GetStdHandle(STD_OUTPUT_HANDLE);
            uint written;
            WriteFile(result, "Hello!".ptr, 6, &written);
            return 0;
        }
    };
}
else static assert(0, "start not implemented for this platform");

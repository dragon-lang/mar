module mar.mem;

version (NoStdc)
{
    public import mar.mem_mmap;
}
else
{
    static import core.stdc.stdlib;
    alias malloc = core.stdc.stdlib.malloc;
    alias free = core.stdc.stdlib.free;
    alias realloc = core.stdc.stdlib.realloc;
    /*
    auto malloc(size_t size)
    {
        auto result = core.stdc.stdlib.malloc(size);
        import mar.io; stdout.writeln("[DEBUG] malloc(", size, ") ", result);
        return result;
    }
    auto free(void* mem)
    {
        import mar.io; stdout.writeln("[DEBUG] free ", mem);
        core.stdc.stdlib.free(mem);
    }
    auto realloc(void* mem, size_t size)
    {
        auto result = core.stdc.stdlib.realloc(mem, size);
        import mar.io; stdout.writeln("[DEBUG] realloc(", mem, ", ", size, ") ", result);
        return result;
    }
    */
    // Returns: true if it resized, false otherwise
    bool tryRealloc(void* mem, size_t size)
    {
        return false;
        /*
        THIS DOESN'T WORK PROPERLY
        if (mem is null)
            return false;
        auto result = realloc(mem, size);
        if (result is mem)
            return true; // success
        // NOTE: this is not ideal
        free(result);
        return false;
        */
    }
}

pragma(inline)
auto reallocOrSave(T)(T* array, size_t newLength, size_t preserveLength)
{
    return cast(T*)reallocOrSaveImpl(array.ptr, newLength * T.sizeof, preserveLength * T.sizeof);
}
pragma(inline)
auto reallocOrSaveArray(T)(T* arrayPtr, size_t newLength, size_t preserveLength)
{
    auto result = reallocOrSaveImpl(arrayPtr, newLength * T.sizeof, preserveLength * T.sizeof);
    if (result is null)
        return null;
    return (cast(T*)result)[0 .. newLength];
}
pragma(inline)
auto reallocOrSave(T)(T[] array, size_t newLength, size_t preserveLength)
{
    auto result = reallocOrSaveImpl(array.ptr, newLength * T.sizeof, preserveLength * T.sizeof);
    if (result is null)
        return null;
    return (cast(T*)result)[0 .. newLength];
}
void* reallocOrSaveImpl(void* mem, size_t newByteSize, size_t preserveByteSize)
{
    import mar.array : acopy;

    if (tryRealloc(mem, newByteSize))
        return mem;

    auto newBuffer = malloc(newByteSize);
    if (!newBuffer)
        return null;
    acopy(newBuffer, mem, preserveByteSize);
    free(mem);
    return newBuffer;
}


version (NoStdc)
{

version (Posix)
{
    version = alloca;

    version (OSX)
        version = Darwin;
    else version (iOS)
        version = Darwin;
    else version (TVOS)
        version = Darwin;
    else version (WatchOS)
        version = Darwin;
}
else version (CRuntime_Microsoft)
{
    version = alloca;
}

// Use DMC++'s alloca() for Win32

version (alloca)
{

/+
#if DOS386
extern size_t _x386_break;
#else
extern size_t _pastdata;
#endif
+/

// for some reason I think the compiler is rewriting references
// from alloca to __alloca
extern (C) void* __alloca(size_t nbyte) { return alloca(nbyte); }

/*******************************************
 * Allocate data from the caller's stack frame.
 * This is a 'magic' function that needs help from the compiler to
 * work right, do not change its name, do not call it from other compilers.
 * Input:
 *      nbytes  number of bytes to allocate
 *      ECX     address of variable with # of bytes in locals
 *              This is adjusted upon return to reflect the additional
 *              size of the stack frame.
 * Returns:
 *      EAX     allocated data, null if stack overflows
 */
extern (C) void* alloca(size_t nbytes)
{
  version (D_InlineAsm_X86)
  {
    asm
    {
        naked                   ;
        mov     EDX,ECX         ;
        mov     EAX,4[ESP]      ; // get nbytes
        push    EBX             ;
        push    EDI             ;
        push    ESI             ;
    }

    version (Darwin)
    {
    asm
    {
        add     EAX,15          ;
        and     EAX,0xFFFFFFF0  ; // round up to 16 byte boundary
    }
    }
    else
    {
    asm
    {
        add     EAX,3           ;
        and     EAX,0xFFFFFFFC  ; // round up to dword
    }
    }

    asm
    {
        jnz     Abegin          ;
        mov     EAX,4           ; // allow zero bytes allocation, 0 rounded to dword is 4..
    Abegin:
        mov     ESI,EAX         ; // ESI = nbytes
        neg     EAX             ;
        add     EAX,ESP         ; // EAX is now what the new ESP will be.
        jae     Aoverflow       ;
    }
    version (Win32)
    {
    asm
    {
        // We need to be careful about the guard page
        // Thus, for every 4k page, touch it to cause the OS to load it in.
        mov     ECX,EAX         ; // ECX is new location for stack
        mov     EBX,ESI         ; // EBX is size to "grow" stack
    L1:
        test    [ECX+EBX],EBX   ; // bring in page
        sub     EBX,0x1000      ; // next 4K page down
        jae     L1              ; // if more pages
        test    [ECX],EBX       ; // bring in last page
    }
    }
    version (DOS386)
    {
    asm
    {
        // is ESP off bottom?
        cmp     EAX,_x386_break ;
        jbe     Aoverflow       ;
    }
    }
    version (Unix)
    {
    asm
    {
        cmp     EAX,_pastdata   ;
        jbe     Aoverflow       ; // Unlikely - ~2 Gbytes under UNIX
    }
    }
    asm
    {
        // Copy down to [ESP] the temps on the stack.
        // The number of temps is (EBP - ESP - locals).
        mov     ECX,EBP         ;
        sub     ECX,ESP         ;
        sub     ECX,[EDX]       ; // ECX = number of temps (bytes) to move.
        add     [EDX],ESI       ; // adjust locals by nbytes for next call to alloca()
        mov     ESP,EAX         ; // Set up new stack pointer.
        add     EAX,ECX         ; // Return value = ESP + temps.
        mov     EDI,ESP         ; // Destination of copy of temps.
        add     ESI,ESP         ; // Source of copy.
        shr     ECX,2           ; // ECX to count of dwords in temps
                                  // Always at least 4 (nbytes, EIP, ESI,and EDI).
        rep                     ;
        movsd                   ;
        jmp     done            ;

    Aoverflow:
        // Overflowed the stack.  Return null
        xor     EAX,EAX         ;

    done:
        pop     ESI             ;
        pop     EDI             ;
        pop     EBX             ;
        ret                     ;
    }
  }
  else version (D_InlineAsm_X86_64)
  {
    version (Win64)
    {
    asm
    {
        /* RCX     nbytes
         * RDX     address of variable with # of bytes in locals
         * Must save registers RBX,RDI,RSI,R12..R15
         */
        naked                   ;
        push    RBX             ;
        push    RDI             ;
        push    RSI             ;
        mov     RAX,RCX         ; // get nbytes
        add     RAX,15          ;
        and     AL,0xF0         ; // round up to 16 byte boundary
        test    RAX,RAX         ;
        jnz     Abegin          ;
        mov     RAX,16          ; // allow zero bytes allocation
    Abegin:
        mov     RSI,RAX         ; // RSI = nbytes
        neg     RAX             ;
        add     RAX,RSP         ; // RAX is now what the new RSP will be.
        jae     Aoverflow       ;

        // We need to be careful about the guard page
        // Thus, for every 4k page, touch it to cause the OS to load it in.
        mov     RCX,RAX         ; // RCX is new location for stack
        mov     RBX,RSI         ; // RBX is size to "grow" stack
    L1:
        test    [RCX+RBX],RBX   ; // bring in page
        sub     RBX,0x1000      ; // next 4K page down
        jae     L1              ; // if more pages
        test    [RCX],RBX       ; // bring in last page

        // Copy down to [RSP] the temps on the stack.
        // The number of temps is (RBP - RSP - locals).
        mov     RCX,RBP         ;
        sub     RCX,RSP         ;
        sub     RCX,[RDX]       ; // RCX = number of temps (bytes) to move.
        add     [RDX],RSI       ; // adjust locals by nbytes for next call to alloca()
        mov     RSP,RAX         ; // Set up new stack pointer.
        add     RAX,RCX         ; // Return value = RSP + temps.
        mov     RDI,RSP         ; // Destination of copy of temps.
        add     RSI,RSP         ; // Source of copy.
        shr     RCX,3           ; // RCX to count of qwords in temps
        rep                     ;
        movsq                   ;
        jmp     done            ;

    Aoverflow:
        // Overflowed the stack.  Return null
        xor     RAX,RAX         ;

    done:
        pop     RSI             ;
        pop     RDI             ;
        pop     RBX             ;
        ret                     ;
    }
    }
    else
    {
    asm
    {
        /* Parameter is passed in RDI
         * Must save registers RBX,R12..R15
         */
        naked                   ;
        mov     RDX,RCX         ;
        mov     RAX,RDI         ; // get nbytes
        add     RAX,15          ;
        and     AL,0xF0         ; // round up to 16 byte boundary
        test    RAX,RAX         ;
        jnz     Abegin          ;
        mov     RAX,16          ; // allow zero bytes allocation
    Abegin:
        mov     RSI,RAX         ; // RSI = nbytes
        neg     RAX             ;
        add     RAX,RSP         ; // RAX is now what the new RSP will be.
        jae     Aoverflow       ;
    }
    version (Unix)
    {
    asm
    {
        cmp     RAX,_pastdata   ;
        jbe     Aoverflow       ; // Unlikely - ~2 Gbytes under UNIX
    }
    }
    asm
    {
        // Copy down to [RSP] the temps on the stack.
        // The number of temps is (RBP - RSP - locals).
        mov     RCX,RBP         ;
        sub     RCX,RSP         ;
        sub     RCX,[RDX]       ; // RCX = number of temps (bytes) to move.
        add     [RDX],RSI       ; // adjust locals by nbytes for next call to alloca()
        mov     RSP,RAX         ; // Set up new stack pointer.
        add     RAX,RCX         ; // Return value = RSP + temps.
        mov     RDI,RSP         ; // Destination of copy of temps.
        add     RSI,RSP         ; // Source of copy.
        shr     RCX,3           ; // RCX to count of qwords in temps
        rep                     ;
        movsq                   ;
        jmp     done            ;

    Aoverflow:
        // Overflowed the stack.  Return null
        xor     RAX,RAX         ;

    done:
        ret                     ;
    }
    }
  }
  else
        static assert(0);
}

}

}
else
{
    alias alloca = core.stdc.stdlib.alloca;
}
module mar.windows.winmm.mmsystem;

/// Equivalent to WAVEHDR
struct WaveHeader
{
    void*       data;
    uint        bufferLength;
    uint        bytesRecorded;
    uint*       user;
    uint        flags;
    uint        loops;
    WaveHeader* next;
    uint*       reserved;
}

/// Equivalent to WOM_*
enum WaveOutputMessage
{
    open = 0x3bb,
    close = 0x3bc,
    done = 0x3bd,
}

/// Equivalent to WIM_*
enum WaveInputMessage
{
    open = 0x3be,
    close = 0x3bf,
    done = 0x3c0,
}

/// Equivalent to HWAVEOUT
struct WaveoutHandle
{
    import mar.wrap;
    import mar.windows : Handle;

    private Handle _handle;
    mixin WrapperFor!"_handle";
    mixin WrapOpCast;
}

/// Equivalent to MMRESULT
struct MultimediaResult
{
    enum Value : uint
    {
        noError          = 0,
        error            = 1,
        badDeviceID      = 2,
        notEnabled       = 3,
        allocated        = 4,
        invaliedHandle   = 5,
        noDriver         = 6,
        nbMem            = 7,
        notSupported     = 8,
        badErrNum        = 9,
        invalidFlag      = 10,
        invalidParam     = 11,
        handleBusy       = 12,
        invalidAlias     = 13,
        badDb            = 14,
        keyNotFound      = 15,
        readError        = 16,
        writeError       = 17,
        deleteError      = 18,
        valNotFound      = 19,
        noDriverCB       = 20,
        waveBadFormat    = 32,
        waveStillPlaying = 33,
        waveUnprepared   = 34
    }
    static auto opDispatch(string member)()
    {
        return MultimediaResult(mixin("Value." ~ member));
    }

    private Value val;
    bool failed() const { pragma(inline, true); return val != Value.noError; }
    bool passed() const { pragma(inline, true); return val == Value.noError; }
    auto print(P)(P printer) const
    {
        pragma(inline, true);
        import mar.print : printArg;
        return printArg(printer, val);
    }
}

/// Equivalent to CALLBACK_* and WAVE_*
enum MuitlmediaOpenFlags : uint
{
    callbackFunction = 0x30000,
}

enum WAVE_MAPPER = cast(void*)cast(ptrdiff_t)-1;

enum : uint
{
    MIM_OPEN      = 961,
    MIM_CLOSE     = 962,
    MIM_DATA      = 963,
    MIM_LONGDATA  = 964,
    MIM_ERROR     = 965,
    MIM_LONGERROR = 966,
    MIM_MOREDATA  = 972,

    MOM_OPEN  = 967,
    MOM_CLOSE = 968,
    MOM_DONE  = 969,
}

/// Equivalent to HMIDIIN
struct MidiInHandle
{
    import mar.wrap;
    import mar.windows : Handle;

    private Handle _handle;
    mixin WrapperFor!"_handle";
    mixin WrapOpCast;
}

/// Equivalent to MIDIHDR
struct MidiHeader
{
    ubyte* data;
    uint size;
    uint recorded;
    uint* user;
    uint flags;
    private MidiHeader* next;
    private uint* reserved1;
    uint offset;
    private uint*[4] reserved2;
}

module mar.windows.winmm;

pragma(lib, "winmm.lib");

import mar.windows.waveout : WaveoutHandle, WaveHeader, WaveFormatEx;

enum MultimediaResult
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
bool failed(MultimediaResult result) { pragma(inline, true); return result != MultimediaResult.noError; }
bool passed(MultimediaResult result) { pragma(inline, true); return result == MultimediaResult.noError; }

enum MuitlmediaOpenFlags : uint
{
    callbackFunction = 0x30000,
}

enum WAVE_MAPPER = cast(void*)cast(ptrdiff_t)-1;

extern (Windows) MultimediaResult waveOutOpen(
    WaveoutHandle* waveout,
    void* deviceID,
    WaveFormatEx* format,
    void* callback,
    void* callbackInstance,
    MuitlmediaOpenFlags flags
);
extern (Windows) MultimediaResult waveOutClose(
    WaveoutHandle     waveout
);
extern (Windows) MultimediaResult waveOutPrepareHeader(
    WaveoutHandle waveout,
    WaveHeader* header,
    uint headerSize
);
extern (Windows) MultimediaResult waveOutUnprepareHeader(
    WaveoutHandle waveout,
    WaveHeader* header,
    uint headerSize
);
extern (Windows) MultimediaResult waveOutWrite(
    WaveoutHandle waveout,
    WaveHeader* header,
    uint headerSize
);


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
struct MidiInHandle
{
    import mar.wrap;
    import mar.windows.types : Handle;

    private Handle _handle;
    mixin WrapperFor!"_handle";
    mixin WrapOpCast;
}

extern (Windows) MultimediaResult midiInOpen(
    MidiInHandle* outHandle,
    uint deviceID,
    void* callback,
    void* callbackArg,
    MuitlmediaOpenFlags flags
);
extern (Windows) MultimediaResult midiInClose(MidiInHandle handle);
extern (Windows) MultimediaResult midiInPrepareHeader(
    MidiInHandle handle,
    MidiHeader* inHeader,
    uint inHeaderSize
);
extern (Windows) MultimediaResult midiInUnprepareHeader(
    MidiInHandle handle,
    MidiHeader* inHeader,
    uint inHeaderSize
);
extern (Windows) MultimediaResult midiInStart(MidiInHandle handle);
extern (Windows) MultimediaResult midiInStop(MidiInHandle handle);
extern (Windows) MultimediaResult midiInAddBuffer(
    MidiInHandle handle,
    MidiHeader* inHeader,
    uint inHeaderSize
);

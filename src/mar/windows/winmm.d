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

enum WaveoutOpenFlags : uint
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
   WaveoutOpenFlags flags
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
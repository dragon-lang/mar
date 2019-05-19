module mar.windows.winmm.link;

pragma(lib, "winmm.lib");

import mar.windows.winmm.nolink;

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

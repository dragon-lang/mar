module mar.windows.winmm.mmreg;

/// Equivalent to WAVE_FORMAT_*
enum WaveFormatTag : ushort
{
    unknown = 0,
    pcm     = 1,
    float_  = 3,
    extensible = 0xfffe,
}

/// Equivalent to WAVEFORMATEX
struct WaveFormatEx
{
align(2):
    WaveFormatTag tag;
    ushort  channelCount;
    uint    samplesPerSec;
    uint    avgBytesPerSec;
    ushort  blockAlign;
    ushort  bitsPerSample;
    ushort  extraSize;
}
static assert(WaveFormatEx.sizeof == 18);

/// Equivalent to SPEAKER_*
enum SpeakerFlags : uint
{
    frontLeft   = 0x0001,
    frontRight  = 0x0002,
    frontCenter = 0x0004,
}

/// Equivalent to WAVEFORMATEXTENSIBLE 
struct WaveFormatExtensible
{
align(2):
    import mar.windows : Guid;

    WaveFormatEx format;
    union
    {
        ushort validBitsPerSample;
        ushort samplesPerBlock;
    }
    SpeakerFlags channelMask;
    Guid subFormat;
}

/// Equivalent to KSDATAFORMAT_SUBTYPE_*
struct KSDataFormat
{
    import mar.windows : Guid;
    static __gshared immutable ieeeFloat = Guid.fromString!"00000003-0000-0010-8000-00aa00389b71";
}

module mar.windows.waveout;

enum WaveFormatTag : ushort
{
    pcm = 1,
    float_ = 3,
    extensible = 0xfffe,
}

struct WaveoutHandle
{
    import mar.wrap;
    import mar.windows : Handle;

    private Handle _handle;
    mixin WrapperFor!"_handle";
    mixin WrapOpCast;
}

align(2):
struct WaveFormatEx
{
  WaveFormatTag tag;
  ushort  channelCount;
  uint    samplesPerSec;
  uint    avgBytesPerSec;
  ushort  blockAlign;
  ushort  bitsPerSample;
  ushort  extraSize;
}
static assert(WaveFormatEx.sizeof == 18);

enum ChannelFlags : uint
{
    frontLeft   = 0x0001,
    frontRight  = 0x0002,
    frontCenter = 0x0004,
}

struct KSDataFormat
{
    import mar.windows : Guid;
    static __gshared immutable ieeeFloat = Guid.fromString!"00000003-0000-0010-8000-00aa00389b71";
}

struct WaveFormatExtensible
{
    import mar.wrap;
    import mar.windows : Guid;

    WaveFormatEx format;
    union
    {
        ushort validBitsPerSample;
        ushort samplesPerBlock;
    }
    ChannelFlags channelMask;
    Guid subFormat;
}

struct WaveHeader
{
    void*          data;
    uint           bufferLength;
    uint           bytesRecorded;
    uint*          user;
    uint           flags;
    uint           loops;
    WaveHeader*    next;
    uint*          reserved;
}

enum WaveOutputMessage
{
    open = 0x3bb,
    close = 0x3bc,
    done = 0x3bd,
}
enum WaveInputMessage
{
    open = 0x3be,
    close = 0x3bf,
    done = 0x3c0,
}

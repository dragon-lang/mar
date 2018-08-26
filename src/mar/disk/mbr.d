module mar.disk.mbr;

import mar.endian : LittleEndianOf, BigEndianOf, toBigEndian;

/**
Implements an API to manage disks using the MBR partition format.
*/

struct ChsAddress
{
    ubyte[3] value;
    void setDefault()
    {
        value[] = 0;
    }
}

struct PartitionType
{
    enum Value : ubyte
    {
        empty                   = 0x00,
        linuxSwapOrSunContainer = 0x82,
        linux                   = 0x83,
    }
    private Value value;
    Value enumValue() const { return value; }
    string name() const
    {
        import mar.conv : asString;
        return asString(value, "?");
    }
    template opDispatch(string name)
    {
        enum opDispatch = PartitionType(__traits(getMember, Value, name));
    }
}

enum PartitionStatus : ubyte
{
    none,
    bootable = 0x80,
}

struct PartitionOnDiskFormat
{
  align(1):
    PartitionStatus status;
    ChsAddress firstSectorChs;
    PartitionType type;
    ChsAddress lastSectorChs;
    LittleEndianOf!uint firstSectorLba;
    LittleEndianOf!uint sectorCount;

    bool bootable() const { return status == 0x80; }
}
static assert(PartitionOnDiskFormat.sizeof == 16);

enum BootstrapSize = 446;

struct OnDiskFormat
{
  align(1):
    ubyte[BootstrapSize] bootstrap;
    PartitionOnDiskFormat[4] partitions;
    ubyte[2] bootSignature;

    void setBootSignature()
    {
        *(cast(ushort*)bootSignature.ptr) = toBigEndian!ushort(0x55AA).getRawValue;
    }

    ubyte[512]* bytes() const { return cast(ubyte[512]*)&this; }
    BigEndianOf!ushort bootSignatureValue() const
    {
        return BigEndianOf!ushort(*(cast(ushort*)bootSignature.ptr));
    }
    bool signatureIsValid() const
    {
        return bootSignatureValue() == toBigEndian!ushort(0x55AA);
    }
}
static assert(OnDiskFormat.sizeof == 512);

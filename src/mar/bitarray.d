module more.bitarray;

struct BitArray(bool IsFixed)
{
    enum BitsPerSizet = size_t.sizeof * 8;

    private ArrayBuilder!size_t array;
    private size_t bitLength;

    bool get(size_t index) const
    in {
        static if (IsFixed)
            assert(index < bitLength, "bit index out of bounds");
    } do
    {
        auto arrayIndex = index / BitsPerSizet;
        static if (!IsFixed)
        {
            if (arrayIndex >= array.length)
                return false;
        }
        return 0 != (array[arrayIndex] & (cast(size_t)1 << (index % BitsPerSizet)));
    }
    /*
    void enable(size_t index)
    {
        
    }
    */
}
alias FixedBitArray = BitArray!true;
alias DynamicBitArray = BitArray!true;

unittest
{
    {
        auto ba = BitArray();
    }
}
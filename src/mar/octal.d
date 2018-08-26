module mar.octal;

template octal(string literal)
{
    version (D_BetterC)
    {
        static assert(0, "this octal template is not supported in betterC right now");
        /*
        enum octal = (){
            return cast(string)octalToHex(literal);
        }();
        */
    }
    else
    {
        enum octal = mixin(octalToHex(literal));
    }
}

ubyte octalCharToValue(char c)
in { assert(c <= '7' && c >= '0', "invalid octal digit"); } do
{
    return cast(ubyte)(c - '0');
}
private char toHexChar(T)(T value)
in { assert(value <= 0xF, "value is too large to be a hex character"); } do
{
    return cast(char)(value + ((value <= 9) ? '0' : ('A' - 10)));
}


version (D_BetterC) { } else
{
    char[] octalToHex(string octLit)
    in { assert(octLit.length > 0); } do
    {
        auto hexDigitCount = 2 + (octLit.length + 1) * 3 / 4;
        auto hexLit = new char[hexDigitCount];
        octalToHexImpl(hexLit, octLit.ptr, octLit.length);
        return hexLit;
    }
}

private void octalToHexImpl(char[] hexLit, const(char)* octLit, size_t octLength)//[] octLit)
{
    size_t hexIndex = hexLit.length - 1;
    for (; octLength >= 4; octLength -= 4)
    {
        const _3 = octLit[octLength - 1].octalCharToValue;
        const _2 = octLit[octLength - 2].octalCharToValue;
        const _1 = octLit[octLength - 3].octalCharToValue;
        const _0 = octLit[octLength - 4].octalCharToValue;
        hexLit[hexIndex--] = toHexChar(((_2 & 0b001) << 3) | ((_3        )     ));
        hexLit[hexIndex--] = toHexChar(((_1 & 0b011) << 2) | ((_2 & 0b110) >> 1));
        hexLit[hexIndex--] = toHexChar(((_0        ) << 1) | ((_1 & 0b100) >> 2));
    }

    switch (octLength)
    {
    case 0: break;
    case 1:
        hexLit[hexIndex--] = toHexChar(octLit[0].octalCharToValue);
        break;
    case 2:
        {
            const temp = octLit[0].octalCharToValue;
            hexLit[hexIndex--] = toHexChar(((temp & 0b001) << 3) | octLit[1].octalCharToValue);
            hexLit[hexIndex--] = toHexChar(                        ((temp & 0b110) >> 1));
            break;
        }
    case 3:
        {
            const temp0 = octLit[0].octalCharToValue;
            const temp1 = octLit[1].octalCharToValue;
            hexLit[hexIndex--] = toHexChar(((temp1 & 0b001) << 3) | octLit[2].octalCharToValue);
            hexLit[hexIndex--] = toHexChar(((temp0 & 0b011) << 2) | ((temp1 & 0b110) >> 1));
            hexLit[hexIndex--] = toHexChar(                         ((temp0 & 0b100) >> 2));
            break;
        }
    default: assert(0, "code bug");
    }

    assert(hexIndex == 1, "code bug");
    hexLit[1] = 'x';
    hexLit[0] = '0';
}

unittest
{
    assert("0x0"   == "0".octalToHex);
    assert("0x1"   == "1".octalToHex);
    assert("0x0"   == "0".octalToHex);
    assert("0x7"   == "7".octalToHex);
    assert("0x08"  == "10".octalToHex);
    assert("0x38"  == "70".octalToHex);
    assert("0x1C0" == "700".octalToHex);
    assert("0xFFF" == "7777".octalToHex);
    assert("0x053977" == "1234567".octalToHex);
    assert("0x0000A" == "000012".octalToHex);
}


template octalDec(alias decimalValue)
{
    enum octalDec = decimalToOctal(decimalValue);
}

// take a value written using decimal digits and interpret
// it as if it was written in octal.
auto decimalToOctal(T)(T value)
{
    T result = 0;
    ushort shift = 0;
    for (; value > 0; value /= 10)
    {
        auto mod10 = value % 10;
        if (mod10 > 7)
            assert(0, "decimal value contains non-octal digits");
        result |= (mod10 << shift);
        shift += 3;
    }
    return result;
}

unittest
{
    assert(0b000_000 == decimalToOctal(00));
    assert(0b000_111 == decimalToOctal(07));
    assert(0b001_000 == decimalToOctal(10));
    assert(0b001_111 == decimalToOctal(17));
    assert(0b010_000 == decimalToOctal(20));
    assert(0b010_111 == decimalToOctal(27));
}

/**
Using a hex literal, get the value interpreting it as if it is an octal litera.
Example:
---
assert(01234 == octalHex!01234);
---
*/
template octalHex(alias hexValue)
{
    enum octalHex = hexToOctal(hexValue);
}

// take a value written using decimal digits and interpret
// it as if it was written in octal.
auto hexToOctal(T)(T value)
{
    T result = 0;
    ushort shift = 0;
    for (; value > 0; value >>= 4)
    {
        auto mod = value & 0b1111;
        if (mod > 7)
            assert(0, "hex value contains non-octal digits");
        result |= (mod << shift);
        shift += 3;
    }
    return result;
}

unittest
{
    assert(0b000_000 == hexToOctal(0x00));
    assert(0b000_111 == hexToOctal(0x07));
    assert(0b001_000 == hexToOctal(0x10));
    assert(0b001_111 == hexToOctal(0x17));
    assert(0b010_000 == hexToOctal(0x20));
    assert(0b010_111 == hexToOctal(0x27));
}

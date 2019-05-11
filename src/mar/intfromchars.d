/**
A small module that creates integers from strings.
*/
module mar.intfromchars;

/**
Creates a single integer from a string of ascii characters.

Example
---
assert(0x61626364 == IntFromChars!"abcd");
---
*/
template IntFromChars(string chars)
{
    enum IntFromChars = mixin((){
        string hexTable = "0123456789abcdef";
        auto result = new char[2 + (2 * chars.length)];
        result[0 .. 2] = "0x";
        foreach (i; 0 .. chars.length)
        {
            result[2 + (2 * i) + 0] = hexTable[(chars[i] >> 4) & 0xF];
            result[2 + (2 * i) + 1] = hexTable[(chars[i] >> 0) & 0xF];
        }
        return result;
    }());
}
unittest
{
    assert(0x61 == IntFromChars!"a");
    assert(0x5a == IntFromChars!"Z");
    assert(0x61626364 == IntFromChars!"abcd");
}
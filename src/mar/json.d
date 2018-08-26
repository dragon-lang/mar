/**
 * A Stupid Simple Json Parser
 *
 * Note: this json implementation was included so JSON objects could be parsed
 *       while maintaining the original member order.
 */
module json;

import std.exception : assumeUnique;
import std.conv : to;
import std.algorithm : filter, startsWith;
import std.range : walkLength;
import std.bigint;
import std.format : format;
import std.ascii : isWhite;

enum JsonType
{
    null_, bool_, string, number, object, array
}
struct JsonObjectMember
{
    string name;
    JsonValue value;
}
struct JsonObjectMemberReference
{
    string name;
    JsonValue* value;
    bool isNull() const { return name is null; }
}
struct JsonObject
{
    JsonObjectMember[] members;
    auto getRef(string name) const
    {
        foreach (ref member; members)
            if (member.name == name)
                return JsonObjectMemberReference(member.name, cast(JsonValue*)&member.value);
        assert(0, "json object is missing property: " ~ name);
    }
    auto tryGetRef(string name)
    {
        foreach (ref member; members)
            if (member.name == name)
                return JsonObjectMemberReference(member.name, &member.value);
        return JsonObjectMemberReference(null);
    }
    auto getAs(T)(string name) const
    {
        return getRef(name).value.as!T();
    }
    auto ref tryGetAs(T)(string name, T ifMissingValue) const
    {
        foreach (member; members)
            if (member.name == name)
                return member.value.as!T;

        return ifMissingValue;
    }
    void setExisting(string name, JsonValue value)
    {
        *getRef(name).value = value;
    }
    void overrideIfExists(string name, JsonValue value)
    {
        auto member = tryGetRef(name);
        if(!member.isNull)
        {
            *member.value = value;
        }
    }
    auto membersByRef() const
    {
        static struct Range
        {
            JsonObjectMember[] members;
            size_t next;
            bool empty() const { return next >= members.length; }
            auto ref front() { return members[next]; }
            void popFront() { next++; }
        }
        return Range(cast(JsonObjectMember[])members, 0);
    }
}
struct JsonValue
{
    @property static JsonValue null_() { return JsonValue(JsonType.null_); }
    union
    {
        bool boolData;
        BigInt bigIntData;
        string stringData;
        JsonObject objectData;
        JsonValue[] arrayData;
    }
    JsonType type;
    private this(JsonType type) { this.type = type; }
    this(bool boolData) { this.boolData = boolData; this.type = JsonType.bool_; }
    this(string stringData) { this.stringData = stringData; this.type = JsonType.string; }
    this(BigInt bigIntData) { this.bigIntData = bigIntData; this.type = JsonType.number; }
    this(JsonObject objectData) { this.objectData = objectData; this.type = JsonType.object; }
    this(JsonValue[] arrayData) { this.arrayData = arrayData; this.type = JsonType.array; }
    auto as(T)() inout
    {
        static if( is(T == bool) )
        {
            assert(type == JsonType.bool_, "expected json value to be a boolean but got " ~ type.to!string);
            return boolData;
        }
        else static if( is(T == string) )
        {
            assert(type == JsonType.string, "expected json value to be a string but got " ~ type.to!string);
            return stringData;
        }
        else static if( is(T == JsonValue[]) )
        {
            assert(type == JsonType.array, "expected json value to be an array but got " ~ type.to!string);
            return arrayData;
        }
        else static if( is(T == JsonObject) )
        {
            assert(type == JsonType.object, "expected json value to be an object but got " ~ type.to!string);
            return objectData;
        }
        else static assert(0);
    }
    auto array() inout { return as!(JsonValue[])(); }
    auto object() inout { return as!(JsonObject)(); }
}
JsonValue parseJson(string text, string filenameForErrors)
{
    auto parser = JsonParser(text.ptr, text.ptr, filenameForErrors);
    auto value = parser.parseValue();
    parser.skipWhitespace();
    if (*parser.next != '\0')
        throw parser.parseError(parser.line(parser.next), "invalid json, multiple root values");
    return value;
}

class JsonParseException : Exception
{
    this(string msg, string file, size_t line) { super(msg, file, line); }
}
auto asRange(T,U)(T* ptr, U* limit)
{
    static struct Range
    {
        T* ptr;
        U* limit;
        bool empty() const { return ptr >= limit; }
        auto front() { return *ptr; }
        void popFront() { ptr++; }
    }
    return Range(ptr, limit);
}
@property auto asRange(const(char)* ptr)
{
    static struct Range
    {
        const(char)* ptr;
        bool empty() const { return *ptr == '\0'; }
        char front() const { return *ptr; }
        void popFront() { ptr++; }
    }
    return Range(ptr);
}
struct JsonParser
{
    immutable(char)* start;
    immutable(char)* next;
    string filenameForErrors;
    size_t line(immutable(char)* src)
    {
        return 1 + filter!(a => (a == '\n'))(start.asRange(src)).walkLength;
    }
    void skipWhitespace()
    {
        for (; isWhite(*next); next++) { }
    }
    JsonParseException parseError(T...)(size_t lineNumber, T args)
    {
        return new JsonParseException(format(args), filenameForErrors, lineNumber);
    }
    JsonValue parseValue()
    {
        skipWhitespace();
        if (*next == '[')
        {
            next++;
            return JsonValue(parseArray());
        }
        if (*next == '{')
        {
            next++;
            return JsonValue(parseObject());
        }
        if (*next == '"')
        {
            next++;
            return JsonValue(parseString());
        }
        if (next.asRange.startsWith("null"))
        {
            next += 4;
            return JsonValue.null_;
        }
        if (next.asRange.startsWith("true"))
        {
            next += 4;
            return JsonValue(true);
        }
        if (next.asRange.startsWith("false"))
        {
            next += 5;
            return JsonValue(false);
        }
        if (*next == '-' || (*next >= '0' && *next <= '9'))
            return JsonValue(parseNumber());

        if (*next == '\0')
            throw parseError(line(next), "expected value but reached EOF");

        throw parseError(line(next), "expected value but got '%s' (0x%x)",
            *next, cast(ubyte)*next);
    }
    JsonValue[] parseArray()
    {
        JsonValue[] array;
        skipWhitespace();
        if (*next != ']')
        {
            for (;;)
            {
                array ~= parseValue();
                skipWhitespace();
                if (*next == ']')
                    break;
                if (*next != ',')
                    throw parseError(line(next), "expected comma ',' but got '%s' (0x%x)", *next, cast(ubyte)*next);
                next++;
                skipWhitespace();
           }
        }
        next++;
        return array;
    }
    JsonObject parseObject()
    {
        JsonObject object;
        skipWhitespace();
        if (*next != '}')
        {
            for(;;)
            {
                if (*next != '"')
                    throw parseError(line(next), "expected object property but got '%s' (0x%x)",
                        *next, cast(ubyte)*next);
                next++;
                auto name = parseString();
                skipWhitespace();
                if (*next != ':')
                    throw parseError(line(next), "all property names must be followed by a colon ':'");
                next++;
                object.members ~= JsonObjectMember(name, parseValue);
                skipWhitespace();
                if (*next == '}')
                    break;
                if (*next != ',')
                    throw parseError(line(next), "expected comma ',' but got '%s' (0x%x)", *next, cast(ubyte)*next);
                next++;
                skipWhitespace();
            }
        }
        next++;
        return object;
    }
    string parseString()
    {
        auto start = next;
        size_t escapeExtras = 0;
        for(;; next++)
        {
            if (*next == '\\')
            {
                next++;
                if (*next == 'u')
                {
                    next += 4;
                    escapeExtras += 5;
                }
                else
                {
                    escapeExtras += 1;
                }
            }
            else if (*next == '"')
               break;
        }
        auto str = start[0 .. next - start];
        next++;
        if (escapeExtras == 0)
            return str;

        auto unescaped = new char[str.length - escapeExtras];
        unescape(str, unescaped.ptr);
        return assumeUnique(unescaped);
    }
    BigInt parseNumber()
    {
        bool negative;
        if (*next == '-')
        {
            negative = true;
            next++;
        }
        auto start = next;
        for (;; next++)
        {
            if ((*next < '0' || *next > '9') && *next != '.')
                break;
        }
        auto result = BigInt(start[0 .. next - start]);
        if (negative)
            result *= -1;
        return result;
    }
}
void unescape(const(char)[] src, char* dst)
{
    for (size_t i = 0; i < src.length; i++, dst++)
    {
        if (src[i] == '\\')
        {
            i++;
            if (src[i] == '"')
                *dst = '"';
            else if (src[i] == '\\')
                *dst = '\\';
            else if (src[i] == 't')
                *dst = '\t';
            else if (src[i] == 'n')
                *dst = '\n';
            else if (src[i] == 'r')
                *dst = '\r';
            else if (src[i] == '/')
                *dst = '/';
            else if (src[i] == 'b')
                *dst = '\b';
            else if (src[i] == 'f')
                *dst = '\f';
            else if (src[i] == 'u')
                assert(0, "not implemented");
            else
                assert(0, "invalid JSON escape");
        }
        else
        {
            *dst = src[i];
        }
    }
}
auto formatEscaped(const(char)[] str)
{
    static struct Formatter
    {
        const(char)* str;
        const(char)* limit;
        void toString(scope void delegate(const(char)[]) sink)
        {
            auto save = str;
            for(; str < limit; str++)
            {
                string escapeSequence = void;
                if (*str == '"')
                    escapeSequence = `\"`;
                else if (*str == '\\')
                    escapeSequence = `\\`;
                else if (*str == '\t')
                    escapeSequence = `\t`;
                else if (*str == '\n')
                    escapeSequence = `\n`;
                else if (*str == '\r')
                    escapeSequence = `\r`;
                else if (*str == '\b')
                    escapeSequence = `\b`;
                else if (*str == '\f')
                    escapeSequence = `\f`;
                else
                    continue;
                sink(save[0 .. str - save]);
                sink(escapeSequence);
                save = str + 1;
            }
            sink(save[0 .. limit - save]);
        }
    }
    return Formatter(str.ptr, str.ptr + str.length);
}

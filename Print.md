# Print API

Mar has its own API to support data conversion to text.

### Printer

An object that accepts text and/or text operations to print.  It must have the following methods:

```D
void flush();
void put(const(char)[] str);
void putc(const char c);

auto getTempBuffer(size_t size)();
auto tryGetTempBufferImpl(size_t size);
void commitBuffer(DefaultPrinterBuffer buf);
```

### Print Method

To allow an object to be converted to text, it must implement the `print` function, i.e.

```D
struct Point
{
    int x;
    int y;
    void print(P)(P printer) const
    {
        import mar.print : printDecimal;
        printDecimal(printer, x);
        printer.putc(',');
        printDecimal(printer, y);
    }
}
```

### sprint functions

```D
// print args into dest buffer
size_t sprint(T...)(char[] dest, T args);

// get print size by printing to a "no-op" printer and tracking the number of character printed
size_t getPrintSize(T...)(T args);

// print and allocate a string for args
char[] sprintMallocNoSentinel(T...)(T args);

// print and allocate a string for args that is null-terminated
SentinelArray!char sprintMallocSentinel(T...)(T args);
```

### Multiple print methods

By default the `print` method will be used on an object, but you can support multiple formats, i.e.

```D
static struct Point
{
    int x;
    int y;
    void print(P)(P printer) const
    {
        import mar.print;
        printDecimal(printer, x);
        printer.putc(',');
        printDecimal(printer, y);
    }
    auto formatHex() const
    {
        static struct Print
        {
            const(Point)* p;
            void print(P)(P printer) const
            {
                import mar.print;
                printer.put("0x");
                printHex(printer, p.x);
                printer.putc(',');
                printer.put("0x");
                printHex(printer, p.y);
            }
        }
        return Print(&this);
    }
}

auto p = Point(10, 18);
stdout.writeln(p);           // prints "10,18"
stdout.writeln(p.formatHex); // prints "0xa,0x12"
```

### Template Bloat

If you have a large project and are concerned with the template bloat from having alot of `print` method/`printer` combinations you can alleviate this by reducing the number of printers.  You can reduce the number of printers by wrapping multiple kinds of printers with a common type. In fact, you could wrap all printers with a common interface which would cause only 1 `print` method to be instantiated per object.  This API allows applications to have full control over the balance between "code specialization" and "code bloat".

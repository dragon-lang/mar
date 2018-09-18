module mar.path;

auto baseNameSplitIndex(T)(T path)
{
    size_t i = path.length;
    for (; i > 0;)
    {
        i--;
        if (path[i] == '/')
        {
            i++;
            break;
        }
    }
    return i;
}

auto dirName(T)(T path)
{
    return path[0 .. baseNameSplitIndex(path)];
}
auto baseName(T)(T path)
{
    return path[baseNameSplitIndex(path) .. $];
}

/**
Example:
---
foreach (dir; SubPathIterator("/foo/bar//baz/bon"))
{
    stdout.writeln(dir);
}
/*
prints:
/foo/
/foo/bar//
/foo/bar//baz/
/foo/bar//baz/bon
---
*/
struct SubPathIterator
{
    static bool isValidStartIndex(const(char)[] dir, size_t index)
    {
        return
            index == 0 ||
            index == dir.length ||
            (dir[index - 1] == '/' && dir[index] != '/');
    }

    const(char)[] current;
    size_t limit;

    /**
    start must point to
    1) 0
    2) dir.length
    3) after a group of directory separators
    Examples: valid start offsets marked with *
    ---
    foo/bar//baz
    *   *    *  *
    0   4    9  12
    
    /apple/tree
    **     *
    01     7
    ---
    */
    this(const(char)[] dir, size_t start = 0)
    in { assert(isValidStartIndex(dir, start), "codebug: SubPathIterator, invalid start index"); } do
    {
        this.current = dir[0 .. start];
        this.limit = dir.length;
        popFront();
    }
    bool empty() const { return current is null; }
    auto front() const { return current; }
    void popFront()
    {
        auto next = current.length;
        if (next == limit)
        {
            current = null;
            return;
        }

        for (;;)
        {
            if (current.ptr[next] == '/')
            {
                // skip extra '/'
                for(;;)
                {
                    next++;
                    if (next == limit || current.ptr[next] != '/')
                        break;
                }
                break;
            }
            next++;
            if (next >= limit)
                break;
        }
        current = current.ptr[0 .. next];
    }
}

unittest
{
    static void test(string path, string[] dirs...)
    {
        size_t dirIndex = 0;
        foreach (dir; SubPathIterator(path))
        {
            assert(dir == dirs[dirIndex]);
            dirIndex++;
        }
    }
    test("/foo/bar//baz/bon", "/", "/foo/", "/foo/bar//", "/foo/bar//baz/", "/foo/bar//baz/bon");

    test("", null);
    test("/", "/");
    test("a", "a");
    test("//", "//");
    test("/a", "/", "/a");
    test("/a/", "/", "/a/");
    test("//a", "//", "//a");
    test("//a/", "//", "//a/");
    test("//a//", "//", "//a//");
    test("///a///", "///", "///a///");
    test("///foo///", "///", "///foo///");
    test("///foo///bar", "///", "///foo///", "///foo///bar");
    test("///foo///bar/", "///", "///foo///", "///foo///bar/");
    test("///foo///bar//", "///", "///foo///", "///foo///bar//");
}

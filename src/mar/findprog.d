module mar.findprog;

import mar.sentinel : litPtr, assumeSentinel;
import mar.c : cstring;
import mar.file : fileExists;

bool usePath(T)(T program)
{
    auto slashIndex = program.indexOf('/');
    return slashIndex == slashIndex.max;
}

cstring findProgram(cstring pathEnv, const(char)[] program)
{
    return findProgramIn(PathIterator(pathEnv), program);
}
cstring findProgramIn(T)(T pathRange, const(char)[] program)
{
    foreach (path; pathRange)
    {
        auto result = getFileIfExists(path, program);
        if (!result.isNull)
            return result;
    }
    return cstring.nullValue;
}

// We make a separate function so we can alloca the function
cstring getFileIfExists(const(char)[] dir, const(char)[] basename)
{
    // TODO: use alloca?
    import mar.mem : free;
    import mar.format : sprintMallocSentinel;
    auto temp = sprintMallocSentinel(dir, "/", basename);
    //import mar.file; print(stdout, "[DEBUG] checking '", temp, "'...\n");
    if (fileExists(temp.ptr))
        return temp.ptr;

    free(temp.ptr.raw);
    return cstring.nullValue;
}

struct PathIterator
{
    const(char)[] current;
    this(cstring pathEnv)
    {
        this.current = pathEnv[0 .. 0];
    }
    bool empty() const { return current.ptr == null; }
    auto front() const { return current; }
    void popFront()
    {
        auto next = current.ptr + current.length;
        for (; next[0] == ':'; next++)
        { }

        if (next[0] == '\0')
            this.current = null;
        else
        {
            auto end = next + 1;
            for (;; end++)
            {
                auto c = end[0];
                if (c == ':' || c == '\0')
                    break;
            }
            this.current = next[0 .. end - next];
        }
    }
}

unittest
{
    // TODO: add unittests for PathIterator
}
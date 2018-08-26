module mar.flag;

template Flag(string name)
{
    enum Flag : bool
    {
        no = false, yes = true
    }
}

struct Yes
{
    template opDispatch(string name)
    {
        enum opDispatch = Flag!name.yes;
    }
}

struct No
{
    template opDispatch(string name)
    {
        enum opDispatch = Flag!name.no;
    }
}

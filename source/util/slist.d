module util.slist;

public import core.experimental.slist : rcslist;
public import containers : EMSISList = SList;
public import std.container : StdSList = SList;
public import stlwrappers : StdForwardListWrapper = ForwardListWrapper;

public import core.experimental.slist : make;

T make(T : StdSList!U, U)()
{
    return T();
}

T make(T : EMSISList!U, U)()
{
    return T();
}

T make(T : StdForwardListWrapper!U, U)()
{
    import stlwrappers : makeSizeTForwardListWrapper;

    static if (is(U == size_t))
    {
        return makeSizeTForwardListWrapper();
    }
    else
    {
        static assert(0);
    }
}

void removeFront(T : EMSISList!U, U)(ref T container)
{
    container.popFront();
}


void remove(T : StdSList!U, U, V)(ref T container, V value)
if (is(V : U))
{
    container.linearRemoveElement(value);
}

T makeAndInsert(size_t size, T)()
{
    T t = make!T();

    foreach (i; 0 .. size)
    {
        t.insertFront(i);
    }

    return t;
}

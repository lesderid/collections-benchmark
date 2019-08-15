module util.array;

public import core.experimental.array : rcarray;
public import std.container : StdArray = Array;
public import containers : EMSIArray = DynamicArray;
public import stdx.collections.array : StdxArray = Array;
public import stlwrappers : StdVectorWrapper = VectorWrapper;

public import core.experimental.array : make;

T make(T : U[], U)()
{
    return [];
}

T make(T : StdArray!U, U)()
{
    enum U[] empty = [];

    import std.container : stdMake = make;
    return stdMake!T(empty);
}

T make(T : EMSIArray!U, U)()
{
    return T();
}

T make(T : StdxArray!U, U)()
{
    return T();
}

T make(T : StdVectorWrapper!U, U)()
{
    import stlwrappers : makeSizeTVectorWrapper, makeInt32VectorWrapper;

    static if (is(U == size_t))
    {
        return StdVectorWrapper!U();
    }
    else static if (is(U == int))
    {
        return makeInt32VectorWrapper();
    }
    else
    {
        static assert(0);
    }
}

void append(T, U)(ref T container, auto ref U elem)
{
    static if (is(T == StdVectorWrapper!U, U : V, V))
    {
        container.insert(elem);
    }
    else
    {
        container ~= elem;
    }
}

auto ref concat(T)(ref T lhs, ref T rhs)
{
    static if (is(T == StdVectorWrapper!U, U))
    {
        return lhs.newFromConcat(&rhs);
    }
    else
    {
        return lhs ~ rhs;
    }
}

T makeAndInsert(size_t size, T)()
{
    T t = make!T();

    foreach (i; 0 .. size)
    {
        t.append(42);
    }

    return t;
}

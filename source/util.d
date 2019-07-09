module util;

public import core.experimental.array : rcarray;
public import std.container : StdArray = Array;
public import containers : EMSIArray = DynamicArray;
public import stdx.collections.array : StdxArray = Array;

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

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

T makeAndInsert(T, size_t size = 100)()
{
    T t = make!T();

    static foreach (i; 0 .. size)
    {
        t ~= 42;
    }

    return t;
}

T[2] makeAndInsert2(T, size_t totalSize = 100)()
{
    T a = make!T();
    T b = make!T();

    static foreach (i; 0 .. totalSize / 2)
    {
        a ~= 1;
        b ~= 2;
    }

    return [a, b];
}

import core.time : Duration;
import std.datetime.stopwatch : StopWatch, AutoStart;
Duration[funs.length / 2] benchmarkWithSetup(funs...)(uint n)
{
    Duration[funs.length / 2] result;

    auto sw = StopWatch(AutoStart.no);

    static foreach (i; 0 .. funs.length / 2)
    {{
        alias fun = funs[i * 2];
        alias setup = funs[i * 2 + 1];

        sw.reset();
        foreach (_; 0 .. n)
        {
            static if (is(typeof(setup()) == void))
            {
                sw.start();
                fun();
            }
            else
            {
                auto setupResult = setup();
                sw.start();
                fun(setupResult);
            }

            sw.stop();
        }
        result[i] = sw.peek();
    }}

    return result;
}

template Transpose(size_t N, alias A, Args...)
{
    import std.meta : AliasSeq;
    static assert(N == 2);

    static if (Args.length == 1)
    {
        alias Transpose = AliasSeq!(A, Args[0]);
    }
    else
    {
        alias Transpose = AliasSeq!(A, Args[(Args.length - 1) / 2], Transpose!(N, Args[0], Args[1 .. (Args.length - 1) / 2], Args[(Args.length - 1) / 2 + 1 .. $]));
    }
}

void noSetup(T)() {}

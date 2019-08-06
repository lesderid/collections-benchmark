module util;

public import core.experimental.array : rcarray;
public import std.container : StdArray = Array;
public import containers : EMSIArray = DynamicArray;
public import stdx.collections.array : StdxArray = Array;
public import stlwrappers : StdVectorWrapper = VectorWrapper, StdUnorderedMapWrapper = UnorderedMapWrapper;

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

T make(T : StdUnorderedMapWrapper!(K, V), K, V)()
{
    import stlwrappers : makeIntByteUnorderedMapWrapper;

    static if (is(K == int) && is(V == byte))
    {
        return makeIntByteUnorderedMapWrapper();
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

T[2] makeAndInsert2(size_t totalSize, T)()
{
    T a = make!T();
    T b = make!T();

    foreach (i; 0 .. totalSize / 2)
    {
        a.append(1);
        b.append(2);
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
    {
        sw.reset();
        foreach (_; 0 .. n)
        {
            alias fun = funs[i * 2];
            alias setup = funs[i * 2 + 1];

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
    }

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

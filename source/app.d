import util : make, rcarray, StdArray, StdxArray, EMSIArray;

import std.stdio : stderr, writeln;
import std.datetime : Duration;

import std.meta : AliasSeq;

alias tests = AliasSeq!(testInsert, testInsertDelete, testConcat);
alias containers = AliasSeq!(int[], StdArray!int, EMSIArray!int, rcarray!int, StdxArray!int);
enum times = 100000;

void testInsert(Container, size_t size = 100)()
{
    auto container = make!Container();

    //debug stderr.writeln("Testing inserts on ", typeof(container).stringof);

    foreach (i; 0 .. size)
    {
        container ~= 42;
    }

    assert(container.length == size && container[size - 1] == 42);
}

void testInsertDelete(Container, size_t size = 100)()
{
    auto container = make!Container();

    //debug stderr.writeln("Testing inserts+deletes on ", typeof(container).stringof);

    foreach (i; 0 .. size)
    {
        container ~= 42;
    }

    foreach (i; 0 .. size)
    {
        static if (is(Container : StdxArray!U, U))
        {
            container.forceLength(container.length - 1);
        }
        else static if (is(Container : EMSIArray!U, U))
        {
            container.removeBack();
        }
        else
        {
            container.length = container.length - 1;
        }
    }

    assert(container.length == 0);
}

void testConcat(Container, size_t size = 100)()
{
    auto a = make!Container();
    auto b = make!Container();

    foreach (i; 0 .. size / 2)
    {
        a ~= 1;
        b ~= 2;
    }

    auto c = a ~ b;

    assert(c.length == size);
}

auto testContainers(Containers...)()
{
    import std.datetime.stopwatch : benchmark;
    import std.meta : staticMap;
    import std.array : array;

    Duration[][string] results;

    static foreach (test; tests)
    {
        results[test.stringof] = benchmark!(staticMap!(test, Containers))(times).array;
    }

    return results;
}

void printResults(Containers...)(Duration[][string] results)
{
    static foreach (test; tests)
    {
        import std.stdio : writeln;
        writeln(test.stringof, ":");

        static foreach (i, Container; Containers)
        {
            writeln("\t", Container.stringof, ": ", results[test.stringof][i]);
        }
    }
}

void plotResults(Containers...)(Duration[][string] results)
{
    import plt = matplotlibd.pyplot;

    auto i = 0;
    foreach (test, testResults; results)
    {
        import std.range : iota;
        import std.algorithm : map;
        import std.array : array;
        import std.conv : to;

        auto title = test ~ " (" ~ times.to!string ~ " runs)";
        auto x = iota(testResults.length);
        auto height = testResults.map!(d => d.total!"msecs").array;

        string[] names;
        foreach (Container; Containers)
        {
            names ~= Container.stringof;
        }

        plt.subplot(results.length, 1, ++i);
        plt.bar(x, height);
        plt.xticks(x, names);
        plt.ylabel("Time (ms)");
        plt.title(title);
    }
    plt.show();
}

void main()
{
    auto results = testContainers!containers;
    results.printResults!containers;
    results.plotResults!containers;
}

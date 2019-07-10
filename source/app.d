import util;

import std.stdio : stderr, writeln;
import std.datetime : Duration;

import std.meta : AliasSeq;

alias tests = AliasSeq!(testInsert, testDelete, testConcat);
alias setupFuns = AliasSeq!(noSetup, makeAndInsert, makeAndInsert);
alias containers = AliasSeq!(int[], StdArray!int, rcarray!int, EMSIArray!int, StdxArray!int);
enum times = 100000;

void testInsert(Container, size_t size = 100)()
{
    auto container = make!Container();

    //debug stderr.writeln("Testing inserts on ", typeof(container).stringof);

    static foreach (i; 0 .. size)
    {
        container ~= 42;
    }

    assert(container.length == size && container[size - 1] == 42);
}

void testDelete(Container, size_t size = 100)(ref Container container)
{
    //debug stderr.writeln("Testing inserts+deletes on ", typeof(container).stringof);

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

void testConcat(Container, size_t size = 100)(ref Container container)
{
    auto c = container ~ container;

    assert(c.length == size * 2);
}

auto testContainers(Containers...)()
{
    import std.datetime.stopwatch : benchmark;
    import std.meta : staticMap;
    import std.array : array;

    Duration[][string] results;

    static foreach (i, test; tests)
    {{
        alias ts = staticMap!(test, Containers);
        alias ss = staticMap!(setupFuns[i], Containers);
        results[test.stringof] = benchmarkWithSetup!(Transpose!(2, ts, ss))(times).array;
    }}

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
    foreach (test; tests)
    {
        auto testResults = results[test.stringof];

        import std.range : iota;
        import std.algorithm : map;
        import std.array : array;
        import std.conv : to;

        auto title = test.stringof ~ " (" ~ times.to!string ~ "x)";
        auto x = iota(testResults.length);
        auto height = testResults.map!(d => d.total!"msecs").array;

        string[] names;
        foreach (Container; Containers)
        {
            names ~= Container.stringof;
        }

        i++;
        //plt.subplot(results.length, 1, i);
        plt.clf();
        plt.bar(x, height);
        plt.xticks(x, names);
        plt.ylabel("Time (ms)");
        plt.ylim(0, 3000);
        plt.title(title);
        plt.savefig("out/" ~ i.to!string ~ ".png", ["dpi": 500]);
    }
    //plt.show();
}

void main()
{
    auto results = testContainers!containers;

    results.printResults!containers;
    results.plotResults!containers;
}

import util;

import std.stdio : stderr, writeln;
import std.datetime : Duration;

import std.meta : AliasSeq;

alias tests = AliasSeq!(testInsert, testDelete, testConcat, testMixed);
alias setupFuns = AliasSeq!(noSetup, makeAndInsert, makeAndInsert, noSetup);
enum testNames = ["100 inserts", "100 deletes", "Concat", "Mixed"];

alias containers = AliasSeq!(int[], StdArray!int, rcarray!int, EMSIArray!int, StdxArray!int);
enum containerNames = ["[]", "Phobos Array", "rcarray", "EMSI Array", "stdx array"];

enum times = 100000;

void testInsert(Container, size_t size = 100)()
{
    auto container = make!Container();

    static foreach (i; 0 .. size)
    {
        container ~= 42;
    }

    assert(container.length == size && container[size - 1] == 42);
}

void testDelete(Container, size_t size = 100)(ref Container container)
{
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

void testMixed(Container)()
{
    auto container = make!Container();

    static foreach (i; 0 .. 50)
    {
        container ~= 42;
    }

    static foreach (i; 0 .. 25)
    {{
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
    }}

    static foreach (i; 0 .. 25)
    {{
        container ~= 42;
        container ~= 42;

        static if (is(Container : StdxArray!U, U))
        {
            container.forceLength(container.length - 2);
        }
        else static if (is(Container : EMSIArray!U, U))
        {
            container.removeBack();
            container.removeBack();
        }
        else
        {
            container.length = container.length - 2;
        }
    }}

    assert(container.length == 25 && container[24 - 1] == 42);
}

auto testContainers(Containers...)()
{
    import std.datetime.stopwatch : benchmark;
    import std.meta : staticMap;
    import std.array : array;

    Duration[][] results;

    static foreach (i, test; tests)
    {{
        alias ts = staticMap!(test, Containers);
        alias ss = staticMap!(setupFuns[i], Containers);
        results ~= benchmarkWithSetup!(Transpose!(2, ts, ss))(times).array;
    }}

    return results;
}

void printResults(Containers...)(Duration[][] results)
{
    static foreach (i, test; tests)
    {
        import std.stdio : writeln;
        writeln(test.stringof, ":");

        static foreach (j, Container; Containers)
        {
            writeln("\t", Container.stringof, ": ", results[i][j]);
        }
    }
}

void plotResults(Containers...)(Duration[][] results)
{
    import plt = matplotlibd.pyplot;

    foreach (i, test; tests)
    {
        auto testResults = results[i];

        import std.range : iota;
        import std.algorithm : map;
        import std.array : array;
        import std.conv : to;

        auto title = testNames[i] ~ " (" ~ times.to!string ~ " runs)";
        auto x = iota(testResults.length);
        auto height = testResults.map!(d => d.total!"msecs").array;

        plt.clf();
        plt.bar(x, height);
        plt.xticks(x, containerNames);
        plt.ylabel("Time (ms)");
        plt.ylim(0, 3000);
        plt.title(title);
        plt.savefig("out/" ~ i.to!string ~ ".png", ["dpi": 500]);
    }
}

void main()
{
    auto results = testContainers!containers;

    results.printResults!containers;
    results.plotResults!containers;
}

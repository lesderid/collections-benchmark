import util : make, rcarray, StdArray, StdxArray, EMSIArray;

import std.stdio : stderr, writeln;
import std.datetime : Duration;

void testInsert(Container, int times = 100)()
{
    auto container = make!Container();

    //debug stderr.writeln("Testing inserts on ", typeof(container).stringof);

    foreach (i; 0 .. times)
    {
        container ~= 42;
    }

    assert(container.length == times && container[times - 1] == 42);
}

void testInsertDelete(Container, int times = 100)()
{
    auto container = make!Container();

    //debug stderr.writeln("Testing inserts+deletes on ", typeof(container).stringof);

    foreach (i; 0 .. times)
    {
        container ~= 42;
    }

    foreach (i; 0 .. times)
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

void testConcat(Container, int times = 100)()
{

}

import std.meta : AliasSeq;
alias tests = AliasSeq!(testInsert, testInsertDelete, testConcat);

auto testContainers(Containers...)(int times = 100000)
{
    import std.datetime.stopwatch : benchmark;
    import std.meta : staticMap;

    Duration[][string] results;

    static foreach (test; tests)
    {
        results[test.stringof] = benchmark!(staticMap!(test, Containers))(times);
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

void main()
{
    import std.meta : AliasSeq;

    alias containers = AliasSeq!(int[], StdArray!int, StdxArray!int, EMSIArray!int, rcarray!int);

    auto results = testContainers!containers;
    results.printResults!containers;
}

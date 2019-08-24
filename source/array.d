module array;

import util.benchmark;
import util.array;

import std.stdio : stderr, writeln;
import std.datetime : Duration;

import std.meta : AliasSeq, ApplyLeft, staticMap, Instantiate;

alias multiPhaseTests = AliasSeq!(testInsert, testDelete, testConcat);
alias multiPhaseSetupFuns = AliasSeq!(makeAndInsert, makeAndInsert, makeAndInsert);

enum phasesPerTest = 5;

enum phaseSizes = [
        //Inserts
        (10 - 0), (50 - 10), (200 - 50), (1000 - 200), (10000-1000),

        //Deletes
        (10 - 0), (50 - 10), (200 - 50), (1000 - 200), (10000-1000),

        //Concats
        10,       50,        200,        1000,         10000,
];

enum phaseSetupSizes = [
        //Inserts
        0, 10, 50, 200, 1000,

        //Deletes
        10, 50, 200, 1000, 10000,

        //Concats
        10, 50, 200, 1000, 10000,
];

enum multiPhaseTestNames = ["Inserts", "Deletes", "Concat"];

enum phaseNames = [
        //Inserts
        "0-10", "10-50", "50-200", "200-1000", "1000-10000",

        //Deletes
        "10-0", "50-10", "200-50", "1000-200", "10000-1000",

        //Concats
        "10+10", "50+50", "200+20", "1000+1000", "10000+10000",
];

enum runsPerMultiPhaseTest = 10000;

alias singlePhaseTests = AliasSeq!(testMixed1, testMixed2, testMixed3);
alias singlePhaseSetupFuns = AliasSeq!(noSetup, noSetup, noSetup);

enum singlePhaseTestNames = ["Mixed 1", "Mixed 2", "Mixed 3"];

alias containers = AliasSeq!(rcarray!size_t, size_t[], StdArray!size_t, EMSIArray!size_t, StdVectorWrapper!size_t);
enum containerNames = ["rcarray", "[]", "Phobos Array", "EMSI Array", "std::vector"];

enum runsPerSinglePhaseTest = 1000000;

void testInsert(size_t size, Container)(ref Container container)
{
    foreach (i; 0 .. size)
    {
        container.append(42);
    }

    assert(container.length >= size && container[$ - 1] == 42);
}

void testDelete(size_t size, Container)(ref Container container)
{
    assert(container.length >= size);

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

    assert(container.length >= 0);
}

void testConcat(size_t size, Container)(ref Container container)
{
    auto c = container.concat(container);

    assert(c.length == size * 2);
}

void testMixed1(Container)()
{
    auto container = make!Container();

    foreach (i; 0 .. 50)
    {
        container.append(42);
    }

    foreach (i; 0 .. 25)
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

    foreach (i; 0 .. 25)
    {
        container.append(42);
        container.append(42);

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
    }

    assert(container.length == 25 && container[$ - 1] == 42);
}

void testMixed2(Container)()
{
    auto container = make!Container();

    foreach (i; 0 .. 100)
    {
        container.append(42);
    }

    foreach (i; 0 .. 50)
    {
        container.append(123);
        container.append(123);
        container.append(123);

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
    }

    foreach (i; 0 .. 75)
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

    assert(container.length == 75 && container[$ - 1] == 42);
}

void testMixed3(Container)()
{
    auto container = make!Container();

    foreach (i; 0 .. 25)
    {
        container.append(42);
        container.append(42);
        container.append(42);
        container.append(42);

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
    }

    foreach (i; 0 .. 5)
    {
        static if (is(Container : StdxArray!U, U))
        {
            container.forceLength(container.length - 5);
        }
        else static if (is(Container : EMSIArray!U, U))
        {
            container.removeBack();
            container.removeBack();
            container.removeBack();
            container.removeBack();
            container.removeBack();
        }
        else
        {
            container.length = container.length - 5;
        }

        container.append(42);
    }

    foreach (i; 0 .. 20)
    {
        container.append(123);
    }

    assert(container.length == 50 && container[$ - 1] == 123);
}

mixin containerBenchmarkFunctions!"array";

void benchmark(bool collect)
{
    auto results = testContainers!containers(collect);

    results.printResults!containers;
    results.plotResults!containers;
}

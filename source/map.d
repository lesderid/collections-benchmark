module map;

import util.benchmark;
import util.map;

import std.stdio : stderr, writeln;
import std.datetime : Duration;

import std.meta : AliasSeq, ApplyLeft, staticMap, Instantiate;

alias multiPhaseTests = AliasSeq!(testInsertNew, testInsertReplace, testSearch, testDelete);
alias multiPhaseSetupFuns = AliasSeq!(makeAndInsert, makeAndInsert, makeAndInsert, makeAndInsert);

enum phasesPerTest = 5;

enum phaseSizes = [
        //Inserts (new)
        (10 - 0), (50 - 10), (200 - 50), (1000 - 200), (10000-1000),

        //Inserts (replace)
        10, 50, 200, 1000, 5000,

        //Searches
        10, 50, 200, 1000, 5000,

        //Deletes
        (10 - 0), (50 - 10), (200 - 50), (1000 - 200), (10000-1000),
];

enum phaseSetupSizes = [
        //Inserts (new)
        0, 10, 50, 200, 1000,

        //Inserts (replace)
        10, 50, 200, 1000, 5000,

        //Searches
        10, 50, 200, 1000, 5000,

        //Deletes
        10, 50, 200, 1000, 10000,
];

enum multiPhaseTestNames = ["Inserts (new)", "Inserts (replace)", "Searches", "Deletes"];

enum phaseNames = [
        //Inserts (new)
        "0-10", "10-50", "50-200", "200-1000", "1000-10000",

        //Inserts (replace)
        "10", "50", "200", "1000", "5000",

        //Searches
        "10", "50", "200", "1000", "5000",

        //Deletes
        "10-0", "50-10", "200-50", "1000-200", "10000-1000",
];

enum runsPerMultiPhaseTest = 10000;

alias singlePhaseTests = AliasSeq!(testMixed1, testMixed2, testMixed3);
alias singlePhaseSetupFuns = AliasSeq!(noSetup, noSetup, noSetup);

enum singlePhaseTestNames = ["Mixed 1", "Mixed 2", "Mixed 3"];

alias containers = AliasSeq!(rcmap!(int, byte), byte[int], EMSIHashMap!(int, byte), StdUnorderedMapWrapper!(int, byte));
enum containerNames = ["rcmap", "Built-in", "EMSI HashMap" , "std::unordered_map"];

enum runsPerSinglePhaseTest = 1000000;

void testInsertNew(size_t size, Container)(ref Container container)
{
    int length = cast(int) container.length;

    foreach (int i; 0 .. size)
    {
        container.insertValue(length + i, byte(42));
    }

    assert(container.length == length + size && container[size - 1] == 42);
}

void testInsertReplace(size_t size, Container)(ref Container container)
{
    foreach (int i; 0 .. size)
    {
        container.insertValue(i, byte(42));
    }

    assert(container.length == size);
}

void testSearch(size_t size, Container)(ref Container container)
{
    foreach (int i; 0 .. size)
    {
        static if (is(Container == StdUnorderedMapWrapper!(K, V), K, V))
        {
            bool canFind = container.contains(i);
        }
        else
        {
            bool canFind = cast(bool) (i in container);
        }
        assert(canFind);
    }
}

void testDelete(size_t size, Container)(ref Container container)
{
    foreach (int i; 0 .. size)
    {
        container.remove(i);
    }
}

void testMixed1(Container)()
{
    auto container = make!Container();

    foreach (int i; 0 .. 50)
    {
        container.insertValue(i, byte(2));
    }

    foreach (int i; 0 .. 25)
    {
        container.remove(i);
    }

    foreach (int i; 25 .. 50)
    {
        container.insertValue(i, byte(42));

        container.remove(i);
    }
}

void testMixed2(Container)()
{
    auto container = make!Container();

    foreach (int i; 0 .. 100)
    {
        container.insertValue(i, byte(2));
    }

    foreach (int i; 0 .. 100)
    {
        auto v = container[i];
        container.remove(i);
        container.insertValue(i, v);
    }
}

void testMixed3(Container)()
{
    auto container = make!Container();

    foreach (byte i; 0 .. 100)
    {
        container.insertValue(int(i), i);
    }

    foreach (int i; 0 .. 100)
    {
        auto v = container[i];

        if (v % 2 == 0)
        {
            container.remove(i);
        }
        else
        {
            container.insertValue(i, v);
        }
    }
}

mixin containerBenchmarkFunctions!"map";

void benchmark(bool collect)
{
    auto results = testContainers!containers(collect);

    results.printResults!containers;
    results.plotResults!containers;
}

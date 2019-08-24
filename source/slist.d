module slist;

import util.benchmark;
import util.slist;

import std.stdio : stderr, writeln;
import std.datetime : Duration;

import std.meta : AliasSeq, ApplyLeft, staticMap, Instantiate;

alias multiPhaseTests = AliasSeq!(testInsert, testDeleteFront, testDeleteValue);
alias multiPhaseSetupFuns = AliasSeq!(makeAndInsert, makeAndInsert, makeAndInsert);

enum phasesPerTest = 5;

enum phaseSizes = [
        //Inserts
        (10 - 0), (50 - 10), (200 - 50), (1000 - 200), (10000-1000),

        //Deletes (front)
        (10 - 0), (50 - 10), (200 - 50), (1000 - 200), (10000-1000),

        //Deletes (by value)
        (10 - 0), (50 - 10), (200 - 50), (500 - 200), (1000-500),
];

enum phaseSetupSizes = [
        //Inserts
        0, 10, 50 , 200, 1000,

        //Deletes (front)
        10, 50, 200, 1000, 10000,

        //Deletes (by value)
        10, 50, 200, 500, 1000,
];

enum multiPhaseTestNames = ["Inserts", "Deletes (front)", "Deletes (by value)"];

enum phaseNames = [
        //Inserts
        "0-10", "10-50", "50-200", "200-1000", "1000-10000",

        //Deletes (front)
        "10-0", "50-10", "200-50", "1000-200", "10000-1000",

        //Deletes (by value)
        "10-0", "50-10", "200-50", "500-200", "1000-500",
];

enum runsPerMultiPhaseTest = 10000;

alias singlePhaseTests = AliasSeq!(testMixed1, testMixed2, testMixed3);
alias singlePhaseSetupFuns = AliasSeq!(noSetup, noSetup, noSetup);

enum singlePhaseTestNames = ["Mixed 1", "Mixed 2", "Mixed 3"];

alias containers = AliasSeq!(rcslist!size_t, StdSList!size_t, EMSISList!size_t, StdForwardListWrapper!size_t);
enum containerNames = ["rcslist", "Phobos SList", "EMSI SList" , "std::forward_list"];

enum runsPerSinglePhaseTest = 1000000;

void testInsert(size_t size, Container)(ref Container container)
{
    foreach (i; 0 .. size)
    {
        container.insertFront(42);
    }

    assert(container.front == 42);
}

void testDeleteFront(size_t size, Container)(ref Container container)
{
    foreach (i; 0 .. size)
    {
        container.removeFront();
    }
}

void testDeleteValue(size_t size, Container)(ref Container container)
{
    foreach (i; 0 .. size)
    {
        container.remove(i);
    }
}

void testMixed1(Container)()
{
    auto container = make!Container();

    foreach (i; 0 .. 50)
    {
        container.insertFront(2);
    }

    foreach (i; 0 .. 25)
    {
        container.removeFront();
    }

    foreach (i; 0 .. 25)
    {
        container.insertFront(42);
        container.insertFront(42);

        container.removeFront();
        container.removeFront();
    }

    assert(container.front == 2);
}

void testMixed2(Container)()
{
    auto container = make!Container();

    foreach (i; 0 .. 100)
    {
        container.insertFront(42);
    }

    foreach (i; 0 .. 50)
    {
        container.insertFront(123);
        container.insertFront(123);
        container.insertFront(123);

        container.removeFront();
        container.remove(42);
    }

    foreach (i; 0 .. 75)
    {
        container.removeFront();
    }
}

void testMixed3(Container)()
{
    auto container = make!Container();

    foreach (i; 0 .. 25)
    {
        container.insertFront(42);
        container.insertFront(42);
        container.insertFront(42);
        container.insertFront(42);

        container.removeFront();
        container.removeFront();
    }

    foreach (i; 0 .. 5)
    {

        container.removeFront();
        container.removeFront();
        container.removeFront();
        container.removeFront();
        container.removeFront();

        container.insertFront(42);
    }

    foreach (i; 0 .. 20)
    {
        container.insertFront(123);

        container.remove(42);
    }

    assert(container.front == 123);
}

mixin containerBenchmarkFunctions!"slist";

void benchmark(bool collect)
{
    auto results = testContainers!containers(collect);

    results.printResults!containers;
    results.plotResults!containers;
}

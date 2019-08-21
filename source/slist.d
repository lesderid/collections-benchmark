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

auto testContainers(Containers...)(bool collect)
{
    import std.datetime.stopwatch : benchmark;
    import std.meta : staticMap;
    import std.array : array;

    Duration[][] results;

    static foreach (i; 0 .. multiPhaseTests.length)
    {
        static foreach (j; i * phasesPerTest .. (i + 1) * phasesPerTest)
        {
            results ~= benchmarkWithSetup!(Transpose!(2,
                    staticMap!(ApplyLeft!(multiPhaseTests[i], phaseSizes[j]), Containers),
                    staticMap!(ApplyLeft!(multiPhaseSetupFuns[i], phaseSetupSizes[j]), Containers)))(runsPerMultiPhaseTest, collect).array;
        }
    }

    foreach (i, test; singlePhaseTests)
    {
        alias ts = staticMap!(test, Containers);
        alias ss = staticMap!(singlePhaseSetupFuns[i], Containers);
        results ~= benchmarkWithSetup!(Transpose!(2, ts, ss))(runsPerSinglePhaseTest, collect).array;
    }

    return results;
}

void printResults(Containers...)(Duration[][] results)
{
    import std.stdio : writeln;

    foreach (i, test; multiPhaseTests)
    {
        writeln(test.stringof, ":");

        foreach (j; 0 .. phasesPerTest)
        {
            writeln("\t", "Phase ", j + 1, " (", phaseNames[i * phasesPerTest + j], ")");

            foreach (k, Container; Containers)
            {
                writeln("\t\t", Container.stringof, ": ", results[i * phasesPerTest + j][k]);
            }
        }
    }

    foreach (i, test; singlePhaseTests)
    {
        writeln(test.stringof, ":");

        foreach (j, Container; Containers)
        {
            writeln("\t", Container.stringof, ": ", results[multiPhaseTests.length * phasesPerTest + i][j]);
        }
    }
}

void plotResults(Containers...)(Duration[][] results)
{
    import plt = matplotlibd.pyplot;

    import std.range : iota;
    import std.algorithm : map;
    import std.array : array;
    import std.conv : to;

    foreach (i, test; multiPhaseTests)
    {
        enum colours = ["C0", "C1", "C2", "C3", "C4", "C5", "C6", "C7", "C8", "C9"];
        static assert(Containers.length <= colours.length);

        auto testResults = results[i * phasesPerTest .. (i + 1) * phasesPerTest];
        auto testPhaseNames = phaseNames[i * phasesPerTest .. (i + 1) * phasesPerTest];

        plt.clf();

        auto title = multiPhaseTestNames[i] ~ " (" ~ runsPerMultiPhaseTest.to!string ~ " runs per phase)";

        double[] x = iota(phasesPerTest).map!(to!double).array;

        enum barWidth = 0.8 / Containers.length;
        foreach (j; 0 .. Containers.length)
        {
            auto height = testResults.map!(t => t.map!(r => r.total!"hnsecs")).map!(t => t[j].to!double / t[0]).array;

            auto xs = x.dup;
            xs[] = xs[] + j * barWidth;

            plt.bar(xs, height, barWidth, ["color": colours[j], "label": containerNames[j]]);
        }

        auto ticks = x.map!(t => t + barWidth + barWidth / 2).array;
        plt.xticks(ticks, testPhaseNames);
        plt.ylabel("Relative time (lower is better)");
        plt.ylim(0, 2);
        plt.axhline(1, ["color": "black"]);
        plt.title(title);
        plt.legend();
        plt.savefig("out/slist/" ~ i.to!string ~ ".png", ["dpi": 500]);
    }

    foreach (i, test; singlePhaseTests)
    {
        auto testResults = results[multiPhaseTests.length * phasesPerTest + i];

        auto title = singlePhaseTestNames[i] ~ " (" ~ runsPerSinglePhaseTest.to!string ~ " runs)";
        auto x = iota(testResults.length);
        auto height = testResults.map!(d => d.total!"msecs").map!(to!double).array;
        height = height.map!(h => h / height[0]).array;

        plt.clf();
        plt.bar(x, height);
        plt.xticks(x, containerNames);
        plt.ylabel("Relative time (lower is better)");
        plt.ylim(0, 2);
        plt.axhline(1, ["color": "black"]);
        plt.title(title);
        plt.savefig("out/slist/" ~ (multiPhaseTests.length + i).to!string ~ ".png", ["dpi": 500]);
    }
}

void benchmark(bool collect)
{
    auto results = testContainers!containers(collect);

    results.printResults!containers;
    results.plotResults!containers;
}

module map;

import util.benchmark;
import util.map;

import std.stdio : stderr, writeln;
import std.datetime : Duration;

import std.meta : AliasSeq, ApplyLeft, staticMap, Instantiate;

alias multiPhaseTests = AliasSeq!(testInsert /*, testDelete*/);
alias multiPhaseSetupFuns = AliasSeq!(makeAndInsert /*, makeAndInsert*/);

enum phasesPerTest = 5;

enum phaseSizes = [
        //Inserts
        (10 - 0), (50 - 10), (200 - 50), (1000 - 200), (10000-1000),

        //Deletes
//      (10 - 0), (50 - 10), (200 - 50), (1000 - 200), (10000-1000),
];

enum phaseSetupSizes = [
        //Inserts
        0, 10, 50 , 200, 1000,

        //Deletes
//      10, 50, 200, 1000, 10000,
];

enum multiPhaseTestNames = ["Inserts" /*, "Deletes" */];

enum phaseNames = [
        //Inserts
        "0-10", "10-50", "50-200", "200-1000", "1000-10000",

        //Deletes
//      "10-0", "50-10", "200-50", "1000-200", "10000-1000",
];

enum runsPerMultiPhaseTest = 10000;

alias singlePhaseTests = AliasSeq!(testMixed1);
alias singlePhaseSetupFuns = AliasSeq!(noSetup);

enum singlePhaseTestNames = ["Mixed 1"];

alias containers = AliasSeq!(rcmap!(int, byte), byte[int], EMSIHashMap!(int, byte), StdUnorderedMapWrapper!(int, byte));
enum containerNames = ["rcmap", "Built-in", "EMSI HashMap" , "std::unordered_map"];

enum runsPerSinglePhaseTest = 1000000;

void testInsert(size_t size, Container)(ref Container container)
{
    int length = cast(int) container.length;

    foreach (int i; 0 .. size)
    {
        container.insertValue(length + i, byte(42));
    }

    assert(container.length == length + size && container[size - 1] == 42);
}

void testDelete(size_t size, Container)(ref Container container)
{

}

void testMixed1(Container)()
{

}

auto testContainers(Containers...)()
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
                    staticMap!(ApplyLeft!(multiPhaseSetupFuns[i], phaseSetupSizes[j]), Containers)))(runsPerMultiPhaseTest).array;
        }
    }

    foreach (i, test; singlePhaseTests)
    {
        alias ts = staticMap!(test, Containers);
        alias ss = staticMap!(singlePhaseSetupFuns[i], Containers);
        results ~= benchmarkWithSetup!(Transpose!(2, ts, ss))(runsPerSinglePhaseTest).array;
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
        plt.savefig("out/map/" ~ i.to!string ~ ".png", ["dpi": 500]);
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
        plt.savefig("out/map/" ~ (multiPhaseTests.length + i).to!string ~ ".png", ["dpi": 500]);
    }
}

void benchmark()
{
    auto results = testContainers!containers;

    results.printResults!containers;
    results.plotResults!containers;
}

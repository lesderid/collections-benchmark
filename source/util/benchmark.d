module util.benchmark;

import core.time : Duration;
import std.datetime.stopwatch : StopWatch, AutoStart;

import core.memory : GC;

Duration[funs.length / 2] benchmarkWithSetup(funs...)(uint n, bool collect)
{
    Duration[funs.length / 2] result;

    auto sw = StopWatch(AutoStart.no);

    static foreach (i; 0 .. funs.length / 2)
    {
        sw.reset();

        if (collect) GC.collect();

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

        if (collect)
        {
            sw.start();
            GC.collect();
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

void noSetup(T)() { }

mixin template containerBenchmarkFunctions(string name)
{
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
            plt.savefig("out/" ~ name ~ "/" ~ i.to!string ~ ".png", ["dpi": 500]);
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
            plt.savefig("out/" ~ name ~ "/" ~ (multiPhaseTests.length + i).to!string ~ ".png", ["dpi": 500]);
        }
    }
}

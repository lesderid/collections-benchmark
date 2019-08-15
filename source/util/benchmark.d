module util.benchmark;

import core.time : Duration;
import std.datetime.stopwatch : StopWatch, AutoStart;
Duration[funs.length / 2] benchmarkWithSetup(funs...)(uint n)
{
    Duration[funs.length / 2] result;

    auto sw = StopWatch(AutoStart.no);

    static foreach (i; 0 .. funs.length / 2)
    {
        sw.reset();
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

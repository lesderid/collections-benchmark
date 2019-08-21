import array : benchmarkArrays = benchmark;
import map : benchmarkMaps = benchmark;
import slist : benchmarkSLists = benchmark;

import std.stdio : writeln;
import std.algorithm : canFind;

int main(string[] args)
{
    auto collect = args.length >= 2 && args[1] == "--collect";

    if (args.length < 2 || collect && args.length < 3)
    {
        writeln("Usage: ", args[0], " [--collect] <array/slist/map/all>");

        return 1;
    }

    import std.file : mkdirRecurse;

    if (args.canFind("array") || args.canFind("all"))
    {
        mkdirRecurse("out/array");

        benchmarkArrays(collect);
    }

    if (args.canFind("slist") || args.canFind("all"))
    {
        mkdirRecurse("out/slist");

        benchmarkSLists(collect);
    }

    if (args.canFind("map") || args.canFind("all"))
    {
        mkdirRecurse("out/map");

        benchmarkMaps(collect);
    }

    return 0;
}

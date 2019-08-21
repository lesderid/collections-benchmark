import array : benchmarkArrays = benchmark;
import map : benchmarkMaps = benchmark;
import slist : benchmarkSLists = benchmark;

import std.stdio : writeln;
import std.algorithm : canFind;

int main(string[] args)
{
    if (args.length < 2)
    {
        writeln("Usage: ", args[0], " <array/slist/map/all>");

        return 1;
    }

    import std.file : mkdirRecurse;

    if (args.canFind("array") || args.canFind("all"))
    {
        mkdirRecurse("out/array");

        benchmarkArrays();
    }

    if (args.canFind("slist") || args.canFind("all"))
    {
        mkdirRecurse("out/slist");

        benchmarkSLists();
    }

    if (args.canFind("map") || args.canFind("all"))
    {
        mkdirRecurse("out/map");

        benchmarkMaps();
    }

    return 0;
}

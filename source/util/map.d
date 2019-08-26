module util.map;

public import core.experimental.rc.map : rcmap;
public import containers : EMSIHashMap = HashMap;
public import stlwrappers : StdUnorderedMapWrapper = UnorderedMapWrapper;

public import core.experimental.rc.map : make;

T make(T : V[K], K, V)()
{
    return null;
}

T make(T : EMSIHashMap!(K, V), K, V)()
{
    return T();
}

T make(T : StdUnorderedMapWrapper!(K, V), K, V)()
{
    import stlwrappers : makeIntByteUnorderedMapWrapper;

    static if (is(K == int) && is(V == byte))
    {
        return makeIntByteUnorderedMapWrapper();
    }
    else
    {
        static assert(0);
    }
}

void insertValue(T, K, V)(ref T container, auto ref K key, auto ref V value)
{
    static if (is(T == StdUnorderedMapWrapper!(K, V)))
    {
        container.insert(key, value);
    }
    else
    {
        container[key] = value;
    }
}

T makeAndInsert(size_t size, T)()
{
    T t = make!T();

    foreach (int i; 0 .. size)
    {
        t.insertValue(i, byte(42));
    }

    return t;
}

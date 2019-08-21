module stlwrappers;

extern(C++, class) struct VectorWrapper(T)
{
    ~this();

    size_t length();
    void length(size_t size);

    alias opDollar = length;

    void insert(T t);

    T opIndex(size_t index);

    VectorWrapper!T newFromConcat(const VectorWrapper!T* rhs);

    ubyte[24] vector; //HACK
}

extern(C++) VectorWrapper!size_t makeSizeTVectorWrapper();
extern(C++) VectorWrapper!int makeInt32VectorWrapper();

extern(C++, class) struct UnorderedMapWrapper(K, V)
{
    ~this();

    void remove(K key);

    size_t length();

    alias opDollar = length;

    void clear();

    void insert(K key, V value);

    V opIndex(K key);

    ubyte[56] map; //HACK
}

extern(C++) UnorderedMapWrapper!(int, byte) makeIntByteUnorderedMapWrapper();

extern(C++, class) struct ForwardListWrapper(T)
{
    ~this();

    void length(size_t size);

    void insertFront(T t);

    void removeFront();

    T front();

    void remove(T t);

    ubyte[8] list; //HACK
}

extern(C++) ForwardListWrapper!size_t makeSizeTForwardListWrapper();

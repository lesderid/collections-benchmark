module cppvector;

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

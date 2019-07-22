#include <vector>
#include <stdint.h>

template<typename T>
class VectorWrapper
{
public:
    VectorWrapper() : vector()
    {
    }

    VectorWrapper(std::vector<T> vector) : vector(vector)
    {
    }

    ~VectorWrapper()
    {
    }

    size_t length()
    {
        return vector.size();
    }

    void length(size_t size)
    {
        vector.resize(size);
    }

    T operator[](size_t index)
    {
        return vector[index];
    }

    void insert(T t)
    {
        vector.push_back(t);
    }

    VectorWrapper<T> newFromConcat(const VectorWrapper<T>* rhs)
    {
        std::vector<T> newVector;
        std::copy(this->vector.begin(), this->vector.end(), std::back_inserter(newVector));
        std::copy(rhs->vector.begin(), rhs->vector.end(), std::back_inserter(newVector));
        return VectorWrapper<T>(newVector);
    }

private:
    std::vector<T> vector;
};

VectorWrapper<size_t> makeSizeTVectorWrapper()
{
    return VectorWrapper<size_t>();
}

VectorWrapper<int32_t> makeInt32VectorWrapper()
{
    return VectorWrapper<int32_t>();
}

template class VectorWrapper<size_t>;
template class VectorWrapper<int32_t>;

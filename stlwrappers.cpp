#include <vector>
#include <unordered_map>
#include <forward_list>
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

template<typename K, typename V>
class UnorderedMapWrapper
{
public:
    UnorderedMapWrapper() : map()
    {
    }

    UnorderedMapWrapper(std::unordered_map<K, V> map) : map(map)
    {
    }

    ~UnorderedMapWrapper()
    {
    }

    size_t length()
    {
        return map.size();
    }

    void clear()
    {
        map.clear();
    }

    void remove(K key)
    {
        map.erase(key);
    }

    V operator[](K key)
    {
        return map[key];
    }

    bool contains(K key)
    {
        return map.contains(key);
    }

    void insert(K key, V value)
    {
        map[key] = value;
    }

private:
    std::unordered_map<K, V> map;
};

UnorderedMapWrapper<int32_t, int8_t> makeIntByteUnorderedMapWrapper()
{
    return UnorderedMapWrapper<int32_t, int8_t>();
}

template class UnorderedMapWrapper<int32_t, int8_t>;

template<typename T>
class ForwardListWrapper
{
public:
    ForwardListWrapper() : list()
    {
    }

    ForwardListWrapper(std::forward_list<T> list) : list(list)
    {
    }

    ~ForwardListWrapper()
    {
    }

    void length(size_t size)
    {
        list.resize(size);
    }

    void insertFront(T t)
    {
        list.push_front(t);
    }

    void removeFront()
    {
        return list.pop_front();
    }

    T front()
    {
        return list.front();
    }

    void remove(T t)
    {
        list.remove(t);
    }

private:
    std::forward_list<T> list;
};

ForwardListWrapper<size_t> makeSizeTForwardListWrapper()
{
    return ForwardListWrapper<size_t>();
}

template class ForwardListWrapper<size_t>;

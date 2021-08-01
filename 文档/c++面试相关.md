c++内存管理：

栈和堆：

栈由系统自动管理分配，存储局部变量和函数参数，所以递归多了会爆栈。

堆由程序员自己申请分配，需要手动管理，即new/delete和malloc/free，不管会内存泄漏。

全局/静态存储区：存全局变量和static变量。

常量存储区：存放常量

程序代码区：存放函数代码

```c++
int a = 0; //全局初始化区  
char *p1; //全局未初始化区  
void main()  
{  
    int b; //栈  
    char s[] = "abc"; //栈  
    char *p2; //栈  
    char *p3 = "123456"; //123456{post.content}在常量区，p3在栈上  
    static int c = 0; //全局(静态)初始化区  
    p1 = (char *)malloc(10); //分配得来得10字节的区域在堆区  
    p2 = (char *)malloc(20); //分配得来得20字节的区域在堆区  
    strcpy(p1, "123456");  //123456{post.content}放在常量区，编译器可能会将它与p3所指向的"123456"优化成一块  
} 
```

const/static和mutable：

static成员变量：属于所有类对象共有的一个static变量，声明在类的.h中，只在类声明外（如类的.cpp)中初始化一次。

static成员函数：由类来调用，只能访问static成员变量。

const变量，只读无法修改，const对象只能调用const函数。

const函数：const函数中无法修改对象的非static成员变量，也无法调用可能会修改非static成员变量的其他成员函数。static成员变量被声明在静态存储区，可以被const函数修改。

mutable：用mutable修饰的成员变量可以在const函数中修改。

左值右值&移动构造&右值引用：

```cpp
std::string s = std::string("a really really long string");

// C++98 works like this
// 1. construct the temporary object std::string("a really really long string")
// 2. call the `COPY` constructor of string to deep copy the content of the temporary object
// 3. the full expression ends, temporary object is destroyed.
// note: the content "a really really long string" is allocated in memory twice

// C++11 works like this
// 1. construct the temporary object std::string("a really really long string")
// 2. call the `MOVE` constructor of string to `STEAL` the content of the temporary object
// 3. the full expression ends, temporary object is destroyed.
// note 1: the content "a really really long string" is allocated in memory only once
// note 2: after step 2, the temporary object is invalid
```

左值:可寻址的变量，具有持久性。

右值:不可寻址的变量，或者给左值赋值时产生的临时变量，赋值完一般就消失。

左值可以被修改，右值不行。

```cpp
int x = 6; // x是左值，6是右值
int &y = x; // 左值引用，y引用x

int &z1 = x * 6; // 错误，x*6是一个右值
const int &z2 =  x * 6; // 正确，可以将一个const引用绑定到一个右值

int &&z3 = x * 6; // 正确，右值引用
int &&z4 = x; // 错误，x是一个左值
```

通过&&进行右值引用，延长右值生命周期，或者通过std::move从左值转到右值。

```cpp
std::vector<int> foo = {1, 2, 3, 4};
std::vector<int>&& v = std::move(foo);
```

拷贝构造函数：将输入变量复制一份产生新的左值分配给类对象，在输入变量析构前堆内分配了两个重复的对象。可以分为浅拷贝和深拷贝，浅拷贝对类对象中的指针只复制某个对象的指针，深拷贝会产生一个一模一样的对象再赋给指针。

移动构造函数：直接接受一个右值作为参数，可以在构造函数里直接传递给要赋值的变量，赋值完右值被销毁，只分配了类中一个对象。移动构造函数可以对深拷贝进行优化不用再产生一个对象直接给右值即可。

```cpp
  B(const B &b)   // 复制（拷贝）构造函数  
    {
        data = b.data; 
        cout << "Copy Constructor is called." << data << endl;
    }
    B(B&& b)      // 移动构造函数，严格意义上移动构造函数的作用是，this去接管b的资源，同时b的资源被销毁
    {
        this->data = b.data;
        cout << "Move Constructor is called." <<data<< endl;
    }

```

智能指针：

unique_ptr：表示指向对象由该指针独占，不能共享，一般用于函数内临时数组的申请，结束即释放。

shared_ptr: 给指针引入了一个引用计数器，引用为0时自动删除对象。

weak_ptr:为了解决shared_ptr循环引用的问题，如果不用weak_ptr?

字节对齐：

32位机默认4字节对齐，64位机默认8字节对齐，alignas()可以设置字节对齐长度16/32/64/128，数据跨平台传输方便。进行内存（字节）对齐的原因：方便移植、提高CPU访存效率（按规定的对齐长度取内存，不用取多次拼接）

虚析构函数：

带有virtual函数的基类，析构函数需要是虚函数，否则子类通过基类指针释放，无法找到子类的析构函数，导致子类的derived成分无法释放。

override关键字（覆写）：

 在派生类中，重写 (override) 继承自基类成员函数的实现 (implementation) 时，要满足如下条件：
  一虚：基类中，成员函数声明为虚拟的 (virtual)
  二容：基类和派生类中，成员函数的返回类型和异常规格 (exception specification) 必须兼容
  四同：基类和派生类中，成员函数名、形参类型、常量属性 (constness) 和 引用限定符 (reference qualifier) 必须完全相同
  如此多的限制条件，导致了虚函数重写极容易因为一个不小心而出错，导致没有对基类的虚函数实现多态，而是重新定义了一个新的虚函数。
  C++11 中的 override 关键字，可以显式的在派生类中声明，哪些成员函数需要被重写，如果没被重写，则编译器会报错。

overload（重载）:

同名函数不同形参

unordered_map与map的区别：unordered_map基于hash表实现，每个key对应一个hash值，根据key的hash值判断元素是否相同，数据是无序的；map基于红黑树实现，数据是有序的。由于unordered_map多用了hash表来记录hash值，内存消耗更大。

静态多态：函数重载、运算符重载、模板

动态多态：虚函数



```cpp
//SmartPtr.h
template<class T>
class SmartPtr
{
public:
    SmartPtr(T* p);
    SmartPtr(const SmartPtr<T> &p);
    SmartPtr<T>& operator=(const SmartPtr<T> &p);
    T& operator*() const;
    T* operator->() const;
    ~SmartPtr();
private:
	int * count;
	T* ptr;
}

//SmartPtr.cpp
#include "SmartPtr.h"

template<class T>
SmartPtr::SmartPtr(T* p)
{
	ptr = p;
    count = new int(1);
}
template<class T>
SmartPtr::SmartPtr(const SmartPtr<T> &p)
{
    ++(*p.count);
    ptr = p.ptr;
    count = p.count;
}
template<class T>
SmartPtr::~SmartPtr()
{
    if(--(*count)==0)
    {
        delete count;
        delete ptr;
        count = nullptr;
        ptr = nullptr;
    }
}
template<class T>
SmartPtr<T>& SmartPtr::operator=(const SmartPtr<T> &p)
{
    ++(*p.count);
    if(--(*count)==0)
    {
        delete count;
        delete ptr;
    }
    count = p.count;
    ptr = p.ptr;
}
template<class T>
T& operator*() const
{
    return *ptr;
}
template<class T>
T* operator->() const
{
    return ptr;
}
```

红黑树

一种优化过的平衡二叉树。
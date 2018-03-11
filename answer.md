# Question One:

* REPL环境下，每句表达式或者声明间互相并不是同一个scope下的，因此`local`变量的声明对之后的语句是不可见的，例如在REPL下输入会得到：

  ```lua
  >local i = 1
  >print(i)
  nil
  >
  ```

  只有声明全局变量才对后面语句可见。

* * `table`类型

    lua所有的复合类型本质上都是`table`类型，而且`table`可以通过任意类型的value索引(除了nil)，长度可变，而不像python中所有类型本质上是`object`类型的继承。lua中类的成员变量和方法的实现，也是通过将某`table`里存储变量或者函数的引用实现。

  * metatable

    lua的元标操作可以理解为对特定`table`类型中一些特殊符号进行函数重载。类似的，在C++里是用`operator`关键词实现类中符号重载；在python中是直接对`object`添加method的方法(eg. \_\_add__，\_\_get\_\_)实现重载，这是因为python中所有类型都是对象。

    例如，用lua写一个`Array`类，我们`setmetatable`了`__add`与`__mul`变量从而实现`Array`加法和点乘的“函数重载”

    ```lua
    #!/usr/local/bin lua

    Array = {}
    Array.mt = {}

    function Array.add (a,b)
    	assert(# a == # b)
    	local sum = Array.new{}
    	for i,value in pairs(a) do sum[i] = value end
    	for j, value in pairs(b) do sum[j] = sum[j] + value end
    	return sum
    end

    function Array.dot (a,b)
    	assert(# a == # b)
    	local sum = Array.new{}
    	for i,value in pairs(a) do sum[i] = value end
    	for j, value in pairs(b) do sum[j] = sum[j] * value end
    	return sum
    end

    function Array.print(array)
    	for _, i in pairs(array) do print(i) end
    end

    Array.mt.__add = Array.add
    Array.mt.__mul = Array.dot

    function Array.new(t)
    	local array = {}
    	setmetatable(array, Array.mt)
    	for i,value in pairs(t) do array[i] = value end
        return array
    end

    a1 = Array.new({2,3,4})
    a2 = Array.new({1,2,3})
    Array.print(a1+a2)
    Array.print(a1*a2)
    ```

* 时间复杂度为$O(2^n)$，改进方法即动态规划，将已经算出的`fib[n]`存起来即可

  ```lua
  local fib = {}
  function fib_index(fib, k)
  	assert(k >= 0)
  	if k == 0 or k == 1 then
  		return k
  	else
  		local s = {}
  		s[0] = 0
  		s[1] = 1
  		for i = 2, k do s[i] = s[i-1] + s[i-2] end
  		return s[k]
  	end
  end

  setmetatable(fib, {__index = fib_index})
  print(fib[3])
  ```

  ​
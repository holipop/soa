-- Struct of Arrays
-- by holipop

---@class soa
---@field __order string[]
local soa = {}
soa.__index = soa

soa._VERSION = "v1.0"
soa._DESCRIPTION = "A convenient struct-of-arrays library for Lua"
soa._URL = "https://github.com/holipop/soa"
soa._LICENSE = [[
    MIT License

    Copyright (c) 2025 holipop

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
]]



---Returns the length of the first array.
---@return integer
function soa:__len ()
    return #self[self.__order[1]]
end

---Creates a struct of arrays, each parameter being the name of an array.
---The order of the arrays is remembered.
---```lua
---local rectangles = soa:new("x", "y", "w", "h")
---```
---@param ... string
---@return soa
function soa:new (...)
    local instance = {
        __order = {}
    }
    local length = select("#", ...)

    for i = 1, length do
        local key = select(i, ...)
        instance[key] = {}
        instance.__order[i] = key
    end
    
    return setmetatable(instance, self)
end

---@alias soa.builder fun(...): soa.builder | soa.end
---@alias soa.end fun(): soa

---Constructs a struct of arrays with a chain of function calls, Ending with an empty parameter list.
---
---This can also be called on an instance to append to it. 
---```lua
---local points = points:build("name", "scores")
---    ("Alice", 230)
---    ("Bobby", 132)
---()
---
---points:build()
---    ("Carry", 500)
---()
---```
---@param ... string?
---@return soa.builder | soa.end
function soa:build (...)
    local instance-- = self:new(...)
    if self == soa then
        instance = self:new(...)
    else
        instance = self
    end

    local function step (...)
        if select("#", ...) == 0 then
            return instance
        end
        instance:write(#instance + 1, ...)
        return step
    end

    return step
end

---Constructs a struct of arrays from an array of structs. 
---This function uses the first entry as a template and assumes every proceeding entry contains the same keys as the first.
---The order of the keys are alphabetical.
---
---This can also be called on an instance to append it.
---```lua
---local scores = soa:from({
---    { name = "Alice", score = 230 },
---    { name = "Bobby", score = 132 },
---    { name = "Carry", score = 500, valid = true }, -- "banned" will be disregarded
---})
---
---scores:from({
---    { name = "Derek", score = 500 }
---})
---```
---@param aos table[]
---@return soa
function soa:from (aos)
    if self == soa then
        local instance = {
            __order = {}
        }
        for k, _ in pairs(aos[1]) do
            table.insert(instance.__order, k)
            instance[k] = {}

            for i = 1, #aos do
                instance[k][i] = aos[i][k]
            end
        end
        table.sort(instance.__order)

        return setmetatable(instance, self)
    else
        for _, k in ipairs(self.__order) do
            for i = 1, #aos do
                self[k][#self[k] + 1] = aos[i][k]
            end
        end

        return self
    end
end

---Write to each of the arrays at the specified index.
---```lua
---local scores = soa:new("name", "score")
---scores:write(1, "Alice", 230)
---scores:write(2, "Bobby", 132)
---scores:write(3, "Carry", 500)
---```
---@param index integer
---@param ... any
function soa:write (index, ...)
    assert(#self.__order == select("#", ...), "must have the same amount of args as arrays")
    for i, k in ipairs(self.__order) do
        self[k][index] = select(i, ...)
    end
end

---Reads from each of the arrays at the specified index, 
---returning each value in the same order the arrays were defined.
---```lua
---local scores = soa:new("name", "score")
---scores:write("Alice", 230)
---scores:write("Bobby", 132)
---
---local name, score = scores:read(1) -- "Alice", 230
---```
---@param index integer
---@return ...
function soa:read (index, ...)
    local i = select("#", ...)
    local k = self.__order[#self.__order - i]

    if i < #self.__order then
        return self:read(index, self[k][index], ...)
    end
    
    return ...
end

---Inserts values at the specified index, almost like `table.insert`.
---@param index integer
---@param ... any
function soa:insert (index, ...)
    assert(#self.__order == select("#", ...), "must have the same amount of args as arrays")
    for i, k in ipairs(self.__order) do
        local item = select(i, ...)
        table.insert(self[k], index, item)
    end
end

---Removes values at the specified index and closes gaps, almost like `table.remove`.
---This returns the removed values in the same order as the arrays were defined.
---@param index integer
---@return ...
function soa:remove (index, ...)
    local i = select("#", ...)
    local k = self.__order[#self.__order - i]

    if i < #self.__order then
        return self:remove(index, table.remove(self[k], index), ...)
    end

    return ...
end

---Writes values to the end of each array.
---@param ... any
function soa:push (...)
    self:write(#self, ...)
end

---Removes values from the end of each array, returning them in the order the arrays were defined.
---@return ...
function soa:pop (...)
    local i = select("#", ...)
    local k = self.__order[#self.__order - i]

    if i < #self.__order then
        local item = self[k][#self[k]]
        self[k][#self[k]] = nil
        return self:pop(item, ...)
    end

    return ...
end

---Sorts every array by a specified name of an array. 
---If no comparison function is given, the specified array is sorted in ascending order.
---```lua
---local points = soa:build("name", "score")
---    ("Alice", 230)
---    ("Bobby", 500)
---    ("Carry", 132)
---()
---points:sort("score")
---for i, name, score in scores:iterate() do
---    print(name, score)
---    -- "Carry", 132
---    -- "Alice", 230
---    -- "Bobby", 500
---end
---```
---@param key string
---@param comp? fun(a, b): number
function soa:sort (key, comp, left, right)
    local list = self[key]
    assert(list, string.format("array named \"%s\" does not exist", key))
    assert(type(list) == "table", string.format("\"%s\" is not an array", key))

    comp = comp or function (a, b)
        return a - b
    end

    left = left or 1
    right = right or #list

    if left < right then
        local query = list[right]
        local i = left - 1

        for j = left, right - 1 do
            if comp(query, list[j]) >= 0 then
                i = i + 1
                self:swap(i, j)
            end
        end

        self:swap(i + 1, right)

        local p = i + 1
        
		self:sort(key, comp, left, p - 1)
		self:sort(key, comp, p + 1, right)
    end
end

---Swaps the values of two indexes for each array.
---@param a integer
---@param b integer
function soa:swap (a, b)
    for i, k in ipairs(self.__order) do
        local list = self[k]
        list[a], list[b] = list[b], list[a]
    end
end

---Creates a table based on the values at a specified index.
---```lua
---local scores = soa:new("name", "score")
---scores:write("Alice", 230)
---scores:write("Bobby", 132)
---
---local alice = scores:construct(1) 
---print(alice.name, alice.score) -- "Alice", 230
---```
---@param index integer
---@return table
function soa:construct (index, metatable)
    local struct = {}
    for _, k in ipairs(self.__order) do
        struct[k] = self[k][index]
    end

    if metatable then
        return setmetatable(struct, metatable)
    else
        return struct
    end
end

---Creates a function that returns the values from a specified index.
---```lua
---local scores = soa:new("name", "score")
---scores:write("Alice", 230)
---scores:write("Bobby", 132)
---
---local bobby = scores:construct(1) 
---print(bobby()) -- "Bobby", 132
---```
---@param index integer
---@return function
function soa:closure (index, ...)
    return function ()
        return self:read(index)
    end
end

---Creates an array of structs.
---@return table[]
function soa:aos ()
    local aos = {}
    for i = 1, #self do
        aos[i] = self:construct(i)
    end
    return aos
end

---Returns an iterator function, intended to be used in a for-loop.
---```lua
---for i, x, y, w, h in rectangles:iterator() do
---    print(name, score)
---end
---```
---@return function
function soa:iterate ()
    local i = 0
    local length = #self[self.__order[1]]
    
    return function ()
        i = i + 1
        if i <= length then
            return i, self:read(i)
        end
    end
end

return soa
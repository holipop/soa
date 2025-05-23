-- Struct of Arrays
-- by holipop

---@class soa
---@field __order string[] A list of strings representing the order of arrays.
---@field __lookup { [string]: number } A look-up table for the names of arrays and their positions in __order
---@field __build soa.builder The function used for `:build` binded to this instance.
local soa = {}
soa.__index = soa

soa._VERSION = "v1.2"
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


---- size ----

---Returns the length of the first array.
---@return integer
function soa:size ()
    return #self[self.__order[1]]
end

soa.__len = soa.size


---- new ----

local function soa_create_builder (self)
    local function step (...)
        if select("#", ...) == 0 then
            return self
        end
        self:write(self:size() + 1, ...)
        return step
    end

    return step
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
        __order = {},
        __lookup = {},
    }
    instance.__build = soa_create_builder(instance)

    local length = select("#", ...)

    for i = 1, length do
        local key = select(i, ...)
        instance[key] = {}
        instance.__order[i] = key
        instance.__lookup[key] = i
    end
    
    return setmetatable(instance, self)
end


---- build ----

---@alias soa.builder fun(...): soa.builder | soa

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
---@return soa.builder
function soa:build (...)
    local instance-- = self:new(...)
    if self == soa then
        instance = self:new(...)
    else
        instance = self
    end

    return instance.__build
end


---- from ----

local function soa_append_from_arr (self, aos)
    for _, k in ipairs(self.__order) do
        for i = 1, #aos do
            self[k][#self[k] + 1] = aos[i][k]
        end
    end

    return self
end

local function soa_create_from_arr (self, aos)
    local instance = {
        __order = {},
        __lookup = {},
    }
    instance.__build = soa_create_builder(instance)

    for k, _ in pairs(aos[1]) do
        table.insert(instance.__order, k)
        instance[k] = {}

        for i = 1, #aos do
            instance[k][i] = aos[i][k]
        end
    end
    table.sort(instance.__order)

    for i, k in ipairs(instance.__order) do
        instance.__lookup[k] = i
    end

    return setmetatable(instance, self)
end

local function soa_append_from_varargs(self, ...)
    local item = (select(1, ...))
    for _, k in ipairs(self.__order) do
        self[k][#self[k] + 1] = item[k]
    end

    if select("#", ...) == 1 then
        return self
    else
        return soa_append_from_varargs(self, select(2, ...))
    end
end

local function soa_create_from_varargs(self, ...)
    local instance = setmetatable({
        __order = {},
        __lookup = {},
    }, self)
    instance.__build = soa_create_builder(instance)

    local template = (select(1, ...))
    for k, v in pairs(template) do
        instance[k] = { v }
        table.insert(instance.__order, k)
    end
    table.sort(instance.__order)

    for i, k in ipairs(instance.__order) do
        instance.__lookup[k] = i
    end

    if select("#", ...) == 1 then
        return instance
    else
        return soa_append_from_varargs(instance, select(2, ...))
    end
end

---Constructs a struct of arrays from an array of structs. 
---This function uses the first entry as a template and assumes every proceeding entry contains the same keys as the first.
---The order of the keys are alphabetical.
---
---This can also be called on an instance to append it.
---
---For both constructing and appending, you can also pass in a variable amount of tables instead of an array.
---
---```lua
---local scores = soa:from({
---    { name = "Alice", score = 230 },
---    { name = "Bobby", score = 132, foo = true }, -- "foo" is ignored
---})
---
---scores:from(
---    { name = "Derek", score = 500 },
---    { name = "Erins", score = 210 }
---)
---```
---@param ... table
---@return soa
---@overload fun(aos: table[]): soa 
function soa:from (...)
    if #(select(1, ...)) > 0 then
        local aos = (select(1, ...))

        if self == soa then
            return soa_create_from_arr(self, aos)
        else
            return soa_append_from_arr(self, aos)
        end
    else
        if self == soa then
            return soa_create_from_varargs(self, ...)
        else
            return soa_append_from_varargs(self, ...)
        end
    end
end


---- write ----

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


---- read ----

---Reads from each of the arrays at the specified index, 
---returning each value in the same order the arrays were defined.
---```lua
---local scores = soa:new("name", "score")
---scores:write(1, "Alice", 230)
---scores:write(2, "Bobby", 132)
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


---- insert ----

---Inserts values at the specified index, similar to `table.insert`.
---@param index integer
---@param ... any
function soa:insert (index, ...)
    assert(#self.__order == select("#", ...), "must have the same amount of args as arrays")
    for i, k in ipairs(self.__order) do
        local item = select(i, ...)
        table.insert(self[k], index, item)
    end
end


---- remove ----

---Removes values at the specified index and closes gaps, similar to `table.remove`. 
---Returns the removed values.
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


---- push ----

---Writes values to the end of each array.
---@param ... any
function soa:push (...)
    self:write(self:size() + 1, ...)
end


---- pop ----

---Removes and returns values from the end of each array.
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


---- swap ----

---Swaps the values of two indexes for each array.
---@param a integer
---@param b integer
function soa:swap (a, b)
    for i, k in ipairs(self.__order) do
        local list = self[k]
        list[a], list[b] = list[b], list[a]
    end
end


---- construct ----

---Creates a table based on the values at a specified index.
---```lua
---local scores = soa:new("name", "score")
---scores:write(1, "Alice", 230)
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


---- closure ----

---Creates a function that returns the values from a specified index.
---The closure can optionally take a name of an array and return just that value.
---```lua
---local scores = soa:new("name", "score")
---scores:write(1, "Alice", 230)
---
---local alice = scores:closure(1) 
---print(alice()) -- "Alice", 230
---print(alice("score")) -- 230
---```
---@param index integer
---@return function
function soa:closure (index, ...)
    return function (key)
        if key then
            return (select(self.__lookup[key], self:read(index)))
        else
            return self:read(index)
        end
    end
end


---- aos ----

---Creates an array of structs.
---@return table[]
function soa:aos ()
    local aos = {}
    for i = 1, self:size() do
        aos[i] = self:construct(i)
    end
    return aos
end


---- iterate ----

---Returns an iterator function, intended for a for-in loop with each entry unpacked.
---```lua
---for i, name, score in scores:iterate() do
---    print(name, score)
---end
---```
---@return function
function soa:iterate ()
    local i = 0
    
    return function ()
        i = i + 1
        if i <= self:size() then
            return i, self:read(i)
        end
    end
end


---- view ----

local soa_view__i = -1
local soa_view__self = -2

local function soa_view_mt__index (t, k)
    return t[soa_view__self][k][t[soa_view__i]]
end

local function soa_view_mt__newindex (t, k, v)
    t[soa_view__self][k][t[soa_view__i]] = v
end

local function soa_view_mt__call (t, v)
    if v then
        t[soa_view__i] = v
    end
    return t[soa_view__i]
end

local soa_view_mt = {
    __index = soa_view_mt__index,
    __newindex = soa_view_mt__newindex,
    __call = soa_view_mt__call,
}

---Creates a "view" of an entry which references an entry in the struct-of-arrays with the behavior of a table. 
---If no index is given, it returns a view for index 1.
---
---You can change the index the view is referencing by calling it and passing an index.
---Calling also returns the index of the view.
---```lua
---local scores = soa:new("name", "score")
---scores:write(1, "Alice", 230)
---
---local view = scores:view(1)
---view.score = view.score + 50
---
---view(2)
---view.name = "Bobby"
---view.score = 400
---
---print(scores:read(1)) -- "Alice", 280
---print(scores:read(2)) -- "Bobby", 400
---```
---@param index? integer
---@return table
function soa:view (index)
    local view = {
        [soa_view__i] = index or 1,
        [soa_view__self] = self,
    }

    return setmetatable(view, soa_view_mt)
end


---- sort ----

local function soa_qsort_views (self, comp, left, right, a, b)
    if left < right then
        a(right)
        local i = left - 1

        for j = left, right - 1 do
            b(j)
            if comp(a, b) >= 0 then
                i = i + 1
                self:swap(i, j)
            end
        end

        self:swap(i + 1, right)

        local p = i + 1

		soa_qsort_views(self, comp, left, p - 1, a, b)
		soa_qsort_views(self, comp, p + 1, right, a, b)
    end

end

---Sorts each array by a comparison function, 
---behaving similarly to using `table.sort` on an array-of-structs.
---
---The comparison function given must have two parameters for two views and must return a number,
---where a negative number puts `a` before `b` and a positive number puts `b` after `a`.
---
---You can optionally supply your own views if you don't want to create garbage.
---```lua
---local points = soa:build("name", "score")
---    ("Alice", 230)
---    ("Bobby", 500)
---    ("Carry", 132)
---()
---
---points:sort(function(a, b)
---    return a.score - b.score
---end)
---
---for i, name, score in scores:iterate() do
---    print(name, score)
---    -- "Carry", 132
---    -- "Alice", 230
---    -- "Bobby", 500
---end
---@param comp fun(a: table, b: table): number
---@param a? table
---@param b? table
function soa:sort (comp, a, b)
    assert(comp, "missing comparison function")

    a = a or self:view()
    b = b or self:view()
    
    soa_qsort_views(self, comp, 1, self:size(), a, b)
end


---- scan ----

---Returns an iterator function.
---This takes in a view that will be incremented until it reaches the end of the struct-of-arrays.
---Note that the view returned is the same one in memory for each loop.
---
---If this is called with no arguments, a view is made automatically starting at 1.
---```lua
---local view = scores:view(5) -- for loop will start at i = 5
---
---for i, entry in scores:scan(view) do
---    entry.score = entry.score + 100
---    print(entry == view) -- true
---end
---```
---@param view? table
---@return function
function soa:scan (view)
    view = view or self:view()
    local index = 0

    return function ()
        index = index + 1
        if index <= self:size() then
            view(index)
            return index, view
        else
            view(1)
        end
    end
end

return soa
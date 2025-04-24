# soa

**soa** is a struct-of-arrays library focused on making it as easy to work with as an array-of-structs.

Structs-of-arrays in Lua tend to be more performant than a list of tables since creating tables is relatively expensive, but the biggest downside is how unwieldly they are to work with.

This library aims to remedy that with minimal overhead and thoughtful abstractions, all contained in the `soa` class.

## Installation

To use, place `soa.lua` in your project and require it.
```lua
local soa = require("soa") -- if it's in your root directory
local soa = require("path.to.soa") -- if it's in a subfolder
```

## Usage

You can create an empty struct-of-arrays with `soa:new`, with each argument being a key on the instance. The __order of the arguments are remembered__ for all operations.

```lua
local scoreboard = soa:new("name", "score")

scoreboard.name[1] = "Alice"
scoreboard.score[1] = 400
```

From here, you can `:read` and `:write` to this just like you would with an ordinary array.

```lua
scoreboard:write(1, "Alice", 400) 
-- at index 1, name = "Alice" and score = 400

local name, score = scoreboard:read(1)
print(name)  -- "Alice"
print(score) -- 400
```

We can get its length directly and iterate through it... (or use `:size`!)

```lua
for i = 1, #scoreboard do
    print(scoreboard:read(i))
end
```

...Or we can use the `:iterate` method in a for-in loop.

```lua
-- this does the same as above
for i, name, score in scoreboard:iterate() do
    print(name, score)
end
```

### Construction

Along with `soa:new`, there is also `:build` which is a cleaner way of instantiating a struct-of-arrays. Each entry is a parameter list and an empty set of parameters returns the instance.

```lua
local scoreboard = soa:build("name", "score")
    ("Alice", 400)
    ("Bobby", 230)
    ("Carry", 590)
()
```

You can also use `:from` to create a struct-of-arrays from an array-of-structs. It uses the first entry as a template and assumes every proceeding element contains all of the fields that the first one has. The arrays are then stored in **alphabetical order**.

```lua
local scoreboard = soa:from({
    { name = "Alice", score = 400 },
    { name = "Bobby", score = 230 },
    { name = "Carry", score = 590, foo = true }, -- "foo" will be disregarded
})
```

Additionally, `:from` can take in a variable amount of tables instead of an array-of-structs.

```lua
local p1 = { x = 3, y = 7 }
local p2 = { x = 6, y = 2 }

local points = soa:from(p1, p2)
```

### Manipulating Data

Along with `:write`, you can use both `:build` and `:from` to append existing instances.

```lua
scoreboard:build()
    ("Derek", 700)
    ("Emily", 230)
()

scoreboard:from({
    { name = "Frank", score = 120 },
    { name = "Ghile", score = 530 },
})
```

`:push` and `:pop` work just like a stack, with the popped items being returned.

```lua
scoreboard:push("Honey", 999)

local name, score = scoreboard:pop() -- entry is removed
```

`:swap` takes two indexes and swaps each entry's position.

```lua
local scoreboard = soa:build("name", "score")
    ("Alice", 400)
    ("Bobby", 230)
()

scoreboard:swap(1, 2)
print(scoreboard:read(1)) -- "Bobby", 230
print(scoreboard:read(2)) -- "Alice", 400
```

`:insert` and `:remove` work similarly to the functions `table.insert` and `table.remove` respectively, inserting an entry at a specified index without overwriting data and removing an entry without creating gaps in the arrays.

```lua
scoreboard:insert(3, "Clara", 300)

local name, score = scoreboard:remove(4)
```

### Deriving Data

Along with `:read` returning multiple values for an entry, there are a few other ways of retrieving data.

> Note that the following methods return copied data and don't mutate the original struct-of-arrays.

`:construct` creates a table with the data from a specified entry. You can optionally supply a metatable as the second argument.

```lua
local entry = scoreboard:construct(1)
print(entry.name, entry.score) -- "Alice", 400

-- with a metatable
local metatable = {
    __len = function (self)
        return self.score
    end
}
local alice = scoreboard:construct(1, metatable)
print(#alice) -- 400
```

`:closure` creates a function that returns the values of specified entry. You can also pass in a key to get a specific value.

```lua
local entry = scoreboard:closure(1)
print(entry())          -- "Alice", 400
print(entry("score"))   -- 400
```

`:aos` creates an array-of-structs from your struct-of-arrays.

```lua
local scoreboard = soa:build("name", "score")
    ("Alice", 400)
    ("Bobby", 230)
()

local aos = scoreboard:aos()

for i, entry in ipairs(aos) do
    print(entry.name, entry.score)
    -- "Alice", 400
    -- "Bobby", 230
end
```

### Views

A **view** allows you to modify an entry in the struct-of-arrays with the syntax of a table. You can create a view via `:view`.

```lua
local scoreboard = soa:build("name", "score")
    ("Alice", 400)
    ("Bobby", 230)
    ("Carry", 700)
()

local view = scoreboard:view(1)
view.name = "Allison"
view.score = view.score + 50

print(scoreboard:read(1)) -- "Allison", 450
```

> The way views are implemented means that using a view in `pairs` won't iterate through the entry's values.

In the example above, you can imagine `entry` as a variable that references values on index `1`. This means that if we swapped values between indexes, the view would still be looking at the same index.

```lua
scoreboard:swap(1, 2)
print(view.name, view.score) -- "Bobby", 230
```

We can change the index a view is referencing by calling it like a function, passing in an index. Calling also returns the index of the view.

```lua
view(2)
print(view.name, view.score) -- "Allison", 450

local index = view()
print(index)                   -- 2
```

With this functionality, we can iterate through a struct-of-arrays easily.

```lua
local view = scoreboard:view()

for i = 1, #scoreboard do
    view(i)
    print(view.name)
    -- "Alice"
    -- "Bobby"
    -- "Carry"
end
```

> Note that calling `:view` without any arguments will return a view referencing index 1.

However, we can use `:scan` as a much more convenient way to iterate in a for-in loop. The loop starts at the index of the view and increments by one.

If you don't pass a view into `:scan`, it creates one automatically starting at 1.

```lua
local view = scoreboard:view(2) -- starts the for loop at index 2

for i, entry in scoreboard:scan(view) do
    print(entry.name)
    -- "Bobby"
    -- "Carry"
    
    print(view == entry) -- true, these are the same table
end
```

> Note that the view returned is the same as the one supplied.

`:sort` utilizies views to make comparison between values intuitive, similar to `table.sort`. It takes a comparison function which takes in two views and must return a number.

```lua
function descending(a, b)
    return b.score - a.score
end

scoreboard:sort(descending)

for i, entry in scoreboard:scan() do
    print(entry.name, entry.score)
    -- "Carry", 700
    -- "Alice", 400
    -- "Bobby", 230
end
```

> If you don't want to create garbage, you can pass in your own views.
> 
> ```lua
> local a = scoreboard:view()
> local b = scoreboard:view()
>
> scoreboard:sort(descending, a, b)
> ```

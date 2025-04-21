# soa

**soa** is a struct-of-arrays library focused on making it as easy to work with as an array-of-structs.

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

We can get its length directly and iterate through it...

```lua
for i = 1, #scoreboard do
    print(scoreboard:read(i))
end
```

...Or we can use the `:iterate` method in a for-in loop.

```lua
for i, name, score in scoreboard:iterate() do
    scoreboard.score[i] = score + 50
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

You can also use `:from` to create a struct-of-arrays from an array-of-structs. 

```lua
local scoreboard = soa:from({
    { name = "Alice", score = 400 },
    { name = "Bobby", score = 230 },
    { name = "Carry", score = 590, valid = true },
    -- the "valid" field will be disregarded
})
```

It uses the first entry as a template and assumes every proceeding element contains all of the fields that the first one has. The arrays are then stored in **alphabetical order**.

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

local name, score = scoreboard:pop() -- entry is removed from scoreboard
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

`:insert` and `:remove` work almost to the functions `table.insert` and `table.remove` respectively, inserting an entry at a specified index without overwriting data and removing an entry without creating gaps in the arrays.

```lua
scoreboard:insert(3, "Clara", 300)

local name, score = scoreboard:remove(4)
```

`:sort` works like `table.sort` and sorts each array based on one of them and a given comparison function. If no function is given, then it sorts in ascending order.

```lua
function descending(a, b)
    return b - a
end

scoreboard:sort("score", descending)
print(scoreboard:read(1)) -- "Derek", 700
print(scoreboard:read(2)) -- "Ghile", 530
```

### Deriving Data

Along with `:read` returning multiple values for an entry, there are a few other ways of retrieving data.

`:construct` creates a table with the data from a specified entry.

```lua
local entry = scoreboard:construct(1)
print(entry.name, entry.score) -- "Alice", 400
```

`:closure` creates a function that returns the values of specified entry.

```lua
local entry = scoreboard:closure(1)
print(entry()) -- "Alice", 400
```

`:aos` returns an array-of-structs from your struct-of-arrays.

```lua
local scoreboard = soa:build("name", "score")
    ("Alice", 400)
    ("Bobby", 230)
()

local aos = scoreboard:aos()

for i, entry in ipairs(aos) do
    print(entry.name, entry.score)
end
```
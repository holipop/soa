# v1.2
- Removed `:shift`. Views can call on themselves to shift their index.
- A view can be passed into `:scan` which is then shifted starting at the index of that view.
- Calling `:view` without an index returns a view at index 1.
- A variable amount of tables can be passed into `:from` for instantiating and appending.
- `:sort` has been changed so it makes use of views.
- The function used for `:build` is now stored on `.__build` and is bound to the instance so it doesn't get garbage collected.
- Calling a view returns its index.
- Added `:size` for compatibility with 5.1.
- Changed the behavior of `:scan` to work with nested for loops.
- Updated annoations.
- Updated README.

# v1.1
- Added `:view`, `:shift`, and `:scan` methods for operations with views
- Functions created with `:closure` now accept a key for a parameter.
- Updated annoations.
- Updated README.
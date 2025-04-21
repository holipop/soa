# v1.2
- Removed `:shift`. Views can call on themselves to shift their index.
- A view can be passed into `:scan` which is then shifted starting at the index of that view.
- Calling `:view` without an index returns a view at index 1.
- A variable amount of tables can be passed into `:from` for instantiating and appending.
- `:sort` has been changed so it makes use of views.

# v1.1
- Added `:view`, `:shift`, and `:scan` methods for operations with views
- Functions created with `:closure` now accept a key for a parameter.
- Updated annoations.
- Updated README.
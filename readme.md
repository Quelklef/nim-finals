# finals

Transparent single-set attributes for Nim types

## Example

```nim
finals:
  type Point = object
    x*: int
    y {.final.}: int

# In another file...

var p: Point
p.x = 3  # fine
p.y = 4  # fine
p.x = 0  # fine
p.y = 1  # Error! `y` can only be set once!
```

## Usage

Like in the example. Must be run with `-d:debug`.

NOTE: This package does NOT work for types defined in the same module. This is because Nim ignores
getters (I think) and setters for same-module types. So in

```nim
# a.nim
finals:
  type X = object
    x {.final.}: int
```

`X.x` will only be protected for `.x=` calls from outside `a.nim`.

## Known bugs

#### Intolerant of other pragmas

If an attribute is marked with any pragmas besides `{.final.}`, those pragmas will be removed.

# finals

Transparent single-set attributes for Nim types

## Example

```nim
finals:
  type Point = object
    x*: int
    y* {.final.}: int

# In another file...

var p: Point
p.x = 3  # fine
p.y = 4  # fine
p.x = 0  # fine
p.y = 1  # Error! `y` can only be set once!
```

## Usage

Like in the example. Generalizes to variant types as well. Multiple typedefs may be present, as wel as
non-typdefs, which will be ignored.

#### For debugging

`finalsd` may be used instead of `finals` to only have an effect with `-d:debug`, and otherwise be a 0-cost noop.

## Gotchas

#### Name conflicts

The macro works by generating, for an attribute `a: A` on type `T`, a getter `proc a(o: T): A` and setter
``proc `a=`(o: T; v: A)``. If you define your own custom setters and getters, there will be a name conflict.

#### Module scoping

Unfortunately, getters and setters only have an effect outside of the module with the relevant typedef.
For instance,

```nim
# a.nim
finals:
  type X = object
    x* {.final.}: int
```

`X.x` will only be protected for `.x=` calls from outside `a.nim`.

This affects uses of `finals`, as well. `finals` only has an effect outside of the module it's used in.

## Known bugs

#### Intolerant of other pragmas

If an attribute is marked with any pragmas besides `{.final.}`, those pragmas will be removed.

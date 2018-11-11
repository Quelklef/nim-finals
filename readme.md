# finals

(Mostly) Transparent single-set attributes for Nim types

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

Like in the example. Generalizes to variant types as well. In a `finals:` block, multiple typedefs may be present, as well as
non-typdefs, which will be ignored.

#### For debugging

`finalsd` may be used instead of `finals` to only have an effect with `-d:debug`, and otherwise be a 0-cost noop.

## Gotchas

#### Name conflicts

The `finals` macro works by generating, for an attribute `a: A` on type `T`, a getter `proc a(o: T): A` and setter
``proc `a=`(o: T; v: A)``. If you define your own custom setters and getters, there will be a name conflict.

#### Module scoping

Unfortunately, the `finals` macro only has an effect _outside_ of the module containing the typedef.
This is because getters and setters are ignored within the same module. It's due to a Nim feature and
is unavoidable.

```nim
# a.nim
finals:
  type X = object
    x* {.final.}: int
```

`X.x` will only be protected for `.x=` calls from _outside_ `a.nim`. This means that the following will
not result in an error:

```nim
# a.nim (continued)
var o* = X()
o.x = 3

# b.nim
import a
o.x = 4
```

In order to circumvent this issue, an user may manually finalize an attribute `X` by calling `ffinalizeX(o)`
(the extra "f" stands for "finals" is added to avoid name conflicts). The previous example would be fixed
like so:

```nim
# a.nim (continued)
var o* = X()
o.x = 3
o.finalizeX();

# b.nim
import a
o.x = 4  # error!
```

#### Contructors and Object Hierarchies

In order for the `finals` macro to work, attributes marked with `{.final.}` are explicitely NOT exported.
Due to this, there is an issue with constructors and object hierarchies:

```nim
finals:
  type Parent* = ref object
    p* {.final.}: int
  type Child* = ref object
    c* {.final.}: int

let c = Child(c: 2, p: 3)  # error! `p` is not accessible
```

## Known bugs

#### Intolerant of other pragmas

If an attribute is marked with any pragmas besides `{.final.}`, those pragmas will be removed.

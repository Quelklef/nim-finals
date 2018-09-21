# finals

Transparent single-set attributes for Nim types

## Example

```nim
mapFinals:
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

NOTE: Attributes can be set multiple times if being set in the same module. This is because `.x` attribute referencing ignores defined getters if the type is defined in the same module.

## Known bugs

#### `{.final.}` attributes cannot be exported

If an attribute is marked with `{.final.}`, then it should NOT be exported. `{.final.}` will also automatically export attributes.

(Note to self: when fixing, a non-exported `{.final.}` object should be a noop)

#### Intolerant of other pragmas

If an attribute is marked with any pragmas besides `{.final.}`, those pragmas will be removed.

#### Does not work perfectly with `var`, `ref`, and `ptr` types.

If the type augmented with `{.finals.}` or `mapFinals:` is a `var`, `ref`, or `ptr` type, the generated setter will still wrap the type in another `var` type.

Example:

```nim
mapFinals:
  type X = ref object
    x {.final.} int
```

Will generate:

```
proc `x=`(obj: var X; val: int) =
  ...
```

when really `obj` should just be of type `X` since `var` types are mutable.

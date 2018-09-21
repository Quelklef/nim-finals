import ../../finals

finals:
  type Variant = object
    case a: bool
    of true:
      b {.final.}: int
    of false:
      c*: int
      case d: bool
      of true:
        e {.final.}: int
      else:
        f: int

proc initVariant*(): Variant =
  return Variant(a: false, c: 0, d: true, e: 0)

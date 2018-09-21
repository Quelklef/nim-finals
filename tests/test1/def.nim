import ../../finals

mapFinals:
  type Point* = object
    x*: int
    y {.final.}: int

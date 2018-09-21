import ../../finals

finals:
  type Point* = object
    x*: int
    y {.final.}: int

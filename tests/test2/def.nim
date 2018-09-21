import ../../finals

finals:
  type X = ref object
    x {.final.}: int

proc newX*(): X =
  new(result)

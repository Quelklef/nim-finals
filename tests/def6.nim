import ../finals

finals:
  type T* = ref object
    p* {.final.}: int

var x* = T(p: 2)
x.ffinalizeP()

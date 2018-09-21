import ../../finals
import def

let x = newX()
x.x = 3

try:
  x.x = 3
  assert(false)
except FinalAttributeError:
  discard

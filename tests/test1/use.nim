import ../../finals
import def

var p: Point
p.x = 0
p.y = 0
p.x = 0

try:
  p.y = 0
  assert false
except FinalAttributeError:
  discard

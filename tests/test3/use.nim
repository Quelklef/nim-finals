import ../../finals
import def

var v = initVariant()

v.c = 0
v.e = 0

v.c = 1

try:
  v.e = 1
  assert(false)
except FinalAttributeError:
  discard

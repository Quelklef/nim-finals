import ../finals
import def6

try:
  x.p = 3
  assert(false)
except FinalAttributeError:
  discard

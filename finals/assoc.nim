type Assoc*[K, V] = object
  ## An association list
  keys*: seq[K]
  vals*: seq[V]

proc initAssoc*[K, V](): Assoc[K, V] =
  return Assoc[K, V](
    keys: @[],
    vals: @[],
  )

proc `[]`*[K, V](assoc: Assoc[K, V]; k: K): V =
  for i, key in assoc.keys:
    if key == k:
      return assoc.vals[i]
  assert false

proc `[]=`*[K, V](assoc: var Assoc[K, V]; k: K, v: V) =
  for i, key in assoc.keys:
    if key == k:
      assoc.vals[i] = v
      return

  assoc.keys.add(k)
  assoc.vals.add(v)

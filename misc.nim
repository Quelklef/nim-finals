proc abort*(T: typedesc): T =
  ## Generates code that is typed with the given type
  ## but will fail if it is ever reached
  assert(false)

proc abort*() =
  ## Generates code that will fail on execution
  assert(false)

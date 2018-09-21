import assoc
import macros

# TODO: Integrate into Nim hierarchy
type FinalAttributeError* = object of Exception

type Table[K, V] = Assoc[K, V]
proc initTable[K, V](): Table[K, V] = initAssoc[K, V]()

proc ensureNoPostfix(node: NimNode): NimNode =
  case node.kind
  of nnkPostfix:
    return node[1]
  else:
    return node

proc contains(n0, n1: NimNode): bool =
  for child in n0:
    if child == n1:
      return true

proc marked(node: NimNode): bool =
  node.expectKind(nnkIdentDefs)

  return node[0].kind == nnkPragmaExpr and newIdentNode("final") in node[0][1]

proc unmark(node: NimNode): NimNode =
  # TODO: Does not tolerate extra pragmas
  node.expectKind(nnkIdentDefs)
  node[0].expectKind(nnkPragmaExpr)

  result = node.copyNimTree()
  result[0] = result[0][0]

proc makeSentinel(node: NimNode; attrTable: var Table[NimNode, NimNode]): NimNode =
  node.expectKind(nnkIdentDefs)
  let sentinelName = genSym(nskField, $node[0][0].ensureNoPostfix & "_set")
  attrTable[node] = sentinelName

  return nnkIdentDefs.newTree(
      sentinelName,
      newIdentNode("bool"),
      newEmptyNode(),
    )

proc mapTypeBody(body: NimNode; attrTable: var Table[NimNode, NimNode]): NimNode =
  if body.kind == nnkDiscardStmt:
    return body

  result = body.copyNimTree
  for i, child in result:
    case child.kind
    of nnkRecCase:
      result[i][1][1] = mapTypeBody(result[i][1][1], attrTable)
    of nnkIdentDefs:
      if child.marked:
        result[i] = result[i].unmark
        result.add(makeSentinel(child, attrTable))
    else: assert false

proc makeProcs(objType, body: NimNode; attrTable: var Table[NimNode, NimNode]): seq[NimNode] =
  case body.kind
  of nnkDiscardStmt:
    discard
  of nnkRecList:
    for child in body:
      result.add(makeProcs(objType, child, attrTable))
  of nnkRecCase:
    for child in result[1][1]:
      result.add(makeProcs(objType, child, attrTable))
  of nnkIdentDefs:
    if body.marked:
      let valType = body[1]
      let attrName = body[0][0].ensureNoPostfix
      let sentinelName = attrTable[body]
      let procName = newIdentNode($attrName & "=")
      let exMsg = $attrName & " cannot be set twice!"
      let procedure = (quote do:
        # TODO: `var` here uses an assumption
        # Should be `var` for `object` and noop for `var`, `ref`, `ptr`.
        proc `procName`*(obj: var `objType`; val: `valType`) =
          if obj.`sentinelName`:
            raise FinalAttributeError.newException(`exMsg`)
          obj.`attrName` = val
          obj.`sentinelName` = true
      )
      result.add(procedure)
  else: assert false

proc mapTypedef(typedef: NimNode): (NimNode, seq[NimNode]) =
  typedef.expectKind(nnkTypedef)
  typedef[2].expectKind(nnkObjectTy)

  var attrTable = initTable[NimNode, NimNode]()
  var resultTypedef = typedef.copyNimTree
  resultTypedef[2][2] = mapTypeBody(resultTypedef[2][2], attrTable)

  return (resultTypedef, makeProcs(typedef[0].ensureNoPostfix, typedef[2][2], attrTable))

macro finals*(typedef: untyped): untyped =
  when defined(debug):
    let (typeDef, procs) = mapTypedef(typedef)
    return nnkStmtList.newTree(
      nnkTypeSection.newTree(typeDef)
    ).add(procs)
  else:
    return typedef

proc mapTypeSection(typeSec: NimNode): (NimNode, seq[NimNode]) =
  typeSec.expectKind(nnkTypeSection)

  var resultTypeSec = typeSec.copyNimTree()
  var resultProcs: seq[NimNode] = @[]
  for i, child in resultTypeSec:
    if child.kind == nnkTypedef:
      let (mapped, procs) = mapTypedef(child)
      resultTypeSec[i] = mapped
      resultProcs.add(procs)

  return (resultTypeSec, resultProcs)

proc mapStmts(stmts: NimNode): NimNode =
  stmts.expectKind(nnkStmtList)

  result = stmts.copyNimTree()
  for i, child in result:
    if child.kind == nnkTypeSection:
      let (typeSec, procs) = mapTypeSection(child)
      result[i] = typeSec
      result.add(procs)

macro mapFinals*(stmts: untyped): untyped =
  when defined(debug):
    result = mapStmts(stmts)
    echo(result.repr)
  else:
    result = stmts

macro final*(node: untyped): untyped =
  ## Must be included to keep the compiler yelling about undeclared routine 'final'
  return node

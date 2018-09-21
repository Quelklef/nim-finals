import macros
import sugar

import assoc

# TODO: Integrate into Nim hierarchy
type FinalAttributeError* = object of Exception

type Table[K, V] = Assoc[K, V]
proc initTable[K, V](): Table[K, V] = initAssoc[K, V]()

proc deepMap(node: NimNode; f: NimNode -> NimNode): NimNode =
  result = f(node.copyNimTree)
  for i, child in result:
    result[i] = child.deepMap(f)

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
    else: assert(false)

proc makeProcs(minimalMutableObjType, body: NimNode; attrTable: var Table[NimNode, NimNode]): seq[NimNode] =
  case body.kind
  of nnkDiscardStmt:
    discard
  of nnkRecList:
    for child in body:
      result.add(makeProcs(minimalMutableObjType, child, attrTable))
  of nnkRecCase:
    for child in result[1][1]:
      result.add(makeProcs(minimalMutableObjType, child, attrTable))
  of nnkIdentDefs:
    if body.marked:
      let valType = body[1]
      let attrName = body[0][0].ensureNoPostfix
      let sentinelName = attrTable[body]
      let procName = newIdentNode($attrName & "=")
      let exMsg = $attrName & " cannot be set twice!"
      let procedure = (quote do:
        proc `procName`*(obj: `minimalMutableObjType`; val: `valType`) =
          if obj.`sentinelName`:
            raise FinalAttributeError.newException(`exMsg`)
          obj.`attrName` = val
          obj.`sentinelName` = true
      )
      result.add(procedure)
  else: assert(false)

proc makeMinimalMutableObjType(typedef: NimNode): NimNode =
  case typedef[2].kind
  of nnkObjectTy:
    return nnkVarTy.newTree(typedef[0].ensureNoPostfix)
  of nnkVarTy, nnkRefTy, nnkPtrTy:
    return typedef[0].ensureNoPostfix
  else: assert(false)

proc findObjectTy(node: NimNode): NimNode =
  case node.kind
  of nnkObjectTy:
    return node
  else:
    return node[0].findObjectTy

proc mapTypedef(typedef: NimNode): (NimNode, seq[NimNode]) =
  typedef.expectKind(nnkTypedef)

  var attrTable = initTable[NimNode, NimNode]()
  var objectTy = findObjectTy(typedef[2])
  var resultTypedef = typedef.copyNimTree
  var resultObjectTy = findObjectTy(resultTypedef[2])
  resultObjectTy[2] = mapTypeBody(resultObjectTy[2], attrTable)

  return (resultTypedef, makeProcs(makeMinimalMutableObjType(typedef), objectTy[2], attrTable))

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

  when not defined(debug):
    return stmts.deepMap(node => (if node.kind == nnkIdentDefs and node.marked: node.unmark else: node))
  else:
    result = stmts.copyNimTree()
    for i, child in result:
      if child.kind == nnkTypeSection:
        let (typeSec, procs) = mapTypeSection(child)
        result[i] = typeSec
        result.add(procs)

macro finals*(stmts: untyped): untyped =
  result = mapStmts(stmts)
  echo(result.repr)


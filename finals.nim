import assoc
import macros

type Table[K, V] = Assoc[K, V]
proc initTable[K, V](): Table[K, V] = initAssoc[K, V]()

proc contains(n0, n1: NimNode): bool =
  for child in n0:
    if child == n1:
      return true

proc marked(node: NimNode): bool =
  node.expectKind(nnkIdentDefs)
  node[0].expectKind(nnkPragmaExpr)
  return newIdentNode("final") in node[0][1]

proc makeSentinel(node: NimNode; attrTable: var Table[NimNode, NimNode]): NimNode =
  node.expectKind(nnkIdentDefs)
  let sentinelName = genSym(nskType, $node[0][0])
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
      if body.marked:
        result.add(makeSentinel(child, attrTable))
    else: assert false

proc makeProcs(objType, body: NimNode; attrTable: var Table[NimNode, NimNode]): seq[NimNode] =
  case body.kind
  of nnkDiscardStmt:
    discard
  of nnkRecCase:
    for child in result[1][1]:
      result.add(makeProcs(objType, child, attrTable))
  of nnkIdentDefs:
    if body.marked:
      let valType = body[2]
      let attrName = body[0]
      let sentinelName = attrTable[body]
      let procName = newIdentNode($attrName & "=")
      let procedure = (quote do:
        proc `procName`*(obj: `objType`; val: `valType`) =
          if obj.`sentinelName`:
            assert false
          obj.`attrName` = val
      )
      result.add(procedure)
  else: assert false

proc mapTypedef(typedef: NimNode): NimNode =
  typedef.expectKind(nnkTypedef)
  typedef[2].expectKind(nnkObjectTy)

  var attrTable = initTable[NimNode, NimNode]()
  var resultTypedef = typedef.copyNimTree
  resultTypeDef[2][2] = mapTypeBody(resultTypeDef[2][2], attrTable)
  result = nnkStmtList.newTree(resultTypedef).add(makeProcs(typedef[0], resultTypeDef[2][2], attrTable))

macro finals*(typedef: untyped): untyped =
  when defined(debug):
    return mapTypedef(typedef)
  else:
    return typedef



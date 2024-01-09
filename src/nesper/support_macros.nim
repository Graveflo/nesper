import std/macros

macro import_vals*(tn: typed, header_file: typed, names: untyped) =
  names.expectKind(nnkStmtList)
  var resultStmtLet = newTree(nnkLetSection)
  
  let itt: NimNode = if names[0].kind in {nnkLetSection, nnkConstSection}:
    names[0]
  else:
    names
  
  if itt.isNil: error("unsupported statement kind")
  for child in itt:
    var sname: NimNode
    case child.kind
    of nnkIdent:
      sname = child
    of nnkAsgn:
      sname = child[0]
    of nnkConstDef:
      if child[0].kind in {nnkPostfix}:
        sname = child[0][1]
      else:
        sname = child[0]
    else:
      error("Unexpected node kind for declaration(" & $child.kind & "): " & repr(child))
    resultStmtLet.add (quote do:
      let `sname.strVal`* {.importc, header: `header_file`.}: `tn`)[0]
  resultStmtLet

template borrowBasicOperations*(typ: typedesc) =
  proc `+` *(x, y: typ): typ {.borrow.}
  proc `-` *(x, y: typ): typ {.borrow.}

  proc `<` *(a, b: typ): bool {.borrow.}
  proc `<=` *(a, b: typ): bool {.borrow.}
  proc `==` *(a, b: typ): bool {.borrow.}

  proc `$` *(v: typ): string {.borrow.}

import strutils, sequtils, sugar, macros

type JsAstKind* = enum
  NONE
  VALUE_STRING
  VALUE_NUMBER
  VALUE_IDENT
  OP_BIN_ADD
  OP_BIN_SUB
  OP_BIN_MUL
  OP_BIN_DIV
  OP_SUBSCRIPT
  OP_INVOKE
  OP_ARROW_FUNC

type JsAst* = ref object of RootObj
  kind: JsAstKind

type JsValue* = ref object of JsAst;
type JsString* = ref object of JsValue
  value: string

type JsNumber* = ref object of JsValue
  value: float

type JsIdent* = ref object of JsValue
  value: string

type JsExpr* = ref object of JsAst;
type JsBinOpAdd* = ref object of JsExpr
  left: JsAst
  right: JsAst

type JsBinOpSub* = ref object of JsExpr
  left: JsAst
  right: JsAst

type JsBinOpMul* = ref object of JsExpr
  left: JsAst
  right: JsAst

type JsBinOpDiv* = ref object of JsExpr
  left: JsAst
  right: JsAst

type JsSubScript* = ref object of JsExpr
  value: JsAst
  index: JsAst

type JsOpInvoke* = ref object of JsExpr
  value: JsAst
  args: seq[JsAst]

type JsOpArrowFunc* = ref object of JsExpr
  params: seq[string]
  children: JsAst

proc toJsString*(x: string): JsString
proc toJsNumber*(x: float): JsNumber
proc toJsIdent*(x: string): JsIdent

type JsConvertable* = int or float or string

proc toJsValue*(x: JsConvertable): JsAst =
  return
    if (x is float):
      cast[float](x).toJsNumber
    elif (x is int):
      cast[int](x).toFloat.toJsNumber
    else: cast[string](x).toJsString

proc `'jss`*(x: string): JsAst = x.toJsString
proc `'jsn`*(x: string): JsAst = x.parseFloat.toJsNumber
proc jsi*(x: string): JsAst = x.toJsIdent
proc jss*(x: string): JsAst = x.toJsString

proc `+`*(x: JsConvertable, y: JsAst): JsBinOpAdd = JsBinOpAdd(kind: JsAstKind.OP_BIN_ADD, left: x.toJsValue, right: y)
proc `-`*(x: JsConvertable, y: JsAst): JsBinOpSub = JsBinOpSub(kind: JsAstKind.OP_BIN_SUB, left: x.toJsValue, right: y)
proc `*`*(x: JsConvertable, y: JsAst): JsBinOpMul = JsBinOpMul(kind: JsAstKind.OP_BIN_MUL, left: x.toJsValue, right: y)
proc `/`*(x: JsConvertable, y: JsAst): JsBinOpDiv = JsBinOpDiv(kind: JsAstKind.OP_BIN_DIV, left: x.toJsValue, right: y)
proc `[]`*(x: JsConvertable, i: JsAst): JsSubScript = JsSubScript(kind: JsAstKind.OP_SUBSCRIPT, value: x.toJsValue, index: i)

proc `+`*(x: JsAst, y: JsConvertable): JsBinOpAdd = JsBinOpAdd(kind: JsAstKind.OP_BIN_ADD, left: x, right: y.toJsValue)
proc `-`*(x: JsAst, y: JsConvertable): JsBinOpSub = JsBinOpSub(kind: JsAstKind.OP_BIN_SUB, left: x, right: y.toJsValue)
proc `*`*(x: JsAst, y: JsConvertable): JsBinOpMul = JsBinOpMul(kind: JsAstKind.OP_BIN_MUL, left: x, right: y.toJsValue)
proc `/`*(x: JsAst, y: JsConvertable): JsBinOpDiv = JsBinOpDiv(kind: JsAstKind.OP_BIN_DIV, left: x, right: y.toJsValue)
proc `[]`*(x: JsAst, i: JsConvertable): JsSubScript = JsSubScript(kind: JsAstKind.OP_SUBSCRIPT, value: x, index: i.toJsValue)

proc `+`*(x: JsAst, y: JsAst): JsBinOpAdd = JsBinOpAdd(kind: JsAstKind.OP_BIN_ADD, left: x, right: y)
proc `-`*(x: JsAst, y: JsAst): JsBinOpSub = JsBinOpSub(kind: JsAstKind.OP_BIN_SUB, left: x, right: y)
proc `*`*(x: JsAst, y: JsAst): JsBinOpMul = JsBinOpMul(kind: JsAstKind.OP_BIN_MUL, left: x, right: y)
proc `/`*(x: JsAst, y: JsAst): JsBinOpDiv = JsBinOpDiv(kind: JsAstKind.OP_BIN_DIV, left: x, right: y)
proc `[]`*(x: JsAst, i: JsAst): JsSubScript = JsSubScript(kind: JsAstKind.OP_SUBSCRIPT, value: x, index: i)

{.experimental: "callOperator".}
proc `()`*(value: JsAst, args: varargs[JsAst]): JsOpInvoke = JsOpInvoke(kind: JsAstKind.OP_INVOKE, value: value, args: @args)

proc padStart(x: var string, maxlen: int, fillChar: char): string =
  while (x.len < maxlen):
    x &= fillChar
  return x

proc padStart(x: string, maxlen: int, fillChar: char): string =
  var x = x
  return x.padStart(maxlen, fillChar)

proc compile*(tree: JsAst): string;

proc compile*(trees: openArray[JsAst]): seq[string] =
  var res = seq[string](@[])
  for x in trees:
    res.add(x.compile())
  return res

proc compile*(tree: JsAst): string =
  if (tree.kind == VALUE_NUMBER):
    var tree = cast[JsNumber](tree)
    return tree.value.formatFloat(ffDefault, -1)
  elif (tree.kind == VALUE_STRING):
    var value = (cast[JsString](tree).value)
    var res: string = ""
    for c in value:
      res &= (
        if (c == '\\'): "\\\\"
        elif (c == '\r'): "\\r"
        elif (c == '\n'): "\\n"
        elif (c == '\t'): "\\t"
        elif (c == '\v'): "\\v"
        elif (c == '\b'): "\\b"
        elif (c == '\f'): "\\f"
        elif (c.isAlphaAscii or c.isAlphaNumeric): "" & c
        else: "\\x" & (int(c).toHex(2).padStart(2, '0'))
      )
    return "\"" & res & "\""
  elif (tree.kind == VALUE_IDENT):
    return cast[JsIdent](tree).value
  elif (tree.kind == OP_BIN_ADD):
    var tree: JsBinOpAdd = cast[JsBinOpAdd](tree)
    return tree.left.compile & " + " & tree.right.compile
  elif (tree.kind == OP_BIN_SUB):
    var tree: JsBinOpSub = cast[JsBinOpSub](tree)
    return tree.left.compile & " - " & tree.right.compile
  elif (tree.kind == OP_BIN_MUL):
    var tree: JsBinOpSub = cast[JsBinOpSub](tree)
    return tree.left.compile & " * " & tree.right.compile
  elif (tree.kind == OP_BIN_DIV):
    var tree: JsBinOpSub = cast[JsBinOpSub](tree)
    return tree.left.compile & " / " & tree.right.compile
  elif (tree.kind == OP_SUBSCRIPT):
    var tree: JsSubScript = cast[JsSubScript](tree)
    return "" & tree.value.compile & "[" & tree.index.compile & "]"
  elif (tree.kind == OP_INVOKE):
    var tree: JsOpInvoke = cast[JsOpInvoke](tree)
    return "" & tree.value.compile & "(" & tree.args.compile().join(", ") & ")"
  elif (tree.kind == OP_ARROW_FUNC):
    var tree: JsOpArrowFunc = cast[JsOpArrowFunc](tree)
    return "(" & tree.params.join(", ") & ") => " & tree.children.compile
  else:
    return ""

proc toJsString*(x: string): JsString = JsString(kind: JsAstKind.VALUE_STRING, value: x)
proc toJsNumber*(x: float): JsNumber = JsNumber(kind: JsAstKind.VALUE_NUMBER, value: x)
proc toJsIdent*(x: string): JsIdent = JsIdent(kind: JsAstKind.VALUE_IDENT, value: x)

proc createArrowFunc*(params: seq[string], children: JsAst): JsOpArrowFunc = JsOpArrowFunc(kind: JsAstKind.OP_ARROW_FUNC, params: params, children: children)

macro js*(code): untyped =
  case code.kind
  of nnkInfix:
    if code[0].strVal == "=>" and code[1].kind == nnkTupleConstr or code[1].kind == nnkPar:
      var params: seq[string] = @[]
      for x in code[1]:
        x.expectKind(nnkIdent)
        params.add(x.strVal)
      return newCall(
        ident("createArrowFunc"),
        newLit(params),
        code[2]
      )
  else: error("")
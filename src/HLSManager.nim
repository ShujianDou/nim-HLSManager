import std/[strutils]
import system/[io]
import parseUtils


type
  Param* = object
    key*: string
    value*: string
  Head* = object
    header*: string
    values*: seq[Param]
  HLSStream* = object
    parts*: seq[Head]

proc toString(str: seq[char]): string =
  result = newStringOfCap(len(str))
  for ch in str:
    add(result, ch)

proc parseOptions(text: string): seq[Param] =
  var charTracker: seq[char]
  var inQuote: bool = false
  var inValue: bool = false
  var params: seq[Param]
  var cParam: Param = Param()
  var idx = 0
  while idx < len(text):
    if not inValue:
      case text[idx]:
        of '=':
          cParam.key = charTracker.toString()
          newSeq(charTracker, 0)
          inValue = true
          if text[idx + 1] == '\"':
            idx = idx + 1
            inQuote = true
        else:
          charTracker.add(text[idx])
    elif not inQuote:
      if text[idx] == ',':
        cParam.value = charTracker.toString()
        newSeq(charTracker, 0)
        inValue = false
        params.add(cParam)
        cParam = Param()
      else:
        charTracker.add(text[idx])
    elif inQuote:
      if text[idx] == '\"':
        cParam.value = charTracker.toString()
        newSeq(charTracker, 0)
        inValue = false
        inQuote = false
        params.add(cParam)
        cParam = Param()
        idx = idx + 1
      else:
        charTracker.add(text[idx])
    inc idx
  return params


proc ParseManifest*(text: seq[string]): HLSStream =
    var stream: HLSStream = HLSStream()
    var i: int = 0
    while i < len(text):
      if text[i] == "":
        inc i
        continue
      let id: int = skipUntil(text[i], ':') + 1
      if id >= len(text[i]):
        inc i
        continue
      echo id
      echo text[i]
      var str: seq[string] = @[text[i][0..id - 1], text[i][id..^1]]
      if(text[i][0] != '#'):
        stream.parts.add(Head(header: "URI", values: @[Param(key: "URI", value: text[i])]))
        inc i
        continue
      if(str[0] == "#EXTM3U"):
        var hParams: seq[Param]
        hParams.add(Param(key: "version", value: str[^1]))
        stream.parts.add(Head(header: "head", values: hParams))
      else:
        stream.parts.add(Head(header: str[0], values: parseOptions(str[1])))
      inc i
    return stream

proc ParseManifest*(file: File): HLSStream =
  var stream: HLSStream = HLSStream()
  while file.endOfFile == false:
    var rStr = file.readLine()
    let i: int = skipUntil(rStr, ':') + 1
    if i >= len(rStr):
      continue
    var str: seq[string] = @[rStr[0..i - 1], rStr[i..^1]]
    if(rStr[0] != '#'):
      var ba: seq[Param]
      ba.add(Param(key: "URI", value: rStr))
      stream.parts.add(Head(header: "URI", values: ba))
      continue
    if(str[0] == "#EXTM3U"):
      var hParams: seq[Param]
      str = split(file.readLine(), ':')
      hParams.add(Param(key: "version", value: str[^1]))
      stream.parts.add(Head(header: "head", values: hParams))
    else:
      stream.parts.add(Head(header: str[0], values: parseOptions(str[1])))
  return stream


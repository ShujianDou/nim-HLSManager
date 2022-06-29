import std/[strutils]
import system/[io]


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
  var flag: bool = false
  var params: seq[Param]
  var cParam: Param = Param()
  for i in text.items:
    if(flag == true):
      if(i == ','):
        cParam.value = replace(toString(charTracker), "\"", "")
        newSeq(charTracker, 0)
        flag = false
        params.add(cParam)
        cParam = Param()
        continue
      charTracker.add(i)
    else:
      case i:
        of '=':
          cParam.key = toString(charTracker)
          newSeq(charTracker, 0)
          flag = true
          continue
        of '\"':
          params[len(params) - 1].value = params[len(params) - 1].value & "," & toString(charTracker)
          newSeq(charTracker, 0)
          continue
        of ',':
          continue
        else:
          charTracker.add(i)
  return params


proc ParseManifest*(text: seq[string]): HLSStream =
    var stream: HLSStream = HLSStream()
    var i: int = 0
    while i < len(text):
      var str: seq[string] = split(text[i], ':')
      if(str[0] == "#EXTM3U"):
        var hParams: seq[Param]
        str = split(text[i], ':')
        hParams.add(Param(key: "version", value: str[1]))
        stream.parts.add(Head(header: "head", values: hParams))
      else:
        stream.parts.add(Head(header: str[0], values: parseOptions(str[1])))
      inc i
    return stream

proc ParseManifest*(file: File): HLSStream =
  var stream: HLSStream = HLSStream()
  while file.endOfFile == false:
    var rStr = file.readLine()
    var str: seq[string] = split(rStr, ':')
    if(rStr[0] != '#'):
      var ba: seq[Param]
      ba.add(Param(key: "URI", value: rStr))
      stream.parts.add(Head(header: "URI", values: ba))
      continue
    if(str[0] == "#EXTM3U"):
      var hParams: seq[Param]
      str = split(file.readLine(), ':')
      hParams.add(Param(key: "version", value: str[1]))
      stream.parts.add(Head(header: "head", values: hParams))
    else:
      stream.parts.add(Head(header: str[0], values: parseOptions(str[1])))
  return stream


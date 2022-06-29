 EXAMPLE:

import strutils
import HLSManager

var testManifest: File = open("/mnt/Aerial/work/Programming/HLSManager/src/master.m3u8", FileMode.fmRead)

let strea: HLSStream = ParseManifest(testManifest)

for param in strea.parts:
    echo "header: $1" % [param.header]
    for val in param.values:
        echo "  Key: $1\n   Value: $2" % [val.key, val.value]

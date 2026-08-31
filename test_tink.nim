# test_tink.nim —— unit tests for tink.nim. Run: nim c -r test_tink.nim
import options
import tink

proc check(cond: bool, name: string, failures: var int) =
  if cond:
    echo "[PASS] ", name
  else:
    inc failures
    echo "[FAIL] ", name

var failures = 0

# crc32 check vector
check(tinkCrc32(@[0x31'u8, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39]) == 0xCBF43926'u32,
      "crc32 vector", failures)

# frame roundtrip
let p = @[1'u8, 2, 3]
let frame = tinkFrameEncode(p)
check(frame.len == p.len + 8, "frame length", failures)
let got = tinkFrameNext(frame, 0)
check(got.isSome, "frame present", failures)
if got.isSome:
  let g = got.get()
  check(g.next == frame.len, "frame next == length", failures)
  check(g.payload == p, "frame payload roundtrip", failures)

# empty frame roundtrip
let fe = tinkFrameEncode(newSeq[byte](0))
let ge = tinkFrameNext(fe, 0)
check(ge.isSome and ge.get().next == fe.len and ge.get().payload.len == 0,
      "empty frame roundtrip", failures)

# CRC tamper rejected
let ft = tinkFrameEncode(p)
var tampered = ft
tampered[4] = byte(int(tampered[4]) + 1) # tamper payload[0]
check(tinkFrameNext(tampered, 0).isNone, "crc tamper rejected", failures)

# frameSkip matches length
let fs = tinkFrameEncode(p)
check(tinkFrameSkip(fs, 0).isSome and tinkFrameSkip(fs, 0).get() == fs.len,
      "frameSkip matches length", failures)

# out of bounds
check(tinkFrameNext(frame, frame.len).isNone, "frameNext out of bounds", failures)
check(tinkFrameSkip(frame, frame.len).isNone, "frameSkip out of bounds", failures)
check(tinkFrameNext(newSeq[byte](0), 0).isNone, "frameNext empty input", failures)

if failures > 0:
  echo failures, " checks FAILED"
  quit(1)
echo "all tests passed"
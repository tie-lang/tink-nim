# tink.nim —— tink data-flow node frame protocol (universal, language-agnostic).
#
# Frame = [len u32 BE][payload][crc u32 BE]; crc = CRC32-IEEE (0xEDB88320).
# Mirrors std/tink.tie (tie standard library) and the other-language tink
# libraries; pure functions over seq[byte], IO (stdin/stdout) left to the
# caller. Nim, no external dependencies.
#
#   let frame = tinkFrameEncode(@[1'u8, 2, 3])
#   let got = tinkFrameNext(frame, 0)  # TinkFrame?

import std/options

# --- CRC32-IEEE (bit-loop, no table; matches std zlib crc32) ---
# Check vector: tinkCrc32("123456789") == 0xCBF43926

func tinkCrc32*(data: openArray[byte]): uint32 =
  var crc = 0xFFFFFFFF'u32
  for b in data:
    crc = crc xor uint32(b)
    for _ in 0 ..< 8:
      crc = if (crc and 1'u32) != 0'u32: (crc shr 1) xor 0xEDB88320'u32 else: crc shr 1
  result = (crc xor 0xFFFFFFFF'u32) and 0xFFFFFFFF'u32

func tinkFrameEncode*(payload: openArray[byte]): seq[byte] =
  let n = payload.len
  result = newSeq[byte](n + 8)
  result[0] = byte((n shr 24) and 0xFF)
  result[1] = byte((n shr 16) and 0xFF)
  result[2] = byte((n shr 8) and 0xFF)
  result[3] = byte(n and 0xFF)
  for i in 0 ..< n:
    result[i + 4] = payload[i]
  let c = tinkCrc32(payload)
  result[n + 4] = byte((c shr 24) and 0xFF'u32)
  result[n + 5] = byte((c shr 16) and 0xFF'u32)
  result[n + 6] = byte((c shr 8) and 0xFF'u32)
  result[n + 7] = byte(c and 0xFF'u32)

proc tinkBe32(b: openArray[byte], off: int): uint32 =
  (uint32(b[off]) shl 24) or (uint32(b[off + 1]) shl 16) or
    (uint32(b[off + 2]) shl 8) or uint32(b[off + 3])

type
  TinkFrame* = object
    payload*: seq[byte]
    next*: int

proc tinkFrameNext*(bytes: openArray[byte], pos: int): Option[TinkFrame] =
  if pos < 0 or bytes.len < pos + 8:
    return none(TinkFrame)
  let n = int(tinkBe32(bytes, pos))
  let endpos = pos + 8 + n
  if bytes.len < endpos:
    return none(TinkFrame)
  var payload = newSeq[byte](n)
  for i in 0 ..< n:
    payload[i] = bytes[pos + 4 + i]
  let want = tinkBe32(bytes, endpos - 4)
  if tinkCrc32(payload) != want:
    return none(TinkFrame)
  some(TinkFrame(payload: payload, next: endpos))

proc tinkFrameSkip*(bytes: openArray[byte], pos: int): Option[int] =
  if pos < 0 or bytes.len < pos + 8:
    return none(int)
  let n = int(tinkBe32(bytes, pos))
  let endpos = pos + 8 + n
  if bytes.len < endpos:
    return none(int)
  some(endpos)
# tink-nim

tink data-flow node frame protocol — Nim module (no dependencies).
Universal and language-agnostic: any component that obeys the frame protocol
can join a tink pipeline.

```
帧 = [ len: u32 BE ][ payload: len 字节 ][ crc: u32 BE ]
len = payload 字节数
crc = CRC32-IEEE(payload)（多项式 0xEDB88320）
```

Mirrors `std/tink.tie` (tie standard library) and the other-language tink
libraries; pure functions over `seq[byte]`, IO (stdin/stdout) left to the
caller. Function names follow the Nim convention (camelCase prefix
`tinkCrc32` / `tinkFrameEncode` / `tinkFrameNext` / `tinkFrameSkip`).

## API

| function | description |
| --- | --- |
| `tinkCrc32(data) -> uint32` | CRC32-IEEE over a byte seq. Check vector: `tinkCrc32("123456789") == 0xCBF43926` |
| `tinkFrameEncode(payload) -> seq[byte]` | encode a payload into a full frame `[len][payload][crc]` |
| `tinkFrameNext(bytes, pos) -> Option[TinkFrame]` | parse one frame at `pos`, verify CRC; `TinkFrame(payload, next)` on success, `none` on out-of-bounds / mismatch |
| `tinkFrameSkip(bytes, pos) -> Option[int]` | skip one frame at `pos` without copying or verifying; `none` on out-of-bounds |

## Usage

```nim
import tink
let frame = tinkFrameEncode(@[1'u8, 2, 3])
let got = tinkFrameNext(frame, 0) # Option[TinkFrame]
```

## Build & test

```bash
nim c --cc:clang --clang.exe=<path-to-clang> -r test_tink.nim
```

Nim 官方 Windows 解压包不含 C 编译器，需指定 clang（或任意 C 编译器）作为后端。

## Cross-language

tink 帧协议各语言实现（API 语义与校验向量一致）：

| language | library |
| --- | --- |
| tie | `std/tink.tie` |
| Rust | `tink-rust`（tink crate） |
| C | `tink-c`（`tink.h` + `tink.c`） |
| Python | `tink-python`（`tink.py`） |
| JavaScript | `tink-js`（`tink.js` + `tink.d.ts`） |
| C++ | `tink-cpp`（`tink.hpp`） |
| Java | `tink-java`（`org.tielang.tink`） |
| C# | `tink-csharp`（namespace `Tink`） |
| Go | `tink-go`（package `tink`） |
| Zig | `tink-zig`（`tink.zig`） |
| Lua | `tink-lua`（`tink.lua`） |
| GDScript | `tink-godot`（`tink.gd`） |
| F# | `tink-fsharp`（`Tink.fs`） |
| PowerShell | `tink-powershell`（`tink.ps1`） |
| Kotlin | `tink-kotlin`（`Tink.kt`） |
| Ruby | `tink-ruby`（`tink.rb`） |
| Julia | `tink-julia`（`tink.jl`） |
| Nim | this module（`tink-nim`） |

## License

本仓库使用 **TIE-LANG Open Source License v1.1**，完整文本见 [LICENSE](LICENSE)。
This repository is distributed under the **TIE-LANG Open Source License v1.1** — see [LICENSE](LICENSE) for the full text.
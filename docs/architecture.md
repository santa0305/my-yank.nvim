# my-yank.nvim モジュール設計指針

## 目的

`my-yank.nvim` は、Neovim 上のコピー処理を統一的に扱うための小さなプラグインとする。  
対象は「どこから取るか」「どう整形するか」「どこへ出すか」の 3 点に限定する。  
history や複雑な state 管理は持たない。  
設計の中心は `source -> transform[] -> sink[]` の単純な実行パイプラインとする。  
Neovim のシステムクリップボードは provider 経由で扱われるため、clipboard 依存は `sink` に閉じ込める。

## 設計原則

- 小さく始める
- ファイル分割は最小限にする
- 公開 API は少なく保つ
- 内部データは plain table で統一する
- source / transform / sink の責務を混ぜない
- preset を first-class に扱う
- history は作らない
- UI 統合や picker は v1 では持たない

## 役割分担

- `source`: コピー元を取得する
- `transform`: 取得した内容を整形する
- `sink`: 整形済みの内容を出力する
- `runner`: spec を解決して全体を実行する
- `config`: デフォルト設定と preset を管理する
- `commands`: ユーザーコマンドを提供する
- `util`: 正規化や path 処理などの補助を提供する

## ディレクトリ構成

```text
my-yank.nvim/
└── lua/
    └── my_yank/
        ├── init.lua          # 公開 API (setup / run / copy)
        ├── config.lua
        ├── commands.lua
        ├── runner.lua
        ├── source.lua
        ├── transform.lua
        ├── sink.lua
        └── util.lua
```

`lua/my_yank/init.lua` がルートモジュールとなっており、  
`require("my_yank")` で `setup` / `run` / `copy` にアクセスする。

## 公開 API

公開 API は最小限にする。

```lua
-- lua/my_yank/init.lua
local config = require("my_yank.config")
local commands = require("my_yank.commands")
local runner = require("my_yank.runner")

local M = {}

function M.setup(opts)
  config.setup(opts or {})
  commands.setup()
end

function M.run(name_or_spec)
  return runner.run(name_or_spec)
end

function M.copy(name_or_spec)
  return M.run(name_or_spec)
end

return M
```

### 方針

- `setup(opts)` は設定と preset 登録、およびコマンド登録を行う
- `run(name_or_spec)` は preset 名または spec table を実行する
- `copy(name_or_spec)` は `run()` の alias とする
- 公開 API に source/transform/sink の詳細を漏らさない

## 実行モデル

実行モデルは固定する。

```text
spec
  -> source を解決
  -> payload を作成
  -> transforms を順に適用
  -> sinks を順に適用
  -> payload を返す
```

### runner の責務

- preset 名を spec に解決する
- spec を normalize する
- source / transform / sink の存在確認を行う
- 実行順を一元管理する
- エラーをまとめて扱う

## 設定方針

設定は `setup()` で受け取り、デフォルト値と deep merge する。  

```lua
{
  clipboard = {
    default_register = "+",
    fallback_register = '"',
  },
  notify = true,
  presets = {
    -- user presets
  },
}
```

### 設計ルール

- default は `config.lua` に集約する
- 設定アクセスは `config.get()` 経由に統一する
- spec 実行時に都度 config を参照できるようにする
- v1 では validation は最小限でよい

## spec 形式

preset も直接実行も、同じ spec 形式で扱う。

```lua
{
  source = "buffer",
  source_opts = {},
  transforms = {
    { "filepath_header", format = "relative" },
    { "codeblock", lang = "auto" },
  },
  sinks = {
    { "clipboard", register = "+" },
    "notify",
  },
}
```

### ルール

- `source` は必須
- `transforms` と `sinks` は省略可
- `"trim"` のような文字列指定を許可する
- `{ "codeblock", lang = "lua" }` のような table 指定を許可する
- runner 実行前に normalize して、`{ name = "...", opts = {...} }` にそろえる

## Payload 方針

内部データは class 化せず plain table で統一する。  
すべての source は payload を返し、すべての transform は payload を受けて payload を返す。

```lua
---@class MyYankPayload
---@field text string
---@field lines string[]
---@field source string
---@field bufnr integer
---@field filetype string?
---@field filepath string?
---@field regtype string?
---@field metadata table?
```

### 方針

- `text` を主データとする
- `lines` は transform や sink で必要なときのために持つ
- `filetype` と `filepath` は codeblock 系 transform のために保持する
- `metadata` は将来拡張用だが、v1 では積極的には使わない

## source モジュール指針

`source.lua` は source 群の集約モジュールとする。

```lua
local M = {}

M.buffer = function(opts) end
M.visual = function(opts) end
M.line = function(opts) end
M.filepath = function(opts) end
M.register = function(opts) end
M.messages = function(opts) end
M.terminal_block = function(opts) end

return M
```

### 各 source の責務

- `buffer`: 現在バッファ全体を取得する
- `visual`: 現在の visual 選択範囲を取得する（visual モードでないときは error）
- `line`: 現在行または指定行を取得する
- `filepath`: ファイルパス文字列を生成する（相対/絶対はオプションで切り替え）
- `register`: 指定レジスタの内容を取得する
- `messages`: `:messages` の内容を取得する
- `terminal_block`: ターミナルバッファのカーソル位置の「1 コマンド + その出力」を取得する

### `terminal_block` の仕様メモ

- プロンプトは「2 行構成」であることを前提にする
- 既定では `$` / `>` / `PS>` / `#` / `%` / `╰` / `❯` / `➜` で始まる行を「プロンプト 2 行目」とみなす
- `source_opts.prompt_patterns` で追加の Lua パターンを受け取れる
- 現在行から上方向にさかのぼって直近のプロンプト 2 行目を探し、そのブロック開始を決める
- 次のプロンプト 2 行目の直前までを 1 ブロックとみなす
- 1 行目のプロンプト情報や次コマンドのプロンプト 1 行目はコピー対象に含めない想定
- 1 行 prompt や複雑な複数行 prompt を完全一般化するものではない

### source の共通ルール

- 返り値は必ず payload
- 取得と整形を混ぜない
- `filepath` source でも payload を返す
- visual mode でないときの `visual` は明示的に error とする

## transform モジュール指針

`transform.lua` は transform 群の集約モジュールとする。

```lua
local M = {}

M.trim = function(payload, opts) end
M.join = function(payload, opts) end
M.filepath_header = function(payload, opts) end
M.codeblock = function(payload, opts) end
M.eol = function(payload, opts) end

return M
```

### v1 に含める transform

- `trim`: 前後の空白や空行を調整する
- `join`: 改行を連結する
- `filepath_header`: 先頭に path を追加する
- `codeblock`: Markdown fenced code block に変換する
- `eol`: 改行コードを LF に統一する（末尾の改行有無もオプションで制御）

### transform のルール

- payload を破壊的変更してもよいが、一貫性を保つ
- 可能なら pure function 的に書く
- `codeblock` は `filepath_header` と分離する（パスを先頭行に出す責務は filepath_header）
- `lang = "auto"` なら `payload.filetype` を使う
- `lang = false` なら fence の言語名を付けない
- `path = "relative" / "absolute"` 指定時は info に `:path` を付ける（例: ```lua:lua/foo.lua）

### `codeblock` の仕様例

```lua
{ "codeblock", lang = "auto", fence = "```", path = "relative" }
```

出力例:

```text
```lua:lua/foo/bar.lua
print("hello")
```
```

## sink モジュール指針

`sink.lua` は出力先の集約モジュールとする。

```lua
local M = {}

M.register = function(payload, opts) end
M.clipboard = function(payload, opts) end
M.notify = function(payload, opts) end

return M
```

### v1 に含める sink

- `register`: 指定レジスタへ書き込む
- `clipboard`: `+` または `*` に書き込む（default/fallback は config 側で指定）
- `notify`: 結果を通知する

### sink のルール

- clipboard 固有事情は `clipboard` sink に閉じ込める
- `vim.fn.setreg()` を使う
- `regtype` を尊重する
- provider 不在時の fallback をここで扱う
- `notify` は副次的機能に留める

## util モジュール指針

`util.lua` は以下のような補助だけを置く。

- spec の normalize
- preset 解決
- path の relative/absolute 変換
- visual range の抽出
- text/lines 相互変換と payload 生成
- エラーメッセージ整形

### 置かないもの

- source の本体実装
- transform の本体実装
- sink の本体実装
- 状態管理

## commands モジュール指針

ユーザーコマンドは `nvim_create_user_command()` で定義する。

```vim
:MyYank {preset}
```

### 方針

- コマンドは `:MyYank` 1 本に絞る（引数で preset 名を渡す）
- 引数の補完で preset 名を提示する
- コマンド実装は薄くし、処理本体は `require("my_yank").run()` に委譲する
- `nargs = 1` とし、preset 名の指定を必須にする

## エラー処理方針

v1 で扱うべきエラーは限定する。

- 未知の source 名
- 未知の transform 名
- 未知の sink 名
- visual source なのに visual mode でない
- clipboard register への書き込み失敗
- バッファ名が空で filepath を作れない

### 方針

- エラーは runner がまとめて扱う
- 原因が分かるメッセージにする
- notify を使うとしても例外を握り潰しすぎない
- 個人開発なので stack trace を隠しすぎない

## preset 設計指針

preset はこのプラグインの主な利用面とする。  
ユーザーは source / transform / sink の詳細よりも、用途単位で呼び出せるべきである。

### デフォルト preset のイメージ

```lua
presets = {
  buffer = {
    source = "buffer",
    transforms = {
      { "filepath_header", format = "relative" },
      { "codeblock", lang = "auto", path = "relative" },
    },
    sinks = {
      "clipboard",
      "notify",
    },
  },

  visual = {
    source = "visual",
    transforms = {
      { "codeblock", lang = "auto" },
    },
    sinks = {
      "clipboard",
      "notify",
    },
  },

  messages = {
    source = "messages",
    transforms = {
      { "codeblock", lang = "txt", path = "relative" },
    },
    sinks = {
      "clipboard",
      "notify",
    },
  },

  terminal = {
    source = "terminal_block",
    transforms = {
      { "codeblock", lang = "bash", path = "none" },
    },
    sinks = {
      "clipboard",
      "notify",
    },
  },

  path = {
    source = "filepath",
    source_opts = { format = "relative" },
    sinks = {
      "clipboard",
      "notify",
    },
  },

  path_with_line = {
    source = "filepath",
    source_opts = { format = "relative", with_line = true },
    sinks = {
      "clipboard",
      "notify",
    },
  },
}
```

## 実装優先順位

1. `config.lua`
2. `runner.lua`
3. `source.buffer`, `source.visual`, `source.filepath`
4. `sink.register`, `sink.clipboard`, `sink.notify`
5. `transform.codeblock`, `transform.filepath_header`, `transform.trim`, `transform.eol`
6. `commands.lua`
7. `messages` / `terminal_block` / `line` / `register` など追加 source

## v1 で入れないもの

- history
- picker
- telescope / snacks 連携
- sqlite
- operatorfunc ベースの独自 yank 置換
- 自動 clipboard sync
- 過剰なデフォルト keymap

## 最終指針

`my-yank.nvim` は「高機能ヤンクマネージャ」ではなく、  
**小さな copy pipeline を preset で使い回すためのプラグイン**として設計する。  
細かく分割しすぎず、しかし責務は混ぜない。  
個人開発では「理論上の拡張性」よりも「3 か月後の自分が読めること」を優先する。

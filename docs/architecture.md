# my-yank.nvim モジュール設計指針

## 目的

`my-yank.nvim` は、Neovim上のコピー処理を統一的に扱うための小さなプラグインとする。  
対象は「どこから取るか」「どう整形するか」「どこへ出すか」の3点に限定する。  
history や複雑な state 管理は持たない。  
設計の中心は `source -> transform[] -> sink[]` の単純な実行パイプラインとする。  
Neovim のシステムクリップボードは provider 経由で扱われるため、clipboard 依存は `sink` に閉じ込める。 [web:35]

## 設計原則

- 小さく始める
- ファイル分割は最小限にする
- 公開APIは少なく保つ
- 内部データは plain table で統一する
- source / transform / sink の責務を混ぜない
- preset を first-class に扱う
- history は作らない
- UI統合や picker は v1 では持たない

## 役割分担

- `source`: コピー元を取得する
- `transform`: 取得した内容を整形する
- `sink`: 整形済みの内容を出力する
- `runner`: spec を解決して全体を実行する
- `config`: デフォルト設定と preset を管理する
- `commands`: ユーザーコマンドを提供する
- `util`: 正規化や path 処理などの補助を提供する

## 推奨ディレクトリ構成

```text
my-yank.nvim/
├── plugin/
│   └── my-yank.lua
└── lua/
    ├── my-yank.lua
    └── my-yank/
        ├── config.lua
        ├── commands.lua
        ├── runner.lua
        ├── source.lua
        ├── transform.lua
        ├── sink.lua
        └── util.lua
```

この構成は、Neovim Lua プラグインで一般的な `plugin/` と `lua/` の分離に沿う。

## 公開API

公開APIは最小限にする。

```lua
-- lua/my-yank.lua
local M = {}

function M.setup(opts) end
function M.run(name_or_spec) end
function M.copy(name_or_spec) end

return M
```

### 方針

- `setup(opts)` は設定と preset 登録を行う
- `run(name_or_spec)` は preset 名または spec table を実行する
- `copy(name_or_spec)` は `run()` の alias とする
- 公開APIに source/transform/sink の詳細を漏らさない

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
Neovim Lua プラグインでは `setup()` を提供する構成が一般的である。 [web:48]

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

return M
```

### 各 source の責務

- `buffer`: 現在バッファ全体を取得する
- `visual`: 現在の visual 選択範囲を取得する
- `line`: 現在行または指定 range を取得する
- `filepath`: ファイルパス文字列を生成する
- `register`: 指定レジスタの内容を取得する

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
M.codeblock = function(payload, opts) end
M.filepath_header = function(payload, opts) end

return M
```

### v1 に含める transform

- `trim`: 前後の空白や空行を調整する
- `join`: 改行を連結する
- `filepath_header`: 先頭に path を追加する
- `codeblock`: Markdown fenced code block に変換する

### transform のルール

- payload を破壊的変更してもよいが、一貫性を保つ
- 可能なら pure function 的に書く
- `codeblock` は `filepath_header` と分離する
- `lang = "auto"` なら `payload.filetype` を使う
- `lang = false` なら fence の言語名を付けない

### `codeblock` の仕様例

```lua
{ "codeblock", lang = "auto", fence = "```" }
```

出力例:

```text
```lua
local x = 1
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
- `clipboard`: `+` または `*` に書き込む
- `notify`: 結果を通知する

### sink のルール

- clipboard 固有事情は `clipboard` sink に閉じ込める
- `vim.fn.setreg()` を使う
- `regtype` を尊重する
- provider 不在時の fallback をここで扱う
- `notify` は副次的機能に留める

Neovim の clipboard は provider 経由で動作するため、clipboard の問題を source や runner に漏らさない。

## util モジュール指針

`util.lua` は以下のような補助だけを置く。

- spec の normalize
- preset 解決
- path の relative/absolute 変換
- visual range の抽出
- table merge 補助
- エラーメッセージ整形

### 置かないもの

- source の本体実装
- transform の本体実装
- sink の本体実装
- 状態管理

## commands モジュール指針

ユーザーコマンドは `nvim_create_user_command()` で定義する。

```lua
:MyYankRun {preset}
:MyYankCopyPath
:MyYankCopyBufferCodeblock
```

### 方針

- 基本は `:MyYankRun` を主コマンドにする
- よく使うものだけ別名コマンドを置く
- コマンド実装は薄くし、処理本体は `require("my-yank").run()` に委譲する
- `nargs` は必要最小限に設定する

## plugin エントリポイント指針

`plugin/my-yank.lua` では、自動読込時に重い処理をしない。  
Neovim Lua プラグインでは、必要時まで重い `require()` を避ける実践も推奨される。[10]

```lua
if vim.g.loaded_my_yank then
  return
end
vim.g.loaded_my_yank = 1

require("my-yank.commands").setup()
```

### 方針

- setup の自動呼び出しはしない
- コマンド登録だけを行う
- 実際の処理はコマンド実行時に require してもよい

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

### 推奨 preset

```lua
presets = {
  copy_buffer_codeblock = {
    source = "buffer",
    transforms = {
      { "filepath_header", format = "relative" },
      { "codeblock", lang = "auto" },
    },
    sinks = {
      "clipboard",
      "notify",
    },
  },

  copy_visual_codeblock = {
    source = "visual",
    transforms = {
      { "codeblock", lang = "auto" },
    },
    sinks = {
      "clipboard",
      "notify",
    },
  },

  copy_path = {
    source = "filepath",
    source_opts = { format = "relative" },
    sinks = {
      "clipboard",
      "notify",
    },
  },

  copy_path_with_line = {
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
5. `transform.codeblock`, `transform.filepath_header`, `transform.trim`
6. `commands.lua`
7. 必要なら `line`, `register`, `join`

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
個人開発では「理論上の拡張性」よりも「3か月後の自分が読めること」を優先する。[4]


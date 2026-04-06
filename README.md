# my-yank.nvim

Neovim 用のコンパクトなコピーパイプラインプラグインです。

「どこから取るか（source）」→「どう整形するか（transform）」→「どこへ出すか（sink）」という
シンプルなパイプラインで、コピー処理を preset として定義・再利用できます。

## 機能

- バッファ全体を Markdown コードブロックとしてコピー
- ビジュアル選択範囲を Markdown コードブロックとしてコピー
- ターミナルバッファでカーソル位置のコマンドブロックをコピー
- `:messages` の内容を Markdown コードブロックとしてコピー
- 現在のファイルパス（相対パス）をコピー
- 行番号付きファイルパスをコピー
- `source -> transform[] -> sink[]` パイプラインで自由にカスタム preset を定義可能

## インストール

### lazy.nvim

```lua
{
  "santa0305/my-yank.nvim",
  config = function()
    require("my_yank").setup()
  end,
}
```

## セットアップ

```lua
require("my_yank").setup()
```

オプションなしで呼び出すとデフォルト設定が使われます。

## コマンド

`:MyYank {preset}` コマンドで preset を実行します。
preset 名は Tab 補完で確認できます。

```vim
:MyYank buffer
:MyYank visual
:MyYank terminal
:MyYank messages
:MyYank path
:MyYank path_with_line
```

## デフォルト preset

| preset 名        | source          | 動作                                                |
|------------------|-----------------|-----------------------------------------------------|
| `buffer`         | `buffer`        | バッファ全体をファイルパス付きコードブロックとしてコピー |
| `visual`         | `visual`        | ビジュアル選択範囲をコードブロックとしてコピー          |
| `terminal`       | `terminal_block`| ターミナルバッファのカーソル位置のコマンドブロックをコピー |
| `messages`       | `messages`      | `:messages` の内容をコードブロックとしてコピー      |
| `path`           | `filepath`      | 相対パスをコピー                                    |
| `path_with_line` | `filepath`      | 行番号付き相対パスをコピー                          |

## ターミナルブロックコピーについて

`terminal_block` source は、ターミナルバッファ内でカーソル位置が属する
「1 コマンド + その出力」を抽出してコピーします。

想定しているプロンプト形式:

- プロンプトは常に 2 行構成
- 2 行目の行頭が `$`、`>`、`PS>` のいずれか
- 1 行目のプロンプト情報（ユーザー名・ホスト名など）はコピーしない
- 次のコマンドのプロンプト 1 行目もコピーしない

コピー結果には「コマンド本体の行」と、そのコマンドに対応する出力だけが含まれます。

## 設定例

```lua
require("my_yank").setup({
  clipboard = {
    default_register = "+",   -- clipboard sink のデフォルトレジスタ
    fallback_register = '"',  -- clipboard 書き込み失敗時の fallback
  },
  notify = true,  -- false にすると notify sink を無効化
  presets = {
    -- デフォルト preset を上書き、または新規 preset を追加
    buffer = {
      source = "buffer",
      transforms = {
        -- ```lua:lua/hogehoge.lua のような info 付きコードブロックを生成
        { "codeblock", lang = "auto", path = "relative" },
      },
      sinks = { "clipboard", "notify" },
    },

    -- カスタム preset の例: :messages をコードブロックとしてコピー
    copy_messages = {
      source = "messages",
      transforms = {
        { "codeblock", lang = "txt" },
      },
      sinks = { "clipboard", "notify" },
    },
  },
})
```

## パイプライン仕様

### source

| 名前            | 取得内容                                           |
|-----------------|----------------------------------------------------|
| `buffer`        | 現在バッファ全体                                   |
| `visual`        | ビジュアル選択範囲（`v` / `V`）                    |
| `line`          | 現在行または指定行                                 |
| `filepath`      | ファイルパス文字列                                 |
| `register`      | 指定レジスタの内容                                 |
| `messages`      | `:messages` の出力                                 |
| `terminal_block`| ターミナルバッファのカーソル位置のコマンドブロック |

### transform

| 名前             | 動作                                            |
|------------------|-------------------------------------------------|
| `trim`           | 前後の空白・空行を除去                          |
| `join`           | 複数行を1行に結合（`sep` オプションで区切りを指定） |
| `filepath_header`| 先頭にファイルパス行を追加                      |
| `codeblock`      | Markdown fenced code block で囲む               |
| `eol`            | 改行コードを LF に統一                          |

#### `codeblock` オプション

```lua
{ "codeblock", lang = "auto", path = "relative", fence = "```" }
```

- `lang`: `"auto"`（filetype を使用） / `false`（言語名なし） / `"lua"` などの固定値
- `path`: `"relative"` / `"absolute"` / 省略（パスなし）
  - 指定すると \`\`\`lua:lua/foo.lua のような info 文字列になります
- `fence`: フェンス文字列（デフォルト: \`\`\`）

### sink

| 名前        | 動作                                               |
|-------------|----------------------------------------------------|
| `register`  | 指定レジスタへ書き込む（デフォルト: `"` レジスタ） |
| `clipboard` | `+` レジスタへ書き込む（失敗時は fallback に書き込み） |
| `notify`    | コピーした文字数を `vim.notify` で通知             |

## キーマップ例

```lua
vim.keymap.set("n", "<leader>yb", function()
  vim.cmd("MyYank buffer")
end, { desc = "Copy buffer as codeblock" })

vim.keymap.set("v", "<leader>yv", function()
  vim.cmd("MyYank visual")
end, { desc = "Copy visual selection as codeblock" })

vim.keymap.set("n", "<leader>yt", function()
  vim.cmd("MyYank terminal")
end, { desc = "Copy terminal block as codeblock" })

vim.keymap.set("n", "<leader>ym", function()
  vim.cmd("MyYank messages")
end, { desc = "Copy :messages as codeblock" })

vim.keymap.set("n", "<leader>yp", function()
  vim.cmd("MyYank path")
end, { desc = "Copy relative path" })
```

## Lua API

```lua
-- preset 名で実行
require("my_yank").run("buffer")

-- spec を直接渡して実行
require("my_yank").run({
  source = "visual",
  transforms = {
    { "codeblock", lang = "auto" },
  },
  sinks = { "clipboard", "notify" },
})

-- run() の alias
require("my_yank").copy("path")
```

## テスト

[mini.nvim](https://github.com/echasnovski/mini.nvim) の `mini.test` を使用しています。

```bash
# 全テスト実行
make test

# 特定ファイルのみ実行
make test_file FILE=tests/test_transform.lua
```

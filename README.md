# my-yank.nvim

Neovim 用のコンパクトなヤンク補助プラグインです。

## 機能

- 現在のバッファ全体を Markdown のコードブロックとしてコピー
- ビジュアル選択範囲を Markdown のコードブロックとしてコピー
- ターミナルバッファで、カーソル位置のコマンドブロックを Markdown のコードブロックとしてコピー
- 現在のファイルパス（相対パス）をコピー
- 現在の行番号付きのファイルパス（相対パス）をコピー
- `:messages` の内容を Markdown のコードブロックとしてコピー
- `source -> transform[] -> sink[]` というパイプラインでコピー処理を組み立て可能

## 構成

- `source`: バッファ・ビジュアル選択・行・パス・レジスタ・ターミナルブロックなどからテキストを取得
- `transform`: trim, join, filepath header 追加, codeblock 化, 改行処理（eol）などの整形
- `sink`: register への書き込み、clipboard への書き込み、notify による通知

## セットアップ

```lua
require("my_yank").setup()
```

## コマンド

```vim
:MyYankRun copy_buffer_codeblock
:MyYankRun copy_terminal_block_codeblock
:MyYankCopyPath
:MyYankCopyBufferCodeblock
```

## デフォルト preset

- `copy_buffer_codeblock`: バッファ全体をコードブロックとしてコピー
- `copy_visual_codeblock`: ビジュアル選択範囲をコードブロックとしてコピー
- `copy_messages_codeblock`: `:messages` をコードブロックとしてコピー
- `copy_terminal_block_codeblock`: ターミナルバッファでカーソル位置のコマンドブロックをコードブロックとしてコピー
- `copy_path`: 相対パスをコピー
- `copy_path_with_line`: 行番号付き相対パスをコピー

## ターミナルブロックコピーについて

`terminal_block` source は、ターミナルバッファ内でカーソル位置の属する「1 コマンド + その出力」を抽出してコピーします。

想定しているプロンプト形式は次の通りです。

- プロンプトは常に 2 行
- 2 行目の行頭が `$`、`>`、`PS>` のいずれか
- 1 行目のプロンプト情報（ユーザー名・ホスト名など）はコピーしない
- 次のコマンドのプロンプト 1 行目もコピーしない

そのため、コピー結果には「コマンド本体の行」と、そのコマンドに対応する出力だけが含まれます。

## 設定例

```lua
require("my_yank").setup({
  presets = {
    copy_buffer_codeblock = {
      source = "buffer",
      transforms = {
        -- ファイルタイプと相対パスを info に含めたコードブロックを生成します。
        -- 例: ```lua:lua/hogehoge.lua
        { "codeblock", lang = "auto", path = "relative" },
      },
      sinks = { "clipboard", "notify" },
    },

    -- :messages をコードブロックとしてコピーする例
    copy_messages_codeblock = {
      source = "messages",
      transforms = {
        -- info 行は例として ```text:messages のようになります
        { "codeblock", lang = "text", path = "relative" },
      },
      sinks = { "clipboard", "notify" },
    },

    -- ターミナルバッファで現在のコマンドブロックをコピーする例
    copy_terminal_block_codeblock = {
      source = "terminal_block",
      transforms = {
        { "codeblock", lang = "bash", path = "none" },
      },
      sinks = { "clipboard", "notify" },
    },
  },
})
```

## キーマップ例

```lua
vim.keymap.set("n", "<leader>yb", function()
  vim.cmd("MyYankRun copy_buffer_codeblock")
end, { desc = "Copy buffer as codeblock" })

vim.keymap.set("n", "<leader>yt", function()
  vim.cmd("MyYankRun copy_terminal_block_codeblock")
end, { desc = "Copy terminal block as codeblock" })

vim.keymap.set("n", "<leader>ym", function()
  vim.cmd("MyYankRun copy_messages_codeblock")
end, { desc = "Copy :messages as codeblock" })
```

# my-yank.nvim

Neovim 用のコンパクトなヤンク補助プラグインです。

## 機能

- 現在のバッファ全体を Markdown のコードブロックとしてコピー
- ビジュアル選択範囲を Markdown のコードブロックとしてコピー
- 現在のファイルパス（相対パス）をコピー
- 現在の行番号付きのファイルパス（相対パス）をコピー
- `source -> transform[] -> sink[]` というパイプラインでコピー処理を組み立て可能

## 構成

- `source`: バッファ・ビジュアル選択・行・パス・レジスタなどからテキストを取得
- `transform`: trim, join, filepath header 追加, codeblock 化, 改行処理（eol）などの整形
- `sink`: register への書き込み、clipboard への書き込み、notify による通知

## セットアップ

```lua
require("my-yank").setup()
```

## コマンド

```vim
:MyYankRun copy_buffer_codeblock
:MyYankCopyPath
:MyYankCopyBufferCodeblock
```

## 設定例

```lua
require("my-yank").setup({
  presets = {
    copy_buffer_codeblock = {
      source = "buffer",
      transforms = {
        { "filepath_header", format = "relative" },
        { "codeblock", lang = "auto" },
      },
      sinks = { "clipboard", "notify" },
    },
  },
})
```

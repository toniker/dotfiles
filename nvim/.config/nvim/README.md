# nvim

Minimal Neovim config — a single `init.lua`. Originally derived from
[kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim), since stripped down.

**Use case:** editing git commit messages, quick looks at Swift / JSON files,
jumping between files with a fuzzy finder. No heavy IDE setup.

## Layout

| File | Purpose |
|---|---|
| `init.lua` | everything: options, keymaps, plugins, formatting, Swift LSP |
| `nvim-pack-lock.json` | pinned plugin revisions (`:h vim.pack-lockfile`) |
| `.stylua.toml` | Lua formatter config for this file |

## Plugins

Managed by the built-in `vim.pack` (Neovim 0.12+). They install on first launch;
run `:checkhealth` after.

- [fzf-lua](https://github.com/ibhagwan/fzf-lua) — fuzzy finder
- [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) (`main`)
- [which-key.nvim](https://github.com/folke/which-key.nvim)

## Keymaps

Leader is `<Space>`.

| Key | Action |
|---|---|
| `<leader><leader>` | find files |
| `<leader>b` | switch buffer |
| `<leader>/` | live grep |
| `<leader>r` | resume last picker |
| `<leader>f` | format buffer / selection (`swiftformat`, `jq`) |
| `<C-h/j/k/l>` | move between windows |
| `<Esc>` | clear search highlight |
| `grn` / `gra` / `grr` / `gd` / `<leader>e` | LSP rename / code action / references / definition / line diagnostics (Swift buffers) |

## External tools (optional, resolved from `PATH`)

- `swiftformat`, `jq` — `<leader>f` formatting
- `sourcekit-lsp` — Swift LSP (ships with Xcode); `xcode-build-server` for
  `.xcodeproj`/`.xcworkspace` projects
- `ripgrep` — `<leader>/` live grep
- `tree-sitter` CLI (≥ 0.26) — installing/refreshing treesitter parsers

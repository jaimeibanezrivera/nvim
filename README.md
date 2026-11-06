# Neovim config

My personal Neovim setup, built on [lazy.nvim](https://github.com/folke/lazy.nvim).

## Layout

```
init.lua              -- options, keymaps, autocmds, theme; loads the plugin groups
lua/plugins/
  ui/                 -- colorschemes, statusline, dashboard, which-key, zj-theme
  editor/             -- fzf, neo-tree, oil, treesitter, completions, autopairs, trouble
  lsp/                -- lsp-config, mason, none-ls
  lang/               -- rust, markdown
  vcs/                -- gitsigns (git), hgsigns and lawrencium (Mercurial), diffview, lazygit
lazy-lock.json        -- pinned plugin versions
```

Lazy.nvim does not read subfolders on its own, so `init.lua` lists each group in its `setup` call. A new group folder needs a matching `{ import = "plugins.<group>" }` entry there.

## Local vs remote

Clipboard behavior depends on the `NVIM_REMOTE` environment variable.

- `NVIM_REMOTE=1`: the shell runs on a remote server. Yanks go through OSC 52 so they reach the local terminal.
- Unset: the shell is local. nvim uses the OS clipboard tool (`xclip`, `wl-copy`, ...).

On the server, set it in the shell config. For fish, `~/.config/fish/config.fish`:

```fish
set -gx NVIM_REMOTE 1
```

## Colorscheme

`init.lua` applies the saved colorscheme at startup. The fzf colorscheme picker writes the choice to `.colorscheme`, which is gitignored.
`lua/plugins/ui/zj-theme.lua` sends the matching alacritty theme through a tunnel on port 7778. The tunnel only exists when the laptop forwards it, so nothing happens without it.

## Adding a plugin

1. Create `lua/plugins/<group>/<name>.lua` in the matching folder and return a lazy.nvim spec.
2. Restart nvim, or run `:Lazy sync`.
3. Commit the new file and the updated `lazy-lock.json`.

## Checking the config

Load the config without opening a UI and print the plugin count:

```sh
nvim --headless -c 'lua print(#require("lazy").plugins())' -c qa
```

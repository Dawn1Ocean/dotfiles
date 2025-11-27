# dotfiles

My dotfiles based on Niri and DankMaterialShell.

Using `GNU stow` to manage.

# Niri & DMS

The original config files are at `~/.config/niri`.

Packages（in `paru`）:
- `dms-shell-bin`, `matugen`, `wl-clipboard`, `cliphist`, `cava`, `qt6-multimedia-ffmpeg`: DankMaterialShell
- `qt6ct`, `nwg-look`: QT & GTK Theme Manager
- `xdg-desktop-portal`, `xdg-desktop-portal-gtk`: Desktop API for screen casting etc.
- `kitty`, `dolphin`: Terminal & File Manager
- `darkman`: Light & Darkmode support
- `grim`, `slurp`, `satty`: Screenshot & Editor
- `fuzzel`: Dmenu app launcher

Before apply the `niri/config.kdl` file, please configure the `output` part according to the display or execute `niri msg outputs`:

```kdl
// ...
output "eDP-1" {
    mode "2560x1440@120.000"
    scale 2
    // ...
}
// ...
```

## Apply

```sh
cd dotfiles
stow --dotfiles niri
```

# Nvim

Inspired by [MartinLwx](https://martinlwx.github.io/zh-cn/config-neovim-from-scratch/). Thanks!

The original config files are at `~/.config/nvim`.

Plugins (managed by `lazy.nvim`):
- `"catppuccin/nvim"`: Nvim Theme 
- `"lukas-reineke/indent-blankline.nvim"`: Indent Blankline
- `"ethanholz/nvim-lastplace"`: Intelligently reopens files at your last edit position
- `"onsails/lspkind.nvim"`: Vscode-like pictograms 
- `"saghen/blink.cmp"`: Auto-completion engine
- `"L3MON4D3/LuaSnip"`: Code snippet engine
- `"mason-org/mason.nvim"`, `"neovim/nvim-lspconfig"`: LSP manager
- `"xiyaowong/transparent.nvim"`: Transparent background

## Apply

```sh
cd dotfiles
stow --dotfiles nvim
```

# Kitty

The original config files are at `~/.config/kitty`.

Using default dark theme and customized default light theme.

I wrote a script to monitor changes in the system `color-scheme` and adjust Kitty's theme accordingly.

## Apply
```sh
cd dotfiles
stow --dotfiles kitty
```

Add `spawn-at-startup` in `.config/niri/config.kdl`:
```kdl
// ...
spawn-at-startup "~/.local/bin/kitty-theme-auto-switch.sh"
// ...
```
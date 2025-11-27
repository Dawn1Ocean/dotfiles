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

## Deploy

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

## Deploy

```sh
cd dotfiles
stow --dotfiles nvim
```

# Kitty

The original config files are at `~/.config/kitty`.

Using default dark theme and customized default light theme.

I wrote a script to monitor changes in the system `color-scheme` and adjust Kitty's theme accordingly.

```sh
#!/bin/bash

LIGHT_THEME="$HOME/.config/kitty/themes/Light_Default.conf"
DARK_THEME="$HOME/.config/kitty/Default.conf"

function update_all_kitties() {
    local THEME_FILE=$1

    grep -aPo '@mykitty[^\s]*' /proc/net/unix | sort | uniq | while read -r socket_path; do
        kitty @ --to "unix:$socket_path" set-colors --all --configured "$THEME_FILE" 2>/dev/null
    done
}

current_mode=$(gsettings get org.gnome.desktop.interface color-scheme)

if [[ "$current_mode" == "'prefer-dark'" ]]; then
    update_all_kitties "$DARK_THEME"
else
    update_all_kitties "$LIGHT_THEME"
fi

gsettings monitor org.gnome.desktop.interface color-scheme | while read -r line; do
    if [[ "$line" == *"prefer-dark"* ]]; then
        update_all_kitties "$DARK_THEME"
    else
        update_all_kitties "$LIGHT_THEME"
    fi
done
```

## Deploy

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

# Darkman

The original script directories are `~/.local/share/dark-mode.d` and `~/.local/share/light-mode.d`.

I wrote a script to restart and change the icons of dms monitor changes in the system `color-scheme` and adjust Kitty's theme accordingly.

> Currently dms has a bug that the first attempt after initialization to restart dms will fail, thus the script will restart dms twice at session startup.

```sh
#!/bin/bash
INIT_FLAG="/tmp/dms_theme_initialized"

try_restart_dms() {
    dms restart
    sleep 0.2
    dms ipc call theme dark
}

sed -i 's/^icon_theme=.*/icon_theme=breeze-dark/' ~/.config/qt6ct/qt6ct.conf

niri msg action do-screen-transition -d 2500 &
sleep 0.01

if [ ! -f "$INIT_FLAG" ]; then
    try_restart_dms
    try_restart_dms
    touch "$INIT_FLAG"
else
    try_restart_dms
fi
```

## Deploy

```sh
cd dotfiles
stow --dotfiles darkman
```
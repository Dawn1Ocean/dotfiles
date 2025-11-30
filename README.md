# dotfiles

My dotfiles based on Niri and DankMaterialShell.

Focused on minimal configuration and out-of-box experience.

Using `GNU stow` to manage.

# Niri & DMS

![Niri in lightmode](img/niri-light.png)
![Niri in darkmode](img/niri-dark.png)

The original config files are at `~/.config/niri`.

Packages（in `paru`）:
- `dms-shell-bin`, `matugen`, `wl-clipboard`, `cliphist`, `cava`, `qt6-multimedia-ffmpeg`, `dsearch-bin`: DankMaterialShell
- `qt6ct`, `nwg-look`: QT & GTK Theme Manager
- `xdg-desktop-portal`, `xdg-desktop-portal-gtk`: Desktop API for screen casting etc.
- `kitty`, `dolphin`: Terminal & File Manager
- `darkman`: Light & Darkmode support
- `grim`, `slurp`, `satty`: Screenshot & Editor

Plugins (in `DMS`):
- `Dank Hooks`: The light / dark mode switch hook script is `.local/bin/hook.sh`.
    ```sh
    #!/bin/bash

    HOOK_NAME="$1"  # e.g., "onWallpaperChanged"
    HOOK_VALUE="$2" # e.g., "/path/to/wallpaper.jpg"

    if [ $HOOK_NAME = "onLightModeChanged" ]; then
        if [ $HOOK_VALUE = "light" ]; then
            niri msg action do-screen-transition -d 600 &
            sed -i 's/^icon_theme=.*/icon_theme=breeze/' ~/.config/qt6ct/qt6ct.conf
        elif [ $HOOK_VALUE = "dark" ]; then
            niri msg action do-screen-transition -d 600 &
            sed -i 's/^icon_theme=.*/icon_theme=breeze-dark/' ~/.config/qt6ct/qt6ct.conf
        fi
    fi
    ```
- `Calculator`: Calculator in DMS Spotlight
    - trigger: `=`
- `Web Search`: Search Plugin in DMS Spotlight
    - trigger: `?`
- `Command Runner`: Calculator in DMS Spotlight
    - trigger: `>`
- `Dank Battery Alerts`: Receive notifications when battery level is low

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

![Nvim in lightmode](img/nvim-light.png)
![Nvim in darkmode](img/nvim-dark.png)

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

![Kitty in lightmode](img/kitty-light.png)
![Kitty in darkmode](img/kitty-dark.png)

The original config files are at `~/.config/kitty`.

Using default dark theme and customized default light theme.

To automatically switch kitty themes between light and dark mode, make sure these files exist:
- `.config/kitty/dark-theme.auto.conf`: `color-scheme` == `'prefer-dark'`
- `.config/kitty/light-theme.auto.conf`: `color-scheme` == `'prefer-light'`
- `.config/kitty/no-preference-theme.auto.conf`: `color-scheme` == `'default'`

## Deploy

```sh
cd dotfiles/kitty/.config/kitty
ln -s font-mac.conf font-platform.conf # On macOS
ln -s font-linux.conf font-platform.conf # On Linux
cd ../../..
stow --dotfiles kitty
```

# Darkman

The original script directory is `~/.local/share/darkman`.

I wrote a script to restart and change the icons of dms monitor changes in the system `color-scheme` and adjust Kitty's theme accordingly.

> Currently dms has a bug that the first attempt after initialization to restart dms will fail, thus the script will restart dms twice at session startup.

> Currently dms has a bug that the system tray widget might be failed to recover after dms restarts.

```sh
#!/bin/bash

MODE="$1"
INIT_FLAG="/tmp/dms_theme_initialized"

case "$MODE" in
    dark)
        THEME_ARG="dark"
        ICON_THEME="breeze-dark"
        ;;
    light)
        THEME_ARG="light"
        ICON_THEME="breeze"
        ;;
    *)
        echo "Usage: $0 {dark|light}"
        exit 1
        ;;
esac

try_restart_dms() {
    dms restart
    sleep 0.2
    dms ipc call theme "$THEME_ARG"
}

sed -i "s/^icon_theme=.*/icon_theme=$ICON_THEME/" ~/.config/qt6ct/qt6ct.conf

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

If you are not concerned about the color of the icon, use this script instead, it's way more faster and smoother. (Default)

```sh
#!/bin/bash

case "$1" in
    dark)
        dms ipc call theme dark
        sed -i 's/^icon_theme=.*/icon_theme=breeze-dark/' ~/.config/qt6ct/qt6ct.conf
        ;;
    light)
        dms ipc call theme light
        sed -i 's/^icon_theme=.*/icon_theme=breeze/' ~/.config/qt6ct/qt6ct.conf
        ;;
    *)
        echo "Usage: $0 {dark|light}"
        exit 1
        ;;
esac

niri msg action do-screen-transition -d 500 &
```

## Deploy

```sh
cd dotfiles
stow --dotfiles darkman
```

(If using the Icon-changing scripts)
```sh
cd dotfiles/darkman/.local/share/darkman
mv niri-theme.sh niri-theme.sh.bak
mv niri-theme-icon.sh.bak niri-theme-icon.sh
chmod +x niri-theme-icon.sh
chmod -x niri-theme.sh.bak
cd ../../../..
stow --dotfiles darkman
```

# Fuzzel

![Fuzzel](img/fuzzel.png)

The original config files are at `~/.config/fuzzel`.

## Deploy

```sh
cd dotfiles
stow --dotfiles fuzzel
```

# Satty

The original config files are at `~/.config/satty`.

## Deploy

```sh
cd dotfiles
stow --dotfiles satty
```

# Fish

The original config files are at `~/.config/fish`.

## Deploy

```sh
cd dotfiles
stow --dotfiles fish
fisher update
```

# Others

## Dolphin Context Menu

In Dolphin (KDE Plasma), we can use `Alt + Shift + F4` to Open Terminal in current folder, and the default terminal is Konsole.

In Niri, we want to open current folder with Kitty. I wrote a script and context menu to do this.

```sh
#!/bin/bash

if [[ "$XDG_CURRENT_DESKTOP" == *"niri"* ]] || [[ "$XDG_SESSION_DESKTOP" == *"niri"* ]]; then
    exec kitty "${@/--workdir/--directory}"
else
    exec konsole "$@"
fi
```

```desktop
[Desktop Entry]
Name=Smart Terminal (Niri / KDE)
Comment=Opens Kitty in Niri, Konsole in KDE
Exec=bash -c /home/dean/.local/bin/smart-terminal.sh %f
Icon=utilities-terminal
Type=Application
Categories=System;TerminalEmulator;
Terminal=false
```

## Qt XWayland Application

Some applications running on XWayland, especially using outdated QT version, like `wps-office-365`, has a dpi issue when scaling is applied.

The solution is to create `.Xresources` file and set independent dpi for those applications:

```
Xft.dpi: 168 // = 96 * scale
```

Then apply at startup:
```kdl
// ...
spawn-sh-at-startup "xrdb -merge ~/.Xresources"
// ...
```

## Deploy

```sh
cd dotfiles
stow --dotfiles others
kcmshell6 componentchooser
```

In the `componentchooser` window, choose Terminal Simulator to `Smart Terminal (Niri / KDE)`.

![componentchooser](img/kcmshell.png)
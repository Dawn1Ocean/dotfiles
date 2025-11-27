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

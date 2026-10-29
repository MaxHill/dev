# Desktop theme files

Run `theme light`, `theme dark`, or `theme` to select a theme with Rofi.
The script syncs `~/dev/themes/<name>/` to
`${XDG_CONFIG_HOME:-$HOME/.config}/theme/` using `rsync -a --checksum --delete`.
The active directory is managed by the script; extra files are removed.
Checksum comparison matters because different palettes can have identical file
sizes and timestamps.

## Files in each theme

- `appearance`: `light` or `dark`, followed by Neovim.
- `colors.css`: Waybar color variables.
- `colors.lua`: Hyprland window border colors.
- `kitty.conf`: includes the installed Kitty palette.
- `hyprland-theme.conf`: shared Hyprlang variables for Hyprpaper and Hyprlock.

The shared Hyprlang file defines `$wallpaper`, `$foreground`, `$background`,
`$workspace_selected_background`, and `$workspace_selected_foreground`.
Its four colors duplicate the corresponding values in `colors.css`; keep them
in sync. It contains no application-specific sections.

Both root configs source `~/.config/theme/hyprland-theme.conf` before using its
variables. Hyprpaper owns its `wallpaper` block. Hyprlock owns its background,
password field, and labels. Do not copy these blocks into theme directories.
Light uses the cream/red wallpaper; dark uses the charcoal/red variant.
Images stay in `~/Pictures/wallpapers/` and are not installed from this repo.

## Activation

The script validates all five theme files and required commands before syncing.
It reloads Hyprland when running in a Hyprland session, signals Waybar and Kitty
to reload, and restarts Hyprpaper. Hyprlock reads its config on the next lock.
Neovim polls the appearance marker; Pi uses Kitty's colors through `system`.

`install.sh` activates dark after installing dependencies, scripts, and configs.
An active theme must exist before starting applications that source its files.
Rsync is not transactional: an interrupted sync can leave a partial update.
The desktop config includes still use `~/.config`; a custom `XDG_CONFIG_HOME`
requires updating those includes too.

## Source references and alternatives

Hyprpaper 0.8.4 explicitly registers a `source` handler in its
[config parser](https://github.com/hyprwm/hyprpaper/blob/v0.8.4/src/config/ConfigManager.cpp).
This setup keeps app configuration static and switches variable files instead
of generating application configs.

[Omarchy v3.0.0](https://github.com/basecamp/omarchy/blob/v3.0.0/bin/omarchy-theme-bg-next)
uses theme background directories, a stable background symlink, and swaybg.
The symlink approach is useful when wallpaper selection should be independent
of theme selection; this repo does not depend on Omarchy.

[ML4W's documented workflow](https://github.com/mylinuxforwork/dotfiles/wiki/Wallpapers)
uses Waypaper, Pywal color generation, and a wallpaper config template. That is
useful for wallpaper-first generated palettes, but adds machinery not needed
for these fixed light/dark themes.

[Kitty's config documentation](https://sw.kovidgoyal.net/kitty/conf/)
documents config includes and `SIGUSR1` reloads without remote control.

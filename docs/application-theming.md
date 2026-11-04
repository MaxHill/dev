# Application theming

## Ownership

- `themes/light` and `themes/dark` contain the active GTK palette and other desktop theme files.
- `scripts/theme` validates the selected theme, syncs it into `$XDG_CONFIG_HOME/theme` (default `~/.config/theme`), and updates the desktop appearance settings.
- `configs/gtk` installs GTK3 and GTK4 entry points. Both import `../theme/gtk.css`. The built-in Adwaita theme supplies widget behavior; our overrides supply cream light surfaces and black dark surfaces.
- Firefox and Thunderbird have separate chrome stylesheets with light/dark media queries. They follow the system appearance rather than having files rewritten by `theme`.
- `install-configs.sh` uses normal Stow behavior for regular config packages. Only Firefox and Thunderbird use `--no-folding`, so runtime profile data stays outside the repo.

The GTK overrides and Firefox stylesheet are adapted from [Adwaita Black](https://github.com/sijan-dev/adwaita-black). See [its license](adwaita-black-LICENSE). We do not install the upstream theme under its original name or run its installer.

## Installation and migration

Close Firefox and Thunderbird/Betterbird before stowing their packages. Run the normal config installer, or install only these packages from the repo root:

```sh
stow --dir=configs --target="$HOME" gtk
stow --dir=configs --target="$HOME" --no-folding firefox thunderbird
```

Stow does not overwrite existing unmanaged files. If it reports conflicts, back up and move aside only the conflicting files before retrying. Do not delete existing profiles or mail data. Older copies of `gtk-light.css` and `gtk-dark.css` are no longer used.

Initialize the active GTK palette after installing the configs:

```sh
theme light
# Or: theme dark
```

The command retains the repo's existing requirement that the checkout lives at `~/dev`. Custom `XDG_CONFIG_HOME` must match the directory where you install the GTK config; the standard Stow package layout targets `~/.config`.

## Firefox and Thunderbird profiles

Both packages register a profile named `dotfiles`:

- Firefox: `~/.mozilla/firefox/dotfiles`
- Thunderbird and Betterbird: `~/.thunderbird/dotfiles`

Betterbird uses Thunderbird's profile location. Do not open the same profile concurrently in Thunderbird and Betterbird.

If an application keeps selecting an old profile, use its profile manager to select `dotfiles` and make it the default. For Firefox, use `about:profiles`. For mail, close the application first, then run `betterbird -P` or `thunderbird -P`. Per-installation profile defaults can override `Default=1` in `profiles.ini`.

A new profile does not inherit existing browser data or mail accounts. Keep the old profile until you have migrated the data you need. Do not commit profile data, credentials, or account configuration to the repo.

Select **System theme — auto** in the application's theme settings. Restart once to load `user.js` and custom chrome CSS. The chrome media queries then follow system appearance changes. CSS edits require another restart. Mail styling is limited to application chrome; message bodies retain their own styling.

## GTK behavior and checks

The GTK overrides replace the old fixed-white styles and invalid `*::headerbar` selector. They preserve native button states, selection, and focus styling rather than forcing every widget's background.

GTK apps can cache their user stylesheet. Reopen them after changing the active palette if they retain old colors. Unlike the Mozilla media queries, live GTK user-CSS reload is not guaranteed. Sandboxed applications may need separate access to the config directories and are not covered by this setup.

Installed GTK test app:

```sh
pavucontrol
```

For a libadwaita app, install and launch `gnome-calculator`.

Run the automated checks from a graphical session:

```sh
bash tests/theming.sh
```

The checks require Stow, rsync, Lua, a C compiler, pkg-config, and GTK3/GTK4/libadwaita development headers. They verify real toolkit palette loading for both appearances, reject GTK theme-parser warnings, and verify that Mozilla profile directories do not fold into the repo. They do not prove every widget or application looks correct.

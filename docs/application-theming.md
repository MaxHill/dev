# Application theming

## Ownership

- `configs/gtk/.local/share/themes` contains the complete GTK themes. Stow installs them as `~/.local/share/themes/adwaita-black-light` and `adwaita-black-dark`. Each contains GTK3/GTK4 stylesheets, a shared palette, and theme metadata.
- `themes/light/gtk-theme` and `themes/dark/gtk-theme` select an installed GTK theme by name. GTK CSS does not live in `themes/`.
- `scripts/theme` validates the selected GTK theme, syncs the desktop theme into `$XDG_CONFIG_HOME/theme` (default `~/.config/theme`), and sets the desktop GTK theme name and color scheme.
- GTK3 and ordinary GTK4 apps use the installed named theme. Libadwaita ignores that name, so `configs/gtk/.config/gtk-4.0/gtk.css` imports the active palette through `../theme/gtk.css`. The switcher makes that active path a symlink to the installed theme's `palette.css`; it does not copy GTK CSS or modify Stow-managed files.
- `configs/mozilla` installs both Firefox and Thunderbird/Betterbird profiles. Their chrome stylesheets import a shared generated `~/.config/theme/mozilla-colors.css` palette.
- `scripts/theme` translates the GTK `@define-color` values in desktop `colors.css` files into Mozilla CSS variables. Both light/dark media queries are included, so the applications still respond to system appearance changes without profile files being rewritten.
- `install-configs.sh` uses normal Stow behavior for regular config packages. Only the `mozilla` package uses `--no-folding`, so runtime profile data stays outside the repo.

The GTK overrides and Firefox stylesheet are adapted from [Adwaita Black](https://github.com/sijan-dev/adwaita-black). See [its license](adwaita-black-LICENSE). We do not install the upstream theme under its original name or run its installer.

## Installation and migration

Close Firefox and Thunderbird/Betterbird before stowing their packages. Run the normal config installer, or install only these packages from the repo root:

```sh
stow --dir=configs --target="$HOME" gtk
stow --dir=configs --target="$HOME" --no-folding mozilla
```

Stow does not overwrite existing unmanaged files. If it reports conflicts, back up and move aside only the conflicting files before retrying. Do not delete existing profiles or mail data. Older copies of `gtk-light.css` and `gtk-dark.css` are no longer used.

Select an installed GTK theme after stowing the configs:

```sh
theme light
# Or: theme dark
```

The command retains the repo's existing requirement that the checkout lives at `~/dev`. The standard Stow layout targets `~/.config` and `~/.local/share`; custom `XDG_CONFIG_HOME` and `XDG_DATA_HOME` must match your installation paths.

Mozilla uses `surface_background_opaque`, `surface_foreground`, `surface_field`, `surface_hover`, and `surface_border` from `themes/light/colors.css` and `themes/dark/colors.css`. These tokens must be six-digit hex colors. A custom desktop theme replaces the palette for its declared appearance; the opposite appearance falls back to the built-in light or dark palette. Editing palette values requires running `theme` again and restarting Mozilla applications to reload the imported CSS. Normal light/dark switching uses the already-loaded media queries.

The profile imports assume the standard `~/.config/theme` location. A custom config-home location needs matching import paths in both chrome stylesheets.

If the old `firefox` and `thunderbird` Stow packages are already installed, their managed files still point at the previous repo paths. Close the apps, remove only those old managed links, then stow `mozilla`. Leave runtime profile data and real directories in place.

To add a theme, create another named theme under `configs/gtk/.local/share/themes/`, with `gtk-3.0/gtk.css`, `gtk-4.0/gtk.css`, and `palette.css`. Stow it, then set the relevant desktop theme's `gtk-theme` file to that name. Its `appearance` file independently controls the system light/dark preference.

## Firefox and Thunderbird profiles

The Mozilla package registers a profile named `dotfiles` for each application:

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

After selecting each theme, reopen Pavucontrol and a libadwaita app to check surfaces, text, selection, and focus visibility.

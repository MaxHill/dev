# Application theming

## Ownership

- `configs/gtk/.local/share/themes` contains the complete GTK themes. Stow installs them as `~/.local/share/themes/adwaita-black-light` and `adwaita-black-dark`. Each contains GTK3/GTK4 stylesheets, a shared palette, and theme metadata.
- `themes/light/gtk-theme` and `themes/dark/gtk-theme` select an installed GTK theme by name. GTK CSS does not live in `themes/`.
- `scripts/theme` validates the selected GTK theme, syncs the desktop theme into `$XDG_CONFIG_HOME/theme` (default `~/.config/theme`), and sets the desktop GTK theme name and color scheme.
- GTK3 and ordinary GTK4 apps use the installed named theme. Libadwaita ignores that name, so `configs/gtk/.config/gtk-4.0/gtk.css` imports the active palette through `../theme/gtk.css`. The switcher makes that active path a symlink to the installed theme's `palette.css`; it does not copy GTK CSS or modify Stow-managed files.
- `configs/mozilla` installs both Firefox and Thunderbird/Betterbird profiles. Their chrome stylesheets import a shared `~/.config/theme/mozilla-colors.css` palette.
- Each desktop theme contains a static `mozilla-colors.css`. The existing theme sync copies it alongside the other desktop files. There is no CSS parsing or generation.
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

Each `themes/<name>/mozilla-colors.css` defines the Firefox/Thunderbird surface variables. Keep them matched to that theme's `colors.css`. New desktop themes must provide their own static `mozilla-colors.css`. After changing palettes or editing CSS, run `theme` and restart Mozilla applications to reload the imported stylesheet; this setup does not live-reload the custom chrome palette.

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

Select **System theme — auto** in the application's theme settings. Restart to load `user.js` and custom chrome CSS. After switching desktop themes, restart again to load the selected static palette. Mail styling is limited to application chrome; message bodies retain their own styling.

## Chromium

Chromium uses the installed GTK theme. In Appearance settings, select **Use GTK** and keep Mode set to **Device**. `scripts/theme` already sets the desktop GTK theme and color scheme, so no browser color policies or per-theme Chromium files are needed. Reopen Chromium if it retains old colors after a theme switch.

`install-browsers.sh` removes the policy symlink from our earlier seed-color setup if it still points to this user's generated file. It leaves unrelated policies untouched. The GTK setup does not add color policies.

The browser installer also adds `--extensions-on-chrome-urls` to `~/.config/chromium-flags.conf` without removing other flags. It installs `dotfiles-command-line-warnings.json` with `CommandLineFlagSecurityWarningsEnabled: false`. This deliberately suppresses warnings for **all** potentially dangerous command-line flags and brings back Chromium's generic “managed by your organization” notice. It does not remove the security risks of those flags. Fully quit and restart Chromium after installation; this policy does not support live refresh.

## GTK behavior and checks

The GTK overrides replace the old fixed-white styles and invalid `*::headerbar` selector. They preserve native button states, selection, and focus styling rather than forcing every widget's background.

GTK apps can cache their user stylesheet. Reopen them after changing the active palette if they retain old colors. Live GTK user-CSS reload is not guaranteed either. Sandboxed applications may need separate access to the config directories and are not covered by this setup.

Installed GTK test app:

```sh
pavucontrol
```

For a libadwaita app, install and launch `gnome-calculator`.

After selecting each theme, reopen Pavucontrol and a libadwaita app to check surfaces, text, selection, and focus visibility.

GTK4's built-in stylesheet uses literal colors for notebook pages, lists, tab indicators, and slider highlights. Defining palette colors alone does not recolor these widgets. Both installed palettes therefore include targeted rules for those surfaces and active accents. Disabled sliders retain native styling.

For a screenshot regression check, capture only Pavucontrol's Playback window with at least one visible slider (use `hyprctl clients -j` for its position and size, then `grim -g 'x,y WIDTHxHEIGHT' /tmp/pavucontrol.png`). Run:

```sh
bash tests/check-pavucontrol-screenshot.sh dark /tmp/pavucontrol.png
# Use light after selecting the light theme and reopening Pavucontrol.
```

This checks the dominant background and presence of the gold accent. It does not replace visual checks of text, focus, disabled controls, or other tabs.

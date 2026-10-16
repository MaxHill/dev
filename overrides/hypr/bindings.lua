-- Personal bindings, loaded after Omarchy's native bindings.
local function bind(keys, description, action)
  hl.unbind(keys)
  o.bind(keys, description, action)
end

bind("SUPER + RETURN", "Terminal", { launch = "ghostty" })
bind("SUPER + B", "Browser", { launch = "firefox" })
bind("SUPER + D", "Discord", { webapp = "https://discord.com/channels/@me" })
-- Replaces Omarchy's window-group toggle.
bind("SUPER + G", "Notion", { webapp = "https://www.notion.so/" })

-- K replaces the keybindings viewer; J and L replace layout controls.
for key, direction in pairs({ H = "l", J = "d", K = "u", L = "r" }) do
  bind("SUPER + " .. key, "Focus " .. direction, hl.dsp.focus({ direction = direction }))
  bind("SUPER + SHIFT + " .. key, "Move window " .. direction, hl.dsp.window.move({ direction = direction }))
end

-- Replace Docker and file-manager bindings. Keep Quattro's native lid handlers.
bind("SUPER + SHIFT + D", "Disable laptop display", "omarchy-hyprland-monitor-internal off")
bind("SUPER + SHIFT + F", "Enable laptop display", "omarchy-hyprland-monitor-internal on")

for _, key in ipairs({ "PRINT", "ALT + PRINT", "SUPER + PRINT" }) do
  hl.unbind(key)
end
bind("CTRL + SHIFT + 3", "Screenshot (fullscreen)", "omarchy-capture-screenshot fullscreen")
bind("CTRL + SHIFT + 4", "Screenshot (region)", "omarchy-capture-screenshot region")
bind("CTRL + SHIFT + 5", "Screen recording menu", "omarchy-menu toggle trigger.capture.screenrecord")

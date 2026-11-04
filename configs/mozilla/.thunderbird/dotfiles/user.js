// Load chrome styling and follow the system appearance (also used by Betterbird).
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
user_pref("widget.gtk.libadwaita-colors.enabled", false);
user_pref("browser.theme.toolbar-theme", 2);
user_pref("browser.theme.content-theme", 2);

// Reset the previous orange override; sidebar highlighting is styled in CSS.
user_pref("mail.appearance.accentColor", "accent-color");

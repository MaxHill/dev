return {
    search_paths = {
        "~/code/work",
        "~/code/personal",
        { path = "~/dev", depth = 0 },
        { path = "~/Dropbox/Notes", depth = 0 },
    },

    -- Session command indexes are zero-based: -s 0 runs lazygit.
    session_commands = {
        "lazygit",
    },

    -- Append diagnostics to the default tmux-sessionizer log file.
    log = true,
}

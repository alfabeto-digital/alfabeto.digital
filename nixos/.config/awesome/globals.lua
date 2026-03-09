local awful = require("awful")
local naughty = require("naughty")

local M = {}

M.terminal = "kitty"
M.editor = os.getenv("EDITOR") or "vim"
M.editor_cmd = M.terminal .. " -e " .. M.editor

M.modkey = "Mod4"
M.altkey = "Mod1"

M.layouts = {
    awful.layout.suit.tile,
}

M.notifications_enabled = true

M.notification_filter = function(n)
    if not M.notifications_enabled and not n.ignore_toggle then
        return nil
    end
    return n
end

-- Notifications
naughty.config.notify_callback = function(n)
    local filtered  = M.notification_filter(n)
    if not filtered then
        return nil
    end

    local beautiful = require("beautiful")
    local gears = require("gears")

    local screen = awful.screen.focused()
    n.height = 100
    n.margin = 10
    n.screen = screen
    n.shape = gears.shape.rounded_rect
    n.border_width = beautiful.border_width or 2
    n.border_color = beautiful.border_focus or "#FE8019"
    n.bg = beautiful.bg_normal or "#282828"
    n.fg = beautiful.fg_normal or "#DCDCCC"
    n.timeout = 5
    n.hover_timeout = 2
    n.position = "top_middle"

    return n
end

return M
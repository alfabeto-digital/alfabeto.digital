-- Load LuaRocks
pcall(require, "luarocks.loader")

-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
local wibox = require("wibox")
local naughty = require("naughty")
local beautiful = require("beautiful")
local client = client

require("awful.autofocus")

-- Theme handling library
awesome.set_preferred_icon_size(64)

-- Initialize theme
beautiful.init(os.getenv("HOME") .. "/.config/awesome/theme.lua")

-- Load local modules
local error_handling = require("error_handling")
local globals = require("globals")
local functions = require("functions")
local widgets = require("widgets")
local wibar_config = require("wibar")
local keybindings = require("keybindings")
local rules_config = require("rules")

-- Set global variables
terminal = globals.terminal
editor = globals.editor
editor_cmd = globals.editor_cmd
modkey = globals.modkey
altkey = globals.altkey
awful.layout.layouts = globals.layouts
notifications_enabled = globals.notifications_enabled

-- Apply error handling
error_handling.setup()

-- Create a taglist button
local taglist_buttons = gears.table.join(
    awful.button({ }, 1, function(t) t:view_only() end),
    awful.button({ modkey }, 1, function(t)
        if client.focus then
            client.focus:move_to_tag(t)
        end
    end),
    awful.button({ }, 3, awful.tag.viewtoggle),
    awful.button({ modkey }, 3, function(t)
        if client.focus then
            client.focus:toggle_tag(t)
        end
    end),
    awful.button({ }, 4, function(t) awful.tag.viewnext(t.screen) end),
    awful.button({ }, 5, function(t) awful.tag.viewprev(t.screen) end)
)

-- Create a tasklist button
local tasklist_buttons = gears.table.join(
    awful.button({ }, 1, function (c)
        if c == client.focus then
            c.minimized = true
        else
            c:emit_signal(
                "request::activate",
                "tasklist",
                {raise = true}
            )
        end
    end),
    awful.button({ }, 3, function()
        awful.util.spawn("rofi -show window")
    end),
    awful.button({ }, 4, function ()
        awful.client.focus.byidx(1)
    end),
    awful.button({ }, 5, function ()
        awful.client.focus.byidx(-1)
    end)
)

-- Connect signals and apply initial configurations
awful.screen.connect_for_each_screen(function(s)
    -- Set wallpaper
    functions.set_wallpaper(s)

    -- Each screen has its own tag table.
    awful.tag(
        { " \u{EDC5}  ", " \u{F188}  ", " \u{F06D}  " }, s, --     
        awful.layout.layouts[1]
    )

    -- Create a promptbox for each screen
    s.mypromptbox = awful.widget.prompt()

    -- Create taglist and tasklist widgets
    s.mytaglist = awful.widget.taglist {
        screen = s,
        filter = awful.widget.taglist.filter.all,
        buttons = taglist_buttons
    }

    s.mytasklist = awful.widget.tasklist {
        screen = s,
        filter = awful.widget.tasklist.filter.currenttags,
        buttons = tasklist_buttons,
        widget_template = wibar_config.tasklist_widget_template
    }

    -- Create systray for each screen
    s.awesome_systray = wibox.widget {
        widget = wibox.container.margin,
        top = 5,
        left = 5,
        {
            widget = wibox.widget.systray(),
            base_size = 40,
            visible = true,
        }
    }

    -- Create the wibar
    wibar_config.setup_wibar(s, widgets, functions, beautiful, naughty)

    -- Set screen padding
    awful.screen.padding(s, { top = 0, bottom = 10, left = 10, right = 10 })
end)

-- Set global keybindings
root.keys(keybindings.globalkeys)

-- Initialize rules
rules_config.init(keybindings, functions)
awful.rules.rules = rules_config.rules

-- Mouse actions for clients
clientbuttons = gears.table.join(
 awful.button({ }, 1, function (c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
    end),
    awful.button({ modkey }, 1, function (c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
        awful.mouse.client.move(c)
    end),
    awful.button({ modkey }, 3, function (c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
        awful.mouse.client.resize(c)
    end)
)

-- Enable sloppy focus, so that focus follows mouse.
client.connect_signal("mouse::enter", function(c)
    c:emit_signal("request::activate", 
"mouse_enter", {raise = false})
end)

-- Define focused client border color
client.connect_signal("focus", function(c) 
    c.border_color = beautiful.border_focus 
end)

-- Define unfocused client border color
client.connect_signal("unfocus", function(c) 
    c.border_color = beautiful.border_normal 
end)

-- Focus client on urgent notification
client.connect_signal("property::urgent", function(c)
    if c.class == "librewolf"
       or c.class == "Signal" then
        awful.client.urgent.jumpto(true)
    end
end)

-- Initial update for widgets that rely on external commands
functions.update_microphone_widget(widgets.microphone_widget)
functions.update_volume_widget(widgets.volume_widget)

-- Run a custom script
awful.spawn.with_shell("~/dante/.bin/startup")

-- Run updates periodically
-- gears.timer {
--    timeout = 5,
--    call_now = true,
--    autostart = true,
--    callback = function()
--        functions.update_microphone_widget()
--        functions.update_volume_widget()
--    end
--}
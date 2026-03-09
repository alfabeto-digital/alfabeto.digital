local gears = require("gears")
local awful = require("awful")
local naughty = require("naughty")
local beautiful = require("beautiful")
local client = client

local M = {}

-- Re-set wallpaper
function M.set_wallpaper(s)
    if beautiful.wallpaper then
        local wallpaper = beautiful.wallpaper
        if type(wallpaper) == "function" then
            wallpaper = wallpaper(s)
        end
        gears.wallpaper.maximized(wallpaper, s, true)
    end
end

-- Tag manipulation
function M.add_tag()
    awful.tag.add(" \u{F08C7}  ", {
        screen = awful.screen.focused(),
        layout = awful.layout.layouts[1] }
    ):view_only()
end

function M.delete_tag()
    local t = awful.screen.focused().selected_tag
    if not t then return end
    t:delete()
end

function M.rename_tag()
    awful.prompt.run {
        prompt       = "New tag name: ",
        textbox      = awful.screen.focused().mypromptbox.widget,
        exe_callback = function(new_name)
            if not new_name or #new_name == 0 then return end
            local t = awful.screen.focused().selected_tag
            if t then
                t.name = new_name
            end
        end
    }
end

-- Toggle notifications
function M.toggle_notifications()
    local globals = require("globals")
    globals.notifications_enabled = not globals.notifications_enabled
    
    naughty.notify({
        title = globals.notifications_enabled and "Normal mode \u{F009A}" or "Focus mode \u{F13E7}",
        text = globals.notifications_enabled and "Notifications enabled" or "Notifications disabled",
        timeout = 3,
        ignore_toggle = true
    })
    
    local widgets = require("widgets")
    widgets.naughty_toggle.text = globals.notifications_enabled and " \u{F009A} " or " \u{F13E7} " -- 󰂚 or 󱏧
end

-- Toggle systray
function M.toggle_systray()
    local screen = awful.screen.focused()
    if screen.awesome_systray then
        screen.awesome_systray.visible = not screen.awesome_systray.visible
        
        local widgets = require("widgets")
        widgets.systray_toggle.text = screen.awesome_systray.visible and "\u{F0BAF} " or "\u{F02A0} "  -- 󰮯 or 󰊠 
    end
end

-- Update the microphone widget
function M.update_microphone_widget(widget)
    awful.spawn.easy_async_with_shell("amixer -D pulse get Capture", function(stdout)
        local muted = string.match(stdout, "%[(o[^%]]*)%]")
        widget:set_microphone_state(muted == "off")
    end)
end

-- Update the volume widget
function M.update_volume_widget(widget)
    awful.spawn.easy_async_with_shell("amixer -D pulse get Master", function(stdout)
        local volume_level = tonumber(string.match(stdout, "(%d?%d?%d)%%")) or 0
        local mute_state = string.match(stdout, "%[(o[^%]]*)%]")
        if mute_state == "off" then volume_level = 0 end
        widget:set_volume_level(volume_level)
    end)
end

-- Spawn or toggle client
function M.awesome_spawn_or_toggle(cmd, class_name, maximizar)
    local matcher = function(c)
        return c.class and c.class:lower():match(class_name:lower())
    end

    local current_tag = awful.screen.focused().selected_tag

    for _, c in ipairs(client.get()) do
        if matcher(c) then
            local in_current_tag = false
            for _, t in ipairs(c:tags()) do
                if t == current_tag then
                    in_current_tag = true
                    break
                end
            end

            if c.minimized then
                c.minimized = false
                c:move_to_tag(current_tag)
                c:raise()
                client.focus = c
                return
            end

            if in_current_tag then
                if client.focus == c then
                    c.minimized = true
                else
                    c:raise()
                    client.focus = c
                end
                return
            else
                c:move_to_tag(current_tag)
                c.minimized = false
                c:raise()
                client.focus = c
                return
            end
        end
    end

    awful.spawn(cmd, {
        callback = function(c)
            c:connect_signal("property::class", function()
                if matcher(c) then
                    c:move_to_tag(current_tag)
                    c.minimized = false
                    c:raise()
                    client.focus = c
                    if maximizar then
                        c.maximized = true
                    end
                end
            end)
        end
    })
end

-- Resize and center specific client
function M.resize_and_center(c, width, height)
    if c and c.screen then
        local screen_geometry = c.screen.geometry
        local new_x = screen_geometry.x + (screen_geometry.width - width) / 2
        local new_y = screen_geometry.y + 30 + (screen_geometry.height - height) / 2

        c:geometry({ x = new_x, y = new_y, width = width, height = height })
    end
end

return M
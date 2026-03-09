local wibox = require("wibox")
local gears = require("gears")
local awful = require("awful")

local M = {}

M.tasklist_widget_template = {
    {
        {
            id = "icon_role",
            widget = wibox.widget.imagebox,
            forced_width = 40,
            forced_height = 40,
        },
        margins = 5,
        widget = wibox.container.margin,
    },
    id = "background_role",
    widget = wibox.container.background,
}

function M.setup_wibar(s, widgets, functions, beautiful, naughty)
    -- Create "empty" widgets to add spacing
    local big_space = wibox.widget.textbox("")
    local small_space = wibox.widget.textbox(" ")

    -- Create a separator
    local separator= wibox.widget.textbox('<span foreground="#FE8019">|</span>')

    -- Create the wibox
    s.mywibox = awful.wibar({
        position = "top",
        screen = s,
        opacity = 0.9,
        border_width = 10,
    })
    s.mywibox.shape = function(cr, w, h)
        gears.shape.rounded_rect(cr, w, h, 15)
    end

    -- Add widgets to the wibox
    s.mywibox:setup {
        layout = wibox.layout.align.horizontal,
        { -- Left widgets
            layout = wibox.layout.fixed.horizontal,
            widgets.home_widget,
            separator,
            widgets.obsidian_widget,
            widgets.thunderbird_widget,
            widgets.thunar_widget,
            separator,
            small_space,
            s.mytaglist,
            separator,
            s.mypromptbox,
            big_space
        },
        {-- Middle widget
            layout = wibox.layout.fixed.horizontal,
            big_space,
            s.mytasklist
        },
        { -- Right widgets
            layout = wibox.layout.fixed.horizontal,
            widgets.systray_toggle,
            s.awesome_systray,
            small_space,
            separator,
            small_space,
            widgets.naughty_toggle,
            small_space,
            separator,
            small_space,
            widgets.microphone_widget,
            small_space,
            widgets.volume_widget,
            small_space,
            separator,
            small_space,
            widgets.mykeyboard,
            widgets.keyboardlayout,
            separator,
            widgets.myclock,
            small_space,
            separator,
            widgets.mycalendar,
            small_space
        },
        position = "top",
        align = "right",
    }
end

return M
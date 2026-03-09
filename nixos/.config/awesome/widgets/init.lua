local wibox = require("wibox")
local awful = require("awful")
local gears = require("gears")
local functions = require("functions")
local calendar_widget = require("widgets.calendar")

local M = {}

-- Home widget
M.home_widget = wibox.widget {
    text   = " \u{F344}  ", -- 
    widget = wibox.widget.textbox,
}
M.home_widget:buttons(gears.table.join(
    awful.button({}, 1, function()
        awful.util.spawn("rofi -show drun")
    end)
))

-- Obsidian widget
M.obsidian_widget = wibox.widget {
    text   = " \u{EEF5}  ", -- 
    widget = wibox.widget.textbox,
}
M.obsidian_widget:buttons(gears.table.join(
    awful.button({}, 1, function()
        functions.awesome_spawn_or_toggle("obsidian", "Obsidian", true)
    end)
))

-- Thunderbird widget
M.thunderbird_widget = wibox.widget {
    text   = " \u{EEF8}  ", -- 
    widget = wibox.widget.textbox,
}
M.thunderbird_widget:buttons(gears.table.join(
    awful.button({}, 1, function()
        functions.awesome_spawn_or_toggle("thunderbird", "thunderbird", true)
    end)
))

-- Thunar widget
M.thunar_widget = wibox.widget {
    text   = " \u{EF81}  ", -- 
    widget = wibox.widget.textbox,
}
M.thunar_widget:buttons(gears.table.join(
    awful.button({}, 1, function()
        functions.awesome_spawn_or_toggle("thunar", "Thunar", true)
    end)
))

-- Create a notifications toggle widget
M.naughty_toggle = wibox.widget {
    widget = wibox.widget.textbox,
    font = "ShureTechMono Nerd Font 14",
    text = " \u{F009A} ", -- 󰂚
    align = "center",
    valign = "center",
}
M.naughty_toggle:buttons(gears.table.join(
    awful.button({}, 1, function()
        functions.toggle_notifications()
    end)
))

-- Create a systray toggle widget
M.systray_toggle = wibox.widget {
    widget = wibox.widget.textbox,
    font = "ShureTechMono Nerd Font 15",
    text = "\u{F0BAF} ", -- 󰮯
    align = "center",
    valign = "center",
}
M.systray_toggle:buttons(gears.table.join(
    awful.button({}, 1, function()
        functions.toggle_systray()
    end)
))

-- Create a microphone widget
M.microphone_widget = wibox.widget {
    {
        id = "icon",
        font = "ShureTechMono Nerd Font 14",
        text = "\u{ED03}", -- 
        widget = wibox.widget.textbox,
        forced_width = 30
    },
    layout = wibox.layout.fixed.horizontal,
    set_microphone_state = function(self, muted)
        if muted then
            self.icon.text = "\u{EFC6}" -- 
        else
            self.icon.text = "\u{ED03}" -- 
        end
        self:set_spacing(5)
        self:set_visible(true)
        self:emit_signal("widget::redraw_needed")
    end,
}

-- Connect signal for the microphone
M.microphone_widget:connect_signal("button::press", function(_, _, _, button)
    if button == 1 then -- left click
        awful.spawn("amixer -D pulse set Capture toggle")
        functions.update_microphone_widget()
    elseif button == 3 then -- right click
        awful.spawn("env GTK_THEME=Kripton pavucontrol --tab=4 &")
    end
    
    gears.timer.start_new(0.1, function()
        functions.update_microphone_widget(M.microphone_widget)
        return false
    end)
end)

-- Create a volume widget
M.volume_widget = wibox.widget {
    {
        id = "icon",
        font = "ShureTechMono Nerd Font 15",
        text = "\u{F0580}", -- 󰖀
        widget = wibox.widget.textbox,
        forced_width = 30
    },
    {
        id = "label",
        font = "ShureTechMono Nerd Font 14",
        align = "center",
        valign = "center",
        widget = wibox.widget.textbox,
    },
    layout = wibox.layout.fixed.horizontal,

    set_volume_level = function(self, volume_level)
        if volume_level == 0 then
            self.icon.text = "\u{F0581}" -- 󰖁
        else
            if volume_level < 33 then
                self.icon.text = "\u{F057F}" -- 󰕿
            elseif volume_level < 67 then
                self.icon.text = "\u{F0580}" -- 󰖀
            else
                self.icon.text = "\u{F057E}" -- 󰕾
            end
        end
        self.label.text = string.format("%d", volume_level)
        self:set_spacing(5)
        self:set_visible(true)
        self:emit_signal("widget::redraw_needed")
    end,
}

-- Conectar señales para el widget de volumen
M.volume_widget:connect_signal("button::press", function(_, _, _, button)
    if button == 1 then -- left click
        awful.spawn("amixer -D pulse set Master toggle")
        functions.update_volume_widget(M.volume_widget)
    elseif button == 2 then -- middle click
        awful.spawn("amixer -D pulse set Master toggle")
        functions.update_volume_widget(M.volume_widget)
    elseif button == 3 then -- right click
        awful.spawn("env GTK_THEME=Kripton pavucontrol --tab=3 &")
    elseif button == 4 then -- scroll up
        awful.spawn("amixer -D pulse set Master 1%+")
    elseif button == 5 then -- scroll down
        awful.spawn("amixer -D pulse set Master 1%-")
    end
    
    -- Actualizar después de un pequeño retraso
    gears.timer.start_new(0.1, function()
        functions.update_volume_widget(M.volume_widget)
        return false
    end)
end)

-- Keyboard layout and switcher
M.keyboardlayout = awful.widget.keyboardlayout()

M.mykeyboard = wibox.widget{
    text = "\u{F11C}", -- 
    widget = wibox.widget.textbox,
    forced_width = 30
}

-- Connect signal for keyboard
M.mykeyboard:connect_signal("button::press", function(_, _, _, button)
    if button == 1 then 
        M.keyboardlayout.next_layout() 
    end
end)

-- Create a clock textbox
M.myclock = wibox.widget.textclock(' \u{F017}  %H:%M') -- 

-- Create a calendar textbox
M.mycalendar = wibox.widget.textclock(' \u{EAB0}  %A, %d %B %Y ') -- 

-- Create a calendar widget
M.calendar = calendar_widget()

-- Connect signal for calendar
M.mycalendar:connect_signal("button::press", function(_, _, _, button)
    if button == 1 then 
        M.calendar.toggle() 
    end
end)

return M
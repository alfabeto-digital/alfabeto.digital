-- {{{ Load resources
-- Load LuaRocks
pcall(require, "luarocks.loader")

-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
local prompt = require("awful.prompt")

require("awful.autofocus")

-- Widget and layout library
local wibox = require("wibox")

-- Theme handling library
local beautiful = require("beautiful")
awesome.set_preferred_icon_size(64)

-- Notification library
local naughty = require("naughty")
local menubar = require("menubar")

-- Calendar widget
local calendar_widget = require("widgets.calendar")

-- Hotkey popup
local hotkeys_popup = require("awful.hotkeys_popup")
require("awful.hotkeys_popup.keys")
-- }}}

-- {{{ Error handling
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
    title = "Oops, there were errors during startup!",
    text = awesome.startup_errors })
end

-- Handle runtime errors after startup
do
local in_error = false
awesome.connect_signal("debug::error", function (err)
    -- Make sure we don't go into an endless error loop
    if in_error then return end
    in_error = true

    naughty.notify({ preset = naughty.config.presets.critical,
        title = "Oops, an error happened!",
        text = tostring(err) })
        in_error = false
    end)
end
-- }}}

-- {{{ Variable definitions
-- Theme
beautiful.init(os.getenv("HOME") .. "/.config/awesome/theme.lua")

-- Default terminal and editor
terminal = "kitty"
editor = os.getenv("EDITOR") or "vim"
editor_cmd = terminal .. " -e " .. editor

-- Default modkey.
modkey = "Mod4"
altkey = "Mod1"

-- Default layout
awful.layout.layouts = {
awful.layout.suit.tile,
}

-- Notifications filter
local notifications_enabled = true

local function notification_filter(n)
    if not notifications_enabled and not n.ignore_toggle then
        return nil
    end
    return n
end

-- Notifications
naughty.config.notify_callback = function(n)
    local filtered  = notification_filter(n)
    if not filtered then
        return nil
    end

    local screen    = awful.screen.focused()
    n.height        = 100
    n.margin        = 10
    n.screen        = screen
    n.shape         = gears.shape.rounded_rect
    n.border_width  = beautiful.border_width or 2
    n.border_color  = beautiful.border_focus or "#FE8019"
    n.bg            = beautiful.bg_normal    or "#282828"
    n.fg            = beautiful.fg_normal    or "#DCDCCC"
    n.timeout       = 10
    n.hover_timeout = 3
    n.position      = "top_middle"
    
    return n
end
-- }}}

-- {{{ Wibar
-- Home widget
local home_widget = wibox.widget {
    text   = " \u{F344}  ", --  
    widget = wibox.widget.textbox,
}
home_widget:buttons(gears.table.join(
    awful.button({}, 1, function()
        awful.util.spawn("rofi -show drun")
    end)
))
-- Obsidian widget
local obsidian_widget = wibox.widget {
    text   = " \u{EEF5}  ", -- 
    widget = wibox.widget.textbox,
}
obsidian_widget:buttons(gears.table.join(
    awful.button({}, 1, function()
        awesome_spawn_or_toggle("obsidian", "Obsidian", true)
    end)
))

-- Thunderbird widget
local thunderbird_widget = wibox.widget {
    text   = " \u{EEF8}  ", -- 
    widget = wibox.widget.textbox,
}
thunderbird_widget:buttons(gears.table.join(
    awful.button({}, 1, function()
        awesome_spawn_or_toggle("thunderbird", "thunderbird", true)
    end)
))

-- Thunar widget
local thunar_widget = wibox.widget {
    text   = " \u{EF81}  ", -- 
    widget = wibox.widget.textbox,
}
thunar_widget:buttons(gears.table.join(
    awful.button({}, 1, function()
        awesome_spawn_or_toggle("thunar", "Thunar", true)
    end)
))

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

-- Create a notifications toggle widget
local naughty_toggle = wibox.widget {
    widget = wibox.widget.textbox,
    font = "ShureTechMono Nerd Font 15",
    text = "🔔",
    align = "center",
    valign = "center",
}

-- Create a systray toggle widget
local systray_toggle = wibox.widget {
    widget = wibox.widget.textbox,
    font = "ShureTechMono Nerd Font 15",
    text = "\u{F02A0} ", -- 󰊠
    align = "center",
    valign = "center",
}

-- Create a systray widget
awful.screen.connect_for_each_screen(function(s)
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
end)

-- Create a microphone widget
microphone_widget = wibox.widget {
    {
        id = "icon",
        font = "ShureTechMono Nerd Font 14",
        text = "",
        widget = wibox.widget.textbox,
        forced_width = 30
    },
    layout = wibox.layout.fixed.horizontal,
    set_microphone_state = function(self, muted)
        if muted then
            self.icon.text = ""
        else
            self.icon.text = ""
        end
        self:set_spacing(5)
        self:set_visible(true)
        self:emit_signal("widget::redraw_needed")
    end,
}

-- Create a volume widget
volume_widget = wibox.widget {
    {
        id = "icon",
        font = "ShureTechMono Nerd Font 15",
        text = "奄",
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
            self.icon.text = "婢"
        else
        if volume_level < 33 then
            self.icon.text = "奄"
        elseif volume_level < 67 then
            self.icon.text = "奔"
            else
                self.icon.text = "墳"
            end
        end
        self.label.text = string.format("%d", volume_level)
        self:set_spacing(5)
        self:set_visible(true)
        self:emit_signal("widget::redraw_needed")
    end,
}

-- Keyboard layout and switcher
keyboardlayout = awful.widget.keyboardlayout()

mykeyboard = wibox.widget{
    text = "",
    widget = wibox.widget.textbox,
    forced_width = 30
}

-- Create a clock textbox
myclock = wibox.widget.textclock('   %H:%M')

-- Create a calendar textbox
mycalendar = wibox.widget.textclock('   %A, %d %B %Y ')

-- Create a calendar widget
local calendar = calendar_widget()
--- }}}

--- {{{ Functions
-- Re-set wallpaper
local function set_wallpaper(s)
        if beautiful.wallpaper then
            local wallpaper = beautiful.wallpaper
            if type(wallpaper) == "function" then
                wallpaper = wallpaper(s)
            end
            gears.wallpaper.maximized(wallpaper, s, true)
    end
end

-- Tag manipulation
local function add_tag()
    awful.tag.add(" \u{F08C7}  ", {
        screen = awful.screen.focused(),
        layout = awful.layout.layouts[1] }
    ):view_only()
end
    
local function delete_tag()
    local t = awful.screen.focused().selected_tag
    if not t then return end
    t:delete()
end
    
local function rename_tag()
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
local function toggle_notifications()
    notifications_enabled = not notifications_enabled
    naughty.notify({
        title = notifications_enabled and "Normal mode 🔔" or "Focus mode 🔕",
        text = notifications_enabled and "Notifications enabled" or "Notifications disabled",
        timeout = 3,
        ignore_toggle = true
    })
    naughty_toggle.text = notifications_enabled and "🔔" or "🔕"
end

naughty_toggle:buttons(gears.table.join(
    awful.button({}, 1, function()
        toggle_notifications()
    end)
))

-- Toggle systray
local function toggle_systray()
    local screen = awful.screen.focused()
        if screen.awesome_systray then
            screen.awesome_systray.visible = not screen.awesome_systray.visible
            systray_toggle.text = screen.awesome_systray.visible and "\u{F0BAF} " or "\u{F02A0} " -- 󰮯 or 󰊠 
    end
end
    
systray_toggle:buttons(gears.table.join(
    awful.button({}, 1, function()
        toggle_systray()
    end)
))

-- Update the microphone widget
function update_microphone_widget()
    awful.spawn.easy_async_with_shell("amixer -D pulse get Capture", function(stdout)
        local muted = string.match(stdout, "%[(o[^%]]*)%]")
        if muted == "off" then
            microphone_widget:set_microphone_state(true)
        else
            microphone_widget:set_microphone_state(false)
        end
    end)
end

-- Update the volume widget
function update_volume_widget()
    awful.spawn.easy_async_with_shell("amixer -D pulse get Master", function(stdout)
        local volume_level = string.match(stdout, "(%d?%d?%d)%%")
        volume_level = tonumber(string.format("% 3d", volume_level))
        local mute_state = string.match(stdout, "%[(o[^%]]*)%]") 
            if mute_state == "off" then
                volume_level = 0
        end
        volume_widget:set_volume_level(volume_level)
   end)
end

-- Search for open client
function is_client_open(class_name)
for _, c in pairs(client.get()) do
       if c.class == class_name then
            return true
        end
    end
    return false
end

-- Spawn or toggle client
function awesome_spawn_or_toggle(cmd, class_name, maximizar)
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
function resize_and_center(c, width, height)
    if c and c.screen then
        local screen_geometry = c.screen.geometry
        local new_x = screen_geometry.x + (screen_geometry.width - width) / 2
        local new_y = screen_geometry.y + 30 + (screen_geometry.height - height) / 2
    
        c:geometry({ x = new_x, y = new_y, width = width, height = height })
    end
end

--- Geometry of individual clients
client.connect_signal("manage", function (c)
    c.shape = function(cr,w,h)
        gears.shape.rounded_rect(cr,w,h,15)
    end
    if c.class == "Zathura" then
        resize_and_center(c,1031, 1337)
    end
    if c.class == "kitty"
       or c.class == "librewolf"
       or c.class == "firefox" 
       or c.class == "Signal" then
        resize_and_center(c, 2100, 1331)
    end
end)

-- Create desktop environment
awful.screen.connect_for_each_screen(function(s)
    -- Set wallpaper
    set_wallpaper(s)
    -- Each screen has its own tag table.
    awful.tag(
        { " \u{EDC5}  ", " \u{F188}  ", " \u{F06D}  " }, s, --      
        awful.layout.layouts[1]
    )

    -- Create a promptbox for each screen
    s.mypromptbox = awful.widget.prompt()
    
    -- Create a taglist widget
    s.mytaglist = awful.widget.taglist {
        screen  = s,
        filter  = awful.widget.taglist.filter.all,
        buttons = taglist_buttons
    }

    -- Create a tasklist widget
    s.mytasklist = awful.widget.tasklist {
        screen   = s,
        filter   = awful.widget.tasklist.filter.currenttags,
        buttons  = tasklist_buttons,
        widget_template = {
            {
                {
                    id            = "icon_role",
                    widget        = wibox.widget.imagebox,
                    forced_width  = 40,
                    forced_height = 40,
                },
                margins = 5,
                widget  = wibox.container.margin,
            },
            id     = "background_role",
            widget = wibox.container.background,
        },
    }     
    
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
        border_width    = 10,
    })
    s.mywibox.shape = function(cr, w, h)
        gears.shape.rounded_rect(cr, w, h, 15)
    end

    -- Add widgets to the wibox
    s.mywibox:setup {
        layout = wibox.layout.align.horizontal,
        { -- Left widgets
            layout = wibox.layout.fixed.horizontal,
            home_widget,
            separator,
            obsidian_widget,
            thunderbird_widget,
            thunar_widget,
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
            naughty_toggle,
            small_space,
            separator,
            small_space,
            systray_toggle,
            s.awesome_systray,
            small_space,
            separator,
            small_space,
            microphone_widget,
            small_space,
            volume_widget,
            small_space,
            separator,
            small_space,
            mykeyboard,
            keyboardlayout,
            separator,
            myclock,
            small_space,
            separator,
            mycalendar,
            small_space
        },
        position = "top",
        align = "right",
   }
   awful.screen.padding(s, { top = 0, bottom = 10, left = 10, right = 10 })
end)
--- }}}

-- {{{ Key bindings
globalkeys = gears.table.join(
    
    -- AWESOME --
    --------------------------------------------------------------------
    awful.key({ modkey, "Control" }, "h", hotkeys_popup.show_help,
    {description= "show help", group="awesome"}),
    --------------------------------------------------------------------
    awful.key({ modkey, "Control" }, "r", awesome.restart,
    {description = "reload awesome", group = "awesome"}),
    --------------------------------------------------------------------
    awful.key({ modkey, "Control" }, "q", awesome.quit,
    {description = "quit awesome", group = "awesome"}),
    --------------------------------------------------------------------
    awful.key({ modkey, "Control" }, "x", function ()
        awful.prompt.run {
            prompt       = "Run Lua code: ",
            textbox      = awful.screen.focused().mypromptbox.widget,
            exe_callback = awful.util.eval,
            history_path = awful.util.get_cache_dir() .. "/history_eval"
        }
    end, {description = "lua execute prompt", group = "awesome"}),
    --------------------------------------------------------------------

    -- SYSTEM --
    --------------------------------------------------------------------
    awful.key({ modkey, "Control" }, "s", function ()
        awful.screen.focused().awesome_systray.visible = 
            not awful.screen.focused().awesome_systray.visible
    end, {description = "toggle systray visibility", group = "system"}),
    --------------------------------------------------------------------
    awful.key({ modkey, "Control" }, "t", function ()
        local s = awful.screen.focused()
            s.mytasklist.visible = not s.mytasklist.visible
    end, {description = "toggle tasklist visibility", group = "system"}),
    --------------------------------------------------------------------
    awful.key({ modkey, "Control" }, "k", function()
        awful.util.spawn("setxkbmap es,us")
            keyboardlayout.next_layout()
    end, {description = "switch keyboard layout", group = "system"}),
    --------------------------------------------------------------------
    awful.key({ modkey, "Control" }, "l", function()
        awful.util.spawn("betterlockscreen -l")
    end, {description = "lock screen", group = "system"}),
    --------------------------------------------------------------------

    -- TAGS --
    --------------------------------------------------------------------
    awful.key({ modkey }, "Left",   awful.tag.viewprev,
    {description = "view previous", group = "tag"}),
    --------------------------------------------------------------------
    awful.key({ modkey }, "Right",  awful.tag.viewnext,
    {description = "view next", group = "tag"}),
    --------------------------------------------------------------------
    awful.key({ modkey, "Control" }, "n", add_tag,
    {description = "add a tag", group = "tag"}),
    --------------------------------------------------------------------
    awful.key({ modkey, "Control" }, "d", delete_tag,
    {description = "delete the current tag", group = "tag"}),
    --------------------------------------------------------------------
    awful.key({ modkey, "Control" }, "m", rename_tag,
    {description = "rename the current tag", group = "tag"}),
    --------------------------------------------------------------------

    -- CLIENT --
    awful.key({ altkey }, "Tab", function ()
        awful.client.focus.byidx( 1)
    end, {description = "focus next by index", group = "client"}),
    --------------------------------------------------------------------
    awful.key({ altkey, "Shift" }, "Tab", function ()
        awful.client.focus.byidx(-1)
    end, {description = "focus previous by index", group = "client"}),
    --------------------------------------------------------------------
    awful.key({ modkey, "Shift" }, "e", function () 
        awful.screen.focus_relative( 1) 
    end, {description = "toggle screen focus", group = "screen"}),
    --------------------------------------------------------------------
    awful.key({ modkey, "Shift" }, "w", function ()
        awful.util.spawn("rofi -show window")
    end, {description = "switch through open clients", group = "client"}),
    --------------------------------------------------------------------

    -- LAUNCHER --
    --------------------------------------------------------------------
    awful.key({ modkey }, "Return", function () 
        awful.spawn(terminal)
    end, {description = "open a terminal", group = "launcher"}),
    --------------------------------------------------------------------
    awful.key({ altkey, "Control" }, "r", function () 
        awful.util.spawn("rofi -show run") 
    end, {description = "run prompt", group = "launcher"}),
    --------------------------------------------------------------------
    awful.key({ altkey, "Control" }, "p", function() 
        awful.util.spawn("rofi -show drun")
    end, {description = "show the menubar", group = "launcher"}),
    --------------------------------------------------------------------
    awful.key({ altkey, "Control" }, "g", function()
        awful.util.spawn("gpick")
    end, {description = "open color picker", group = "launcher"}),
    --------------------------------------------------------------------
    awful.key({ altkey, "Control" }, "o", function()
        awful.util.spawn("obs")
    end, {description = "open screen recorder", group = "launcher"}),
    --------------------------------------------------------------------
    awful.key({ altkey, "Control" }, "c", function()
        awful.util.spawn("qalculate-gtk")
    end, {description = "open calculator", group = "launcher"}),
    --------------------------------------------------------------------
    awful.key({ altkey, "Control" }, "s", function()
        awful.util.spawn("flameshot gui")
    end, {description = "take a screenshot", group = "launcher"}),
    --------------------------------------------------------------------

    -- LAYOUT --
    --------------------------------------------------------------------
    awful.key({ modkey, "Control" }, "Up", function () 
        awful.tag.incmwfact( 0.05) 
    end, {description = "increase master width factor", group = "layout"}),
    --------------------------------------------------------------------
    awful.key({ modkey, "Control" }, "Down", function ()
        awful.tag.incmwfact(-0.05) 
    end, {description = "decrease master width factor", group = "layout"}),
    --------------------------------------------------------------------
    
    --APPS
    --------------------------------------------------------------------
    -- Super + O → Obsidian
    awful.key({ modkey }, "o", function()
        awesome_spawn_or_toggle("obsidian", "Obsidian", true) 
    end, {description = "obsidian", group = "launcher"}),
    --------------------------------------------------------------------
    -- Super + M → Thunderbird
    awful.key({ modkey }, "m", function()
        awesome_spawn_or_toggle("thunderbird", "thunderbird", true)
    end, {description = "thunderbird", group = "launcher"}),
    --------------------------------------------------------------------
    -- Super + F → Thunar
    awful.key({ modkey }, "f", function()
        awesome_spawn_or_toggle("thunar", "Thunar", true)
    end, {description = "thunar", group = "launcher"}),
    --------------------------------------------------------------------
    -- Super + B → Librewolf
    awful.key({ modkey }, "b", function()
        local clients = {}
        for _, c in ipairs(client.get()) do
            if c.class == "librewolf" then
                table.insert(clients, c)
            end
        end
    
        if #clients == 0 then
            awful.spawn("librewolf")
            return
        end
    
        local current = client.focus
        local idx = 1
    
        if current then
            for i, c in ipairs(clients) do
                if c == current then
                    idx = (i % #clients) + 1
                    break
                end
            end
        end
    
        local next_client = clients[idx]
        if next_client and next_client.first_tag then
            next_client.first_tag:view_only()
            next_client:emit_signal("request::activate", "keybinding", {raise = true})
        end
    end, {description = "librewolf", group = "client"}),
    --------------------------------------------------------------------
    -- Super + T → Terminal dashboard
    awful.key({ modkey }, "t", function()
        for s in screen do
            local tag = s.tags[3]
            if tag then
                tag:view_only()
            end
        end
    end, {description = "terminal dashboard", group = "launcher"})    
)

clientkeys = gears.table.join(
    --CLIENT
    --------------------------------------------------------------------
    awful.key({ modkey, "Shift" }, "c", function (c) 
        c:kill()
    end, {description = "close", group = "client"}),
    --------------------------------------------------------------------
    awful.key({ modkey, "Control" }, "e", function (c)  
        c:move_to_screen()
    end, {description = "move to screen", group = "screen"}),
    --------------------------------------------------------------------
    awful.key({ modkey, "Shift" }, "f", function (c)
        c.fullscreen = not c.fullscreen
        c:raise()
    end, {description = "toggle fullscreen", group = "client"}),
    --------------------------------------------------------------------
    awful.key({ modkey, "Shift" }, "j", function(c)
        resize_and_center(c, 2100, 1331)
    end, {description = "Resize and center active window to 2100x1331", group = "client"}),
    --------------------------------------------------------------------
    awful.key({ modkey, "Shift" }, "k", function(c)
        resize_and_center(c, 1600, 900)
    end, {description = "Resize and center active window to 1600x900", group = "client"}),
    --------------------------------------------------------------------
    awful.key({ modkey, "Shift" }, "l", function(c)
        resize_and_center(c, 1280, 720)
    end, {description = "Resize and center active window to 1280x720", group = "client"}),
    --------------------------------------------------------------------
    awful.key({ modkey, "Shift" }, "m", function (c)
        c.maximized = not c.maximized
        c:raise()
    end, {description = "(un)maximize", group = "client"}),
    --------------------------------------------------------------------
    awful.key({ modkey, "Shift" }, "t", function (c)
        awful.titlebar.toggle(c)
    end, {description = "toggle titlebar", group = "client"}),
    --------------------------------------------------------------------
    awful.key({ modkey, "Shift" }, "space", 
        awful.client.floating.toggle,
    {description = "toggle floating", group = "client"}),
    --------------------------------------------------------------------
    awful.key({ modkey, "Shift" }, "Return", function (c) 
        c:swap(awful.client.getmaster()) 
    end, {description = "move to master", group = "client"})
    --------------------------------------------------------------------
)

-- Binding client buttons
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

-- Bind all key numbers to tags.
for i = 1, 9 do
    globalkeys = gears.table.join(globalkeys,
        -- View tag only.
        --------------------------------------------------------------------
        awful.key({ modkey }, "#" .. i + 9, function ()
        local screen = awful.screen.focused()
            local tag = screen.tags[i]
            if tag then
                tag:view_only()
            end
        end, {description = "view tag #"..i, group = "tag"}),
        --------------------------------------------------------------------
        -- Move client to tag.
        awful.key({ modkey, "Control" }, "#" .. i + 9, function ()
            if client.focus then
                local tag = client.focus.screen.tags[i]
                if tag then
                    client.focus:move_to_tag(tag)
                end
            end
        end, {description = "move focused client to tag #"..i, group = "tag"})
        --------------------------------------------------------------------
    )
end
-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
-- Rules to apply to new clients (through the "manage" signal).
awful.rules.rules = {
    -- All clients will match this rule.
    { 
        rule = { },
        properties = {
            border_width = beautiful.border_width,
            border_color = beautiful.border_normal,
            focus = awful.client.focus.filter,
            raise = true,
            keys = clientkeys,
            buttons = clientbuttons,
            screen = awful.screen.preferred,
            placement = awful.placement.centered + 
            --awful.placement.no_overlap + 
            awful.placement.no_offscreen
     }
    },
    -- Floating clients.
    {
        rule_any = {
             instance = {
            },
            class = {
                "kitty",
                "Arandr",
                "Blueman-manager",
                "Gpick",
                "pavucontrol",
                "Xarchiver",
                "Kvantum Manager",
                "Lxappearance",
                "Geeqie",
                "vlc",
                "Nm-connection-editor",
                "Nvidia-settings",
                "Transmission-gtk",
                "Webapp-manager.py",
                "Timeshift-gtk",
                "Qalculate-gtk",
                "TeamViewer",
                "Zathura",
                "zoom",
                "Gucharmap",
                "QDirStat",
                "scrcpy",
                "Thunar",
                "Blueman-services",
                "mpv",
                "VirtualBox"
            },
            name = {
                "Open With",
                "Settings"
            },
            role = {
                "Organizer",
                "PictureInPicture",
                "Popup",
                "browser"
            }
       }, properties = { floating = true }
    },

    -- Add titlebars to normal clients and dialogs
    {
        rule_any = {
            type = { "normal", "dialog" }
        }, properties = { titlebars_enabled = false }
    },

    -- Set applications positioning rules
    --------------------------------------------------------------------
    { 
        rule_any = {
            class = {
                "libreoffice-startcenter",
                "calibre",
                "Com.github.xournalpp.xournalpp"
            }
        },
        properties = {
            tag = " \u{F188}  ", -- 
            maximized = true,
            screen = function()
            return screen.count() end,
            switch_to_tags = true 
        } 
    },
    --------------------------------------------------------------------
    {
        rule_any = {
            class = 
            { 
                "kitty",
                "librewolf",
                "firefox",
                "Signal"
            },
        },
        properties = {
            floating = true,
        },
        callback = function(c)
            c.floating = true
            resize_and_center(c, 2100, 1331)
        end,
    },
    --------------------------------------------------------------------
    { 
        rule_any = {
            class = {
                "zoom",
                "TeamViewer"
            }
        },
        properties = {
            tag = " \u{EEF8}  ", --  
            screen = function()
                return screen.count() end,
            switch_to_tags = true
        }
    },
    --------------------------------------------------------------------
    {
        rule_any = {
            class = {
                "VirtualBox",
                "QGIS3",
                "scrcpy" 
            }
        },
        properties = {
            tag = " \u{F06D}  ", --  
            screen = 1,
            switch_to_tags = true
        }
    },
    --------------------------------------------------------------------
    --{
    --    rule = {
    --        class = "obs"
    --    },
    --    properties = {
    --        tag = " \u{F06D}  ", --  
    --        maximized = true,
    --        screen = function()
    --            return screen.count() end,
    --        switch_to_tags = true
    --    }
    --},
    --------------------------------------------------------------------
}
-- }}}

-- {{{ Signals
-- Set wallpaper
screen.connect_signal("property::geometry", set_wallpaper)

-- Bind the volume widget to mouse events
volume_widget:connect_signal("button::press", function(_, _, _, button)
    if button == 1 then -- left click
        awful.spawn("amixer -D pulse set Master toggle")
        update_volume_widget()
    elseif button == 2 then -- middle click
        awful.spawn("amixer -D pulse set Master toggle")
        update_volume_widget()
        elseif button == 3 then -- right click
            awful.spawn("env GTK_THEME=Kripton pavucontrol --tab=3 &")
            update_volume_widget()
            elseif button == 4 then -- scroll up
                awful.spawn("amixer -D pulse set Master 5%+")
                update_volume_widget()
                elseif button == 5 then -- scroll down
                    awful.spawn("amixer -D pulse set Master 5%-")
                    update_volume_widget()
                end
    
    update_volume_widget()
    update_volume_widget()
end)

-- Bind the microphone widget to mouse events
microphone_widget:connect_signal("button::press", function(_, _, _, button)
    if button == 1 then -- left click
        awful.spawn("amixer -D pulse set Capture toggle")
        update_microphone_widget()
        update_microphone_widget()
    elseif button == 3 then -- right click
        awful.spawn("env GTK_THEME=Kripton pavucontrol --tab=4 &")
    end
end)

-- Keyboard layout
mykeyboard:connect_signal("button::press",
    function(_, _, _, button)
        if button == 1 then keyboardlayout.next_layout() end
end)

-- Calendar toggle
mycalendar:connect_signal("button::press",
    function(_, _, _, button)
         if button == 1 then calendar.toggle() end
end)

-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c)
    if awesome.startup
        and not c.size_hints.user_position
        and not c.size_hints.program_position then
            awful.placement.no_offscreen(c)
            end
end)

-- Add a titlebar if titlebars_enabled is set to true in the rules.
client.connect_signal("request::titlebars", function(c)
    -- buttons for the titlebar
    local buttons = gears.table.join(
        awful.button({ }, 1, function()
            c:emit_signal("request::activate", 
            "titlebar", {raise = true})
            awful.mouse.client.move(c)
        end),
        awful.button({ }, 3, function()
            c:emit_signal("request::activate", 
            "titlebar", {raise = true})
            awful.mouse.client.resize(c)
        end)
    )

    awful.titlebar(c) : setup {
    { -- Left
        awful.titlebar.widget.iconwidget(c),
        buttons = buttons,
            layout  = wibox.layout.fixed.horizontal
        },
        { -- Middle
            { -- Title
                align  = "center",
                widget = awful.titlebar.widget.titlewidget(c)
            },
            buttons = buttons,
            layout  = wibox.layout.flex.horizontal
        },
        { -- Right
            awful.titlebar.widget.floatingbutton (c),
            awful.titlebar.widget.maximizedbutton(c),
            awful.titlebar.widget.closebutton    (c),
            layout = wibox.layout.fixed.horizontal()
        },
        layout = wibox.layout.align.horizontal
    }
end)

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
  if c.class == "librewolf" then
    awful.client.urgent.jumpto(true)
  end
end)
-- }}}

-- {{{ Run on startup
-- Update the microphone widget
update_microphone_widget()

-- Update the volume widget
update_volume_widget()

-- Run a custom script
awful.spawn.with_shell("~/dante/.bin/startup")
-- }}}
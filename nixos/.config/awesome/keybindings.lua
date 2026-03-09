local awful = require("awful")
local gears = require("gears")
local functions = require("functions")
local hotkeys_popup = require("awful.hotkeys_popup")
require("awful.hotkeys_popup.keys")

local M = {}

-- Load global variables
local globals = require("globals")
local terminal = globals.terminal
local modkey = globals.modkey
local altkey = globals.altkey

M.globalkeys = gears.table.join(

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
        local screen = awful.screen.focused()
        if screen.awesome_systray then
            screen.awesome_systray.visible = not screen.awesome_systray.visible
            local widgets = require("widgets")
            widgets.systray_toggle.text = screen.awesome_systray.visible and "\u{F0BAF} " or "\u{F02A0} "
        end
    end, {description = "toggle systray visibility", group = "system"}),
    --------------------------------------------------------------------
    awful.key({ modkey, "Control" }, "t", function ()
        local s = awful.screen.focused()
        s.mytasklist.visible = not s.mytasklist.visible
    end, {description = "toggle tasklist visibility", group = "system"}),
    --------------------------------------------------------------------
    awful.key({ modkey, "Control" }, "k", function()
        awful.util.spawn("setxkbmap es,us")
        local widgets = require("widgets")
        widgets.keyboardlayout.next_layout()
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
    awful.key({ modkey, "Control" }, "n", function()
        functions.add_tag()
    end, {description = "add a tag", group = "tag"}),
    --------------------------------------------------------------------
    awful.key({ modkey, "Control" }, "d", function()
        functions.delete_tag()
    end, {description = "delete the current tag", group = "tag"}),
    --------------------------------------------------------------------
    awful.key({ modkey, "Control" }, "m", function()
        functions.rename_tag()
    end, {description = "rename the current tag", group = "tag"}),
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
        functions.awesome_spawn_or_toggle("obsidian", "Obsidian", true)
    end, {description = "obsidian", group = "launcher"}),
    --------------------------------------------------------------------
    -- Super + M → Thunderbird
    awful.key({ modkey }, "m", function()
        functions.awesome_spawn_or_toggle("thunderbird", "thunderbird", true)
    end, {description = "thunderbird", group = "launcher"}),
    --------------------------------------------------------------------
    -- Super + F → Thunar
    awful.key({ modkey }, "f", function()
        functions.awesome_spawn_or_toggle("thunar", "Thunar", true)
    end, {description = "thunar", group = "launcher"}),
    --------------------------------------------------------------------
    -- Super + B → Librewolf
    awful.key({ modkey }, "b", function()
        local client = client
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

M.clientkeys = gears.table.join(
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
        functions.resize_and_center(c, 2100, 1331)
    end, {description = "Resize and center active window to 2100x1331", group = "client"}),
    --------------------------------------------------------------------
    awful.key({ modkey, "Shift" }, "k", function(c)
        functions.resize_and_center(c, 1600, 900)
    end, {description = "Resize and center active window to 1600x900", group = "client"}),
    --------------------------------------------------------------------
    awful.key({ modkey, "Shift" }, "l", function(c)
        functions.resize_and_center(c, 1280, 720)
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

M.clientbuttons = gears.table.join(
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
    M.globalkeys = gears.table.join(M.globalkeys,
        -- View tag only.
        awful.key({ modkey }, "#" .. i + 9, function ()
            local s = awful.screen.focused()
            local tag = s.tags[i]
            if tag then
                tag:view_only()
            end
        end, {description = "view tag #"..i, group = "tag"}),

        -- Move client to tag.
        awful.key({ modkey, "Control" }, "#" .. i + 9, function ()
            if client.focus then
                local tag = client.focus.screen.tags[i]
                if tag then
                    client.focus:move_to_tag(tag)
                end
            end
        end, {description = "move focused client to tag #"..i, group = "tag"})
    )
end

return M
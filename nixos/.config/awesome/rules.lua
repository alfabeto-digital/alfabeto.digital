local gears = require("gears")
local awful = require("awful")
local functions = require("functions")
local beautiful = require("beautiful")
local client = client

local M = {}
M.rules = {}

function M.init(keybindings, functions)
    M.rules = {
        -- All clients will match this rule.
        {
            rule = { },
            properties = {
                border_width = beautiful.border_width,
                border_color = beautiful.border_normal,
                focus = awful.client.focus.filter,
                raise = true,
                keys = keybindings.clientkeys,
                buttons = keybindings.clientbuttons,
                screen = awful.screen.preferred,
                placement = awful.placement.centered +
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
                    "Com.github.xournalpp",
                    "librewolf",
                    "firefox",
                    "Signal"
                }
            },
            properties = {
                callback = function(c)
                    --if c.class == "Zathura" then
                    --    local functions = require("functions")
                    --    functions.resize_and_center(c,1031, 1337)
                    --elseif c.class == "kitty"
                    --   or c.class == "librewolf"
                    --   or c.class == "firefox" 
                    --   or c.class == "Signal" then
                    --    local functions = require("functions")
                    --    functions.resize_and_center(c, 2100, 1331)
                    --end
                    --c.shape = function(cr,w,h)
                    --    gears.shape.rounded_rect(cr,w,h,15)
                    --end
                end
            }
        }
    }
end

-- Client signal for geometry
client.connect_signal("manage", function (c)
    c.shape = function(cr,w,h)
        gears.shape.rounded_rect(cr,w,h,15)
    end
    if c.class == "Zathura" then
        functions.resize_and_center(c,1031, 1337)
    end
    if c.class == "kitty"
       or c.class == "librewolf"
       or c.class == "firefox"
       or c.class == "Signal" then
        functions.resize_and_center(c, 2100, 1331)
    end
end)

return M
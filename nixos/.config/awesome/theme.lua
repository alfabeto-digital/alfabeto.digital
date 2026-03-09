local theme_assets = require("beautiful.theme_assets")
local xresources = require("beautiful.xresources")
local dpi = xresources.apply_dpi

-- {{{ Main
local theme = {}
theme.wallpaper = "~/.config/awesome/background_awesomewm.png"
-- }}}

-- {{{ Fonts
theme.font          = "ShureTechMono Nerd Font 14"
theme.taglist_font  = "ShureTechMono Nerd Font 14"
-- }}}

-- {{{ Colors
theme.bg_normal     = "#282828"
theme.bg_focus      = "#1E2320"
theme.bg_urgent     = "#282828"
theme.bg_systray    = theme.bg_normal
theme.fg_normal     = "#DCDCCC"
theme.fg_focus      = "#F0DFAF"
theme.fg_urgent     = "#CC9393"
-- }}}

-- {{{ Borders
theme.useless_gap   = dpi(3)
theme.border_width  = dpi(2)
theme.border_normal = "#282828"
theme.border_focus  = "#FE8019"
theme.border_marked = "#CC9393"
-- }}}

-- {{{ Titlebars
theme.titlebar_bg_focus  = "#282828"
theme.titlebar_bg_normal = "#282828"
-- }}}

-- {{{ Mouse Finder
theme.mouse_finder_color = "#CC9393"
-- }}}

-- {{{ Menu
theme.menu_height = dpi(25)
theme.menu_width  = dpi(150)
-- }}}

-- {{{ Icons taglist
theme.taglist_squares_sel   = "~/.config/awesome/taglist/squarefz.png"
theme.taglist_squares_unsel = "~/.config/awesome/taglist/squarez.png"
-- }}}

theme.tasklist_disable_task_name = true

-- {{{ Titlebar
theme.titlebar_close_button_normal              =   "~/.config/awesome/titlebar/close_normal.png"
theme.titlebar_close_button_focus               =   "~/.config/awesome/titlebar/close_focus.png"
theme.titlebar_floating_button_normal_inactive  =   "~/.config/awesome/titlebar/floating_normal_inactive.png"
theme.titlebar_floating_button_focus_inactive   =   "~/.config/awesome/titlebar/floating_focus_inactive.png"
theme.titlebar_floating_button_normal_active    =   "~/.config/awesome/titlebar/floating_normal_active.png"
theme.titlebar_floating_button_focus_active     =   "~/.config/awesome/titlebar/floating_focus_active.png"
theme.titlebar_maximized_button_normal_inactive =   "~/.config/awesome/titlebar/maximized_normal_inactive.png"
theme.titlebar_maximized_button_focus_inactive  =   "~/.config/awesome/titlebar/maximized_focus_inactive.png"
theme.titlebar_maximized_button_normal_active   =   "~/.config/awesome/titlebar/maximized_normal_active.png"
theme.titlebar_maximized_button_focus_active    =   "~/.config/awesome/titlebar/maximized_focus_active.png"
-- }}}

-- {{{ Layout
theme.layout_tile       =   "~/.config/awesome/layouts/tile.png"
-- }}}

-- Define the icon theme for application icons. If not set then the icons
-- from /usr/share/icons and /usr/share/icons/hicolor will be used.
theme.icon_theme = "/usr/share/icons/Gruvbox-Plus-Dark"

return theme

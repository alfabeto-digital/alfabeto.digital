local awful = require("awful")
local beautiful = require("beautiful")
local wibox = require("wibox")
local gears = require("gears")
local naughty = require("naughty")

local calendar_widget = {}

local function worker(user_args)

	local calendar_themes = {
        	nencatacoa = {
            		bg = '#282828',
            		fg = '#C6CEBE',
            		focus_date_bg = '#FE8019',
            		focus_date_fg = '#000000',
            		weekend_day_bg = '#1E2320',
            		weekday_fg = '#FE8019',
            		header_fg = '#FE8019',
            		border = '#FE8019'
        	}
    	}

    	local args = user_args or {}

    	local theme = args.theme or 'nencatacoa'
    	local placement = args.placement or 'top_right'
    	local radius = args.radius or 15
    	local next_month_button = args.next_month_button or 5
   	local previous_month_button = args.previous_month_button or 4
    	local start_sunday = args.start_sunday or true

    	local styles = {}
    	local function rounded_shape(size)
        	return function(cr, width, height)
            		gears.shape.rounded_rect(cr, width, height, size)
        	end
    	end

    	styles.month = {
        	padding = 10,
        	bg_color = calendar_themes[theme].bg,
        	border_width = 10,
    	}

    	styles.normal = {
        	markup = function(t) return t end,
        	shape = rounded_shape(20)
    	}

    	styles.focus = {
        	fg_color = calendar_themes[theme].focus_date_fg,
        	bg_color = calendar_themes[theme].focus_date_bg,
        	markup = function(t) return '<b>' .. t .. '</b>' end,
        	shape = rounded_shape(20)
    	}

    	styles.header = {
        	fg_color = calendar_themes[theme].header_fg,
        	bg_color = calendar_themes[theme].bg,
        	markup = function(t) return '<b>' .. t .. '</b>' end
    	}

    	styles.weekday = {
        	fg_color = calendar_themes[theme].weekday_fg,
        	bg_color = calendar_themes[theme].bg,
        	markup = function(t) return t end,
    	}

    	local function decorate_cell(widget, flag, date)
        	if flag == 'monthheader' and not styles.monthheader then
            		flag = 'header'
        	end

        	-- highlight only today's day
        	if flag == 'focus' then
            		local today = os.date('*t')
            		if not (today.month == date.month and today.year == date.year) then
                	flag = 'normal'
            	end
        end

        local props = styles[flag] or {}
        	if props.markup and widget.get_text and widget.set_markup then
        		widget:set_markup(props.markup(widget:get_text()))
        end
        -- Change bg color for weekends
        local d = { year = date.year, month = (date.month or 1), day = (date.day or 1) }
        local weekday = tonumber(os.date('%w', os.time(d)))
        local default_bg = (weekday == 0 or weekday == 6)
        	and calendar_themes[theme].weekend_day_bg
            	or calendar_themes[theme].bg
        
	local ret = wibox.widget {
        	{
                	{
                    		widget,
                    		halign = 'center',
                    		widget = wibox.container.place
                	},
                	margins = (props.padding or 2) + (props.border_width or 0),
                	widget = wibox.container.margin
            	},
            	shape = props.shape,
            	shape_border_color = props.border_color or '#000000',
            	shape_border_width = props.border_width or 0,
            	fg = props.fg_color or calendar_themes[theme].fg,
            	bg = props.bg_color or default_bg,
            	widget = wibox.container.background
        }

        return ret
end

local cal = wibox.widget {
	date = os.date('*t'),
        font = beautiful.get_font(),
        fn_embed = decorate_cell,
        long_weekdays = true,
        start_sunday = start_sunday,
        widget = wibox.widget.calendar.month
}

local popup = awful.popup {
        ontop = true,
        visible = false,
        shape = rounded_shape(radius),
        offset = { y = 5 },
        border_width = 3,
        border_color = calendar_themes[theme].border,
        widget = cal,
	opacity = 0.9
}

popup:buttons(
	awful.util.table.join(
        	awful.button({}, next_month_button, function()
                	local a = cal:get_date()
                        a.month = a.month + 1
                        cal:set_date(nil)
                        cal:set_date(a)
                        popup:set_widget(cal)
                end),
                awful.button({}, previous_month_button, function()
                        local a = cal:get_date()
                        a.month = a.month - 1
                        cal:set_date(nil)
                        cal:set_date(a)
                        popup:set_widget(cal)
                end)
	)
)

function calendar_widget.toggle()
    if popup.visible then
        -- Ocultar el calendario
        popup.visible = false
    else
        -- Actualizar la fecha al día actual
        cal:set_date(nil)  -- Limpiar la fecha actual
        cal:set_date(os.date('*t'))  -- Establecer la fecha al día actual

        -- Posicionar y mostrar el calendario
        awful.placement.top_right(popup, { margins = { top = 75, right = 10 }, parent = awful.screen.focused() })
        popup.visible = true
    end
end

--function calendar_widget.toggle()
--	if popup.visible then
--            	cal:set_date(nil) 
--            	cal:set_date(os.date('*t'))
--            	popup:set_widget(nil) 
--            	popup:set_widget(cal)
--            	popup.visible = not popup.visible
--        else
--		awful.placement.top_right(popup, { margins = { top = 75, right = 10}, parent = awful.screen.focused() })
--
--            	popup.visible = true
--        end
--end

return calendar_widget

end

return setmetatable(calendar_widget, { __call = function(_, ...)
    return worker(...)
end })

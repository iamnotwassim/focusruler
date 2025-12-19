local _ = require("gettext")
local Menu = {}
local UIManager = require("ui/uimanager")
local SpinWidget = require("ui/widget/spinwidget")

function Menu:new(args)
    local o = {}
    setmetatable(o, self)
    self.__index = self

    o.settings = args.settings
    o.ruler = args.ruler
    o.ruler_ui = args.ruler_ui
    o.ui = args.ui

    return o
end

-- Add main entry for Focus Ruler in KOReader's menu
function Menu:addToMainMenu(menu_items)
    menu_items.focus_ruler = {
        text = _("Focus Ruler"),
        sub_item_table = {
            {
                text = _("Toggle focus ruler"),
                keep_menu_open = true,
                checked_func = function()
                    return self.settings:isEnabled()
                end,
                callback = function()
                    self.ruler_ui:toggleEnabled()
                end,
            },
            {
                text = _("Visible lines"),
                keep_menu_open = true,
                callback = function()
                    self:showFocusWindowLinesDialog()
                end,
            },
            {
                text = _("Navigation mode"),
                keep_menu_open = true,
                sub_item_table = {
                    {
                        text = _("Tap to move"),
                        checked_func = function()
                            return self.settings:get("navigation_mode") == "tap"
                        end,
                        callback = function()
                            self.settings:set("navigation_mode", "tap")
                            self.ruler_ui:displayNotification(_("Tap to move"))
                        end,
                    },
                    {
                        text = _("Swipe to move"),
                        checked_func = function()
                            return self.settings:get("navigation_mode") == "swipe"
                        end,
                        callback = function()
                            self.settings:set("navigation_mode", "swipe")
                            self.ruler_ui:displayNotification(_("Swipe to move"))
                        end,
                    },
                    {
                        text = _("None (bring-your-own gesture)"),
                        checked_func = function()
                            return self.settings:get("navigation_mode") == "none"
                        end,
                        callback = function()
                            self.settings:set("navigation_mode", "none")
                            self.ruler_ui:displayNotification(_("Navigation disabled"))
                        end,
                    },
                },
            },
            {
                text = _("Notifications"),
                checked_func = function()
                    return self.settings:get("notification")
                end,
                callback = function()
                    self.settings:toggle("notification")
                end,
            },
        },
    }
end

function Menu:showFocusWindowLinesDialog()
    local spin_widget = SpinWidget:new({
        value = self.settings:get("focus_window_lines") or 1,
        value_min = 1,
        value_max = 10,
        value_step = 1,
        value_hold_step = 1,
        title_text = _("Visible lines"),
        ok_text = _("Set"),
        callback = function(new_lines)
            self.settings:set("focus_window_lines", new_lines.value)

            if self.settings:isEnabled() then
                self.ruler_ui:buildUI()
                self.ruler_ui:updateUI()
            end
        end,
    })

    UIManager:show(spin_widget)
end

return Menu

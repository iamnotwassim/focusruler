local _ = require("gettext")
local Device = require("device")
local Screen = require("device").screen
local Geom = require("ui/geometry")
local GestureRange = require("ui/gesturerange")
local InputContainer = require("ui/widget/container/inputcontainer")
local logger = require("logger")

local Settings = require("lib2/settings")
local Ruler = require("lib2/ruler")
local RulerUI = require("lib2/ui/ruler_ui")
local Menu = require("lib2/ui/menu")
local Dispatcher = require("dispatcher")

local FocusRuler = InputContainer:extend({
    name = "focusruler",
    is_doc_only = true,
})

function FocusRuler:init()
    logger.info("FocusRuler: init() called")

    -- Initialize components --
    self.settings = Settings:new()

    self.ruler = Ruler:new({
        settings = self.settings,
        ui = self.ui,
        view = self.view,
        document = self.document,
    })

    self.ruler_ui = RulerUI:new({
        settings = self.settings,
        ruler = self.ruler,
        ui = self.ui,
        document = self.document,
    })

    self.menu = Menu:new({
        settings = self.settings,
        ruler = self.ruler,
        ruler_ui = self.ruler_ui,
        ui = self.ui,
    })

    --- Register to main menu so that `addToMainMenu` is called
    self.ui.menu:registerToMainMenu(self.menu)

    -- Register to UIManager
    self.view:registerViewModule("focus_ruler", self)

    -- Register gesture events so we can handle them
    self:registerGestures()

    -- Register actions (custom gesture by user)
    self:registerActions()

    -- Initialize UI if enabled
    if self.settings:isEnabled() then
        -- NOTE: only build the UI here, positioning is set in onPageUpdate
        self.ruler_ui:buildUI()
    end
end

-- Register gestures, define the zones that we want to listen to
function FocusRuler:registerGestures()
    local screen = Screen:getSize()
    local offset_ratio = 0.125
    local offset_ratio_end = 1 - offset_ratio * 2

    -- Set up gesture ranges for different parts of the screen
    if Device:isTouchDevice() then
        local range = Geom:new({
            x = offset_ratio * screen.w,
            y = offset_ratio * screen.h,
            w = offset_ratio_end * Screen:getWidth(),
            h = offset_ratio_end * Screen:getHeight(),
        })

        self.ges_events = {
            Tap = {
                GestureRange:new({
                    ges = "tap",
                    range = range,
                }),
            },
            Swipe = {
                GestureRange:new({
                    ges = "swipe",
                    range = range,
                }),
            },
        }
    end
end

-- Register actions so that user can bind them to gestures
function FocusRuler:registerActions()
    Dispatcher:registerAction("focus_ruler_move_to_next_line", {
        category = "none",
        event = "FocusRulerMoveToNextLine",
        title = _("Focus Ruler: Move to next line"),
        general = true,
    })

    Dispatcher:registerAction("focus_ruler_move_to_previous_line", {
        category = "none",
        event = "FocusRulerMoveToPreviousLine",
        title = _("Focus Ruler: Move to previous line"),
        general = true,
    })

    -- Register state management actions
    Dispatcher:registerAction("focus_ruler_set_state", {
        category = "string",
        event = "FocusRulerSetState",
        title = _("Focus Ruler"),
        general = true,
        args = { true, false },
        toggle = { _("enable"), _("disable") },
    })

    Dispatcher:registerAction("focus_ruler_toggle", {
        category = "none",
        event = "FocusRulerToggle",
        title = _("Focus Ruler: toggle"),
        general = true,
    })
end

function FocusRuler:addToMainMenu(menu_items)
    self.menu:addToMainMenu(menu_items)
end

function FocusRuler:paintTo(bb, x, y)
    self.ruler_ui:paintTo(bb, x, y)
end

-- Document Events --
function FocusRuler:onPageUpdate(new_page)
    return self.ruler_ui:onPageUpdate(new_page)
end

-- Gesture Events --
function FocusRuler:onSwipe(arg, ges)
    return self.ruler_ui:onSwipe(arg, ges)
end

function FocusRuler:onTap(arg, ges)
    return self.ruler_ui:onTap(arg, ges)
end

-- Custom Events (Actions) --
function FocusRuler:onFocusRulerMoveToNextLine()
    self.ruler_ui:handleLineNavigation("next")
end

function FocusRuler:onFocusRulerMoveToPreviousLine()
    self.ruler_ui:handleLineNavigation("prev")
end

function FocusRuler:onFocusRulerSetState(state)
    self.ruler_ui:setEnabled(state)
end

function FocusRuler:onFocusRulerToggle()
    local state = not self.settings:get("enabled")
    self.ruler_ui:setEnabled(state)
end

return FocusRuler

local _ = require("gettext")
local Blitbuffer = require("ffi/blitbuffer")
local Device = require("device")
local Event = require("ui/event")
local Font = require("ui/font")
local FrameContainer = require("ui/widget/container/framecontainer")
local Geom = require("ui/geometry")
local LineWidget = require("ui/widget/linewidget")
local MovableContainer = require("ui/widget/container/movablecontainer")
local Notification = require("ui/widget/notification")
local Screen = Device.screen
local UIManager = require("ui/uimanager")
local WidgetContainer = require("ui/widget/container/widgetcontainer")
local Widget = require("ui/widget/widget")
local logger = require("logger")

local ignore_events = {
    "hold",
    "hold_release",
    "hold_pan",
    "swipe",
    "touch",
    "pan",
    "pan_release",
}

-- Simple overlay widget for covering text
local CoverOverlay = Widget:extend{
    width = nil,
    height = nil,
}

function CoverOverlay:getSize()
    return Geom:new{ w = self.width, h = self.height }
end

function CoverOverlay:paintTo(bb, x, y)
    if self.height > 0 then
        bb:paintRect(x, y, self.width, self.height, Blitbuffer.COLOR_WHITE)
    end
end

---@class RulerUI
local RulerUI = WidgetContainer:new()

function RulerUI:new(args)
    local o = WidgetContainer:new(args)
    setmetatable(o, self)
    self.__index = self

    o.ruler = args.ruler
    o.settings = args.settings
    o.ui = args.ui
    o.document = args.document

    o:init()

    return o
end

function RulerUI:init()
    self.ruler_widget = nil
    self.touch_container_widget = nil
    self.movable_widget = nil
    self.top_overlay = nil
    self.bottom_overlay = nil
    self.focus_geom = nil
    self.is_built = false
end

-- Check if there's an active highlight/selection
function RulerUI:isHighlightActive()
    -- Method 1: Check if any widget is dominating the screen
    if UIManager.isDominated then
        local ok, dominated = pcall(function() return UIManager:isDominated() end)
        if ok and dominated then
            logger.info("FocusRuler: Screen dominated by widget")
            return true
        end
    end
    
    -- Method 2: Check the highlight module state
    if self.ui.highlight then
        if self.ui.highlight.selected_text and self.ui.highlight.selected_text.text then
            logger.info("FocusRuler: selected_text exists")
            return true
        end
    end
    
    -- Method 3: Check if ButtonDialog or similar is in the widget stack
    if UIManager.getTopWidget then
        local ok, top = pcall(function() return UIManager:getTopWidget() end)
        if ok and top then
            local widget_name = top.name or (top.widget and top.widget.name) or ""
            logger.info("FocusRuler: Top widget:", widget_name)
            if widget_name == "ButtonDialog" or widget_name == "highlight" then
                return true
            end
        end
    end
    
    return false
end

function RulerUI:buildUI()
    self:buildFocusWindowUI()
end

function RulerUI:buildFocusWindowUI()
    local screen_width = Screen:getWidth()
    local screen_height = Screen:getHeight()
    
    self.top_overlay = CoverOverlay:new{
        width = screen_width,
        height = 0,
    }
    
    self.bottom_overlay = CoverOverlay:new{
        width = screen_width,
        height = 0,
    }
    
    self.ruler_widget = LineWidget:new({
        background = Blitbuffer.COLOR_WHITE,
        dimen = Geom:new({ w = screen_width, h = 2 }),
    })
    
    local padding_y = 0.01 * screen_height
    self.touch_container_widget = FrameContainer:new({
        bordersize = 0,
        padding = 0,
        padding_top = padding_y,
        padding_bottom = padding_y,
        self.ruler_widget,
    })

    self.movable_widget = MovableContainer:new({
        ignore_events = ignore_events,
        self.touch_container_widget,
    })
end

function RulerUI:updateUI()
    self:updateFocusWindowUI()
end

function RulerUI:updateFocusWindowUI()
    local focus_geom = self.ruler:getFocusWindowGeometry()
    local screen_height = Screen:getHeight()
    
    if focus_geom and self.top_overlay and self.bottom_overlay then
        self.top_overlay.height = math.max(0, focus_geom.y)
        self.bottom_overlay.height = math.max(0, screen_height - (focus_geom.y + focus_geom.h))
        self.focus_geom = focus_geom
        
        local trans_y = focus_geom.y + focus_geom.h - self.touch_container_widget.padding_top
        self.movable_widget:setMovedOffset({ x = 0, y = trans_y })
    end
    
    self:repaint()
end

function RulerUI:repaint()
    UIManager:setDirty("all", "ui")
end

function RulerUI:paintTo(bb, x, y)
    if not self.settings:isEnabled() then
        return
    end
    
    -- Don't paint overlays if highlight is active
    if self:isHighlightActive() then
        return
    end

    if self.top_overlay and self.top_overlay.height > 0 then
        self.top_overlay:paintTo(bb, x, y)
    end
    
    if self.bottom_overlay and self.focus_geom then
        local bottom_y = self.focus_geom.y + self.focus_geom.h
        self.bottom_overlay:paintTo(bb, x, bottom_y)
    end
end

function RulerUI:onPageUpdate(new_page)
    if not self.settings:isEnabled() then
        return
    end

    self.ruler:setInitialPositionOnPage(new_page)
    self:updateUI()
end

function RulerUI:handleLineNavigation(direction)
    if direction == "next" then
        if self.ruler:moveToNextLine() then
            self:updateUI()
            return true
        end
        self.ui:handleEvent(Event:new("GotoViewRel", 1))
        return true
    elseif direction == "prev" then
        if self.ruler:moveToPreviousLine() then
            self:updateUI()
            return true
        end
        self.ui:handleEvent(Event:new("GotoViewRel", -1))
        return true
    end
    return false
end

function RulerUI:setEnabled(enabled)
    if enabled then
        self.settings:enable()
        self:buildUI()
        self.ruler:setInitialPositionOnPage(self.document:getCurrentPage())
        self:updateUI()
        self:displayNotification(_("Focus ruler enabled"))
    else
        self.settings:disable()
        self:repaint()
        self:displayNotification(_("Focus ruler disabled"))
    end
end

function RulerUI:toggleEnabled()
    self:setEnabled(not self.settings:isEnabled())
end

function RulerUI:onTap(_, ges)
    if not self.settings:isEnabled() then
        return false
    end

    if self:isHighlightActive() then
        return false
    end
    
    local is_tap_to_move = self.ruler:isTapToMoveMode()
    
    if self.focus_geom then
        local tap_in_focus = ges.pos.y >= self.focus_geom.y and 
                            ges.pos.y <= (self.focus_geom.y + self.focus_geom.h)
        if tap_in_focus and not is_tap_to_move then
            return false
        end
    end

    if is_tap_to_move then
        self.ruler:moveToNearestLine(ges.pos.y)
        self.ruler:exitTapToMoveMode()
        self:updateUI()
        return true
    end

    if self.settings:get("navigation_mode") == "tap" then
        return self:handleLineNavigation("next")
    end

    return false
end

function RulerUI:onSwipe(_, ges)
    if not self.settings:isEnabled() then
        return false
    end

    local navigation_mode = self.settings:get("navigation_mode")

    if navigation_mode == "swipe" or navigation_mode == "tap" then
        if ges.direction == "north" then
            return self:handleLineNavigation("prev")
        end

        if navigation_mode == "swipe" and ges.direction == "south" then
            return self:handleLineNavigation("next")
        end
    end

    return false
end

function RulerUI:displayNotification(text)
    if not self.settings:get("notification") then
        return
    end

    UIManager:show(Notification:new({
        text = text,
        timeout = 2,
    }))
end

return RulerUI
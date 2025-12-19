local Device = require("device")
local logger = require("logger")

local Ruler = {}

function Ruler:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

    -- Dependencies
    o.settings = o.settings
    o.ui = o.ui
    o.view = o.view
    o.document = o.document

    -- State
    o.current_line_y = nil
    o.current_line_x = nil
    o.screen_height = Device.screen:getHeight()
    o.screen_width = Device.screen:getWidth()
    o.cached_texts = nil
    o.cached_texts_page = nil
    o.last_page = 0
    o.tap_to_move = false

    return o
end

function Ruler:setInitialPositionOnPage(new_page)
    local texts = self:getTexts()
    if #texts.sboxes < 1 then
        logger.error("No text boxes found on page " .. new_page)
        return
    end

    -- page change direction.
    local direction = new_page >= self.last_page and "next" or "prev"

    -- check if the page jump is more than 1 page.
    local is_jump = math.abs(new_page - self.last_page) > 1

    -- start at first line, if move to previous page, set to last line.
    -- if jump, set to first line.
    local line = 1
    if not is_jump and direction == "prev" then
        line = #texts.sboxes
    end

    self:move(0, texts.sboxes[line].y + texts.sboxes[line].h)
    self.last_page = new_page
end

function Ruler:moveToNextLine()
    local positions = self:getNearestTextPositions()
    if positions.next then
        self:move(0, positions.next.y + positions.next.h)
        return true
    end

    return false
end

function Ruler:moveToPreviousLine()
    local positions = self:getNearestTextPositions()
    if positions.prev then
        self:move(0, positions.prev.y + positions.prev.h)
        return true
    end

    return false
end

function Ruler:moveToNearestLine(y)
    local positions = self:getNearestTextPositions(y)
    if positions.curr then
        self:move(0, positions.curr.y + positions.curr.h)
        return true
    end
    return false
end

function Ruler:move(x, y)
    self.current_line_y = y
    self.current_line_x = x
end

--- Get nearest text boxes from a given `y`, if `y` is nil, use the current line position.
--- This function is used to find the nearest text boxes above and below the current line.
---@param y? number
---@return table
function Ruler:getNearestTextPositions(y)
    if y == nil then
        y = self.current_line_y
    end

    local texts = self:getTexts()

    local nearest_idx, nearest_sbox = nil, nil
    local min_distance = math.huge

    for i, sbox in ipairs(texts.sboxes) do
        local distance = math.abs(sbox.y + sbox.h - y)
        if distance < min_distance then
            min_distance = distance
            nearest_idx = i
            nearest_sbox = sbox
        end
    end

    local prev = nearest_idx and texts.sboxes[nearest_idx - 1] or nil
    local next = nearest_idx and texts.sboxes[nearest_idx + 1] or nil

    return { prev = prev, curr = nearest_sbox, next = next }
end

-- Get the textboxes (dimen) of texts on the current page
---@param ignore_cache? boolean
---@return table
function Ruler:getTexts(ignore_cache)
    local page = self.document:getCurrentPage()

    if not ignore_cache and self.cached_texts and self.cached_texts_page == page then
        return self.cached_texts
    end

    local texts = self.ui.document:getTextFromPositions(
        { x = 0, y = 0, page = page },
        { x = self.screen_width, y = self.screen_height },
        true
    )

    self.cached_texts = texts
    self.cached_texts_page = page

    return texts and texts or { sboxes = {} }
end

-- Get geometry for focus window mode (returns the clear/visible area)
function Ruler:getFocusWindowGeometry()
    local num_lines = self.settings:get("focus_window_lines") or 1
    local positions = self:getNearestTextPositions()
    
    if not positions.curr then
        return nil
    end
    
    -- Start with current line
    local top_y = positions.curr.y
    local bottom_y = positions.curr.y + positions.curr.h
    local line_height = positions.curr.h
    
    -- If we want multiple lines, expand the window
    if num_lines > 1 then
        local texts = self:getTexts()
        local curr_idx = nil
        
        -- Find current line index
        for i, sbox in ipairs(texts.sboxes) do
            if sbox.y == positions.curr.y then
                curr_idx = i
                break
            end
        end
        
        if curr_idx then
            -- Add lines below (for lines > 1)
            local lines_to_add = num_lines - 1
            for i = 1, lines_to_add do
                local next_line = texts.sboxes[curr_idx + i]
                if next_line then
                    bottom_y = next_line.y + next_line.h
                end
            end
        end
    end
    
    -- Add a little padding around the focus area
    local padding = line_height * 0.2
    
    return {
        x = 0,
        y = top_y - padding,
        w = self.screen_width,
        h = (bottom_y - top_y) + (padding * 2),
        line_height = line_height,
    }
end

-- Tap to move mode handling --
function Ruler:isTapToMoveMode()
    return self.tap_to_move
end

function Ruler:enterTapToMoveMode()
    self.tap_to_move = true
end

function Ruler:exitTapToMoveMode()
    self.tap_to_move = false
end

return Ruler

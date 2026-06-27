local validator = require("lib.validator")

local container = {
    layouts = {
        horizontal_rows = "horizontal_rows",
        vertical_columns = "vertical_columns",
        vertical_flow = "vertical_flow",
        manual = "manual"
    }
}
container.__index = container

local function render_vertical_flow(self, container_x, container_y, data)
    local x = container_x + self.padding.left
    local y = container_y + self.padding.top

    for _, key in ipairs(self.render_order) do
        local child = self.children[key]

        if not child then
            error("An error occured, can't find the element with key: " .. key)
        end

        local element = child.element

        local element_x, element_y
        if child.offset then
            element_x = x + (child.offset.x_offset or 0)
            element_y = y + (child.offset.y_offset or 0)
        else
            element_x = x
            element_y = y
        end

        element:render(element_x, element_y, data)

        y = element_y + element.size.height
    end
end

local function render_horizontal_rows(self, container_x, container_y, data)
    local x = container_x + self.padding.left
    local y = container_y + self.padding.top

    local row_height = 0
    for _, key in ipairs(self.render_order) do
        local child = self.children[key]

        if not child then
            error("An error occured, can't find the element with key: " .. key)
        end

        local element = child.element

        -- If it doesn't fit horizontally, wrap to new row.
        if x + element.size.width > self.size.width + container_x then
            x = container_x + self.padding.left
            y = y + row_height + self.spacing
            row_height = 0
        end

        if y + element.size.height > self.size.height then
            break
        end

        element:render(x, y, data)

        -- Move x including spacing between elements.
        x = x + element.size.width + self.spacing

        -- Determine largest height, adjust row height to it.
        row_height = math.max(row_height, element.size.height)
    end
end

local function render_vertical_columns(self, container_x, container_y, data)
    local x = container_x + self.padding.left
    local y = container_y + self.padding.top

    local column_width = 0
    for _, key in ipairs(self.render_order) do
        local child = self.children[key]

        if not child then
            error("An error occured, can't find the element with key: " .. key)
        end

        local element = child.element

        -- If it doesn't fit vertically, wrap to next column.
        if y + element.size.height > self.size.height + container_y then
            y = container_y + self.padding.top
            x = x + column_width + self.spacing
            column_width = 0
        end

        if x + element.size.width > self.size.width then
            break
        end

        element:render(x, y, data)

        -- Move y including spacing between elements.
        y = y + element.size.height + self.spacing

        -- Determine widest element so far in this column.
        column_width = math.max(column_width, element.size.width)
    end
end

local function render_elements_manually(self, container_x, container_y, data)
    for _, key in ipairs(self.render_order) do
        local child = self.children[key]

        local element_x = container_x + child.offset.x_offset
        local element_y = container_y + child.offset.y_offset

        if child.offset.respect_padding then
            element_x = element_x + self.padding.left
            element_y = element_y + self.padding.top
        end

        child.element:render(element_x, element_y, data)
    end
end

function container:new(m, layout, size, padding)
    validator.validate_parameter(layout, "string", true, "layout")
    validator.validate_parameter(size, "table", true, "size")
    validator.validate_parameter(padding, "table", false, "padding")

    local padding_sides = { "top", "right", "bottom", "left" }

    -- Normalize missing padding fields
    local corrected_padding = {}
    for _, side in ipairs(padding_sides) do
        corrected_padding[side] = padding and padding[side] or 0
    end

    if not layout or not self.layouts[layout] then
        error("Invalid layout: " .. (layout or "nil"))
    end

    return setmetatable({
        m = m,
        layout = layout,
        size = size,
        padding = corrected_padding,
        spacing = 1,
        children = {},
        render_order = {}
    }, self)
end

function container:add_element(id, element, position_offset)
    -- TODO: More element validation, does it fit? Does it contain the correct fields?
    if type(element) ~= "table" or not element.render then
        error("Invalid element, can't render this.")
    end

    if self.children[id] then
        error(("Element with id %d already exists."):format(id))
    end

    local offset
    if position_offset then
        offset = {
            x_offset = (position_offset.x_offset or 0),
            y_offset = (position_offset.y_offset or 0),
            respect_padding = position_offset.respect_padding
        }
    else
        offset = {
            x_offset = 0,
            y_offset = 0,
            respect_padding = false
        }
    end

    local entry = {
        element = element,
        offset = offset
    }

    self.children[id] = entry
    table.insert(self.render_order, id)

    return true
end

function container:add_background(background)
    self.background = background
end

function container:element_exists(id)
    return self.children[id] ~= nil
end

function container:update_element(id, element_field, value)
    local entry = self.children[id]
    if type(entry) ~= "table" then
        error("Can't update an entry that doesn't exist: " .. tostring(id))
    end
    if type(entry.element) ~= "table" then
        error("Invalid element in entry: " .. tostring(id))
    end
    if element_field == nil then
        error("element_field must not be nil")
    end

    entry.element[element_field] = value
end

function container:remove_element(id)
    local entry = self.children[id]

    if not entry then
        return
    end

    self.children[id] = nil

    for i, k in ipairs(self.render_order) do
        if k == id then
            table.remove(self.render_order, i)
            break
        end
    end
end

function container:calculate_row_capacity(element_width, element_height)
    local usable_width = self.size.width - (self.padding.left + self.padding.right)
    local usable_height = self.size.height - (self.padding.top + self.padding.bottom)

    local columns = math.floor(usable_width / (element_width + self.spacing))
    local rows = math.floor(usable_height / (element_height + self.spacing))

    return rows * columns
end

function container:handle_click(x, y)
    local is_in_x = x >= self.latest_x and x < (self.latest_x + self.size.width)
    local is_in_y = y >= self.latest_y and y < (self.latest_y + self.size.height)

    if not is_in_x or not is_in_y then
        return false
    end

    local clicked = false
    for _, entry in pairs(self.children) do
        local child = entry.element

        if child.handle_click then
            clicked = child:handle_click(x, y)
        end

        if clicked then
            break
        end
    end

    return clicked
end

--- Renders the elements registered in the container, following the layout's structure.
--- Won't render any elements if they're off screen. Paging has to be done by the parent.
function container:render(x, y, data)
    self.latest_x = x
    self.latest_y = y

    if self.background then
        local background_x, background_y
        if self.background.respect_padding then
            background_x = x + self.padding.left
            background_y = y + self.padding.top
        else
            background_x = x
            background_y = y
        end

        self.background:render(background_x, background_y)
    end

    if self.layout == self.layouts.horizontal_rows then
        render_horizontal_rows(self, x, y, data)
    elseif self.layout == self.layouts.vertical_columns then
        render_vertical_columns(self, x, y, data)
    elseif self.layout == self.layouts.manual then
        render_elements_manually(self, x, y, data)
    elseif self.layout == self.layouts.vertical_flow then
        render_vertical_flow(self, x, y, data)
    end
end

return container

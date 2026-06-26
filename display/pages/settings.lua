local Container = require("display.elements.container")
local Toggle = require("display.elements.toggle")
local Button = require("display.elements.button")

local settings_page = {}
settings_page.__index = settings_page

function settings_page.new(m, size, settings, task_runner)
    local auto_pickup = Toggle.new(m,
        "Auto recover completed quarries?", {
            fg = colours.black,
            bg = m:get_default_bg_colour()
        },
        settings:read(settings.keys.auto_recover_quarries),
        function(value)
            settings:set(settings.keys.auto_recover_quarries, value)
        end)

    local padding = {
        top = 1,
        left = 1
    }

    local container = Container:new(
        m,
        Container.layouts.vertical_flow,
        size,
        padding)

    container:add_element(1, auto_pickup)

    return setmetatable({
        m = m,
        task_runner = task_runner,
        container = container,
    }, settings_page)
end

function settings_page:handle_click(x, y)
    local click_handled = self.container:handle_click(x, y)

    return click_handled
end

function settings_page:render(x, y, _)
    self.container:render(x, y)
end

return settings_page

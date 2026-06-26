local Container             = require("display.elements.container")
local Button                = require("display.elements.button")
local Label                 = require("display.elements.label")
local Background            = require("display.elements.background")
local Text                  = require("display.elements.text")
local Confirm               = require("display.elements.confirm")

local ts                    = require("display.turtle_status")

local list                  = require("lib.list")

local quarry_details_page   = {}
quarry_details_page.__index = quarry_details_page

local function format_location(location)
    if not location then
        return "Unknown"
    end

    return ("%d %d %d"):format(location.x, location.y, location.z)
end

local function format_number(value)
    return value or "Unknown"
end

function quarry_details_page:new(m, size, page_switcher, task_runner)
    local buttons_container_size = {
        width = 20,
        height = size.height
    }

    local buttons_container_padding = {
        top = 1,
        bottom = 1,
        left = 1,
    }

    local buttons_container = Container:new(
        m,
        Container.layouts.manual,
        buttons_container_size,
        buttons_container_padding)

    local buttons_background = Background:fill_container(buttons_container, true)
    buttons_background:solid(colours.grey)
    buttons_container:add_background(buttons_background)

    local back_button = Button:new(m, {
            height = 3,
            width = 10
        },
        "<< Back",
        colours.black,
        colours.lightBlue,
        function() page_switcher("quarries") end)

    buttons_container:add_element(1, back_button, {
        respect_padding = true,
        x_offset = 1,
        y_offset = buttons_container_size.height - 6,
    })

    local label_size = {
        height = 3,
        width = 15
    }

    local status_label = Label:new(
        m,
        label_size,
        "",
        colours.white,
        colours.black,
        true)

    local status_label_id = 2
    buttons_container:add_element(status_label_id, status_label, {
        x_offset = 1,
        y_offset = 1,
        respect_padding = true
    })

    local pause_button = Button:new(m, {
            height = 3,
            width = 13
        },
        "Pause",
        colours.black,
        colours.lightBlue,
        function() end)

    local pause_button_id = 3
    buttons_container:add_element(pause_button_id, pause_button, {
        respect_padding = true,
        y_offset = 5,
        x_offset = 1,
    })

    local recover_button = Button:new(m, {
            height = 3,
            width = 13,
        },
        "Recover",
        colours.black,
        colours.red,
        function() end)

    local recover_button_id = 4
    buttons_container:add_element(recover_button_id, recover_button, {
        respect_padding = true,
        y_offset = 9,
        x_offset = 1,
    })

    local kill_button = Button:new(m, {
            height = 3,
            width = 13,
        },
        "Kill",
        colours.black,
        colours.red,
        function() end)

    local kill_button_id = 5
    buttons_container:add_element(kill_button_id, kill_button, {
        respect_padding = true,
        y_offset = 13,
        x_offset = 1,
    })

    local information_container_size = {
        width = size.width - buttons_container_size.width,
        height = size.height
    }

    local information_container_padding = {
        top    = 1,
        right  = 1,
        bottom = 1,
        left   = 1
    }

    local information_container = Container:new(
        m,
        Container.layouts.manual,
        information_container_size,
        information_container_padding)

    local information_background = Background:fill_container(information_container, true)
    information_background:solid(colours.grey)
    information_container:add_background(information_background)

    local recover_confirm_lines = {
        "Are you sure?", "",
        "You won't be able to control ",
        "this turtle remotely anymore, ",
        "only recover it."
    }
    local confirm = Confirm:new(m, recover_confirm_lines)

    local turtle_header_id = 2
    local turtle_header = Text:new(m, "", colours.white)
    information_container:add_element(turtle_header_id, turtle_header, {
        respect_padding = true,
        x_offset        = 1,
        y_offset        = 1
    })

    local fuel_id = 3
    local fuel = Text:new(m, "", colours.white)
    information_container:add_element(fuel_id, fuel, {
        respect_padding = true,
        x_offset        = 1,
        y_offset        = 2
    })

    local position_info_id = 4
    local position_info = Text:new(m, "", colours.white)
    information_container:add_element(position_info_id, position_info, {
        respect_padding = true,
        x_offset        = 1,
        y_offset        = 5
    })

    local quarry_info_id = 5
    local quarry_info = Text:new(m, "", colours.white)
    information_container:add_element(quarry_info_id, quarry_info, {
        respect_padding = true,
        x_offset        = 1,
        y_offset        = 11
    })

    return setmetatable({
        m = m,
        page_switcher = page_switcher,
        task_runner = task_runner,
        buttons_container = buttons_container,
        information_container = information_container,
        button_elements = {
            pause_button_id = pause_button_id,
            recover_button_id = recover_button_id,
            kill_button_id = kill_button_id,
        },
        text_elements = {
            status_label_id = status_label_id,
            turtle_header_id = turtle_header_id,
            fuel_id = fuel_id,
            position_info_id = position_info_id,
            quarry_info_id = quarry_info_id,
        },
        confirm = confirm,
    }, self)
end

function quarry_details_page:handle_click(x, y)
    if self.confirm:is_opened_for(self.selected_id) then
        -- Consume click, let confirmation handle it.
        return self.confirm:handle_click(x, y)
    else
        self.confirm:close()
    end

    return self.buttons_container:handle_click(x, y)
end

function quarry_details_page:render(x, y, data)
    local turtles = list.convert_map_to_array(data.turtles, "id")

    local selected_turtle = list.find(turtles, "id", data.selected_id)
    if not selected_turtle then return end
    self.selected_id = selected_turtle.id

    local label_colour = ts.quarry_status_to_colour(selected_turtle.metadata.status)
    if label_colour == colours.grey then label_colour = colours.red end

    self.buttons_container:update_element(
        self.text_elements.status_label_id,
        "text",
        selected_turtle.metadata.status)
    self.buttons_container:update_element(
        self.text_elements.status_label_id,
        "label_colour",
        label_colour)

    local turtle_header_text = "Quarry ID: #" .. selected_turtle.id
    self.information_container:update_element(
        self.text_elements.turtle_header_id,
        "content",
        turtle_header_text)

    local fuel_lines = {
        ("Current fuel level: %d"):format(selected_turtle.metadata.fuel_level or 0),
        ("Stored fuel units: %d"):format(selected_turtle.metadata.stored_fuel_units or 0),
    }
    self.information_container:update_element(
        self.text_elements.fuel_id,
        "content",
        fuel_lines)

    local position_lines = {
        "Position information:", "",
        ("  Currently at: %s"):format(
            format_location(selected_turtle.metadata.current_location)),
        ("  Mining layer: %s out of %s"):format(
            format_number(selected_turtle.metadata.current_layer),
            format_number(selected_turtle.metadata.boundaries and selected_turtle.metadata.boundaries.layers)),
        ("  Mining row: %s"):format(
            format_number(selected_turtle.metadata.current_row))
    }
    self.information_container:update_element(
        self.text_elements.position_info_id,
        "content",
        position_lines)

    local quarry_lines = {
        "Quarry information:", "",
        ("  Dimensions: %sx%s blocks"):format(
            format_number(selected_turtle.metadata.boundaries and selected_turtle.metadata.boundaries.width),
            format_number(selected_turtle.metadata.boundaries and selected_turtle.metadata.boundaries.depth)),
        ("  Total layers: %s"):format(
            format_number(selected_turtle.metadata.boundaries and selected_turtle.metadata.boundaries.layers)),
        ("  Starting location: %s"):format(
            format_location(selected_turtle.metadata.boundaries and selected_turtle.metadata.boundaries.starting_position))
    }
    self.information_container:update_element(
        self.text_elements.quarry_info_id,
        "content",
        quarry_lines)

    self.confirm.on_yes = function()
        self.task_runner:add_task(self.task_runner.tasks.kill, { id = selected_turtle.id })
    end

    self.buttons_container:update_element(
        self.button_elements.kill_button_id,
        "on_click",
        function()
            self.confirm:open(selected_turtle.id)
        end)

    if ts.is_turtle_active(selected_turtle.metadata.status) then
        self.buttons_container:update_element(
            self.button_elements.pause_button_id,
            "text",
            "Pause")
        self.buttons_container:update_element(
            self.button_elements.pause_button_id,
            "button_colour",
            colours.lightBlue)

        self.buttons_container:update_element(
            self.button_elements.pause_button_id,
            "on_click",
            function()
                self.task_runner:add_task(self.task_runner.tasks.pause, { id = selected_turtle.id })
            end)

        self.buttons_container:update_element(self.button_elements.pause_button_id, "disabled", false)
        self.buttons_container:update_element(self.button_elements.kill_button_id, "disabled", false)
        self.buttons_container:update_element(self.button_elements.recover_button_id, "disabled", true)
    elseif ts.is_paused(selected_turtle.metadata.status) then
        self.buttons_container:update_element(
            self.button_elements.pause_button_id,
            "text",
            "Resume")
        self.buttons_container:update_element(
            self.button_elements.pause_button_id,
            "button_colour",
            colours.green)

        self.buttons_container:update_element(
            self.button_elements.pause_button_id,
            "on_click",
            function()
                self.task_runner:add_task(self.task_runner.tasks.resume, { id = selected_turtle.id })
            end)

        self.buttons_container:update_element(self.button_elements.pause_button_id, "disabled", false)
        self.buttons_container:update_element(self.button_elements.kill_button_id, "disabled", false)
        self.buttons_container:update_element(self.button_elements.recover_button_id, "disabled", true)
    else -- Turtle is offline or completed.
        self.buttons_container:update_element(self.button_elements.pause_button_id, "disabled", true)
        self.buttons_container:update_element(self.button_elements.kill_button_id, "disabled", true)
        self.buttons_container:update_element(self.button_elements.recover_button_id, "disabled", false)

        self.buttons_container:update_element(
            self.button_elements.recover_button_id,
            "on_click",
            function()
                self.task_runner:add_task(self.task_runner.tasks.recover, {
                    offline_turtle = selected_turtle,
                    id = selected_turtle.id,
                })
                self.page_switcher("quarries")
            end)
    end

    self.buttons_container:render(x, y)
    self.information_container:render(x + self.buttons_container.size.width, y)

    if self.confirm:is_opened_for(selected_turtle.id) then
        self.confirm:render()
    end
end

return quarry_details_page

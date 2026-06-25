local wireless = require("wireless")
local Display = require("display")

local TurtleStore = require("turtle_store")
local Settings = require("settings")

local printer = require("lib.printer")
local time = require("lib.time")
local string_util = require("lib.string_util")

local handlers = {
    dispatch_pickup = require("handlers.dispatch_pickup"),
    dispatch_resupply = require("handlers.dispatch_resupply"),
    dispatch_fluid_fill = require("handlers.dispatch_fluid_fill"),
}

local turtle_store = TurtleStore.new()
local settings = Settings.new()

printer.print_info("Booting manager #" .. os.getComputerID())

wireless.open()
wireless.discovery.host("manager")

local monitor = peripheral.find("monitor")
local display
if monitor then
    display = Display:new(monitor, settings)

    -- Add everything from the store to the display
    local turtles = turtle_store:list()
    for id, turtle in pairs(turtles) do
        display:add_or_update_turtle(id, turtle)
    end
end

settings:register_on_change(function(key, value)
    local turtles = turtle_store:list()
    for id, _ in pairs(turtles) do
        wireless.settings.update_setting_on(id, key, value)
    end
end)

wireless.router.register_handler(
    wireless.protocols.telemetry,
    wireless.heartbeat.operation,
    function(sender, msg)
        local turtle = turtle_store:get(sender)

        if not turtle then return false end

        local updated = turtle_store:update(sender, {
            last_seen = time.epoch_in_seconds(),
            status = msg.status,
            metadata = msg.data,
        })

        if display then
            display:add_or_update_turtle(sender, updated)
        end

        wireless.registry.accept(sender)

        return true
    end)

wireless.router.register_handler(
    wireless.protocols.registry,
    wireless.registry.operations.register,
    function(sender, msg)
        local data = {
            role = msg.data.role,
            metadata = msg.data.metadata
        }

        turtle_store:upsert(sender, data)

        wireless.settings.overwrite_settings_on(sender, settings:list())

        printer.print_info("New turtle registered: #" .. sender .. " '" .. data.role .. "'")
    end)

wireless.router.register_handler(
    wireless.protocols.pickup,
    wireless.pickup.operations.request,
    function(sender, msg)
        handlers.dispatch_pickup(sender, msg, turtle_store)
    end)

wireless.router.register_handler(
    wireless.protocols.resupply,
    wireless.resupply.operations.request,
    function(sender, msg)
        handlers.dispatch_resupply(sender, msg, turtle_store)
    end)

wireless.router.register_handler(
    wireless.protocols.fluid_fill,
    wireless.fluid_fill.operations.report,
    function(sender, msg)
        handlers.dispatch_fluid_fill(sender, msg, turtle_store)
    end)

wireless.router.register_handler(
    wireless.protocols.job,
    wireless.job.operations.job_completed,
    function(sender, msg)
        if msg.data.job_type == "quarry" then
            local updated = turtle_store:update(sender, {
                ["metadata.status"] = "Completed",
                ["metadata.current_location"] = msg.data.coordinates,
            })

            if settings:read(settings.keys.auto_recover_quarries) == true then
                wireless.pickup.request(os.getComputerID(), msg.data.coordinates, "turtle:" .. sender)
            end

            if display then
                display:add_or_update_turtle(sender, updated)
            end
        elseif msg.data.job_type == "pickup" and string_util.starts_with(msg.data.what, "turtle") then
            local id = string_util.split_by(msg.data.what, ":")[2]

            turtle_store:delete(tonumber(id))

            if display then
                display:delete_turtle(tonumber(id))
            end
        end
    end)

local function mark_stale()
    while true do
        local turtles = turtle_store:list()
        local now = time.epoch_in_seconds()

        for k, v in pairs(turtles) do
            if v.metadata and (v.metadata.status == "Completed" or v.metadata.status == "Offline") then
                goto continue
            end

            local new_status
            if not v.last_seen or now - v.last_seen >= 15 then
                new_status = "Offline"
            elseif now - v.last_seen >= 2 then
                new_status = "Stale"
            end

            if new_status then
                local updated = turtle_store:update(k, {
                    ["metadata.status"] = new_status
                })
                if display then
                    display:add_or_update_turtle(k, updated)
                end
            end

            ::continue::
        end

        sleep(1)
    end
end

local main_loops = { wireless.router.loop, mark_stale }

if display then
    table.insert(main_loops, function() display:loop() end)
    table.insert(main_loops, function() display.task_runner:loop() end)
end

printer.print_success("Manager online.")

parallel.waitForAny(table.unpack(main_loops))

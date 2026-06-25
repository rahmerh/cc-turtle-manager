local wireless      = require("wireless")
local locator       = require("movement.locator")

local inventory     = require("lib.inventory")
local errors        = require("lib.errors")
local printer       = require("lib.printer")

local fueler        = {}

local ACCEPTED_FUEL = {
    ["minecraft:coal"] = true
}

function fueler.get_fuel_level()
    return turtle.getFuelLevel()
end

function fueler.refuel_from_inventory()
    if turtle.getFuelLevel() > 0 then
        return true
    end

    local fuel_slot = inventory.details_from_slot(1)
    if fuel_slot and fuel_slot.count < 64 then
        local fuel_slots = inventory.get_slots_containing_item("minecraft:coal")

        for _, slot in ipairs(fuel_slots) do
            inventory.merge_into_slot(slot, 1)

            fuel_slot = inventory.details_from_slot(1)
            if fuel_slot.count == 64 then
                break
            end
        end
    end

    turtle.select(1)
    if turtle.refuel(4) then
        return true
    else
        return false, errors.NOT_FUEL
    end
end

function fueler.handle_movement_result(ok, err, ctx)
    if ok then return "retry" end
    if err ~= errors.NO_FUEL then return ok, err end

    if fueler.refuel_from_inventory() then
        return "retry"
    end

    local manager_id = ctx and ctx.manager_id
    local current_coordinates = locator.get_current_coordinates()
    local desired = { ["minecraft:coal"] = 64 }

    if not manager_id then
        return nil, errors.NO_FUEL
    end

    printer.print_info("Requesting fuel...")
    wireless.resupply.request(
        manager_id,
        current_coordinates,
        desired)
    local arrived_msg = wireless.resupply.await_arrived()
    if not arrived_msg then
        return nil, errors.NO_FUEL
    end

    inventory.drop_slots(1, 1, "up")
    wireless.resupply.ready(arrived_msg._sender)
    wireless.resupply.await_done()

    local slot = inventory.find_item("minecraft:coal")
    if slot ~= 1 then
        local moved, moved_err = inventory.move_to_slot(slot, 1, true)

        if not moved and moved_err then
            return moved, moved_err
        end
    end

    return "retry"
end

return fueler

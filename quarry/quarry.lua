local movement  = require("movement")
local wireless  = require("wireless")

local inventory = require("lib.inventory")
local printer   = require("lib.printer")
local miner     = require("lib.miner")
local scanner   = require("lib.scanner")

local quarry    = {}

function quarry.get_row_direction_for_layer(width, layer)
    if width % 2 == 1 then
        return (layer % 2 == 0) and "south" or "north"
    else
        local dirs = { "east", "south", "west", "north" }
        return dirs[layer % 4 + 1]
    end
end

function quarry.starting_location_for_row(layer, row, boundaries)
    local current_layer_row_direction = quarry.get_row_direction_for_layer(boundaries.width, layer)

    local even_row = row % 2 == 0
    local to_move_x
    local to_move_z
    if current_layer_row_direction == "north" then
        to_move_x = row

        if even_row then
            to_move_z = 0
        else
            to_move_z = boundaries.depth - 1
        end
    elseif current_layer_row_direction == "east" then
        to_move_z = boundaries.depth - (row + 1)
        if even_row then
            to_move_x = 0
        else
            to_move_x = boundaries.width - 1
        end
    elseif current_layer_row_direction == "south" then
        to_move_x = boundaries.width - (row + 1)
        if even_row then
            to_move_z = boundaries.depth - 1
        else
            to_move_z = 0
        end
    elseif current_layer_row_direction == "west" then
        to_move_z = row
        if even_row then
            to_move_x = boundaries.width - 1
        else
            to_move_x = 0
        end
    end

    local steps_to_move_down = (boundaries.layers - layer) * 3 + 2

    local target_x = boundaries.starting_position.x + to_move_x
    local target_y = boundaries.starting_position.y - steps_to_move_down
    local target_z = boundaries.starting_position.z - to_move_z

    return {
        x = target_x,
        y = target_y,
        z = target_z
    }
end

function quarry.mine_bedrock_layer(start_x, start_z, width, depth, movement_context)
    movement.move_to(start_x, -59, start_z, movement_context)
    movement.turn_to_direction("north")

    local to_move_forward = depth - 1

    while movement.get_current_coordinates().y > -60 do
        local moved_down = movement.move_down(movement_context)
        if not moved_down then
            break
        else
            miner.mine_down()
        end
    end

    for row = 1, width do
        for _ = 1, to_move_forward do
            miner.mine()

            while scanner.is_block("minecraft:bedrock", "forward") do
                miner.mine_up()
                movement.move_up(movement_context)
                miner.mine()
            end

            local moved_forward = movement.move_forward(movement_context)
            if moved_forward then
                to_move_forward = to_move_forward - 1
            end

            miner.mine_up()
            miner.mine_down()

            if inventory.are_all_slots_full() then
                quarry.unload(movement_context.manager_id)
            end

            while movement.get_current_coordinates().y > -60 do
                local moved_down = movement.move_down(movement_context)
                if not moved_down then
                    break
                else
                    miner.mine_down()
                end
            end
        end

        if row == width then
            break
        end

        if row % 2 == 0 then
            movement.turn_left()
            if scanner.is_block("minecraft:bedrock", "forward") then
                movement.move_up(movement_context)
            end
            miner.mine()
            movement.move_forward(movement_context)

            miner.mine_up()
            miner.mine_down()

            movement.turn_left()
        else
            movement.turn_right()
            if scanner.is_block("minecraft:bedrock", "forward") then
                movement.move_up(movement_context)
            end
            miner.mine()
            movement.move_forward(movement_context)

            miner.mine_up()
            miner.mine_down()

            movement.turn_right()
        end

        to_move_forward = depth - 1
    end
end

function quarry.unload(manager_id)
    local has_chests = inventory.is_item_in_slot("minecraft:chest", 2)

    if not has_chests then
        printer.print_info("Requesting chests...")
        local desired = { ["minecraft:chest"] = 64 }
        local request_id = wireless.resupply.request(manager_id, movement.get_current_coordinates(), desired)
        local arrived_msg = wireless.resupply.await_arrived(request_id)
        if not arrived_msg then
            error("Timed out waiting for chest resupply.")
        end

        inventory.drop_slots(2, 2, "up")
        wireless.resupply.ready(arrived_msg._sender, request_id)
        local done_msg = wireless.resupply.await_done(request_id, arrived_msg._sender)
        if not done_msg then
            error("Timed out waiting for chest resupply to finish.")
        end
    end

    movement.move_back()
    movement.move_up()

    turtle.select(2)
    turtle.placeDown()
    inventory.drop_slots(3, 16, "down")

    local chest_coordinates = movement.get_current_coordinates()
    chest_coordinates.y = chest_coordinates.y - 1 -- Adjust down, since we're on top of the chest.
    wireless.pickup.request(manager_id, chest_coordinates, "chest")

    if not scanner.is_free("forward") then
        miner.mine()
    end

    movement.move_forward()
    movement.move_down()
end

function quarry.mine_layer(layer, boundaries, start_from_row, on_row_done, manager_id, fluid_tracker)
    local direction = quarry.get_row_direction_for_layer(boundaries.width, layer)
    local movement_context = { dig = true, manager_id = manager_id }

    local rows, length
    if direction == "north" or direction == "south" then
        rows = boundaries.width - start_from_row
        length = boundaries.depth - 1
    else
        rows = boundaries.depth - start_from_row
        length = boundaries.width - 1
    end

    for _ = 1, rows do
        local coords = quarry.starting_location_for_row(layer, start_from_row, boundaries)
        local moved, moved_error = movement.move_to(coords.x, coords.y, coords.z, movement_context)
        if not moved then error("Turtle stuck: " .. moved_error) end

        local face = (start_from_row % 2 == 0) and direction or movement.opposite_of(direction)
        movement.turn_to_direction(face)

        if fluid_tracker then
            local fluid_detected = scanner.is_fluid("up") or scanner.is_fluid("down")

            if fluid_detected then
                fluid_tracker:add(movement.get_current_coordinates())
            end
        end

        miner.mine_up(); miner.mine_down()
        for _ = 1, length do
            local ok, err = miner.mine()

            -- if fluid_tracker then
            --     print("forward")
            --     fluid_detected = scanner.is_fluid("forward")
            -- end

            if not ok and err then
                printer.print_error(err); return false, err
            end

            movement.move_forward(movement_context)
            miner.mine_up(); miner.mine_down()

            local fluid_detected
            if fluid_tracker then
                fluid_detected = scanner.is_fluid("up") or scanner.is_fluid("down")
            end

            if inventory.are_all_slots_full() then
                quarry.unload(manager_id)
            end

            if fluid_detected then
                fluid_tracker:add(movement.get_current_coordinates())
            end
        end

        start_from_row = start_from_row + 1
        on_row_done()
    end

    return true
end

return quarry

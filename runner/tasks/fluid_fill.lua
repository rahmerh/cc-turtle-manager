local movement = require("movement")

local task_stages = require("task_stages")

local printer = require("lib.printer")
local inventory = require("lib.inventory")
local miner = require("lib.miner")
local list = require("lib.list")

local function group_by_x(coords)
    local grouped = {}

    for _, c in ipairs(coords) do
        if not grouped[c.x] then
            grouped[c.x] = {}
        end
        table.insert(grouped[c.x], c)
    end

    for x, l in pairs(grouped) do
        table.sort(l, function(a, b)
            return a.z > b.z
        end)
    end

    local sorted_groups = {}
    for x, l in pairs(grouped) do
        table.insert(sorted_groups, { x = x, coords = l })
    end

    table.sort(sorted_groups, function(a, b)
        return a.x < b.x
    end)

    return sorted_groups
end

return function(task, config, movement_context, report_progress)
    if not task.stage then
        printer.print_info(("[%s] Filling fluid in %d columns."):format(
            task.job_id,
            #task.fluid_columns))

        report_progress(task.job_id, task_stages.to_supply, true)
    else
        printer.print_info(("[%s] Resuming fluid fill task"):format(task.job_id))
    end

    if task.stage == task_stages.to_supply then
        local arrived, arrived_err = movement.move_to(
            config.supply_chest_pos.x,
            config.supply_chest_pos.y + 1,
            config.supply_chest_pos.z,
            movement_context)
        if not arrived and arrived_err then
            return arrived, arrived_err
        end

        turtle.select(2)

        local amount_of_filler_blocks = list.map_len(task.fluid_columns) * 3

        local filler_slot, filler_err = inventory.pull_items_from_down("minecraft:cobblestone", amount_of_filler_blocks)
        if not filler_slot then
            return nil, filler_err
        end

        report_progress(task.job_id, task_stages.to_target, false)
    end

    local coords_list = list.convert_map_to_array(task.fluid_columns)

    if task.stage == task_stages.to_target then
        movement.move_to(
            coords_list[1].x,
            coords_list[1].y + 2,
            coords_list[1].z,
            movement_context)

        report_progress(task.job_id, task_stages.filling_fluid, false)
    end

    if task.stage == task_stages.filling_fluid then
        local grouped = group_by_x(coords_list)

        for _, group in ipairs(grouped) do
            movement.move_to(
                group.coords[1].x,
                group.coords[1].y + 2,
                group.coords[1].z,
                movement_context)
            movement.turn_to_direction("north")

            for i = 1, #group.coords do
                turtle.select(2)

                movement.move_down(movement_context)
                movement.move_down(movement_context)

                turtle.placeDown()
                movement.move_up(movement_context)
                turtle.placeDown()
                movement.move_up(movement_context)
                turtle.placeDown()

                if i < #group.coords then
                    movement.move_forward(movement_context)
                end
            end
        end

        for _, group in ipairs(grouped) do
            movement.move_to(
                group.coords[1].x,
                group.coords[1].y + 2,
                group.coords[1].z,
                movement_context)
            movement.turn_to_direction("north")

            miner.mine_down()
            movement.move_down(movement_context)
            miner.mine_down()
            movement.move_down(movement_context)
            miner.mine_down()
            for i = 1, #group.coords - 1 do
                miner.mine()
                movement.move_forward(movement_context)
                miner.mine_up()
                miner.mine_down()
            end
        end

        report_progress(task.job_id, task_stages.to_unloading, false)
    end

    if task.stage == task_stages.to_unloading then
        local moved_back, moved_back_err = movement.move_to(
            config.unloading_chest_pos.x,
            config.unloading_chest_pos.y + 1,
            config.unloading_chest_pos.z,
            movement_context)

        if not moved_back and moved_back_err then
            return moved_back, moved_back_err
        end
    end
end

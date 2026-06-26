local errors = require("lib.errors")
local list = require("lib.list")

local scanner = {}

function scanner.is_block(block_type, direction)
    local ok, info
    if direction == "up" then
        ok, info = turtle.inspectUp()
    elseif direction == "down" then
        ok, info = turtle.inspectDown()
    elseif direction == "forward" then
        ok, info = turtle.inspect()
    else
        return nil, errors.INVALID_DIRECTION
    end

    if not ok then
        return false
    else
        return info.name == block_type
    end
end

function scanner.is_free(direction)
    local detected
    if direction == "up" then
        detected = turtle.detectUp()
    elseif direction == "down" then
        detected = turtle.detectDown()
    elseif direction == "forward" then
        detected = turtle.detect()
    else
        return nil, errors.INVALID_DIRECTION
    end

    return not detected
end

return scanner

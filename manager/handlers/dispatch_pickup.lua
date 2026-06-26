local wireless = require("wireless")

local errors = require("lib.errors")
local dispatch_utils = require("dispatch_helpers")

return function(sender, msg, turtle_store)
    local runners = turtle_store:get_by_role("runner")

    if not runners or next(runners) == nil then
        return nil, errors.wireless.NO_AVAILABLE_RUNNERS
    end

    local id = dispatch_utils.find_least_queued(runners, sender)

    if not id then
        return nil, errors.wireless.NO_AVAILABLE_RUNNERS
    end

    wireless.pickup.assign(
        id,
        msg.data.target,
        msg.data.what,
        sender,
        msg.id)
end

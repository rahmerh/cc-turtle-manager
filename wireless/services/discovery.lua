local time = require("lib.time")

local discovery = {}

local discovery_protocol = "discovery:manager"

--- Starts a "host" for a manager computer.
function discovery.host_manager()
    local existing_manager = rednet.lookup(discovery_protocol)

    if existing_manager then
        return false, "Another manager already alive: #" .. existing_manager
    end

    rednet.host(discovery_protocol, "" .. os.getComputerID())

    return true
end

--- Finds the manager's computer id to be used in sending messages.
--- @return integer|nil, string?  id or nil,"not_found"
function discovery.find_manager(timeout_seconds)
    local deadline = time.alive_duration_in_seconds() + timeout_seconds

    repeat
        local id = rednet.lookup(discovery_protocol)

        if id then
            return id
        end

        sleep(1)
    until time.alive_duration_in_seconds() >= deadline

    return nil, "not_found"
end

return discovery

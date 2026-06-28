local core = require("wireless._internal.core")

local registry = {
    operations = {
        register = "registry:register",
        accepted = "registry:accepted",
    }
}

--- Register this turtle with a manager.
--- @param manager_id integer
--- @param role string              -- e.g. "quarry", "runner", "manager"
--- @return true|nil, string?       -- true or nil,"no_ack"
function registry.announce_at(manager_id, role, metadata)
    local data = {
        role = role,
        metadata = metadata
    }
    local payload = core.create_payload(registry.operations.register, data)

    local attempts = 5

    for i = 1, attempts do
        core.send(manager_id, payload, core.protocols.registry)

        local message = core.await_response(registry.operations.accepted, 5, {
            sender = manager_id,
            protocol = core.protocols.registry,
            reply_to = payload.id,
        })

        if message then
            return true, payload.id
        end

        if i < attempts then
            sleep(1)
        end
    end

    return nil, "no_ack"
end

--- Used to reply to a turtle registering. Method should only be used by a manager.
---@param receiver integer id of the receiving computer.
---@param reply_to integer the id of the message it's replying to.
function registry.accept(receiver, reply_to)
    local payload = core.create_payload(registry.operations.accepted, nil, reply_to)

    core.send(receiver, payload, core.protocols.registry)
end

return registry

local core = require("wireless._internal.core")

local printer = require("lib.printer")

local router = {
    _handlers = {},
}

--- Registers a handler/callback for the specified protocol and operation.
---@param protocol string the protocol to listen to.
---@param operation string the operation to filter on.
---@param handler function the callback to invoke for each message with the protocol and operation.
function router.register_handler(protocol, operation, handler)
    if type(protocol) ~= "string" then
        error("Protocol is required/invalid.")
    end

    if type(operation) ~= "string" then
        error("Operation is required/invalid.")
    end

    if type(handler) ~= "function" then
        error("Handler is required/invalid.")
    end

    router._handlers[operation] = {
        protocol = protocol,
        handler = handler
    }
end

--- Receive message from rednet and route to registered handlers
---@param timeout_seconds integer amount of seconds for each "receive message" poll
local function step(timeout_seconds)
    local sender, msg, protocol = core.receive(timeout_seconds)
    if not sender or type(msg) ~= "table" then
        return false
    end

    if msg.id then
        core.stash_response(sender, msg, protocol)
    end

    if type(msg.operation) ~= "string" then
        return false
    end

    local handler = router._handlers[msg.operation]

    -- No handler registered for operation.
    if not handler then
        return false
    end

    if not handler.protocol or handler.protocol ~= protocol then
        return false
    end

    local ok, response, error = pcall(handler.handler, sender, msg, protocol)

    if not ok then
        printer.print_error("Handler crash: " .. tostring(response))
    elseif response and error == nil then
        return true
    end
end

--- Main loop to listen/handle messages.
function router.loop()
    while true do
        -- TODO: Handle result
        step(5)
    end
end

return router

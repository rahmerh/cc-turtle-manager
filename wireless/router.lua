local core = require("wireless._internal.core")

local printer = require("lib.printer")
local errors = require("lib.errors")

local router = {
    _handlers = {},
}

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

function router.step(timeout)
    local sender, msg, protocol = core.receive(timeout)
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

function router.loop()
    while true do
        router.step(5)
    end
end

return router

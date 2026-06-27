local time = require("lib.time")
local errors = require("lib.errors")

local _private = {}
local core = {
    protocols = {
        telemetry = "telemetry",
        registry = "registry",
        settings = "settings",
        job = "job",
        pickup = "pickup",
        resupply = "resupply",
        turtle_commands = "turtle_commands",
    },
    _inbox = {},
    _listeners = {}
}

math.randomseed((os.epoch("utc") % (2 ^ 31)) + os.getComputerID()); math.random(); math.random()

function _private.next_id()
    return ("%d-%d-%d"):format(os.getComputerID(), os.epoch("utc"), math.random(1, 1e9))
end

function core.create_payload(operation, data, reply_to)
    return {
        id = _private.next_id(),
        reply_to = reply_to,
        operation = operation,
        data = data,
    }
end

function core.open()
    peripheral.find("modem", rednet.open)

    return rednet.isOpen()
end

function core.send(receiver, payload, protocol)
    rednet.send(receiver, payload, protocol)
end

function core.receive(timeout_seconds)
    return rednet.receive(nil, timeout_seconds)
end

function core.stash_response(sender, msg, protocol)
    if type(msg) == "table" and msg.id then
        msg._sender         = sender
        msg._protocol       = protocol
        core._inbox[msg.id] = msg
    end
end

function core.take_response(id)
    local message = core._inbox[id]

    if message then
        core._inbox[id] = nil
    end

    return message
end

local function matches(msg, operation, options)
    if type(msg) ~= "table" or msg.operation ~= operation then
        return false
    end

    if options then
        if options.sender and msg._sender ~= options.sender then
            return false
        end

        if options.protocol and msg._protocol ~= options.protocol then
            return false
        end

        if options.reply_to and msg.reply_to ~= options.reply_to then
            return false
        end
    end

    return true
end

function core.await_response(operation, timeout_seconds, options)
    local deadline = time.alive_duration_in_seconds() + timeout_seconds

    while true do
        for id, msg in pairs(core._inbox) do
            if matches(msg, operation, options) then
                core._inbox[id] = nil
                return msg
            end
        end

        if time.alive_duration_in_seconds() >= deadline then
            return nil, errors.wireless.TIMEOUT
        end

        sleep(1)
    end
end

return core

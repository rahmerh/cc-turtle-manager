local constants = require("lib.constants")

local core = require("wireless._internal.core")

local pickup = {
    operations = {
        request = "pickup:request",
        assign = "pickup:assign",
        accepted = "pickup:accepted",
    }
}

function pickup.request(receiver, target, what)
    local data = {
        job_type = constants.job_types.pickup,
        target = target,
        what = what,
    }
    local payload = core.create_payload(pickup.operations.request, data)

    core.send(receiver, payload, core.protocols.pickup)

    return payload.id
end

function pickup.assign(receiver, target, what, requested_by, request_id)
    local data = {
        job_type = constants.job_types.pickup,
        target = target,
        what = what,
        requested_by = requested_by,
        request_id = request_id,
    }
    local payload = core.create_payload(pickup.operations.assign, data)

    core.send(receiver, payload, core.protocols.pickup)
end

function pickup.await_accepted(reply_to, sender)
    return core.await_response(pickup.operations.accepted, 5, {
        sender = sender,
        protocol = core.protocols.pickup,
        reply_to = reply_to,
    })
end

function pickup.accept(receiver, job_id)
    local data = {
        job_id = job_id
    }
    local payload = core.create_payload(pickup.operations.accepted, data, job_id)

    core.send(receiver, payload, core.protocols.pickup)
end

return pickup

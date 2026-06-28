local constants = require("lib.constants")

local core = require("wireless._internal.core")

local resupply = {
    operations = {
        request = "resupply:request",
        assign = "resupply:assign",
        accepted = "resupply:accepted",
        arrived = "resupply:arrived",
        ready = "resupply:ready",
        done = "resupply:done",
    }
}

function resupply.request(receiver, turtle_position, items)
    local data = {
        job_type = constants.job_types.resupply,
        target = turtle_position,
        manifest = items
    }
    local payload = core.create_payload(resupply.operations.request, data)

    core.send(receiver, payload, core.protocols.resupply)

    return payload.id
end

function resupply.await_arrived(reply_to, sender)
    return core.await_response(resupply.operations.arrived, 60 * 60, {
        sender = sender,
        protocol = core.protocols.resupply,
        reply_to = reply_to,
    }) -- 1 Hour
end

function resupply.assign(receiver, target, manifest, requested_by, request_id)
    local data = {
        job_type = constants.job_types.resupply,
        target = target,
        manifest = manifest,
        requested_by = requested_by,
        request_id = request_id,
    }
    local payload = core.create_payload(resupply.operations.assign, data)

    core.send(receiver, payload, core.protocols.resupply)
end

function resupply.accept(receiver, job_id)
    local data = {
        job_id = job_id
    }
    local payload = core.create_payload(resupply.operations.accepted, data, job_id)

    core.send(receiver, payload, core.protocols.resupply)
end

function resupply.await_accepted(reply_to, sender)
    return core.await_response(resupply.operations.accepted, 5, {
        sender = sender,
        protocol = core.protocols.resupply,
        reply_to = reply_to,
    })
end

function resupply.arrived(receiver, reply_to)
    local payload = core.create_payload(resupply.operations.arrived, nil, reply_to)
    core.send(receiver, payload, core.protocols.resupply)
end

function resupply.ready(receiver, reply_to)
    local payload = core.create_payload(resupply.operations.ready, nil, reply_to)
    core.send(receiver, payload, core.protocols.resupply)
end

function resupply.await_ready(reply_to, sender)
    return core.await_response(resupply.operations.ready, 5, {
        sender = sender,
        protocol = core.protocols.resupply,
        reply_to = reply_to,
    })
end

function resupply.done(receiver, reply_to)
    local payload = core.create_payload(resupply.operations.done, nil, reply_to)
    core.send(receiver, payload, core.protocols.resupply)
end

function resupply.await_done(reply_to, sender)
    return core.await_response(resupply.operations.done, 5, {
        sender = sender,
        protocol = core.protocols.resupply,
        reply_to = reply_to,
    })
end

return resupply

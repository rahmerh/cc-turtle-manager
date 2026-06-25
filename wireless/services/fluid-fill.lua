local core = require("wireless._internal.core")

local fluid_fill = {
    operations = {
        report = "fluid_fill:report",
        assign = "fluid_fill:assign",
        accepted = "fluid_fill:accepted",
    }
}

function fluid_fill.report(receiver, fluid_columns)
    local data = {
        fluid_columns = fluid_columns
    }
    local payload = core.create_payload(fluid_fill.operations.report, data)

    core.send(receiver, payload, core.protocols.fluid_fill)
end

function fluid_fill.assign(receiver, fluid_columns, requested_by)
    local data = {
        fluid_columns = fluid_columns,
        requested_by = requested_by
    }
    local payload = core.create_payload(fluid_fill.operations.assign, data)

    core.send(receiver, payload, core.protocols.fluid_fill)
end

function fluid_fill.accept(receiver, job_id)
    local data = {
        job_id = job_id
    }
    local payload = core.create_payload(fluid_fill.operations.accepted, data)

    core.send(receiver, payload, core.protocols.fluid_fill)
end

return fluid_fill

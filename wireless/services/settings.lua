local core = require("wireless._internal.core")

local settings = {
    operations = {
        update = "settings:update",
        overwrite = "settings:overwrite",
    }
}

function settings.update_setting_on(receiver, key, value)
    local data = {
        key = key,
        value = value
    }
    local payload = core.create_payload(settings.operations.update, data)

    core.send(receiver, payload, core.protocols.settings)
end

function settings.overwrite_settings_on(receiver, all_settings, reply_to)
    local data = {
        all_settings = all_settings,
    }
    local payload = core.create_payload(settings.operations.overwrite, data, reply_to)

    core.send(receiver, payload, core.protocols.settings)
end

function settings.await_settings_overwrite(sender, reply_to)
    return core.await_response(settings.operations.overwrite, 5, {
        sender = sender,
        protocol = core.protocols.settings,
        reply_to = reply_to,
    })
end

return settings

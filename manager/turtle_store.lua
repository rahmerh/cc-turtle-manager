local TurtleStore = {}
TurtleStore.__index = TurtleStore

local function split(path)
    local result = {}

    for token in string.gmatch(path, "[^%.]+") do
        local n = tonumber(token)
        result[#result + 1] = n or token
    end

    return result
end

local function walk(root, tokens)
    local t = root
    for i = 1, #tokens - 1 do
        local k = tokens[i]
        if type(t[k]) ~= "table" then
            t[k] = {}
        end
        t = t[k]
    end
    return t, tokens[#tokens]
end

local function normalize_turtle(turtle)
    turtle = turtle or {}

    if not turtle.role then
        turtle.role = "unknown"
    end

    if type(turtle.metadata) ~= "table" then
        turtle.metadata = {}
    end

    if not turtle.metadata.status then
        turtle.metadata.status = "Unknown"
    end

    return turtle
end

function TurtleStore.new(path)
    local self = setmetatable({
        _path = path or "turtles.db",
        _turtles = {},
    }, TurtleStore)

    if fs.exists(self._path) then
        local f = fs.open(self._path, "r")
        local raw = f.readAll(); f.close()
        self._turtles = textutils.unserialize(raw) or {}
        for _, turtle in pairs(self._turtles) do
            normalize_turtle(turtle)
        end
    end

    return self
end

function TurtleStore:save()
    local file = fs.open(self._path, "w")
    file.write(textutils.serialize(self._turtles))
    file.close()
end

function TurtleStore:get(id)
    if not self._turtles[id] then
        return nil
    end

    return normalize_turtle(self._turtles[id])
end

function TurtleStore:get_by_role(role)
    local result = {}

    for id, turtle in pairs(self._turtles) do
        turtle = normalize_turtle(turtle)
        if turtle.role == role then result[id] = turtle end
    end

    return result
end

function TurtleStore:update(id, data)
    if not self._turtles[id] then
        self._turtles[id] = {}
    end

    normalize_turtle(self._turtles[id])

    for k, v in pairs(data) do
        local tokens = split(k)
        local parent, last = walk(self._turtles[id], tokens)

        parent[last] = v
    end

    self:save()

    return normalize_turtle(self._turtles[id])
end

function TurtleStore:upsert(id, data)
    self._turtles[id] = normalize_turtle(data)
    self:save()
end

function TurtleStore:list()
    for _, turtle in pairs(self._turtles) do
        normalize_turtle(turtle)
    end

    return self._turtles
end

function TurtleStore:delete(id)
    self._turtles[id] = nil
    self:save()
end

return TurtleStore

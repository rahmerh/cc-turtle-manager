local queue = {}
queue.__index = queue

local function atomic_write(path, tbl)
    local tmp = path .. ".tmp"
    local f = fs.open(tmp, "w")
    f.write(textutils.serialize(tbl))
    f.close()
    if fs.exists(path) then fs.delete(path) end
    fs.move(tmp, path)
end

local function load_file(path)
    if not fs.exists(path) then return nil end
    local f = fs.open(path, "r")
    local raw = f.readAll()
    f.close()
    return textutils.unserialize(raw)
end

local function persist(self)
    atomic_write(self.file_name, { first = self.first, last = self.last, items = self.items })
end

function queue.new(file_name)
    local self = setmetatable({
        first = 1,
        last = 0,
        items = {},
        file_name = file_name
    }, queue)

    local data = load_file(file_name)
    if data then
        self.first = data.first or 1
        self.last  = data.last or 0
        self.items = data.items or {}
    else
        persist(self)
    end

    return self
end

function queue:all()
    local result = {}
    for i = self.first, self.last do
        table.insert(result, self.items[i])
    end
    return result
end

function queue:enqueue(item)
    self.last = self.last + 1
    self.items[self.last] = item
    persist(self)
end

function queue:peek()
    if self.first > self.last then return nil end
    return self.items[self.first]
end

function queue:ack()
    if self.first > self.last then return false end
    self.items[self.first] = nil
    self.first = self.first + 1
    persist(self)
    return true
end

function queue:size()
    return self.last - self.first + 1
end

function queue:compact()
    if self.first == 1 then return end
    local j = 1
    for i = self.first, self.last do
        self.items[j] = self.items[i]
        self.items[i] = nil
        j = j + 1
    end
    self.first, self.last = 1, j - 1
    persist(self)
end

--- Nudges an entry earlier or later in the queue.
---@param index number The index in the queue.
---@param direction number +1 to move later, -1 to move earlier.
function queue:nudge(index, direction)
    if index < self.first or index > self.last then
        error("Index out of range")
    end

    local swap_with = index + direction
    if swap_with < self.first or swap_with > self.last then
        return false
    end

    self.items[index], self.items[swap_with] = self.items[swap_with], self.items[index]

    persist(self)
    return true
end

function queue:get(index)
    local item = self.items[index]

    if not item then
        error(("No item found at index: %d"):format(index))
    end

    return item
end

function queue:find(field, value)
    for i, item in pairs(self.items) do
        if item[field] == value then
            return i, item
        end
    end
    return nil
end

function queue:update(index, field, value)
    if not self.items[index] then
        error(("No item on index: %d"):format(index))
    end

    self.items[index][field] = value

    persist(self)
end

return queue

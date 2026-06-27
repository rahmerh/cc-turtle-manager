local JobQueue = {}
JobQueue.__index = JobQueue

local function save(self)
    local file = fs.open(self._path, "w")

    local data = { jobs = self._jobs, first = self.first, last = self.last }

    file.write(textutils.serialize(data))

    file.close()
end

function JobQueue.new()
    local self = setmetatable({
        _path = "job_queue.json",
        _jobs = {},
        first = 1,
        last = 0,
    }, JobQueue)

    if fs.exists(self._path) then
        local f = fs.open(self._path, "r")
        local raw = f.readAll(); f.close()
        local data = textutils.unserialize(raw) or {}

        self._jobs = data._jobs or {}
        self.first = data.first
        self.last = data.last
    else
        save(self)
    end

    return self
end

function JobQueue:enqueue(job)
    self.last = self.last + 1
    self._jobs[self.last] = job

    save(self)
end

function JobQueue:peek()
    if self.first > self.last then return nil end

    return self._jobs[self.first]
end

function JobQueue:pop()
    if self.first > self.last then return false end
    self.items[self.first] = nil
    self.first = self.first + 1
    persist(self)
    return true
end

return JobQueue

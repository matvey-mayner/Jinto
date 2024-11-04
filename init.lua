local component = component
local computer = computer
local gpu = component.proxy(component.list("gpu")())
local screen = component.list("screen")()
gpu.bind(screen)
gpu.setResolution(50, 16)

local function clear()
    gpu.fill(1, 1, 50, 16, " ")
end

local function write(x, y, text)
    gpu.set(x, y, text)
end

local function readFile(path)
    local drive = component.proxy(computer.getBootAddress())
    local handle, reason = drive.open(path, "r")
    if not handle then
        return nil, reason
    end

    local content = ""
    repeat
        local chunk = drive.read(handle, math.huge)
        content = content .. (chunk or "")
    until not chunk

    drive.close(handle)
    return content
end

local function boot()
    clear()
    write(2, 2, "System Starting...")

    if not computer.getBootAddress() then
        write(2, 4, "Boot Adress Not Found!")
        return
    end

    local program, reason = readFile("/Kernel/boot.lua")
    if not program then
        clear()
        write(2, 2, "Error On start Boot.lua:")
        write(2, 3, reason)
        return
    end

    local success, err = pcall(load(program))
    if not success then
        clear()
        write(2, 2, "Error When Executing Boot.lua :")
        write(2, 3, err)
        return
    end
end

boot()

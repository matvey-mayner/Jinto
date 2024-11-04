-- /Jinto Kernel/init.lua
local component = component
local computer = computer
local gpu = component.proxy(component.list("gpu")())
local screen = component.list("screen")()
gpu.bind(screen)
gpu.setResolution(50, 16)

local loadedModules = {}  -- Cache for loaded modules

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

-- Simple require implementation
local function require(moduleName)
    if loadedModules[moduleName] then
        return loadedModules[moduleName]
    end

    local path = "/" .. moduleName .. ".lua"  -- Form the file path
    local program, reason = readFile(path)
    if not program then
        error("Error loading module " .. moduleName .. ": " .. reason)
    end

    local module, err = load(program, "=" .. moduleName)
    if not module then
        error("Compilation error in module " .. moduleName .. ": " .. err)
    end

    local success, result = pcall(module)
    if not success then
        error("Execution error in module " .. moduleName .. ": " .. result)
    end

    loadedModules[moduleName] = result  -- Cache the module
    return result
end

local function dofile(path)
    local program, reason = readFile(path)
    if not program then
        error("Error loading file " .. path .. ": " .. reason)
    end

    local chunk, err = load(program, "=" .. path)
    if not chunk then
        error("Compilation error in file " .. path .. ": " .. err)
    end

    local success, result = pcall(chunk)
    if not success then
        error("Execution error in file " .. path .. ": " .. result)
    end

    return result
end

local function boot()
    clear()
    write(2, 2, "System booting...")

    if not computer.getBootAddress() then
        write(2, 4, "No boot drive address found.")
        return
    end

    local success, err = pcall(function()
        require("main")
    end)
    if not success then
        clear()
        write(2, 2, "Error running main.lua:")
        write(2, 3, err)
        return
    end
end

boot()

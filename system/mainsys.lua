-- Version 1.4.1
local component = component
local computer = computer
local fs = component.proxy(computer.getBootAddress())
local gpu = component.proxy(component.list("gpu")())
local screen = component.list("screen")()
gpu.bind(screen)
gpu.setResolution(50, 16)  -- Set screen resolution

local currentDir = "/"
local hostapt = "http://83.25.177.183/package-host/packages/"

local function clear()
    gpu.fill(1, 1, 50, 16, " ")
end

local function write(x, y, text)
    gpu.set(x, y, text)
end

local function readInput(prompt)
    write(1, 16, prompt)
    local input = ""
    while true do
        local event, _, char = computer.pullSignal()
        if event == "key_down" then
            if char == 13 then
                gpu.fill(#prompt + 1, 16, 50 - #prompt, 1, " ")
                break
            elseif char == 8 then
                if #input > 0 then
                    input = input:sub(1, -2)
                    write(#input + #prompt, 16, " ")
                end
            else
                input = input .. string.char(char)
                write(#input + #prompt, 16, string.char(char))
            end
        end
    end
    return input
end

local function resolvePath(path)
    if path:sub(1, 1) == "/" then
        return path
    else
        return currentDir .. path
    end
end

local function listDisks()
    local y = 2
    for address in component.list("filesystem") do
        local proxy = component.proxy(address)
        write(1, y, "Disk: " .. address:sub(1, 8))
        y = y + 1
        for file in proxy.list("/") do  -- Используем итератор напрямую
            write(1, y, " - " .. file)
            y = y + 1
        end
    end
end

local function ls()
    if fs.isDirectory(currentDir) then
        local items = fs.list(currentDir)  -- Получаем список файлов как таблицу
        local y = 2
        for _, item in ipairs(items) do  -- Проходим по таблице
            write(1, y, item)
            y = y + 1
        end
    else
        write(1, 15, "Error: Not a directory")
    end
end

local function cd(path)
    local newPath = resolvePath(path)
    if fs.isDirectory(newPath) then
        currentDir = newPath
        if currentDir:sub(-1) ~= "/" then
            currentDir = currentDir .. "/"
        end
    else
        write(1, 15, "Error: Directory not found")
    end
end

local function rm(path)
    local fullPath = resolvePath(path)
    if fs.exists(fullPath) then
        fs.remove(fullPath)
    else
        write(1, 15, "Error: File not found")
    end
end

local function title()
    write(1, 1, "Welcome To Jinto!")
end

local function mkdir(path)
    local fullPath = resolvePath(path)
    if not fs.exists(fullPath) then
        fs.makeDirectory(fullPath)
    else
        write(1, 15, "Error: Directory already exists")
    end
end

local function shutdown()
    computer.shutdown()
end

local function reboot()
    computer.shutdown(true)
end

local function cat(path)
    local fullPath = resolvePath(path)
    if fs.exists(fullPath) then
        local handle = fs.open(fullPath, "r")
        local y = 2
        repeat
            local data = fs.read(handle, 64)
            if data then
                write(1, y, data)
                y = y + 1
            end
        until not data
        fs.close(handle)
    else
        write(1, 15, "Error: File not found")
    end
end

local function edit(path)
    local fullPath = resolvePath(path)
    local content = ""
    if fs.exists(fullPath) then
        local handle = fs.open(fullPath, "r")
        content = fs.read(handle, fs.size(fullPath))
        fs.close(handle)
    end

    write(1, 15, "Enter new content (end with empty line):")
    local y = 2
    fs.remove(fullPath)
    local handle = fs.open(fullPath, "w")
    while true do
        local line = readInput("")
        if line == "" then break end
        fs.write(handle, line .. "\n")
        write(1, y, line)
        y = y + 1
    end
    fs.close(handle)
end

local function run(path)
    local fullPath = resolvePath(path)
    if fs.exists(fullPath) then
        local program, err = loadfile(fullPath)
        if program then
            local success, err = pcall(program)
            if not success then
                write(1, 15, "Execution error: " .. err)
            end
        else
            write(1, 15, "Load error: " .. err)
        end
    else
        write(1, 15, "Error: File not found")
    end
end

local function apt(name)
    local internet = component.list("internet")()
    if not internet then
        write(1, 15, "Error: Internet card not found")
        return
    end
    local inet = component.proxy(internet)
    local handle, err = inet.request(url)
    if not handle then
        write(1, 15, "Error: " .. err)
        return
    end

    local filename = url:match("[^/]+$")  -- Имя файла из URL
    local file = fs.open(filename, "w")
    for chunk in handle do
        fs.write(file, chunk)
    end
    fs.close(file)
    write(1, 15, "Downloaded: " .. filename)
end

local function executeCommand(command)
    local args = {}
    for word in command:gmatch("%S+") do
        table.insert(args, word)
    end

    if args[1] == "cls" then
        clear()
        title()
    elseif args[1] == "ls" then
        if args[2] == "disks" then
            listDisks()
        else
            ls()
        end
    elseif args[1] == "cd" and args[2] then
        cd(args[2])
    elseif args[1] == "rm" and args[2] then
        rm(args[2])
    elseif args[1] == "mkdir" and args[2] then
        mkdir(args[2])
    elseif args[1] == "shutdown" then
        shutdown()
    elseif args[1] == "reboot" then
        reboot()
    elseif args[1] == "cat" and args[2] then
        cat(args[2])
    elseif args[1] == "edit" and args[2] then
        edit(args[2])
    elseif args[1] == "run" and args[2] then
        run(args[2])
    elseif args[1] == "apt" and args[2] == "install" and args[3] then
        apt(hostapt/args[3])
    else
        local success, err = pcall(function()
            local result = load(command)
            if result then
                result()
            end
        end)
        if not success then
            write(1, 15, "Error: " .. err)
        end
    end
end

local function shell()
    clear()
    title()

    while true do
        write(1, 16, "> ")
        local command = readInput(currentDir .. "> ")
        executeCommand(command)
    end
end

shell()

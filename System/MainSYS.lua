-- Jinto Shell
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

local function readInput(prompt)
    write(1, 16, prompt)  -- Display prompt
    local input = ""
    while true do
        local event, _, char = computer.pullSignal()
        if event == "key_down" then
            if char == 13 then  -- Enter key
                break
            elseif char == 8 then  -- Backspace key
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

local function executeCommand(command)
    if command == "cls" then
        clear()
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

if command == "reboot" then
 write(1, 16, "rebooting...")
 computer.shutdown(true)
 break
end

local function shell()
    clear()
    write(1, 1, "Welcome to Jinto!")

    while true do
        local command = readInput("> ")
        if command == "shutdown" then
            write(1, 16, "shutdowning...")
            computer.shutdown()
            break
        end
        executeCommand(command)
    end
end

shell()

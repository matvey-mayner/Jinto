local module = {}

local hostapt = "http://83.25.177.183/package-host/packages/"
local sysupdate = "http://83.25.177.183/package-host/packages/system/mainsys.lua"

module.run = function (args)
  local type = args[2]
  if type == "install"
    apt(hostapt.. args[3])
  elseif type == "update"
    local contentnow = read("/system/bin/".. args[3].. ".lua")
    local contentnew = readweb(hostapt.. args[3])
    if contentnow ~= contentnew then
      apt(hostapt.. args[3])
    end
  end
end

local function write(x, y, text)
    gpu.set(x, y, text)
end

function read(path)
  if fs.exists(path) then
        local handle, err = fs.open(path, "r")
        if not handle then
            write(1, 15, "Error: Could not open file - " .. err .. "\n")
            return
        end

        local content = ""
        repeat
            local chunk = fs.read(handle, math.huge)  -- Читаем весь файл за один раз
            if chunk then
                content = content .. chunk
            end
        until not chunk
        fs.close(handle)
        return content
  end
end

function readweb(url)
    local internet_address = component.list("internet")()
    if not internet_address then
        return "Error: Internet card not found"
    end

    local inet = component.proxy(internet_address)

    local handle, err = inet.request(url .. ".lua")
    if not handle then
        return "Error: " .. tostring(err)
    end

    local content = ""
    while true do
        local chunk = handle.read(1024)  -- Read 1024 bytes at a time
        if not chunk then break end  -- Exit the loop if no more data
        content = content .. chunk  -- Append the chunk to the content string
    end

    handle.close()  -- Close the stream after use
    return content  -- Return the collected content
end


function apt(url)
    
    local internet_address = component.list("internet")()
    if not internet_address then
        write(1, 15, "Error: Internet card not found\n")
        return
    end
    
    local inet = component.proxy(internet_address)
    
    local handle, err = inet.request(url.. ".lua")
    if not handle then
        write(1, 15, "Error: " .. tostring(err) .. "\n")
        return
    end

    local filename = url:match("/([^/]+)$")
    if not filename then
        write(1, 15, "Error: Could not determine filename from URL\n")
        return
    end

    local file = fs.open(filename, "w")
    if not file then
        write(1, 15, "Error opening file\n")
        return
    end

    local totalBytes = 0
    while true do
        local chunk = handle.read(1024)  -- Читаем 1024 байта за раз
        if not chunk then break end  -- Если нет больше данных, выходим из цикла
        fs.write(file, chunk)
        totalBytes = totalBytes + #chunk
    end
    
    fs.close(file)
    handle.close()  -- Закрываем поток после использования
    write(1, 1, "Downloaded: " .. filename .. " (" .. totalBytes .. " bytes)\n")
end

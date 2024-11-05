local function write(x, y, text)
    local gpu = componets.proxy(components.list("gpu"))()
    gpu.set(x, y, text)
end

write(1,15,"Hello world")

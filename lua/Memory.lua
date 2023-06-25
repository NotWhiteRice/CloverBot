
Memory = {}

function Memory.readLE(ptr, length)
    local domain = ""
    local root = ptr >> 24

    ptr = ptr & 0xFFFFFF
    if root == 0 then
        domain = "BIOS"
    elseif root == 2 then
        domain = "EWRAM"
    elseif root == 3 then
        domain = "IWRAM"
    elseif root == 8 then
        domain = "ROM"
    end

    if length == 1 then
        return memory.read_u8(ptr, domain)
    elseif length == 2 then
        return memory.read_u16_le(ptr, domain)
    elseif length == 3 then
        return memory.read_u24_le(ptr, domain)
    elseif length == 4 then
        return memory.read_u32_le(ptr, domain)
    else
        local value = 0
        for i = length - 1, 0, -1 do
            value = (value << 8) + memory.read_u8(ptr + i, domain)
        end
        return value
    end
end

function Memory.readBE(ptr, length)
    local domain = ""
    local root = ptr >> 24

    ptr = ptr & 0xFFFFFF
    if root == 0 then
        domain = "BIOS"
    elseif root == 2 then
        domain = "EWRAM"
    elseif root == 3 then
        domain = "IWRAM"
    elseif root == 8 then
        domain = "ROM"
    end

    if length == 1 then
        return memory.read_u8(ptr, domain)
    elseif length == 2 then
        return memory.read_u16_be(ptr, domain)
    elseif length == 3 then
        return memory.read_u24_be(ptr, domain)
    elseif length == 4 then
        return memory.read_u32_be(ptr, domain)
    else
        local value = 0
        for i = 0, length - 1, 1 do
            value = (value << 8) + memory.read_u8(ptr + i, domain)
        end
        return value
    end
end

function Memory.readDword(ptr)
    return Memory.readLE(ptr, 4)
end

function Memory.readWord(ptr)
    return Memory.readLE(ptr, 2)
end

function Memory.readByte(ptr)
    return Memory.readLE(ptr, 1)
end
local utils = {}

function utils.readMemLE(ptr, len)
    if len == 1 then return memory.read_u8(ptr)
    elseif len == 2 then return memory.read_u16_le(ptr)
    elseif len == 3 then return memory.read_u24_le(ptr)
    elseif len == 4 then return memory.read_u32_le(ptr)
    else
        local value = 0
        for i = len - 1, 0, -1 do value = (value << 8) + memory.read_u8(ptr + i) end
        return value
    end

end


function parseMon(ptr) 
    local mon = {}
    mon.PID = utils.readMemLE(ptr, 4)
    mon.otID = utils.readMemLE(ptr + 4, 4)
    mon.key = mon.PID ~ mon.otID
    mon.TID = utils.readMemLE(ptr + 4, 2)
    mon.SID = utils.readMemLE(ptr + 6, 2)
    mon.shinyValue = mon.TID ~ mon.SID ~ (mon.PID >> 16) ~ (mon.PID % 65536)
    mon.isShiny = mon.shinyValue < 8 and 1 or 0
    mon.level = utils.readMemLE(ptr + 84, 1)
    mon.HP = utils.readMemLE(ptr + 86, 2)
    mon.totalHP = utils.readMemLE(ptr + 88, 2)
    mon.atk = utils.readMemLE(ptr + 90, 2)
    mon.def = utils.readMemLE(ptr + 92, 2)
    mon.spd = utils.readMemLE(ptr + 94, 2)
    mon.spAtk = utils.readMemLE(ptr + 96, 2)
    mon.spDef = utils.readMemLE(ptr + 98, 2)

    local substructSel = {
		[ 0] = {0, 1, 2, 3},
		[ 1] = {0, 1, 3, 2},
		[ 2] = {0, 2, 1, 3},
		[ 3] = {0, 3, 1, 2},
		[ 4] = {0, 2, 3, 1},
		[ 5] = {0, 3, 2, 1},
		[ 6] = {1, 0, 2, 3},
		[ 7] = {1, 0, 3, 2},
		[ 8] = {2, 0, 1, 3},
		[ 9] = {3, 0, 1, 2},
		[10] = {2, 0, 3, 1},
		[11] = {3, 0, 2, 1},
		[12] = {1, 2, 0, 3},
		[13] = {1, 3, 0, 2},
		[14] = {2, 1, 0, 3},
		[15] = {3, 1, 0, 2},
		[16] = {2, 3, 0, 1},
		[17] = {3, 2, 0, 1},
		[18] = {1, 2, 3, 0},
		[19] = {1, 3, 2, 0},
		[20] = {2, 1, 3, 0},
		[21] = {3, 1, 2, 0},
		[22] = {2, 3, 1, 0},
		[23] = {3, 2, 1, 0}
	}

    local substruct = substructSel[mon.PID % 24]
    local growth = utils.readMemLE(ptr + 32 + substruct[1] * 12, 12) ~ mon.key
    local attack = utils.readMemLE(ptr + 32 + substruct[2] * 12, 12) ~ mon.key
    local evCond = utils.readMemLE(ptr + 32 + substruct[3] * 12, 12) ~ mon.key
    local misc = utils.readMemLE(ptr + 32 + substruct[4] * 12, 12) ~ mon.key

    return mon

end

function getTrainer()
    local ptr = utils.readMemLE(0x0300500C, 4)
    local trainer = {}

    trainer.TID = utils.readMemLE(ptr + 10, 2)
    trainer.SID = utils.readMemLE(ptr + 12, 2)
    trainer.dir = utils.readMemLE(0x02036e50, 1) / 17
    trainer.isMoving = utils.readMemLE(0x0203707B, 1)
    trainer.isWalking = utils.readMemLE(0x0203707A, 1)
    return trainer
end

function getParty()
    local party = {}
    local start = 0x02024284
    local partyCount = utils.readMemLE(0x02024029, 1)

    for i = 1, partyCount do
        party[i] = parseMon(start)
        start = start + 100
    end

    return party
end

local iter = 0
local resets = 0
local chance = 819100 / 8192
function main()
    local trainer = getTrainer()
    local party = getParty()
    gui.text(3, 3, "Resets: "..resets)
    gui.text(3, 23, "Odds (%): "..(100 - chance))
    if utils.readMemLE(0x02024029, 1) > 0 then
        if party[1]["isShiny"] == 0 then
            local btn = input.get()
            btn["Power"] = true
            joypad.set(btn)
            resets = resets + 1
            chance = chance * 8191 / 8192
        end
    else
        if iter == 0 then
            local btn = input.get()
            btn["A"] = true
            joypad.set(btn)
            iter = 1
        else 
            local btn = input.get()
            btn["A"] = false
            joypad.set(btn)
            iter = 0
        end
    end
end

event.onframestart(main)
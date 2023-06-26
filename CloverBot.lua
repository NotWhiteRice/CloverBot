local utils = {}

function utils.translatePath(path)
    local separator = package.config:sub(1, 1)
    local out = string.gsub(path, "\\", separator)
    return out == nil and path or out
end

dofile (utils.translatePath("lua\\Memory.lua"))
dofile (utils.translatePath("lua\\Invocation.lua"))

GameSettings.init()

console.log("Lua version: ".._VERSION)
package.path = utils.translatePath(";.\\lua\\?.lua;")

--json = require "Json"
--pokemonList = require "PokemonList"

--etc.

function parseMon(ptr) 
    local mon = {}
    mon.hasAnomaly = false
    mon.PID = Memory.readDword(ptr)
    mon.otID = Memory.readDword(ptr + 4)
    mon.TID = Memory.readWord(ptr + 4)
    mon.SID = Memory.readWord(ptr + 6)
    mon.key = mon.PID ~ mon.otID
    mon.lang = Memory.readByte(ptr + 18)
    local eggFlags = Memory.readByte(ptr + 19)
    mon.isBadEgg = eggFlags & 1
    mon.hasSpecies = (eggFlags >> 1) & 1
    mon.isEgg = (eggFlags >> 2) & 1
    mon.markings = Memory.readByte(ptr + 27)
    mon.unknown0 = Memory.readWord(ptr + 30)
    mon.status = Memory.readDword(ptr + 80)
    mon.level = Memory.readByte(ptr + 84)
    mon.pkrsTimer = Memory.readByte(ptr + 85)
    mon.HP = Memory.readWord(ptr + 86)
    mon.totalHP = Memory.readWord(ptr + 88)
    mon.atk = Memory.readWord(ptr + 90)
    mon.def = Memory.readWord(ptr + 92)
    mon.spd = Memory.readWord(ptr + 94)
    mon.spAtk = Memory.readWord(ptr + 96)
    mon.spDef = Memory.readWord(ptr + 98)

    local ssList = {
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

    local ss = ssList[mon.PID % 24]
    local growth = {}
    local attacks = {}
    local evCond = {}
    local misc = {}

    for i = 0, 2 do
        growth[i] = Memory.readDword(ptr + 32 + ss[1] * 12 + i * 4) ~ mon.key
        attacks[i] = Memory.readDword(ptr + 32 + ss[2] * 12 + i * 4) ~ mon.key
        evCond[i] = Memory.readDword(ptr + 32 + ss[3] * 12 + i * 4) ~ mon.key
        misc[i] = Memory.readDword(ptr + 32 + ss[4] * 12 + i * 4) ~ mon.key
    end

    mon.species = (growth[0] & 0xFFFF)
    mon.heldItem = growth[0] >> 16
    mon.exp = growth[1]
    mon.ppBonuses = growth[2] & 0xFF
    mon.friendship = (growth[2] >> 8) & 0xFF
    mon.unknown1 = growth[2] >> 16
    mon.isShiny = (mon.unknown1 >> 8) & 1

    mon.moves = {
        attacks[0] & 0xFFFF,
        attacks[0] >> 16,
        attacks[1] & 0xFFFF,
        attacks[1] >> 16
    }
    mon.pp = {
        attacks[2] & 0xFF,
        (attacks[2] >> 8) & 0xFF,
        (attacks[2] >> 16) & 0xFF,
        attacks[2] >> 24
    }

    mon.hpEV = evCond[0] & 0xFF
    mon.atkEV = (evCond[0] >> 8) & 0xFF
    mon.defEV = (evCond[0] >> 16) & 0xFF
    mon.spdEV = evCond[0] >> 24
    mon.spAtkEV = evCond[1] & 0xFF
    mon.spDefEV = (evCond[1] >> 8) & 0xFF
    mon.unknown2 = ((evCond[1] >> 16) & 0xFF) << 32 + evCond[2]

    mon.pokerus = misc[0] & 0xFF
    mon.metLocation = (misc[0] >> 8) & 0xFF
    mon.originData = misc[0] >> 16
    local ivFlags = misc[1]
    mon.hpIV = ivFlags & 0x1F
    mon.atkIV = (ivFlags >> 5) & 0x1F
    mon.defIV = (ivFlags >> 10) & 0x1F
    mon.spdIV = (ivFlags >> 15) & 0x1F
    mon.spAtkIV = (ivFlags >> 20) & 0x1F
    mon.spDefIV = (ivFlags >> 25) & 0x1F
    mon.altAbility = (ivFlags >> 31) & 0x1F
    mon.unknown3 = misc[2]

    return mon
end

function getTrainer()
    local ptr = Memory.readDword(0x0300500C)
    local trainer = {}

    trainer.TID = Memory.readWord(ptr + 10)
    trainer.SID = Memory.readWord(ptr + 12)
    trainer.dir = Memory.readByte(0x02036e50) / 17
    trainer.isMoving = Memory.readByte(0x0203707B)
    trainer.isWalking = Memory.readByte(0x0203707A)
    return trainer
end

function getParty()
    local party = {}
    local start = 0x02024284
    local partyCount = Memory.readByte(0x02024029)

    for i = 1, partyCount do
        party[i] = parseMon(start)
        start = start + 100
    end

    return party
end

function getData()
    local data = {}
    data.frameCount = emu.framecount()
    data.fps = client.get_approx_framerate()

    return data
end

local iter = 0
function main()
    local trainer = getTrainer()
    local party = getParty()

    if Memory.readByte(0x02024029) > 0 then
        if party[1]["isShiny"] == 0 and party[1]["hasAnomaly"] == false then
            local btn = input.get()
            btn["Power"] = true
            joypad.set(btn)
        end
    else
        if iter == 0 then
            if math.random(1, 10) == 2 then
                local btn = input.get()
                btn["A"] = true
                joypad.set(btn)
                iter = 1
            end
        else 
            local btn = input.get()
            btn["A"] = false
            joypad.set(btn)
            iter = 0
        end
    end
end

event.onframestart(main)
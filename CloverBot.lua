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
    mon.shinyValue = mon.TID ~ mon.SID ~ (mon.PID >> 16) ~ (mon.PID % 65536)
    mon.isShiny = mon.shinyValue < 8 and 1 or 0
    mon.lang = Memory.readByte(ptr + 18)
    mon.hasAnomaly = mon.hasAnomaly or mon.lang ~= 2
    local eggFlags = Memory.readByte(ptr + 19)
    mon.hasAnomaly = mon.hasAnomaly or eggFlags ~= 2
    mon.isBadEgg = eggFlags & 1
    mon.hasSpecies = (eggFlags >> 1) & 1
    mon.isEgg = (eggFlags >> 2) & 1
    mon.markings = Memory.readByte(ptr + 27)
    mon.hasAnomaly = mon.hasAnomaly or mon.markings ~= 0
    mon.unknown0 = Memory.readWord(ptr + 30)
    mon.hasAnomaly = mon.hasAnomaly or mon.unknown0 ~= 0
    mon.status = Memory.readDword(ptr + 80)
    mon.hasAnomaly = mon.hasAnomaly or mon.status ~= 0
    mon.level = Memory.readByte(ptr + 84)
    mon.hasAnomaly = mon.hasAnomaly or mon.level ~= 5
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
    mon.hasAnomaly = mon.hasAnomaly or mon.species ~= 4
    mon.heldItem = growth[0] >> 16
    mon.hasAnomaly = mon.hasAnomaly or mon.heldItem ~= 0
    mon.exp = growth[1]
    mon.hasAnomaly = mon.hasAnomaly or mon.exp ~= 135
    mon.ppBonuses = growth[2] & 0xFF
    mon.hasAnomaly = mon.hasAnomaly or mon.ppBonuses ~= 0
    mon.friendship = (growth[2] >> 8) & 0xFF
    mon.hasAnomaly = mon.hasAnomaly or mon.friendship ~= 70
    mon.unknown1 = growth[2] >> 16
    mon.hasAnomaly = mon.hasAnomaly or mon.unknown1 ~= 0

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
    mon.hasAnomaly = mon.hasAnomaly or mon.hpEV ~= 0
    mon.atkEV = (evCond[0] >> 8) & 0xFF
    mon.hasAnomaly = mon.hasAnomaly or mon.atkEV ~= 0
    mon.defEV = (evCond[0] >> 16) & 0xFF
    mon.hasAnomaly = mon.hasAnomaly or mon.defEV ~= 0
    mon.spdEV = evCond[0] >> 24
    mon.hasAnomaly = mon.hasAnomaly or mon.spdEV ~= 0
    mon.spAtkEV = evCond[1] & 0xFF
    mon.hasAnomaly = mon.hasAnomaly or mon.spAtkEV ~= 0
    mon.spDefEV = (evCond[1] >> 8) & 0xFF
    mon.hasAnomaly = mon.hasAnomaly or mon.spDefEV ~= 0
    mon.unknown2 = ((evCond[1] >> 16) & 0xFF) << 32 + evCond[2]
    mon.hasAnomaly = mon.hasAnomaly or mon.unknown2 ~= 0

    mon.pokerus = misc[0] & 0xFF
    mon.hasAnomaly = mon.hasAnomaly or (mon.pokerus == 0 and mon.pkrsTimer ~= 255)
    mon.metLocation = (misc[0] >> 8) & 0xFF
    mon.originData = misc[0] >> 16
    mon.hasAnomaly = mon.hasAnomaly or mon.originData ~= 37381
    local ivFlags = misc[1]
    mon.hpIV = ivFlags & 0x1F
    mon.atkIV = (ivFlags >> 5) & 0x1F
    mon.defIV = (ivFlags >> 10) & 0x1F
    mon.spdIV = (ivFlags >> 15) & 0x1F
    mon.spAtkIV = (ivFlags >> 20) & 0x1F
    mon.spDefIV = (ivFlags >> 25) & 0x1F
    mon.altAbility = (ivFlags >> 31) & 0x1F
    mon.hasAnomaly = mon.hasAnomaly or mon.altAbility ~= 0
    mon.unknown3 = misc[2]
    mon.hasAnomaly = mon.hasAnomaly or mon.unknown3 ~= 2147483648

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
local resets = 0
local chance = 819100 / 8192
local lowest = 65536
local highest = 0
local previous = 0
function main()
    local trainer = getTrainer()
    local party = getParty()
    gui.text(3, 3, "Resets: "..resets)
    gui.text(3, 23, "Odds (%): "..(100 - chance))
    gui.text(3, 43, "Lowest SV: "..lowest)
    gui.text(3, 63, "Most recent SV: "..previous)
    gui.text(3, 83, "Highest SV: "..highest)

    if Memory.readByte(0x02024029) > 0 then
        previous = party[1]["shinyValue"]
        if(party[1]["shinyValue"] > highest) then
            highest = party[1]["shinyValue"]
        end
        if(party[1]["shinyValue"] < lowest) then
            lowest = party[1]["shinyValue"]
        end

        if party[1]["isShiny"] == 0 and party[1]["hasAnomaly"] == false then
            previous = party[1]["shinyValue"]
            local btn = input.get()
            btn["Power"] = true
            joypad.set(btn)
            resets = resets + 1
            chance = chance * 8191 / 8192
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
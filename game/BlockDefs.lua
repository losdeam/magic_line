-- [ts]: BlockDefs.ts
local ____lualib = require("lualib_bundle") -- 1
local __TS__Class = ____lualib.__TS__Class -- 1
local ____exports = {} -- 1
local ____Config = require("game.Config") -- 4
local Config = ____Config.Config -- 4
local ____Effects = require("game.Effects") -- 5
local makeRule = ____Effects.makeRule -- 5
____exports.BlockDefs = __TS__Class() -- 19
local BlockDefs = ____exports.BlockDefs -- 19
BlockDefs.name = "BlockDefs" -- 19
function BlockDefs.prototype.____constructor(self) -- 19
end -- 19
function BlockDefs.count(self) -- 96
	return #____exports.BlockDefs.List -- 97
end -- 96
function BlockDefs.placeableCount(self) -- 101
	local count = 0 -- 102
	for ____, def in ipairs(____exports.BlockDefs.List) do -- 103
		if def.placeable then -- 103
			count = count + 1 -- 105
		end -- 105
	end -- 105
	return count -- 108
end -- 101
function BlockDefs.isPlaceable(self, index) -- 112
	if index < 0 or index >= #____exports.BlockDefs.List then -- 112
		return false -- 114
	end -- 114
	return ____exports.BlockDefs.List[index + 1].placeable -- 116
end -- 112
function BlockDefs.lockedIndex(self) -- 120
	return ____exports.BlockDefs:indexOf(____exports.BlockDefs.Blocked) -- 121
end -- 120
function BlockDefs.at(self, index) -- 124
	local list = ____exports.BlockDefs.List -- 125
	if index <= 0 then -- 125
		return list[1] -- 127
	end -- 127
	if index >= #list then -- 127
		return list[#list] -- 130
	end -- 130
	return list[index + 1] -- 132
end -- 124
function BlockDefs.indexOf(self, id) -- 136
	local list = ____exports.BlockDefs.List -- 137
	do -- 137
		local i = 0 -- 138
		while i < #list do -- 138
			if list[i + 1].id == id then -- 138
				return i -- 140
			end -- 140
			i = i + 1 -- 138
		end -- 138
	end -- 138
	return -1 -- 143
end -- 136
function BlockDefs.find(self, id) -- 146
	local index = ____exports.BlockDefs:indexOf(id) -- 147
	if index < 0 then -- 147
		return nil -- 149
	end -- 149
	return ____exports.BlockDefs.List[index + 1] -- 151
end -- 146
BlockDefs.Physical = "physical" -- 146
BlockDefs.Magic = "magic" -- 146
BlockDefs.Status = "status" -- 146
BlockDefs.Heal = "heal" -- 146
BlockDefs.Blocked = "blocked" -- 146
BlockDefs.List = { -- 146
	{ -- 29
		id = ____exports.BlockDefs.Physical, -- 30
		color = 14833484, -- 31
		glyph = "物", -- 32
		placeable = true, -- 33
		rules = { -- 34
			makeRule("physicalDamage", "currentEnemy", 4, 3), -- 35
			makeRule( -- 37
				"debuffArmor", -- 37
				"currentEnemy", -- 37
				1, -- 37
				0, -- 37
				6 -- 37
			), -- 37
			makeRule( -- 39
				"physicalDamage", -- 39
				"allEnemies", -- 39
				2, -- 39
				1, -- 39
				8 -- 39
			), -- 39
			makeRule( -- 41
				"manaGain", -- 41
				"self", -- 41
				1, -- 41
				3, -- 41
				Config.MinChainLength, -- 41
				0, -- 41
				false -- 41
			) -- 41
		} -- 41
	}, -- 41
	{ -- 44
		id = ____exports.BlockDefs.Magic, -- 45
		color = 3898336, -- 46
		glyph = "法", -- 47
		placeable = true, -- 48
		rules = { -- 49
			makeRule("magicDamage", "currentEnemy", 3, 3), -- 50
			makeRule( -- 52
				"magicDamage", -- 52
				"allEnemies", -- 52
				1, -- 52
				1, -- 52
				6 -- 52
			), -- 52
			makeRule( -- 54
				"buffDamage", -- 54
				"self", -- 54
				1, -- 54
				0, -- 54
				8 -- 54
			), -- 54
			makeRule( -- 55
				"manaGain", -- 55
				"self", -- 55
				1, -- 55
				3, -- 55
				Config.MinChainLength, -- 55
				0, -- 55
				false -- 55
			) -- 55
		} -- 55
	}, -- 55
	{ -- 58
		id = ____exports.BlockDefs.Status, -- 59
		color = 10181072, -- 60
		glyph = "状", -- 61
		placeable = true, -- 62
		rules = { -- 63
			makeRule( -- 65
				"buffDamage", -- 65
				"self", -- 65
				0, -- 65
				0.5, -- 65
				Config.MinChainLength, -- 65
				1 -- 65
			), -- 65
			makeRule( -- 67
				"debuffArmor", -- 67
				"currentEnemy", -- 67
				1, -- 67
				0, -- 67
				4, -- 67
				0 -- 67
			), -- 67
			makeRule( -- 69
				"buffDamage", -- 69
				"self", -- 69
				1, -- 69
				0, -- 69
				8 -- 69
			), -- 69
			makeRule( -- 70
				"manaGain", -- 70
				"self", -- 70
				1, -- 70
				3, -- 70
				Config.MinChainLength, -- 70
				0, -- 70
				false -- 70
			) -- 70
		} -- 70
	}, -- 70
	{ -- 73
		id = ____exports.BlockDefs.Heal, -- 74
		color = 4633190, -- 75
		glyph = "治", -- 76
		placeable = true, -- 77
		rules = { -- 78
			makeRule("heal", "self", 3, 2), -- 79
			makeRule( -- 81
				"dispel", -- 81
				"self", -- 81
				1, -- 81
				0, -- 81
				4, -- 81
				0 -- 81
			), -- 81
			makeRule( -- 83
				"shield", -- 83
				"self", -- 83
				2, -- 83
				1, -- 83
				8 -- 83
			), -- 83
			makeRule( -- 84
				"manaGain", -- 84
				"self", -- 84
				1, -- 84
				3, -- 84
				Config.MinChainLength, -- 84
				0, -- 84
				false -- 84
			) -- 84
		} -- 84
	}, -- 84
	{ -- 87
		id = ____exports.BlockDefs.Blocked, -- 88
		color = 5922667, -- 89
		glyph = "锁", -- 90
		placeable = false, -- 91
		rules = {} -- 92
	} -- 92
} -- 92
return ____exports -- 92
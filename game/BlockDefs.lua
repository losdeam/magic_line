-- [ts]: BlockDefs.ts
local ____lualib = require("lualib_bundle") -- 1
local __TS__Class = ____lualib.__TS__Class -- 1
local ____exports = {} -- 1
local ____Effects = require("game.Effects") -- 4
local makeRule = ____Effects.makeRule -- 4
____exports.BlockDefs = __TS__Class() -- 18
local BlockDefs = ____exports.BlockDefs -- 18
BlockDefs.name = "BlockDefs" -- 18
function BlockDefs.prototype.____constructor(self) -- 18
end -- 18
function BlockDefs.count(self) -- 82
	return #____exports.BlockDefs.List -- 83
end -- 82
function BlockDefs.placeableCount(self) -- 87
	local count = 0 -- 88
	for ____, def in ipairs(____exports.BlockDefs.List) do -- 89
		if def.placeable then -- 89
			count = count + 1 -- 91
		end -- 91
	end -- 91
	return count -- 94
end -- 87
function BlockDefs.isPlaceable(self, index) -- 98
	if index < 0 or index >= #____exports.BlockDefs.List then -- 98
		return false -- 100
	end -- 100
	return ____exports.BlockDefs.List[index + 1].placeable -- 102
end -- 98
function BlockDefs.lockedIndex(self) -- 106
	return ____exports.BlockDefs:indexOf(____exports.BlockDefs.Blocked) -- 107
end -- 106
function BlockDefs.at(self, index) -- 110
	local list = ____exports.BlockDefs.List -- 111
	if index <= 0 then -- 111
		return list[1] -- 113
	end -- 113
	if index >= #list then -- 113
		return list[#list] -- 116
	end -- 116
	return list[index + 1] -- 118
end -- 110
function BlockDefs.indexOf(self, id) -- 122
	local list = ____exports.BlockDefs.List -- 123
	do -- 123
		local i = 0 -- 124
		while i < #list do -- 124
			if list[i + 1].id == id then -- 124
				return i -- 126
			end -- 126
			i = i + 1 -- 124
		end -- 124
	end -- 124
	return -1 -- 129
end -- 122
function BlockDefs.find(self, id) -- 132
	local index = ____exports.BlockDefs:indexOf(id) -- 133
	if index < 0 then -- 133
		return nil -- 135
	end -- 135
	return ____exports.BlockDefs.List[index + 1] -- 137
end -- 132
BlockDefs.Physical = "physical" -- 132
BlockDefs.Magic = "magic" -- 132
BlockDefs.Status = "status" -- 132
BlockDefs.Heal = "heal" -- 132
BlockDefs.Blocked = "blocked" -- 132
BlockDefs.List = { -- 132
	{ -- 28
		id = ____exports.BlockDefs.Physical, -- 29
		color = 14833484, -- 30
		glyph = "物", -- 31
		placeable = true, -- 32
		rules = { -- 33
			makeRule("physicalDamage", "currentEnemy", 4, 3), -- 34
			makeRule("manaGain", "self", 1, 3) -- 35
		} -- 35
	}, -- 35
	{ -- 38
		id = ____exports.BlockDefs.Magic, -- 39
		color = 3898336, -- 40
		glyph = "法", -- 41
		placeable = true, -- 42
		rules = { -- 43
			makeRule("magicDamage", "currentEnemy", 3, 3), -- 44
			makeRule("manaGain", "self", 1, 3) -- 45
		} -- 45
	}, -- 45
	{ -- 48
		id = ____exports.BlockDefs.Status, -- 49
		color = 10181072, -- 50
		glyph = "状", -- 51
		placeable = true, -- 52
		rules = { -- 53
			makeRule( -- 55
				"buffDamage", -- 55
				"self", -- 55
				0, -- 55
				0.5, -- 55
				3, -- 55
				1 -- 55
			), -- 55
			makeRule( -- 57
				"debuffArmor", -- 57
				"currentEnemy", -- 57
				1, -- 57
				0, -- 57
				5, -- 57
				0 -- 57
			), -- 57
			makeRule("manaGain", "self", 1, 3) -- 58
		} -- 58
	}, -- 58
	{ -- 61
		id = ____exports.BlockDefs.Heal, -- 62
		color = 4633190, -- 63
		glyph = "治", -- 64
		placeable = true, -- 65
		rules = { -- 66
			makeRule("heal", "self", 3, 2), -- 67
			makeRule( -- 69
				"dispel", -- 69
				"self", -- 69
				1, -- 69
				0, -- 69
				5, -- 69
				0 -- 69
			), -- 69
			makeRule("manaGain", "self", 1, 3) -- 70
		} -- 70
	}, -- 70
	{ -- 73
		id = ____exports.BlockDefs.Blocked, -- 74
		color = 5922667, -- 75
		glyph = "锁", -- 76
		placeable = false, -- 77
		rules = {} -- 78
	} -- 78
} -- 78
return ____exports -- 78
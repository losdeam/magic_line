-- [ts]: Skills.ts
local ____lualib = require("lualib_bundle") -- 1
local __TS__Class = ____lualib.__TS__Class -- 1
local ____exports = {} -- 1
--- 构造一条效果三元组（技能多为固定数值，因此无需链长规则）。
function ____exports.makeSpec(kind, value, target) -- 14
	return {kind = kind, value = value, target = target} -- 15
end -- 14
--- 技能用于应对难以消除的局面：重排棋盘 / 引爆场上最大连通块。
____exports.Skills = __TS__Class() -- 19
local Skills = ____exports.Skills -- 19
Skills.name = "Skills" -- 19
function Skills.prototype.____constructor(self) -- 19
end -- 19
function Skills.count(self) -- 38
	return #____exports.Skills.List -- 39
end -- 38
function Skills.find(self, id) -- 42
	for ____, def in ipairs(____exports.Skills.List) do -- 43
		if def.id == id then -- 43
			return def -- 45
		end -- 45
	end -- 45
	return nil -- 48
end -- 42
Skills.Shuffle = "shuffle" -- 42
Skills.Blast = "blast" -- 42
Skills.List = { -- 42
	{ -- 24
		id = ____exports.Skills.Shuffle, -- 25
		name = "重排棋盘", -- 26
		cost = 20, -- 27
		effects = {____exports.makeSpec("boardShuffle", 1, "board")} -- 28
	}, -- 28
	{ -- 30
		id = ____exports.Skills.Blast, -- 31
		name = "引爆最大块", -- 32
		cost = 35, -- 33
		effects = {____exports.makeSpec("boardBlast", 1, "board")} -- 34
	} -- 34
} -- 34
return ____exports -- 34
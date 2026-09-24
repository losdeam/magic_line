-- [ts]: ChainTiers.ts
local ____lualib = require("lualib_bundle") -- 1
local __TS__Class = ____lualib.__TS__Class -- 1
local ____exports = {} -- 1
local ____Config = require("game.Config") -- 4
local Config = ____Config.Config -- 4
--- 链长档位注册表：解析器只查表取倍率，不含任何按档位的分支。
____exports.ChainTiers = __TS__Class() -- 20
local ChainTiers = ____exports.ChainTiers -- 20
ChainTiers.name = "ChainTiers" -- 20
function ChainTiers.prototype.____constructor(self) -- 20
end -- 20
function ChainTiers.count(self) -- 37
	return #____exports.ChainTiers.List -- 38
end -- 37
function ChainTiers.tierOf(self, chainLength) -- 42
	local list = ____exports.ChainTiers.List -- 43
	for ____, tier in ipairs(list) do -- 44
		if chainLength >= tier.minChain and chainLength <= tier.maxChain then -- 44
			return tier -- 46
		end -- 46
	end -- 46
	if chainLength < list[1].minChain then -- 46
		return list[1] -- 50
	end -- 50
	return list[#list] -- 52
end -- 42
function ChainTiers.multiplierOf(self, chainLength) -- 56
	return ____exports.ChainTiers:tierOf(chainLength).multiplier -- 57
end -- 56
function ChainTiers.nameOf(self, chainLength) -- 61
	return ____exports.ChainTiers:tierOf(chainLength).name -- 62
end -- 61
function ChainTiers.isStrictlyIncreasing(self) -- 66
	local list = ____exports.ChainTiers.List -- 67
	if #list == 0 then -- 67
		return false -- 69
	end -- 69
	do -- 69
		local i = 0 -- 71
		while i < #list do -- 71
			do -- 71
				if list[i + 1].maxChain < list[i + 1].minChain then -- 71
					return false -- 73
				end -- 73
				if i == 0 then -- 73
					goto __continue14 -- 76
				end -- 76
				if list[i + 1].multiplier <= list[i].multiplier then -- 76
					return false -- 79
				end -- 79
				if list[i + 1].minChain ~= list[i].maxChain + 1 then -- 79
					return false -- 82
				end -- 82
			end -- 82
			::__continue14:: -- 82
			i = i + 1 -- 71
		end -- 71
	end -- 71
	return true -- 85
end -- 66
function ChainTiers.describeAll(self) -- 89
	local parts = {} -- 90
	for ____, tier in ipairs(____exports.ChainTiers.List) do -- 91
		local upper = tier.maxChain >= ____exports.ChainTiers.NoLimit and "+" or "-" .. tostring(tier.maxChain) -- 92
		parts[#parts + 1] = ((((tostring(tier.minChain) .. upper) .. " ") .. tier.name) .. "×") .. tostring(tier.multiplier) -- 93
	end -- 93
	return table.concat(parts, " / ") -- 95
end -- 89
ChainTiers.Contact = "contact" -- 89
ChainTiers.Combo = "combo" -- 89
ChainTiers.Resonance = "resonance" -- 89
ChainTiers.Overload = "overload" -- 89
ChainTiers.NoLimit = 9999 -- 89
ChainTiers.List = {{ -- 89
	id = ____exports.ChainTiers.Contact, -- 31
	name = "接触", -- 31
	minChain = Config.MinChainLength, -- 31
	maxChain = Config.MinChainLength + 1, -- 31
	multiplier = 1 -- 31
}, { -- 31
	id = ____exports.ChainTiers.Combo, -- 32
	name = "连击", -- 32
	minChain = 4, -- 32
	maxChain = 5, -- 32
	multiplier = 1.25 -- 32
}, { -- 32
	id = ____exports.ChainTiers.Resonance, -- 33
	name = "共鸣", -- 33
	minChain = 6, -- 33
	maxChain = 7, -- 33
	multiplier = 1.6 -- 33
}, { -- 33
	id = ____exports.ChainTiers.Overload, -- 34
	name = "超载", -- 34
	minChain = 8, -- 34
	maxChain = ____exports.ChainTiers.NoLimit, -- 34
	multiplier = 2.1 -- 34
}} -- 34
return ____exports -- 34
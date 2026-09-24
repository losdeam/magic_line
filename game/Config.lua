-- [ts]: Config.ts
local ____lualib = require("lualib_bundle") -- 1
local __TS__Class = ____lualib.__TS__Class -- 1
local ____exports = {} -- 1
--- 全局配置表。所有可调数值集中在这里，便于手感快速调参。
____exports.Config = __TS__Class() -- 30
local Config = ____exports.Config -- 30
Config.name = "Config" -- 30
function Config.prototype.____constructor(self) -- 30
end -- 30
function Config.wave(self, index) -- 116
	local list = ____exports.Config.Waves -- 117
	if index < 0 or index >= #list then -- 117
		return list[#list] -- 119
	end -- 119
	return list[index + 1] -- 121
end -- 116
function Config.difficultyScale(self, difficulty) -- 124
	local scale = ____exports.Config.DifficultyScales[difficulty] -- 125
	if scale == nil then -- 125
		return 1 -- 127
	end -- 127
	return scale -- 129
end -- 124
function Config.stageEnemyScale(self, stage) -- 133
	local scale = 1 -- 134
	do -- 134
		local i = 1 -- 135
		while i < stage do -- 135
			scale = scale * ____exports.Config.StageEnemyScale -- 136
			i = i + 1 -- 135
		end -- 135
	end -- 135
	return scale -- 138
end -- 133
Config.DesignSceneHeight = 1080 -- 133
Config.DesignSceneWidth = 960 -- 133
Config.Columns = 7 -- 133
Config.Rows = 7 -- 133
Config.CellSize = 104 -- 133
Config.CellGap = 6 -- 133
Config.BoardCenterY = -120 -- 133
Config.NoticeY = 150 -- 133
Config.NoticeEnemyX = -190 -- 133
Config.NoticeEnemyY = 176 -- 133
Config.NoticePlayerX = 190 -- 133
Config.NoticePlayerY = -430 -- 133
Config.NoticeSystemX = 0 -- 133
Config.NoticeSystemY = -120 -- 133
Config.HitFlashDuration = 0.24 -- 133
Config.PlayerHitTintAlpha = 90 -- 133
Config.MinChainLength = 2 -- 133
Config.MaxGroupSize = 5 -- 133
Config.GroupSizeRelaxLimit = 7 -- 133
Config.CellColorRetries = 12 -- 133
Config.BoardRefillRetries = 24 -- 133
Config.RefillFallbackRetries = 8 -- 133
Config.MaxFrameDelta = 0.1 -- 133
Config.PlayerMaxHp = 100 -- 133
Config.MaxMana = 100 -- 133
Config.BoardResetPenalty = 8 -- 133
Config.EliteHeavyBlockCells = 2 -- 133
Config.LockDurationActions = 2 -- 133
Config.BuffDamagePerStack = 0.15 -- 133
Config.DebuffArmorPerStack = 0.2 -- 133
Config.BuffDurationTurns = 2 -- 133
Config.DebuffDurationTurns = 2 -- 133
Config.MagicShieldBonus = 0.5 -- 133
Config.MinDamage = 1 -- 133
Config.StageClearHealRatio = 0.3 -- 133
Config.StageEnemyScale = 1.25 -- 133
Config.StageWaveCount = 3 -- 133
Config.DifficultyScales = {casual = 0.8, standard = 1, hard = 1.3} -- 133
Config.Waves = {{ -- 133
	name = "小怪", -- 110
	isElite = false, -- 110
	hp = 40, -- 110
	attack = 8, -- 110
	heavyAttack = 0, -- 110
	armor = 4, -- 110
	actionTurns = 3, -- 110
	actionSeconds = 5 -- 110
}, { -- 110
	name = "小怪", -- 111
	isElite = false, -- 111
	hp = 60, -- 111
	attack = 10, -- 111
	heavyAttack = 0, -- 111
	armor = 6, -- 111
	actionTurns = 3, -- 111
	actionSeconds = 4 -- 111
}, { -- 111
	name = "精英", -- 112
	isElite = true, -- 112
	hp = 120, -- 112
	attack = 14, -- 112
	heavyAttack = 24, -- 112
	armor = 10, -- 112
	actionTurns = 2, -- 112
	actionSeconds = 3 -- 112
}} -- 112
return ____exports -- 112
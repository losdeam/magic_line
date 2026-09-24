-- [ts]: Combat.ts
local ____lualib = require("lualib_bundle") -- 1
local __TS__Class = ____lualib.__TS__Class -- 1
local __TS__SetDescriptor = ____lualib.__TS__SetDescriptor -- 1
local ____exports = {} -- 1
local ____Config = require("game.Config") -- 5
local Config = ____Config.Config -- 5
local ____Effects = require("game.Effects") -- 6
local applyDamage = ____Effects.applyDamage -- 6
local executeEffects = ____Effects.executeEffects -- 6
local makeActor = ____Effects.makeActor -- 6
local ____Skills = require("game.Skills") -- 7
local Skills = ____Skills.Skills -- 7
____exports.Combat = __TS__Class() -- 21
local Combat = ____exports.Combat -- 21
Combat.name = "Combat" -- 21
function Combat.prototype.____constructor(self, board) -- 39
	self.resetCount = 0 -- 26
	self.waveIndex = 0 -- 27
	self.stage = 1 -- 28
	self.difficultyScale = 1 -- 29
	self.realtime = false -- 30
	self.realtimeTimer = 0 -- 31
	self.charged = false -- 33
	self.lastAction = "attack" -- 35
	self.expiredLockCount = 0 -- 37
	self.board = board -- 40
	self.player = makeActor(Config.PlayerMaxHp, 0, Config.MaxMana) -- 41
	local wave = Config:wave(0) -- 42
	self.enemy = makeActor(wave.hp, wave.armor, 0) -- 43
	self.enemies = {self.enemy} -- 44
	self:loadWave() -- 45
end -- 39
function Combat.prototype.currentWave(self) -- 73
	return Config:wave(self.waveIndex) -- 74
end -- 73
function Combat.prototype.setRealtime(self, on) -- 98
	self.realtime = on -- 99
	self:resetTimer() -- 100
end -- 98
function Combat.prototype.resetTimer(self) -- 103
	self.realtimeTimer = self.enemyIntervalSeconds -- 104
end -- 103
function Combat.prototype.advanceTime(self, dt) -- 111
	if not self.realtime then -- 111
		return false -- 113
	end -- 113
	self.realtimeTimer = self.realtimeTimer - dt -- 115
	if self.realtimeTimer > 0 then -- 115
		return false -- 117
	end -- 117
	self:resetTimer() -- 119
	return true -- 120
end -- 111
function Combat.prototype.setDifficultyScale(self, scale) -- 123
	self.difficultyScale = scale -- 124
end -- 123
function Combat.prototype.loadWave(self) -- 128
	local wave = Config:wave(self.waveIndex) -- 129
	local scale = self.difficultyScale * Config:stageEnemyScale(self.stage) -- 130
	self.enemy.maxHp = math.floor(wave.hp * scale + 0.5) -- 131
	self.enemy.hp = self.enemy.maxHp -- 132
	self.enemy.shield = 0 -- 133
	self.enemy.armor = wave.armor -- 134
	self.enemy.debuffStacks = 0 -- 135
	self.charged = false -- 137
	self.lastAction = "attack" -- 138
	self:resetTimer() -- 139
end -- 128
function Combat.prototype.enemyAct(self) -- 162
	self.expiredLockCount = self.board:expireLocks() -- 165
	local wave = Config:wave(self.waveIndex) -- 166
	local scale = self.difficultyScale * Config:stageEnemyScale(self.stage) -- 167
	if wave.isElite then -- 167
		if not self.charged then -- 167
			self.charged = true -- 170
			self.lastAction = "charge" -- 171
			return 0 -- 172
		end -- 172
		self.charged = false -- 174
		self.lastAction = "heavy" -- 175
		local block = {kind = "boardBlock", value = Config.EliteHeavyBlockCells, target = "board"} -- 176
		self:applySpecs({block}) -- 181
		return applyDamage(self.player, wave.heavyAttack * scale) -- 182
	end -- 182
	self.lastAction = "attack" -- 184
	return applyDamage(self.player, wave.attack * scale) -- 185
end -- 162
function Combat.prototype.advanceWave(self) -- 189
	self.waveIndex = self.waveIndex + 1 -- 190
	if self.waveIndex >= Config.StageWaveCount then -- 190
		return true -- 192
	end -- 192
	self:loadWave() -- 194
	return false -- 195
end -- 189
function Combat.prototype.nextStage(self) -- 199
	self.stage = self.stage + 1 -- 200
	self.waveIndex = 0 -- 201
	self:loadWave() -- 202
	local ____self_player_0, ____hp_1 = self.player, "hp" -- 202
	____self_player_0[____hp_1] = ____self_player_0[____hp_1] + math.floor(self.player.maxHp * Config.StageClearHealRatio + 0.5) -- 203
	if self.player.hp > self.player.maxHp then -- 203
		self.player.hp = self.player.maxHp -- 205
	end -- 205
end -- 199
function Combat.prototype.resetBattle(self) -- 210
	self.waveIndex = 0 -- 211
	self.stage = 1 -- 212
	self.resetCount = 0 -- 213
	self.player.hp = self.player.maxHp -- 214
	self.player.shield = 0 -- 215
	self.player.buffStacks = 0 -- 216
	self.player.debuffStacks = 0 -- 217
	self.player.mana = 0 -- 218
	self:loadWave() -- 219
end -- 210
function Combat.prototype.applySpecs(self, specs) -- 223
	return executeEffects( -- 224
		specs, -- 224
		self:makeContext() -- 224
	) -- 224
end -- 223
function Combat.prototype.useSkill(self, id) -- 228
	local def = Skills:find(id) -- 229
	if def == nil then -- 229
		return {ok = false, message = "技能不存在：" .. id} -- 231
	end -- 231
	if self.player.mana < def.cost then -- 231
		return { -- 234
			ok = false, -- 234
			message = (((def.name .. " 需要 ") .. tostring(def.cost)) .. " 魔力，当前 ") .. tostring(self.player.mana) -- 234
		} -- 234
	end -- 234
	local ____self_player_2, ____mana_3 = self.player, "mana" -- 234
	____self_player_2[____mana_3] = ____self_player_2[____mana_3] - def.cost -- 236
	self:applySpecs(def.effects) -- 237
	return { -- 238
		ok = true, -- 238
		message = ((def.name .. "（魔力 −") .. tostring(def.cost)) .. "）" -- 238
	} -- 238
end -- 228
function Combat.prototype.availableSkills(self) -- 242
	return Skills.List -- 243
end -- 242
function Combat.prototype.ensureBoardPlayable(self) -- 250
	if self.board:isPlayable() then -- 250
		return nil -- 252
	end -- 252
	self.board:reset() -- 254
	self.resetCount = self.resetCount + 1 -- 255
	local ____self_player_4, ____hp_5 = self.player, "hp" -- 255
	____self_player_4[____hp_5] = ____self_player_4[____hp_5] - Config.BoardResetPenalty -- 256
	if self.player.hp < 0 then -- 256
		self.player.hp = 0 -- 258
	end -- 258
	return ("棋盘无可连线区域，已重排棋盘（生命 −" .. tostring(Config.BoardResetPenalty)) .. "）" -- 260
end -- 250
function Combat.prototype.makeContext(self) -- 263
	return {player = self.player, currentEnemy = self.enemy, allEnemies = self.enemies, board = self.board} -- 264
end -- 263
__TS__SetDescriptor( -- 263
	Combat.prototype, -- 263
	"boardResetCount", -- 263
	{get = function(self) -- 263
		return self.resetCount -- 50
	end}, -- 50
	true -- 50
) -- 50
__TS__SetDescriptor( -- 50
	Combat.prototype, -- 50
	"defeated", -- 50
	{get = function(self) -- 50
		return self.player.hp <= 0 -- 55
	end}, -- 55
	true -- 55
) -- 55
__TS__SetDescriptor( -- 55
	Combat.prototype, -- 55
	"stageNumber", -- 55
	{get = function(self) -- 55
		return self.stage -- 60
	end}, -- 60
	true -- 60
) -- 60
__TS__SetDescriptor( -- 60
	Combat.prototype, -- 60
	"waveNumber", -- 60
	{get = function(self) -- 60
		return self.waveIndex + 1 -- 65
	end}, -- 65
	true -- 65
) -- 65
__TS__SetDescriptor( -- 65
	Combat.prototype, -- 65
	"waveCount", -- 65
	{get = function(self) -- 65
		return Config.StageWaveCount -- 70
	end}, -- 70
	true -- 70
) -- 70
__TS__SetDescriptor( -- 70
	Combat.prototype, -- 70
	"enemyInterval", -- 70
	{get = function(self) -- 70
		return Config:wave(self.waveIndex).actionTurns -- 79
	end}, -- 79
	true -- 79
) -- 79
__TS__SetDescriptor( -- 79
	Combat.prototype, -- 79
	"isRealtime", -- 79
	{get = function(self) -- 79
		return self.realtime -- 84
	end}, -- 84
	true -- 84
) -- 84
__TS__SetDescriptor( -- 84
	Combat.prototype, -- 84
	"enemyIntervalSeconds", -- 84
	{get = function(self) -- 84
		return Config:wave(self.waveIndex).actionSeconds -- 89
	end}, -- 89
	true -- 89
) -- 89
__TS__SetDescriptor( -- 89
	Combat.prototype, -- 89
	"secondsLeft", -- 89
	{get = function(self) -- 89
		return self.realtimeTimer -- 94
	end}, -- 94
	true -- 94
) -- 94
__TS__SetDescriptor( -- 94
	Combat.prototype, -- 94
	"isCharged", -- 94
	{get = function(self) -- 94
		return self.charged -- 144
	end}, -- 144
	true -- 144
) -- 144
__TS__SetDescriptor( -- 144
	Combat.prototype, -- 144
	"lastEnemyAction", -- 144
	{get = function(self) -- 144
		return self.lastAction -- 149
	end}, -- 149
	true -- 149
) -- 149
__TS__SetDescriptor( -- 149
	Combat.prototype, -- 149
	"lastExpiredLocks", -- 149
	{get = function(self) -- 149
		return self.expiredLockCount -- 154
	end}, -- 154
	true -- 154
) -- 154
return ____exports -- 154
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
local ____Levels = require("game.Levels") -- 7
local Levels = ____Levels.Levels -- 7
local ____Skills = require("game.Skills") -- 8
local Skills = ____Skills.Skills -- 8
____exports.Combat = __TS__Class() -- 22
local Combat = ____exports.Combat -- 22
Combat.name = "Combat" -- 22
function Combat.prototype.____constructor(self, board, level) -- 50
	self.resetCount = 0 -- 27
	self.waveIndex = 0 -- 28
	self.stage = 1 -- 29
	self.difficultyScale = 1 -- 30
	self.realtime = false -- 31
	self.realtimeTimer = 0 -- 32
	self.prepared = -1 -- 36
	self.cooldowns = {} -- 38
	self.skillCursor = 0 -- 40
	self.lastAction = "attack" -- 42
	self.lastSkill = "普通攻击" -- 44
	self.newLocks = 0 -- 46
	self.expiredLockCount = 0 -- 48
	self.board = board -- 51
	self.level = level == nil and Levels.Default or level -- 52
	self.player = makeActor(Config.PlayerMaxHp, 0, Config.MaxMana) -- 53
	local wave = Levels:waveOf(self.level, 0) -- 54
	self.enemy = makeActor(wave.hp, wave.armor, 0) -- 55
	self.enemies = {self.enemy} -- 56
	self:loadWave() -- 57
end -- 50
function Combat.prototype.currentWave(self) -- 90
	return Levels:waveOf(self.level, self.waveIndex) -- 91
end -- 90
function Combat.prototype.setRealtime(self, on) -- 115
	self.realtime = on -- 116
	self:resetTimer() -- 117
end -- 115
function Combat.prototype.resetTimer(self) -- 120
	self.realtimeTimer = self.enemyIntervalSeconds -- 121
end -- 120
function Combat.prototype.advanceTime(self, dt) -- 128
	if not self.realtime then -- 128
		return false -- 130
	end -- 130
	self.realtimeTimer = self.realtimeTimer - dt -- 132
	if self.realtimeTimer > 0 then -- 132
		return false -- 134
	end -- 134
	self:resetTimer() -- 136
	return true -- 137
end -- 128
function Combat.prototype.setDifficultyScale(self, scale) -- 140
	self.difficultyScale = scale -- 141
end -- 140
function Combat.prototype.loadWave(self) -- 145
	local wave = self:currentWave() -- 146
	local scale = self.difficultyScale * Config:stageEnemyScale(self.stage) -- 147
	self.enemy.maxHp = math.floor(wave.hp * scale + 0.5) -- 148
	self.enemy.hp = self.enemy.maxHp -- 149
	self.enemy.shield = 0 -- 150
	self.enemy.armor = wave.armor -- 151
	self.enemy.debuffStacks = 0 -- 152
	self.prepared = -1 -- 154
	self.lastAction = "attack" -- 155
	self.skillCursor = 0 -- 156
	self.cooldowns = {} -- 157
	do -- 157
		local i = 0 -- 158
		while i < #wave.skills do -- 158
			local ____self_cooldowns_0 = self.cooldowns -- 158
			____self_cooldowns_0[#____self_cooldowns_0 + 1] = 0 -- 159
			i = i + 1 -- 158
		end -- 158
	end -- 158
	self.newLocks = 0 -- 161
	self:resetTimer() -- 162
end -- 145
function Combat.prototype.enemyAct(self) -- 196
	self.expiredLockCount = self.board:expireLocks() -- 199
	do -- 199
		local i = 0 -- 201
		while i < #self.cooldowns do -- 201
			if self.cooldowns[i + 1] > 0 then -- 201
				local ____self_cooldowns_1, ____temp_2 = self.cooldowns, i + 1 -- 201
				____self_cooldowns_1[____temp_2] = ____self_cooldowns_1[____temp_2] - 1 -- 203
			end -- 203
			i = i + 1 -- 201
		end -- 201
	end -- 201
	local wave = self:currentWave() -- 206
	local scale = self.difficultyScale * Config:stageEnemyScale(self.stage) -- 207
	local index = self.prepared >= 0 and self.prepared or self:pickSkill(wave) -- 208
	if index < 0 then -- 208
		local fallback = Levels:fallbackSkill(wave) -- 211
		self.lastAction = "attack" -- 212
		self.lastSkill = fallback.name -- 213
		self.newLocks = 0 -- 214
		return applyDamage(self.player, fallback.damage * scale) -- 215
	end -- 215
	local skill = Levels:skillOf(wave, index) -- 217
	if self.prepared >= 0 then -- 217
		self.prepared = -1 -- 220
		self.cooldowns[index + 1] = skill.cooldownActions -- 221
		self.lastAction = "release" -- 222
	elseif skill.preparesNext then -- 222
		self.prepared = index -- 225
		self.lastAction = "prepare" -- 226
		self.lastSkill = skill.name -- 227
		self.newLocks = 0 -- 228
		return 0 -- 229
	else -- 229
		self.lastAction = "attack" -- 231
		self.cooldowns[index + 1] = skill.cooldownActions -- 232
	end -- 232
	self.lastSkill = skill.name -- 234
	local locksBefore = self.board:lockedCount() -- 235
	self:applySpecs(skill.effects) -- 236
	self.newLocks = self.board:lockedCount() - locksBefore -- 237
	return applyDamage(self.player, skill.damage * scale) -- 238
end -- 196
function Combat.prototype.pickSkill(self, wave) -- 242
	local count = #wave.skills -- 243
	if count == 0 then -- 243
		return -1 -- 245
	end -- 245
	do -- 245
		local offset = 0 -- 247
		while offset < count do -- 247
			local index = (self.skillCursor + offset) % count -- 248
			if self.cooldowns[index + 1] <= 0 then -- 248
				self.skillCursor = (index + 1) % count -- 250
				return index -- 251
			end -- 251
			offset = offset + 1 -- 247
		end -- 247
	end -- 247
	return -1 -- 254
end -- 242
function Combat.prototype.advanceWave(self) -- 258
	self.waveIndex = self.waveIndex + 1 -- 259
	if self.waveIndex >= self.waveCount then -- 259
		return true -- 261
	end -- 261
	self:loadWave() -- 263
	return false -- 264
end -- 258
function Combat.prototype.nextStage(self) -- 268
	self.stage = self.stage + 1 -- 269
	self.waveIndex = 0 -- 270
	self:loadWave() -- 271
	local ____self_player_3, ____hp_4 = self.player, "hp" -- 271
	____self_player_3[____hp_4] = ____self_player_3[____hp_4] + math.floor(self.player.maxHp * Config.StageClearHealRatio + 0.5) -- 272
	if self.player.hp > self.player.maxHp then -- 272
		self.player.hp = self.player.maxHp -- 274
	end -- 274
end -- 268
function Combat.prototype.resetBattle(self) -- 279
	self.waveIndex = 0 -- 280
	self.stage = 1 -- 281
	self.resetCount = 0 -- 282
	self.player.hp = self.player.maxHp -- 283
	self.player.shield = 0 -- 284
	self.player.buffStacks = 0 -- 285
	self.player.debuffStacks = 0 -- 286
	self.player.mana = 0 -- 287
	self:loadWave() -- 288
end -- 279
function Combat.prototype.applySpecs(self, specs) -- 292
	return executeEffects( -- 293
		specs, -- 293
		self:makeContext() -- 293
	) -- 293
end -- 292
function Combat.prototype.useSkill(self, id) -- 297
	local def = Skills:find(id) -- 298
	if def == nil then -- 298
		return {ok = false, message = "技能不存在：" .. id} -- 300
	end -- 300
	if self.player.mana < def.cost then -- 300
		return { -- 303
			ok = false, -- 303
			message = (((def.name .. " 需要 ") .. tostring(def.cost)) .. " 魔力，当前 ") .. tostring(self.player.mana) -- 303
		} -- 303
	end -- 303
	local ____self_player_5, ____mana_6 = self.player, "mana" -- 303
	____self_player_5[____mana_6] = ____self_player_5[____mana_6] - def.cost -- 305
	self:applySpecs(def.effects) -- 306
	return { -- 307
		ok = true, -- 307
		message = ((def.name .. "（魔力 −") .. tostring(def.cost)) .. "）" -- 307
	} -- 307
end -- 297
function Combat.prototype.availableSkills(self) -- 311
	return Skills.List -- 312
end -- 311
function Combat.prototype.ensureBoardPlayable(self) -- 319
	if self.board:isPlayable() then -- 319
		return nil -- 321
	end -- 321
	self.board:reset() -- 323
	self.resetCount = self.resetCount + 1 -- 324
	local ____self_player_7, ____hp_8 = self.player, "hp" -- 324
	____self_player_7[____hp_8] = ____self_player_7[____hp_8] - Config.BoardResetPenalty -- 325
	if self.player.hp < 0 then -- 325
		self.player.hp = 0 -- 327
	end -- 327
	return ("棋盘无可连线区域，已重排棋盘（生命 −" .. tostring(Config.BoardResetPenalty)) .. "）" -- 329
end -- 319
function Combat.prototype.makeContext(self) -- 332
	return {player = self.player, currentEnemy = self.enemy, allEnemies = self.enemies, board = self.board} -- 333
end -- 332
__TS__SetDescriptor( -- 332
	Combat.prototype, -- 332
	"boardResetCount", -- 332
	{get = function(self) -- 332
		return self.resetCount -- 62
	end}, -- 62
	true -- 62
) -- 62
__TS__SetDescriptor( -- 62
	Combat.prototype, -- 62
	"defeated", -- 62
	{get = function(self) -- 62
		return self.player.hp <= 0 -- 67
	end}, -- 67
	true -- 67
) -- 67
__TS__SetDescriptor( -- 67
	Combat.prototype, -- 67
	"stageNumber", -- 67
	{get = function(self) -- 67
		return self.stage -- 72
	end}, -- 72
	true -- 72
) -- 72
__TS__SetDescriptor( -- 72
	Combat.prototype, -- 72
	"waveNumber", -- 72
	{get = function(self) -- 72
		return self.waveIndex + 1 -- 77
	end}, -- 77
	true -- 77
) -- 77
__TS__SetDescriptor( -- 77
	Combat.prototype, -- 77
	"waveCount", -- 77
	{get = function(self) -- 77
		return #self.level.waves -- 82
	end}, -- 82
	true -- 82
) -- 82
__TS__SetDescriptor( -- 82
	Combat.prototype, -- 82
	"levelDef", -- 82
	{get = function(self) -- 82
		return self.level -- 87
	end}, -- 87
	true -- 87
) -- 87
__TS__SetDescriptor( -- 87
	Combat.prototype, -- 87
	"enemyInterval", -- 87
	{get = function(self) -- 87
		return self:currentWave().actionTurns -- 96
	end}, -- 96
	true -- 96
) -- 96
__TS__SetDescriptor( -- 96
	Combat.prototype, -- 96
	"isRealtime", -- 96
	{get = function(self) -- 96
		return self.realtime -- 101
	end}, -- 101
	true -- 101
) -- 101
__TS__SetDescriptor( -- 101
	Combat.prototype, -- 101
	"enemyIntervalSeconds", -- 101
	{get = function(self) -- 101
		return self:currentWave().actionSeconds -- 106
	end}, -- 106
	true -- 106
) -- 106
__TS__SetDescriptor( -- 106
	Combat.prototype, -- 106
	"secondsLeft", -- 106
	{get = function(self) -- 106
		return self.realtimeTimer -- 111
	end}, -- 111
	true -- 111
) -- 111
__TS__SetDescriptor( -- 111
	Combat.prototype, -- 111
	"isPreparing", -- 111
	{get = function(self) -- 111
		return self.prepared >= 0 -- 167
	end}, -- 167
	true -- 167
) -- 167
__TS__SetDescriptor( -- 167
	Combat.prototype, -- 167
	"lastSkillName", -- 167
	{get = function(self) -- 167
		return self.lastSkill -- 172
	end}, -- 172
	true -- 172
) -- 172
__TS__SetDescriptor( -- 172
	Combat.prototype, -- 172
	"lastNewLocks", -- 172
	{get = function(self) -- 172
		return self.newLocks -- 177
	end}, -- 177
	true -- 177
) -- 177
__TS__SetDescriptor( -- 177
	Combat.prototype, -- 177
	"lastEnemyAction", -- 177
	{get = function(self) -- 177
		return self.lastAction -- 182
	end}, -- 182
	true -- 182
) -- 182
__TS__SetDescriptor( -- 182
	Combat.prototype, -- 182
	"lastExpiredLocks", -- 182
	{get = function(self) -- 182
		return self.expiredLockCount -- 187
	end}, -- 187
	true -- 187
) -- 187
return ____exports -- 187
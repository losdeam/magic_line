-- [ts]: Game.ts
local ____lualib = require("lualib_bundle") -- 1
local __TS__Class = ____lualib.__TS__Class -- 1
local __TS__New = ____lualib.__TS__New -- 1
local ____exports = {} -- 1
local ____Dora = require("Dora") -- 5
local Node = ____Dora.Node -- 5
local Vec2 = ____Dora.Vec2 -- 5
local ____Board = require("game.Board") -- 6
local Board = ____Board.Board -- 6
local ____BoardView = require("game.BoardView") -- 7
local BoardView = ____BoardView.BoardView -- 7
local ____Combat = require("game.Combat") -- 8
local Combat = ____Combat.Combat -- 8
local ____Config = require("game.Config") -- 9
local Config = ____Config.Config -- 9
local ____Effects = require("game.Effects") -- 10
local formatEffects = ____Effects.formatEffects -- 10
local ____Hud = require("game.Hud") -- 11
local Hud = ____Hud.Hud -- 11
local ____Settings = require("game.Settings") -- 12
local Settings = ____Settings.Settings -- 12
local ____Skills = require("game.Skills") -- 13
local Skills = ____Skills.Skills -- 13
____exports.Game = __TS__Class() -- 15
local Game = ____exports.Game -- 15
Game.name = "Game" -- 15
function Game.prototype.____constructor(self, parent) -- 27
	self.turnsUntilEnemy = 0 -- 24
	self.defeated = false -- 25
	self.parent = parent -- 28
	self.settings = Settings:load() -- 29
	self.board = __TS__New(Board) -- 30
	self.combat = __TS__New(Combat, self.board) -- 31
	self.combat:setDifficultyScale(self.settings:difficultyScale()) -- 32
	self.combat:setRealtime(self.settings.mode == "realtime") -- 33
	self.view = __TS__New(BoardView, self.board) -- 34
	self.hud = __TS__New(Hud, Skills.List) -- 35
	self.root = Node() -- 36
	self.view.root.position = Vec2(0, Config.BoardCenterY) -- 37
	self.view.root:addTo(self.root) -- 38
	self.hud.root:addTo(self.root) -- 39
	self.hud.onSkill = function(____, id) return self:handleSkill(id) end -- 40
	self.hud.onRestart = function() return self:restart() end -- 41
	self.hud.onToggleMode = function() return self:toggleMode() end -- 42
	self.hud.onCycleDifficulty = function() return self:cycleDifficulty() end -- 43
	self.hud.onToggleHint = function() return self:toggleHint() end -- 44
	self.turnsUntilEnemy = self.combat.enemyInterval -- 45
end -- 27
function Game.prototype.start(self) -- 49
	self.root:addTo(self.parent) -- 50
	self:refreshHud() -- 51
	self.hud:showNotice("按住滑过相邻同色方块，松手结算") -- 52
	if not self.settings.saved then -- 52
		self.hud:showNotice("设置未保存（仅内存态生效）") -- 54
	end -- 54
	self.root:schedule(function(dt) -- 56
		self:tick(dt) -- 57
		return false -- 58
	end) -- 56
end -- 49
function Game.prototype.tick(self, dt) -- 63
	self.view:update(dt) -- 64
	self.hud:update(dt) -- 65
	local result = self.view:takePendingResult() -- 66
	if result ~= nil then -- 66
		if self.hud.isSettingsOpen then -- 66
			self.view:refreshFromBoard() -- 70
		else -- 70
			self:handleChain(result) -- 72
		end -- 72
	end -- 72
	if not self.defeated and self.combat:advanceTime(dt) then -- 72
		self:enemyAct() -- 76
	end -- 76
	if self.combat.isRealtime and not self.defeated then -- 76
		self.hud:setTimerInfo( -- 79
			("敌方行动倒计时 " .. tostring(math.ceil(self.combat.secondsLeft))) .. " 秒", -- 80
			self.combat.secondsLeft / self.combat.enemyIntervalSeconds -- 81
		) -- 81
	end -- 81
end -- 63
function Game.prototype.submitChain(self, cells) -- 87
	self.view:submitChain(cells) -- 88
	local result = self.view:takePendingResult() -- 89
	if result ~= nil then -- 89
		self:handleChain(result) -- 91
	end -- 91
end -- 87
function Game.prototype.handleChain(self, result) -- 95
	if self.defeated then -- 95
		return -- 97
	end -- 97
	local enemyHpBefore = self.combat.enemy.hp -- 99
	local playerHpBefore = self.combat.player.hp -- 100
	self.combat:applySpecs(result.specs) -- 101
	local enemyLost = enemyHpBefore - self.combat.enemy.hp -- 102
	local hpGained = self.combat.player.hp - playerHpBefore -- 103
	self.board:applyChain(result.cells) -- 104
	self.view:flashCleared(result.cells) -- 105
	self.view:animateFall(self.board.collapseMoves, self.board.collapseSpawns) -- 106
	self.view:refreshFromBoard() -- 107
	self:reportChain(result, enemyLost, hpGained) -- 108
	local resetNotice = self.combat:ensureBoardPlayable() -- 109
	if resetNotice ~= nil then -- 109
		self.hud:showNotice(resetNotice) -- 111
		self.view:refreshFromBoard() -- 112
	end -- 112
	if self.combat.enemy.hp <= 0 then -- 112
		self:handleWaveCleared() -- 115
	elseif not self.combat.isRealtime then -- 115
		self.turnsUntilEnemy = self.turnsUntilEnemy - 1 -- 118
		if self.turnsUntilEnemy <= 0 then -- 118
			self:enemyAct() -- 120
		end -- 120
	end -- 120
	if self.combat.player.hp <= 0 then -- 120
		self:defeat() -- 124
		return -- 125
	end -- 125
	self:refreshHud() -- 127
end -- 95
function Game.prototype.reportChain(self, result, enemyLost, hpGained) -- 134
	local mana = 0 -- 135
	local buff = 0 -- 136
	local debuff = 0 -- 137
	local shield = 0 -- 138
	for ____, spec in ipairs(result.specs) do -- 139
		if spec.kind == "manaGain" then -- 139
			mana = mana + spec.value -- 141
		elseif spec.kind == "shield" then -- 141
			shield = shield + spec.value -- 143
		elseif spec.kind == "buffDamage" then -- 143
			buff = buff + spec.value -- 145
		elseif spec.kind == "debuffArmor" then -- 145
			debuff = debuff + spec.value -- 147
		end -- 147
	end -- 147
	if enemyLost > 0 then -- 147
		self.hud:showNotice( -- 151
			"-" .. tostring(enemyLost), -- 151
			0, -- 151
			16770442 -- 151
		) -- 151
		self.hud:hitEnemy() -- 152
	end -- 152
	if hpGained > 0 then -- 152
		self.hud:showNotice( -- 155
			"+" .. tostring(hpGained), -- 155
			1, -- 155
			10477728 -- 155
		) -- 155
	end -- 155
	if debuff > 0 then -- 155
		self.hud:showNotice( -- 158
			("破甲 " .. tostring(debuff)) .. " 层", -- 158
			0, -- 158
			13672703 -- 158
		) -- 158
	end -- 158
	if buff > 0 then -- 158
		self.hud:showNotice( -- 161
			("增伤 +" .. tostring(buff)) .. " 层", -- 161
			2, -- 161
			16770442 -- 161
		) -- 161
	end -- 161
	if shield > 0 then -- 161
		self.hud:showNotice( -- 164
			"护盾 +" .. tostring(shield), -- 164
			2, -- 164
			9422079 -- 164
		) -- 164
	end -- 164
	if mana > 0 then -- 164
		self.hud:showNotice( -- 167
			"魔力 +" .. tostring(mana), -- 167
			2, -- 167
			9422079 -- 167
		) -- 167
	end -- 167
	if enemyLost <= 0 and hpGained <= 0 and mana <= 0 and buff <= 0 and shield <= 0 then -- 167
		self.hud:showNotice( -- 171
			formatEffects(result.specs), -- 171
			2 -- 171
		) -- 171
	end -- 171
end -- 134
function Game.prototype.handleWaveCleared(self) -- 175
	if self.combat:advanceWave() then -- 175
		self.combat:nextStage() -- 177
		self.hud:showNotice(("本关通关，进入第 " .. tostring(self.combat.stageNumber)) .. " 关（生命已回复）") -- 178
	else -- 178
		self.hud:showNotice(("第 " .. tostring(self.combat.waveNumber)) .. " 波来袭") -- 180
	end -- 180
	self.board:reset() -- 183
	self.view:refreshFromBoard() -- 184
	self.turnsUntilEnemy = self.combat.enemyInterval -- 185
end -- 175
function Game.prototype.enemyAct(self) -- 188
	local damage = self.combat:enemyAct() -- 189
	local action = self.combat.lastEnemyAction -- 190
	if action == "prepare" then -- 190
		self.hud:showNotice(("敌方蓄力「" .. self.combat.lastSkillName) .. "」 — 下次行动释放", 0, 16757611) -- 193
	elseif action == "release" then -- 193
		self.hud:hitPlayer(damage) -- 195
		local lockText = self.combat.lastNewLocks > 0 and ("，封锁 " .. tostring(self.combat.lastNewLocks)) .. " 格" or "" -- 196
		self.hud:showNotice( -- 197
			((("敌方「" .. self.combat.lastSkillName) .. "」 −") .. tostring(damage)) .. lockText, -- 197
			0, -- 197
			16747146 -- 197
		) -- 197
	else -- 197
		self.hud:hitPlayer(damage) -- 199
		self.hud:showNotice( -- 200
			(("敌方" .. self.combat.lastSkillName) .. " −") .. tostring(damage), -- 200
			2, -- 200
			16757611 -- 200
		) -- 200
	end -- 200
	if self.combat.lastExpiredLocks > 0 then -- 200
		self.hud:showNotice( -- 203
			("封锁自动解除 " .. tostring(self.combat.lastExpiredLocks)) .. " 格", -- 203
			2, -- 203
			10475263 -- 203
		) -- 203
	end -- 203
	self.view:refreshFromBoard() -- 206
	self.turnsUntilEnemy = self.combat.enemyInterval -- 207
	if self.combat.player.hp <= 0 then -- 207
		self:defeat() -- 209
		return -- 210
	end -- 210
	self:refreshHud() -- 212
end -- 188
function Game.prototype.handleSkill(self, id) -- 215
	if self.defeated then -- 215
		return -- 217
	end -- 217
	local before = self:captureBlocks() -- 219
	local result = self.combat:useSkill(id) -- 220
	self.hud:showNotice(result.message, 2, result.ok and 9427199 or 16757611) -- 221
	if result.ok then -- 221
		self.hud:glowSkill(id) -- 224
		local changed = self:diffBlocks(before) -- 225
		local resetNotice = self.combat:ensureBoardPlayable() -- 226
		if resetNotice ~= nil then -- 226
			self.hud:showNotice(resetNotice) -- 228
		end -- 228
		self.view:refreshFromBoard() -- 230
		self.view:skillCast(changed) -- 231
	end -- 231
	self:refreshHud() -- 233
end -- 215
function Game.prototype.captureBlocks(self) -- 237
	local snapshot = {} -- 238
	do -- 238
		local row = 0 -- 239
		while row < self.board.rows do -- 239
			do -- 239
				local col = 0 -- 240
				while col < self.board.columns do -- 240
					snapshot[#snapshot + 1] = self.board:cellIndex(col, row) -- 241
					col = col + 1 -- 240
				end -- 240
			end -- 240
			row = row + 1 -- 239
		end -- 239
	end -- 239
	return snapshot -- 244
end -- 237
function Game.prototype.diffBlocks(self, before) -- 248
	local changed = {} -- 249
	local i = 0 -- 250
	do -- 250
		local row = 0 -- 251
		while row < self.board.rows do -- 251
			do -- 251
				local col = 0 -- 252
				while col < self.board.columns do -- 252
					local index = self.board:cellIndex(col, row) -- 253
					if i < #before and before[i + 1] ~= index then -- 253
						changed[#changed + 1] = self.board:flatIndex(col, row) -- 255
					end -- 255
					i = i + 1 -- 257
					col = col + 1 -- 252
				end -- 252
			end -- 252
			row = row + 1 -- 251
		end -- 251
	end -- 251
	return changed -- 260
end -- 248
function Game.prototype.toggleMode(self) -- 264
	local mode = self.settings:toggleMode() -- 265
	local saved = self.settings:save() -- 266
	self.combat:setRealtime(mode == "realtime") -- 267
	self:restart() -- 269
	self.hud:showNotice(("已切换为" .. self.settings:modeName()) .. (saved and "" or "（设置未保存）")) -- 270
	self:refreshHud() -- 271
end -- 264
function Game.prototype.cycleDifficulty(self) -- 275
	self.settings:cycleDifficulty() -- 276
	local saved = self.settings:save() -- 277
	self.combat:setDifficultyScale(self.settings:difficultyScale()) -- 278
	self.combat:loadWave() -- 279
	self.hud:showNotice(("难度：" .. self.settings:difficultyName()) .. (saved and "" or "（设置未保存）")) -- 280
	self:refreshHud() -- 281
end -- 275
function Game.prototype.toggleHint(self) -- 285
	self.settings:toggleHint() -- 286
	local saved = self.settings:save() -- 287
	self.hud:showNotice(("操作提示：" .. (self.settings.showHint and "开" or "关")) .. (saved and "" or "（设置未保存）")) -- 288
	self:refreshHud() -- 289
end -- 285
function Game.prototype.defeat(self) -- 292
	self.defeated = true -- 293
	self.hud:showDefeat(((("玩家生命归零 — 止步于第 " .. tostring(self.combat.stageNumber)) .. " 关第 ") .. tostring(self.combat.waveNumber)) .. " 波") -- 294
	self:refreshHud() -- 295
end -- 292
function Game.prototype.restart(self) -- 298
	self.defeated = false -- 299
	self.board:reset() -- 300
	self.view:refreshFromBoard() -- 301
	self.combat:resetBattle() -- 302
	self.combat:setDifficultyScale(self.settings:difficultyScale()) -- 303
	self.combat:setRealtime(self.settings.mode == "realtime") -- 304
	self.turnsUntilEnemy = self.combat.enemyInterval -- 305
	self.hud:hideDefeat() -- 306
	self.hud:showNotice("重新开始本关") -- 307
	self:refreshHud() -- 308
end -- 298
function Game.prototype.refreshHud(self) -- 311
	local wave = self.combat:currentWave() -- 312
	self.hud:setStageInfo((((("第 " .. tostring(self.combat.stageNumber)) .. " 关 · 波次 ") .. tostring(self.combat.waveNumber)) .. "/") .. tostring(self.combat.waveCount)) -- 313
	self.hud:setEnemyInfo(wave.name, self.combat.enemy.hp, self.combat.enemy.maxHp) -- 314
	self.hud:setPlayerInfo(self.combat.player.hp, self.combat.player.maxHp, self.combat.player.mana, self.combat.player.maxMana) -- 315
	if self.combat.isRealtime then -- 315
		self.hud:setTimerInfo( -- 317
			("敌方行动倒计时 " .. tostring(math.ceil(self.combat.secondsLeft))) .. " 秒", -- 318
			self.combat.secondsLeft / self.combat.enemyIntervalSeconds -- 319
		) -- 319
	else -- 319
		self.hud:setTimerInfo( -- 322
			("敌方行动倒计时 " .. tostring(self.turnsUntilEnemy)) .. " 回合", -- 323
			self.turnsUntilEnemy / self.combat.enemyInterval -- 324
		) -- 324
	end -- 324
	self.hud:syncSkills(self.combat.player.mana) -- 327
	self.hud:syncSettings( -- 328
		self.settings:modeName(), -- 328
		self.settings:difficultyName(), -- 328
		self.settings.showHint, -- 328
		self.settings.saved -- 328
	) -- 328
end -- 311
return ____exports -- 311
-- [ts]: Hud.ts
local ____lualib = require("lualib_bundle") -- 1
local __TS__Class = ____lualib.__TS__Class -- 1
local __TS__New = ____lualib.__TS__New -- 1
local __TS__SetDescriptor = ____lualib.__TS__SetDescriptor -- 1
local ____exports = {} -- 1
local ____Dora = require("Dora") -- 4
local Color = ____Dora.Color -- 4
local DrawNode = ____Dora.DrawNode -- 4
local Node = ____Dora.Node -- 4
local Vec2 = ____Dora.Vec2 -- 4
local ____Config = require("game.Config") -- 5
local Config = ____Config.Config -- 5
local ____UiLayout = require("game.UiLayout") -- 7
local HudLayout = ____UiLayout.HudLayout -- 7
local Palette = ____UiLayout.Palette -- 7
local ____Controls = require("game.ui.Controls") -- 8
local BarWidget = ____Controls.BarWidget -- 8
local ButtonWidget = ____Controls.ButtonWidget -- 8
local FloatTextWidget = ____Controls.FloatTextWidget -- 8
local PanelWidget = ____Controls.PanelWidget -- 8
local makeLabel = ____Controls.makeLabel -- 8
local ____Widget = require("game.ui.Widget") -- 9
local colorFromHex = ____Widget.colorFromHex -- 9
____exports.Hud = __TS__Class() -- 18
local Hud = ____exports.Hud -- 18
Hud.name = "Hud" -- 18
function Hud.prototype.____constructor(self, skills) -- 59
	self.skillButtons = {} -- 27
	self.skillCosts = {} -- 28
	self.skillIds = {} -- 30
	self.floatLanes = {} -- 32
	self.floatQueue = {} -- 33
	self.floatQueueHex = {} -- 34
	self.hitTint = 0 -- 37
	self.settingsPanelParts = {} -- 43
	self.settingsButtons = {} -- 44
	self.settingsOpen = false -- 49
	self.panelParts = {} -- 50
	self.onSkill = function() -- 53
	end -- 53
	self.onRestart = function() -- 54
	end -- 54
	self.onToggleMode = function() -- 55
	end -- 55
	self.onCycleDifficulty = function() -- 56
	end -- 56
	self.onToggleHint = function() -- 57
	end -- 57
	local root = Node() -- 60
	self.root = root -- 61
	local hitLayer = DrawNode() -- 64
	hitLayer.z = -1 -- 65
	hitLayer:addTo(root) -- 66
	self.hitLayer = hitLayer -- 67
	self.stageLabel = makeLabel("", HudLayout.FontStage) -- 69
	if self.stageLabel ~= nil then -- 69
		self.stageLabel.position = Vec2(0, HudLayout.StageY) -- 71
		self.stageLabel:addTo(root) -- 72
	end -- 72
	self.enemyName = makeLabel("", HudLayout.FontName) -- 75
	if self.enemyName ~= nil then -- 75
		self.enemyName.position = Vec2(0, HudLayout.EnemyNameY) -- 77
		self.enemyName:addTo(root) -- 78
	end -- 78
	self.enemyBar = __TS__New(BarWidget, HudLayout.EnemyBarWidth, HudLayout.EnemyBarHeight, Palette.EnemyBar) -- 80
	self.enemyBar:setPosition(0, HudLayout.EnemyBarY) -- 81
	self.enemyBar:addTo(root) -- 82
	self.timerLabel = makeLabel("", HudLayout.FontLabel) -- 84
	if self.timerLabel ~= nil then -- 84
		self.timerLabel.position = Vec2(0, HudLayout.TimerLabelY) -- 86
		self.timerLabel:addTo(root) -- 87
	end -- 87
	self.playerBar = __TS__New(BarWidget, HudLayout.PlayerBarWidth, HudLayout.PlayerBarHeight, Palette.PlayerBar) -- 90
	self.playerBar:setPosition(0, HudLayout.PlayerBarY) -- 91
	self.playerBar:addTo(root) -- 92
	self.playerName = makeLabel("玩家生命", HudLayout.FontLabel) -- 94
	if self.playerName ~= nil then -- 94
		self.playerName.anchor = Vec2(1, 0.5) -- 96
		self.playerName.position = Vec2(HudLayout.PlayerNameX, HudLayout.PlayerBarY) -- 97
		self.playerName:addTo(root) -- 98
	end -- 98
	self.manaBar = __TS__New(BarWidget, HudLayout.ManaBarWidth, HudLayout.ManaBarHeight, Palette.ManaBar) -- 101
	self.manaBar:setPosition(0, HudLayout.ManaBarY) -- 102
	self.manaBar:addTo(root) -- 103
	self.timerBar = __TS__New(BarWidget, HudLayout.TimerBarWidth, HudLayout.TimerBarHeight, Palette.TimerBar) -- 106
	self.timerBar:setPosition(0, HudLayout.TimerBarY) -- 107
	self.timerBar:addTo(root) -- 108
	do -- 108
		local i = 0 -- 111
		while i < #skills do -- 111
			local def = skills[i + 1] -- 112
			local button = __TS__New( -- 113
				ButtonWidget, -- 113
				(def.name .. " ") .. tostring(def.cost), -- 113
				HudLayout.SkillButtonWidth, -- 113
				HudLayout.SkillButtonHeight, -- 113
				Palette.ButtonPrimary -- 113
			) -- 113
			button:setPosition((i - (#skills - 1) / 2) * HudLayout.SkillButtonSpacing, HudLayout.SkillButtonY) -- 114
			button:addTo(root) -- 115
			local id = def.id -- 116
			button.onClick = function() return self:onSkill(id) end -- 117
			local ____self_skillButtons_0 = self.skillButtons -- 117
			____self_skillButtons_0[#____self_skillButtons_0 + 1] = button -- 118
			local ____self_skillCosts_1 = self.skillCosts -- 118
			____self_skillCosts_1[#____self_skillCosts_1 + 1] = def.cost -- 119
			local ____self_skillIds_2 = self.skillIds -- 119
			____self_skillIds_2[#____self_skillIds_2 + 1] = def.id -- 120
			i = i + 1 -- 111
		end -- 111
	end -- 111
	do -- 111
		local lane = 0 -- 123
		while lane < 3 do -- 123
			local widget = __TS__New(FloatTextWidget, HudLayout.FontNotice) -- 124
			widget:addTo(root) -- 125
			local ____self_floatLanes_3 = self.floatLanes -- 125
			____self_floatLanes_3[#____self_floatLanes_3 + 1] = widget -- 126
			local queue = {} -- 127
			local hexes = {} -- 128
			local ____self_floatQueue_4 = self.floatQueue -- 128
			____self_floatQueue_4[#____self_floatQueue_4 + 1] = queue -- 129
			local ____self_floatQueueHex_5 = self.floatQueueHex -- 129
			____self_floatQueueHex_5[#____self_floatQueueHex_5 + 1] = hexes -- 130
			lane = lane + 1 -- 123
		end -- 123
	end -- 123
	self.hintLabel = makeLabel("按住滑过相邻同色方块，松手结算（≥2 连即可消除）", HudLayout.FontLabel) -- 134
	if self.hintLabel ~= nil then -- 134
		self.hintLabel.position = Vec2(0, HudLayout.HintY) -- 136
		self.hintLabel:addTo(root) -- 137
	end -- 137
	self.settingsButton = __TS__New( -- 141
		ButtonWidget, -- 141
		"设置", -- 141
		HudLayout.SettingsButtonWidth, -- 141
		HudLayout.SettingsButtonHeight, -- 141
		Palette.ButtonNeutral -- 141
	) -- 141
	self.settingsButton:setPosition(HudLayout.SettingsButtonX, HudLayout.SettingsButtonY) -- 142
	self.settingsButton:addTo(root) -- 143
	self.settingsButton.onClick = function() return self:toggleSettings() end -- 144
	local settingsPanel = __TS__New(PanelWidget, HudLayout.SettingsPanelWidth, HudLayout.SettingsPanelHeight, Palette.PanelBackground) -- 147
	settingsPanel:setPosition(0, 0) -- 148
	settingsPanel:addTo(root) -- 149
	local ____self_settingsPanelParts_6 = self.settingsPanelParts -- 149
	____self_settingsPanelParts_6[#____self_settingsPanelParts_6 + 1] = settingsPanel.root -- 150
	local settingsTitle = makeLabel("设置", HudLayout.FontPanelTitle) -- 151
	if settingsTitle ~= nil then -- 151
		settingsTitle.position = Vec2(0, HudLayout.SettingsTitleY) -- 153
		settingsTitle:addTo(root) -- 154
		local ____self_settingsPanelParts_7 = self.settingsPanelParts -- 154
		____self_settingsPanelParts_7[#____self_settingsPanelParts_7 + 1] = settingsTitle -- 155
	end -- 155
	self.modeButton = __TS__New( -- 157
		ButtonWidget, -- 157
		"模式：回合制", -- 157
		HudLayout.SettingsRowWidth, -- 157
		HudLayout.SettingsRowHeight, -- 157
		Palette.ButtonPrimary -- 157
	) -- 157
	self.modeButton:setPosition(0, HudLayout.SettingsModeY) -- 158
	self.modeButton:addTo(root) -- 159
	self.modeButton.onClick = function() return self:onToggleMode() end -- 160
	local ____self_settingsPanelParts_8 = self.settingsPanelParts -- 160
	____self_settingsPanelParts_8[#____self_settingsPanelParts_8 + 1] = self.modeButton.root -- 161
	local ____self_settingsButtons_9 = self.settingsButtons -- 161
	____self_settingsButtons_9[#____self_settingsButtons_9 + 1] = self.modeButton -- 162
	self.difficultyButton = __TS__New( -- 163
		ButtonWidget, -- 163
		"难度：标准", -- 163
		HudLayout.SettingsRowWidth, -- 163
		HudLayout.SettingsRowHeight, -- 163
		Palette.ButtonPrimary -- 163
	) -- 163
	self.difficultyButton:setPosition(0, HudLayout.SettingsDifficultyY) -- 164
	self.difficultyButton:addTo(root) -- 165
	self.difficultyButton.onClick = function() return self:onCycleDifficulty() end -- 166
	local ____self_settingsPanelParts_10 = self.settingsPanelParts -- 166
	____self_settingsPanelParts_10[#____self_settingsPanelParts_10 + 1] = self.difficultyButton.root -- 167
	local ____self_settingsButtons_11 = self.settingsButtons -- 167
	____self_settingsButtons_11[#____self_settingsButtons_11 + 1] = self.difficultyButton -- 168
	self.hintButton = __TS__New( -- 169
		ButtonWidget, -- 169
		"操作提示：开", -- 169
		HudLayout.SettingsRowWidth, -- 169
		HudLayout.SettingsRowHeight, -- 169
		Palette.ButtonPrimary -- 169
	) -- 169
	self.hintButton:setPosition(0, HudLayout.SettingsHintY) -- 170
	self.hintButton:addTo(root) -- 171
	self.hintButton.onClick = function() return self:onToggleHint() end -- 172
	local ____self_settingsPanelParts_12 = self.settingsPanelParts -- 172
	____self_settingsPanelParts_12[#____self_settingsPanelParts_12 + 1] = self.hintButton.root -- 173
	local ____self_settingsButtons_13 = self.settingsButtons -- 173
	____self_settingsButtons_13[#____self_settingsButtons_13 + 1] = self.hintButton -- 174
	local closeButton = __TS__New( -- 175
		ButtonWidget, -- 175
		"关闭设置", -- 175
		HudLayout.SettingsCloseWidth, -- 175
		HudLayout.SettingsCloseHeight, -- 175
		Palette.ButtonNeutral -- 175
	) -- 175
	closeButton:setPosition(0, HudLayout.SettingsCloseY) -- 176
	closeButton:addTo(root) -- 177
	closeButton.onClick = function() return self:closeSettings() end -- 178
	local ____self_settingsPanelParts_14 = self.settingsPanelParts -- 178
	____self_settingsPanelParts_14[#____self_settingsPanelParts_14 + 1] = closeButton.root -- 179
	local ____self_settingsButtons_15 = self.settingsButtons -- 179
	____self_settingsButtons_15[#____self_settingsButtons_15 + 1] = closeButton -- 180
	self.saveLabel = makeLabel("", HudLayout.FontSmall) -- 181
	if self.saveLabel ~= nil then -- 181
		self.saveLabel.position = Vec2(0, HudLayout.SettingsSaveY) -- 183
		self.saveLabel:addTo(root) -- 184
		local ____self_settingsPanelParts_16 = self.settingsPanelParts -- 184
		____self_settingsPanelParts_16[#____self_settingsPanelParts_16 + 1] = self.saveLabel -- 185
	end -- 185
	local panel = __TS__New(PanelWidget, HudLayout.DefeatPanelWidth, HudLayout.DefeatPanelHeight, Palette.PanelBackground) -- 189
	panel:setPosition(0, 0) -- 190
	panel:addTo(root) -- 191
	local ____self_panelParts_17 = self.panelParts -- 191
	____self_panelParts_17[#____self_panelParts_17 + 1] = panel.root -- 192
	local title = makeLabel("战斗结束", HudLayout.FontPanelTitleLarge) -- 193
	if title ~= nil then -- 193
		title.position = Vec2(0, HudLayout.DefeatTitleY) -- 195
		title:addTo(root) -- 196
		local ____self_panelParts_18 = self.panelParts -- 196
		____self_panelParts_18[#____self_panelParts_18 + 1] = title -- 197
	end -- 197
	self.panelText = makeLabel("", HudLayout.FontStage) -- 199
	if self.panelText ~= nil then -- 199
		self.panelText.position = Vec2(0, HudLayout.DefeatTextY) -- 201
		self.panelText:addTo(root) -- 202
		local ____self_panelParts_19 = self.panelParts -- 202
		____self_panelParts_19[#____self_panelParts_19 + 1] = self.panelText -- 203
	end -- 203
	local restart = __TS__New( -- 205
		ButtonWidget, -- 205
		"重新开始本关", -- 205
		HudLayout.DefeatButtonWidth, -- 205
		HudLayout.DefeatButtonHeight, -- 205
		Palette.ButtonPrimary -- 205
	) -- 205
	restart:setPosition(0, HudLayout.DefeatButtonY) -- 206
	restart:addTo(root) -- 207
	restart.onClick = function() return self:onRestart() end -- 208
	local ____self_panelParts_20 = self.panelParts -- 208
	____self_panelParts_20[#____self_panelParts_20 + 1] = restart.root -- 209
	self.restartButton = restart -- 210
	self:closeSettings() -- 212
	self:hideDefeat() -- 213
end -- 59
function Hud.prototype.toggleSettings(self) -- 220
	if self.settingsOpen then -- 220
		self:closeSettings() -- 222
		return -- 223
	end -- 223
	self:openSettings() -- 225
end -- 220
function Hud.prototype.openSettings(self) -- 228
	self.settingsOpen = true -- 229
	for ____, part in ipairs(self.settingsPanelParts) do -- 230
		part.visible = true -- 231
	end -- 231
	for ____, button in ipairs(self.settingsButtons) do -- 233
		button:setEnabled(true) -- 234
	end -- 234
end -- 228
function Hud.prototype.closeSettings(self) -- 238
	self.settingsOpen = false -- 239
	for ____, part in ipairs(self.settingsPanelParts) do -- 240
		part.visible = false -- 241
	end -- 241
	for ____, button in ipairs(self.settingsButtons) do -- 244
		button:setEnabled(false) -- 245
	end -- 245
end -- 238
function Hud.prototype.syncSettings(self, modeName, difficultyName, hintOn, saved) -- 250
	self.modeButton:setText("模式：" .. modeName) -- 251
	self.difficultyButton:setText("难度：" .. difficultyName) -- 252
	self.hintButton:setText("操作提示：" .. (hintOn and "开" or "关")) -- 253
	if self.hintLabel ~= nil then -- 253
		self.hintLabel.visible = hintOn -- 255
	end -- 255
	if self.saveLabel ~= nil then -- 255
		self.saveLabel.text = saved and "设置已保存" or "设置未保存（仅内存态生效）" -- 258
		self.saveLabel.color = colorFromHex(saved and Palette.TextOk or Palette.TextWarn, 255) -- 259
	end -- 259
end -- 250
function Hud.prototype.update(self, dt) -- 263
	self.enemyBar:update(dt) -- 264
	self.timerBar:update(dt) -- 265
	self.playerBar:update(dt) -- 266
	self.manaBar:update(dt) -- 267
	for ____, button in ipairs(self.skillButtons) do -- 269
		button:update(dt) -- 270
	end -- 270
	do -- 270
		local lane = 0 -- 273
		while lane < #self.floatLanes do -- 273
			do -- 273
				local widget = self.floatLanes[lane + 1] -- 274
				widget:update(dt) -- 275
				if widget.active then -- 275
					goto __continue47 -- 277
				end -- 277
				local queue = self.floatQueue[lane + 1] -- 279
				if #queue == 0 then -- 279
					goto __continue47 -- 281
				end -- 281
				local text = table.remove(queue, 1) -- 283
				local hex = table.remove(self.floatQueueHex[lane + 1], 1) -- 284
				if text ~= nil and hex ~= nil then -- 284
					self:playNotice(lane, text, hex) -- 286
				end -- 286
			end -- 286
			::__continue47:: -- 286
			lane = lane + 1 -- 273
		end -- 273
	end -- 273
	if self.hitTint > 0 then -- 273
		self.hitTint = self.hitTint - dt * 320 -- 290
		if self.hitTint < 0 then -- 290
			self.hitTint = 0 -- 292
		end -- 292
		self:drawHitTint() -- 294
	end -- 294
end -- 263
function Hud.prototype.setStageInfo(self, text) -- 298
	if self.stageLabel ~= nil then -- 298
		self.stageLabel.text = text -- 300
	end -- 300
end -- 298
function Hud.prototype.setEnemyInfo(self, name, hp, maxHp) -- 304
	if self.enemyName ~= nil then -- 304
		self.enemyName.text = name -- 306
	end -- 306
	self.enemyBar:set( -- 308
		(("敌方生命 " .. tostring(hp)) .. "/") .. tostring(maxHp), -- 308
		hp, -- 308
		maxHp -- 308
	) -- 308
end -- 304
function Hud.prototype.setTimerInfo(self, text, remainingRatio) -- 311
	if remainingRatio == nil then -- 311
		remainingRatio = 1 -- 311
	end -- 311
	if self.timerLabel ~= nil then -- 311
		self.timerLabel.text = text -- 313
	end -- 313
	self.timerBar:set("", remainingRatio * 100, 100) -- 316
end -- 311
function Hud.prototype.setPlayerInfo(self, hp, maxHp, mana, maxMana) -- 319
	self.playerBar:set( -- 320
		(("生命 " .. tostring(hp)) .. "/") .. tostring(maxHp), -- 320
		hp, -- 320
		maxHp -- 320
	) -- 320
	self.manaBar:set( -- 321
		(("魔力 " .. tostring(mana)) .. "/") .. tostring(maxMana), -- 321
		mana, -- 321
		maxMana -- 321
	) -- 321
end -- 319
function Hud.prototype.glowSkill(self, skillId) -- 325
	do -- 325
		local i = 0 -- 326
		while i < #self.skillIds do -- 326
			if self.skillIds[i + 1] == skillId then -- 326
				self.skillButtons[i + 1]:glow() -- 328
				return -- 329
			end -- 329
			i = i + 1 -- 326
		end -- 326
	end -- 326
end -- 325
function Hud.prototype.syncSkills(self, mana) -- 335
	do -- 335
		local i = 0 -- 336
		while i < #self.skillButtons do -- 336
			self.skillButtons[i + 1]:setEnabled(mana >= self.skillCosts[i + 1]) -- 337
			i = i + 1 -- 336
		end -- 336
	end -- 336
end -- 335
function Hud.prototype.showNotice(self, text, lane, hex) -- 345
	if lane == nil then -- 345
		lane = 2 -- 345
	end -- 345
	if hex == nil then -- 345
		hex = Palette.NoticeDefault -- 345
	end -- 345
	if #self.floatLanes == 0 then -- 345
		return -- 347
	end -- 347
	local index = lane -- 349
	if index < 0 or index >= #self.floatLanes then -- 349
		index = 2 -- 351
	end -- 351
	if not self.floatLanes[index + 1].active then -- 351
		self:playNotice(index, text, hex) -- 354
		return -- 355
	end -- 355
	local queue = self.floatQueue[index + 1] -- 357
	if #queue >= 3 then -- 357
		table.remove(queue, 1) -- 360
		table.remove(self.floatQueueHex[index + 1], 1) -- 361
	end -- 361
	queue[#queue + 1] = text -- 363
	local ____self_floatQueueHex_index_21 = self.floatQueueHex[index + 1] -- 363
	____self_floatQueueHex_index_21[#____self_floatQueueHex_index_21 + 1] = hex -- 364
end -- 345
function Hud.prototype.hitPlayer(self, damage) -- 368
	self.playerBar:flash(Palette.HitFlashPlayer, Config.HitFlashDuration) -- 369
	self.playerBar:shake(0.3, 6) -- 370
	self.hitTint = Config.PlayerHitTintAlpha -- 371
	self:drawHitTint() -- 372
	if damage > 0 then -- 372
		self:showNotice( -- 374
			"-" .. tostring(damage), -- 374
			1, -- 374
			Palette.NoticeDamage -- 374
		) -- 374
	end -- 374
end -- 368
function Hud.prototype.hitEnemy(self) -- 379
	self.enemyBar:flash(Palette.HitFlashEnemy, Config.HitFlashDuration) -- 380
	self.enemyBar:shake(0.22, 4) -- 381
end -- 379
function Hud.prototype.playNotice(self, lane, text, hex) -- 384
	self.floatLanes[lane + 1]:show(text, hex, ____exports.Hud.LaneX[lane + 1], ____exports.Hud.LaneY[lane + 1]) -- 385
end -- 384
function Hud.prototype.drawHitTint(self) -- 388
	self.hitLayer:clear() -- 389
	if self.hitTint <= 0 then -- 389
		return -- 391
	end -- 391
	self.hitLayer:drawPolygon( -- 393
		{ -- 394
			Vec2(-1600, -1100), -- 394
			Vec2(1600, -1100), -- 394
			Vec2(1600, 1100), -- 394
			Vec2(-1600, 1100) -- 394
		}, -- 394
		Color( -- 395
			255, -- 395
			60, -- 395
			50, -- 395
			math.floor(self.hitTint) -- 395
		) -- 395
	) -- 395
end -- 388
function Hud.prototype.showDefeat(self, text) -- 399
	if self.panelText ~= nil then -- 399
		self.panelText.text = text -- 401
	end -- 401
	for ____, part in ipairs(self.panelParts) do -- 403
		part.visible = true -- 404
	end -- 404
	self.restartButton:setEnabled(true) -- 407
end -- 399
function Hud.prototype.hideDefeat(self) -- 410
	for ____, part in ipairs(self.panelParts) do -- 411
		part.visible = false -- 412
	end -- 412
	self.restartButton:setEnabled(false) -- 414
end -- 410
Hud.LaneX = {Config.NoticeEnemyX, Config.NoticePlayerX, Config.NoticeSystemX} -- 410
Hud.LaneY = {Config.NoticeEnemyY, Config.NoticePlayerY, Config.NoticeSystemY} -- 410
__TS__SetDescriptor( -- 410
	Hud.prototype, -- 410
	"isSettingsOpen", -- 410
	{get = function(self) -- 410
		return self.settingsOpen -- 217
	end}, -- 217
	true -- 217
) -- 217
return ____exports -- 217
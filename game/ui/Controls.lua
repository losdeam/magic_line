-- [ts]: Controls.ts
local ____lualib = require("lualib_bundle") -- 1
local __TS__Class = ____lualib.__TS__Class -- 1
local __TS__ClassExtends = ____lualib.__TS__ClassExtends -- 1
local __TS__SetDescriptor = ____lualib.__TS__SetDescriptor -- 1
local ____exports = {} -- 1
local ____Dora = require("Dora") -- 4
local Color = ____Dora.Color -- 4
local Label = ____Dora.Label -- 4
local Vec2 = ____Dora.Vec2 -- 4
local ____Widget = require("game.ui.Widget") -- 5
local BaseWidget = ____Widget.BaseWidget -- 5
local colorFromHex = ____Widget.colorFromHex -- 5
--- 统一创建文本标签（`Label` 可能返回 undefined，因此集中判空与设置锚点）。
function ____exports.makeLabel(text, fontSize) -- 8
	local label = Label("sarasa-mono-sc-regular", fontSize) -- 9
	if label == nil then -- 9
		return nil -- 11
	end -- 11
	label.text = text -- 13
	label.color = Color(240, 245, 255, 255) -- 14
	label.anchor = Vec2(0.5, 0.5) -- 15
	return label -- 16
end -- 8
--- 纯色面板：HUD 底板与结算面板背景。
____exports.PanelWidget = __TS__Class() -- 20
local PanelWidget = ____exports.PanelWidget -- 20
PanelWidget.name = "PanelWidget" -- 20
__TS__ClassExtends(PanelWidget, BaseWidget) -- 20
function PanelWidget.prototype.____constructor(self, width, height, fillHex) -- 23
	BaseWidget.prototype.____constructor(self, width, height) -- 24
	self.fillHex = fillHex -- 25
	self:redraw() -- 26
end -- 23
function PanelWidget.prototype.drawSelf(self) -- 29
	self.canvas:drawPolygon( -- 30
		{ -- 31
			Vec2(0, 0), -- 31
			Vec2(self.width, 0), -- 31
			Vec2(self.width, self.height), -- 31
			Vec2(0, self.height) -- 31
		}, -- 31
		colorFromHex(self.fillHex, 235), -- 32
		2, -- 33
		colorFromHex(8359075, 200) -- 34
	) -- 34
end -- 29
--- 进度条：血条 / 魔力条 / 敌方血条；内置数值文本，并做缓动过渡。
____exports.BarWidget = __TS__Class() -- 40
local BarWidget = ____exports.BarWidget -- 40
BarWidget.name = "BarWidget" -- 40
__TS__ClassExtends(BarWidget, BaseWidget) -- 40
function BarWidget.prototype.____constructor(self, width, height, fillHex) -- 62
	BaseWidget.prototype.____constructor(self, width, height) -- 63
	self.shownRatio = 1 -- 43
	self.targetRatio = 1 -- 44
	self.initialized = false -- 45
	self.flashTimer = 0 -- 48
	self.flashDuration = 0.24 -- 49
	self.flashHex = 16777215 -- 50
	self.lastText = "" -- 52
	self.fillHex = fillHex -- 64
	local label = ____exports.makeLabel( -- 65
		"", -- 65
		math.max( -- 65
			14, -- 65
			math.floor(height * 0.66) -- 65
		) -- 65
	) -- 65
	if label ~= nil then -- 65
		label.position = Vec2(width / 2, height / 2) -- 67
		label:addTo(self.root) -- 68
	end -- 68
	self.label = label -- 70
	self:redraw() -- 71
end -- 62
function BarWidget.prototype.flash(self, hex, duration) -- 55
	self.flashHex = hex -- 56
	self.flashDuration = duration > 0 and duration or 0.24 -- 57
	self.flashTimer = self.flashDuration -- 58
	self:redraw() -- 59
end -- 55
function BarWidget.prototype.set(self, text, value, max) -- 75
	local ratio = max > 0 and value / max or 0 -- 76
	if ratio < 0 then -- 76
		ratio = 0 -- 78
	end -- 78
	if ratio > 1 then -- 78
		ratio = 1 -- 81
	end -- 81
	self.targetRatio = ratio -- 83
	if not self.initialized then -- 83
		self.initialized = true -- 86
		self.shownRatio = ratio -- 87
	end -- 87
	if self.label ~= nil then -- 87
		self.label.text = text -- 90
	end -- 90
	self.lastText = text -- 92
	self:redraw() -- 93
end -- 75
function BarWidget.prototype.update(self, dt) -- 102
	self:advanceShake(dt) -- 103
	local needRedraw = false -- 104
	if self.flashTimer > 0 then -- 104
		self.flashTimer = self.flashTimer - dt -- 106
		if self.flashTimer < 0 then -- 106
			self.flashTimer = 0 -- 108
		end -- 108
		needRedraw = true -- 110
	end -- 110
	local gap = self.targetRatio - self.shownRatio -- 112
	if math.abs(gap) >= 0.002 then -- 112
		local step = dt * 7 -- 114
		if step > 1 then -- 114
			step = 1 -- 116
		end -- 116
		self.shownRatio = self.shownRatio + gap * step -- 118
		needRedraw = true -- 119
	elseif self.shownRatio ~= self.targetRatio then -- 119
		self.shownRatio = self.targetRatio -- 121
		needRedraw = true -- 122
	end -- 122
	if needRedraw then -- 122
		self:redraw() -- 125
	end -- 125
end -- 102
function BarWidget.prototype.drawSelf(self) -- 129
	local w = self.width -- 130
	local h = self.height -- 131
	self.canvas:drawPolygon( -- 132
		{ -- 132
			Vec2(0, 0), -- 132
			Vec2(w, 0), -- 132
			Vec2(w, h), -- 132
			Vec2(0, h) -- 132
		}, -- 132
		colorFromHex(1119775, 230) -- 132
	) -- 132
	if self.shownRatio > 0 then -- 132
		self.canvas:drawPolygon( -- 134
			{ -- 135
				Vec2(0, 0), -- 135
				Vec2(w * self.shownRatio, 0), -- 135
				Vec2(w * self.shownRatio, h), -- 135
				Vec2(0, h) -- 135
			}, -- 135
			colorFromHex(self.fillHex, 240) -- 136
		) -- 136
	end -- 136
	if self.flashTimer > 0 then -- 136
		local alpha = math.floor(200 * (self.flashTimer / self.flashDuration)) -- 141
		self.canvas:drawPolygon( -- 142
			{ -- 143
				Vec2(0, 0), -- 143
				Vec2(w, 0), -- 143
				Vec2(w, h), -- 143
				Vec2(0, h) -- 143
			}, -- 143
			colorFromHex(self.flashHex, alpha) -- 144
		) -- 144
	end -- 144
	self.canvas:drawPolygon( -- 150
		{ -- 151
			Vec2(0, 0), -- 151
			Vec2(w, 0), -- 151
			Vec2(w, h), -- 151
			Vec2(0, h) -- 151
		}, -- 151
		Color(0, 0, 0, 0), -- 152
		2, -- 153
		colorFromHex(9413309, 170) -- 154
	) -- 154
end -- 129
__TS__SetDescriptor( -- 129
	BarWidget.prototype, -- 129
	"text", -- 129
	{get = function(self) -- 129
		return self.lastText -- 98
	end}, -- 98
	true -- 98
) -- 98
--- 按钮：点按结束触发 `onClick`；禁用时变灰且不再接收触控。
____exports.ButtonWidget = __TS__Class() -- 160
local ButtonWidget = ____exports.ButtonWidget -- 160
ButtonWidget.name = "ButtonWidget" -- 160
__TS__ClassExtends(ButtonWidget, BaseWidget) -- 160
function ButtonWidget.prototype.____constructor(self, text, width, height, hex) -- 170
	BaseWidget.prototype.____constructor(self, width, height) -- 171
	self.pressed = false -- 164
	self.glowTimer = 0 -- 166
	self.glowDuration = 0.45 -- 167
	self.onClick = function() -- 168
	end -- 168
	self.hex = hex -- 172
	local label = ____exports.makeLabel( -- 173
		text, -- 173
		math.max( -- 173
			16, -- 173
			math.floor(height * 0.4) -- 173
		) -- 173
	) -- 173
	if label ~= nil then -- 173
		label.position = Vec2(width / 2, height / 2) -- 175
		label:addTo(self.root) -- 176
	end -- 176
	self.label = label -- 178
	self:enableTouch() -- 179
	self:redraw() -- 180
end -- 170
function ButtonWidget.prototype.setText(self, text) -- 183
	if self.label ~= nil then -- 183
		self.label.text = text -- 185
	end -- 185
end -- 183
function ButtonWidget.prototype.glow(self) -- 190
	self.glowTimer = self.glowDuration -- 191
	self:redraw() -- 192
end -- 190
function ButtonWidget.prototype.update(self, dt) -- 196
	self:advanceShake(dt) -- 197
	if self.glowTimer <= 0 then -- 197
		return -- 199
	end -- 199
	self.glowTimer = self.glowTimer - dt -- 201
	if self.glowTimer < 0 then -- 201
		self.glowTimer = 0 -- 203
	end -- 203
	self:redraw() -- 205
end -- 196
function ButtonWidget.prototype.setEnabled(self, on) -- 208
	if self.enabled == on then -- 208
		return -- 210
	end -- 210
	self.enabled = on -- 212
	self.root.touchEnabled = on -- 213
	self:redraw() -- 214
end -- 208
function ButtonWidget.prototype.handleTapBegan(self, _location) -- 217
	if not self.enabled then -- 217
		return -- 219
	end -- 219
	self.pressed = true -- 221
	self.root.scaleX = 0.93 -- 222
	self.root.scaleY = 0.93 -- 223
end -- 217
function ButtonWidget.prototype.handleTapEnded(self, _location) -- 226
	if self.pressed then -- 226
		self.pressed = false -- 228
		self.root.scaleX = 1 -- 229
		self.root.scaleY = 1 -- 230
	end -- 230
	if self.enabled then -- 230
		self:onClick() -- 233
	end -- 233
end -- 226
function ButtonWidget.prototype.drawSelf(self) -- 237
	local w = self.width -- 238
	local h = self.height -- 239
	local base = self.enabled and self.hex or 3752271 -- 240
	self.canvas:drawPolygon( -- 241
		{ -- 242
			Vec2(0, 0), -- 242
			Vec2(w, 0), -- 242
			Vec2(w, h), -- 242
			Vec2(0, h) -- 242
		}, -- 242
		colorFromHex(base, 245), -- 243
		3, -- 244
		colorFromHex(10466257, 220) -- 245
	) -- 245
	if self.glowTimer > 0 then -- 245
		local alpha = math.floor(215 * (self.glowTimer / self.glowDuration)) -- 248
		self.canvas:drawPolygon( -- 249
			{ -- 249
				Vec2(0, 0), -- 249
				Vec2(w, 0), -- 249
				Vec2(w, h), -- 249
				Vec2(0, h) -- 249
			}, -- 249
			Color(255, 255, 255, alpha) -- 249
		) -- 249
	end -- 249
end -- 237
--- 飘字：向上飘并淡出，用于展示效果与提示。
____exports.FloatTextWidget = __TS__Class() -- 255
local FloatTextWidget = ____exports.FloatTextWidget -- 255
FloatTextWidget.name = "FloatTextWidget" -- 255
__TS__ClassExtends(FloatTextWidget, BaseWidget) -- 255
function FloatTextWidget.prototype.____constructor(self, fontSize) -- 260
	BaseWidget.prototype.____constructor(self, 560, 40) -- 261
	self.duration = 1.2 -- 257
	self.life = 0 -- 258
	local label = ____exports.makeLabel("", fontSize) -- 262
	if label ~= nil then -- 262
		label.position = Vec2(280, 20) -- 264
		label:addTo(self.root) -- 265
	end -- 265
	self.label = label -- 267
	self.visible = false -- 268
end -- 260
function FloatTextWidget.prototype.show(self, text, hex, x, y) -- 275
	if self.label ~= nil then -- 275
		self.label.text = text -- 277
		self.label.color = colorFromHex(hex, 255) -- 278
	end -- 278
	self.life = self.duration -- 280
	self.visible = true -- 281
	self.root.opacity = 1 -- 282
	self:setPosition(x, y) -- 283
end -- 275
function FloatTextWidget.prototype.update(self, dt) -- 286
	if self.life <= 0 then -- 286
		return -- 288
	end -- 288
	self.life = self.life - dt -- 290
	if self.life <= 0 then -- 290
		self.life = 0 -- 292
		self.visible = false -- 293
		return -- 294
	end -- 294
	local t = self.life / self.duration -- 296
	self.root.position = Vec2(self.root.x, self.root.y + 46 * dt) -- 297
	self.root.opacity = t > 0.5 and 1 or t * 2 -- 298
end -- 286
__TS__SetDescriptor( -- 286
	FloatTextWidget.prototype, -- 286
	"active", -- 286
	{get = function(self) -- 286
		return self.life > 0 -- 272
	end}, -- 272
	true -- 272
) -- 272
return ____exports -- 272
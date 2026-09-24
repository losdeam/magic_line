-- [ts]: Widget.ts
local ____lualib = require("lualib_bundle") -- 1
local __TS__Class = ____lualib.__TS__Class -- 1
local __TS__SetDescriptor = ____lualib.__TS__SetDescriptor -- 1
local ____exports = {} -- 1
local ____Dora = require("Dora") -- 4
local Color = ____Dora.Color -- 4
local DrawNode = ____Dora.DrawNode -- 4
local Node = ____Dora.Node -- 4
local Size = ____Dora.Size -- 4
local Vec2 = ____Dora.Vec2 -- 4
--- 把 0xRRGGBB 转成 Dora 的 Color 对象。
function ____exports.colorFromHex(hex, alpha) -- 7
	if alpha == nil then -- 7
		alpha = 255 -- 7
	end -- 7
	local r = math.floor(hex / 65536) % 256 -- 8
	local g = math.floor(hex / 256) % 256 -- 9
	local b = hex % 256 -- 10
	return Color(r, g, b, alpha) -- 11
end -- 7
--- 所有 UI 元素的基类：方块、面板、按钮、血条、飘字均从此派生。
-- 控件自身不注册 schedule，动画由 Game 的单一循环调用 update(dt) 驱动。
____exports.BaseWidget = __TS__Class() -- 18
local BaseWidget = ____exports.BaseWidget -- 18
BaseWidget.name = "BaseWidget" -- 18
function BaseWidget.prototype.____constructor(self, width, height) -- 32
	self.selected = false -- 23
	self.enabled = true -- 24
	self.baseX = 0 -- 26
	self.baseY = 0 -- 27
	self.shakeTimer = 0 -- 28
	self.shakeDuration = 0.24 -- 29
	self.shakeAmplitude = 5 -- 30
	self.width = width -- 33
	self.height = height -- 34
	local root = Node() -- 35
	root.size = Size(width, height) -- 36
	root.anchor = Vec2(0.5, 0.5) -- 37
	root.touchEnabled = false -- 38
	self.root = root -- 39
	local canvas = DrawNode() -- 40
	canvas:addTo(root) -- 41
	self.canvas = canvas -- 42
end -- 32
function BaseWidget.prototype.addTo(self, parent) -- 45
	self.root:addTo(parent) -- 46
end -- 45
function BaseWidget.prototype.setPosition(self, x, y) -- 49
	self.baseX = x -- 50
	self.baseY = y -- 51
	self.root.position = Vec2(x, y) -- 52
end -- 49
function BaseWidget.prototype.shake(self, duration, amplitude) -- 56
	if duration == nil then -- 56
		duration = 0.24 -- 56
	end -- 56
	if amplitude == nil then -- 56
		amplitude = 5 -- 56
	end -- 56
	self.shakeDuration = duration > 0 and duration or 0.24 -- 57
	self.shakeAmplitude = amplitude -- 58
	self.shakeTimer = self.shakeDuration -- 59
end -- 56
function BaseWidget.prototype.advanceShake(self, dt) -- 63
	if self.shakeTimer <= 0 then -- 63
		return -- 65
	end -- 65
	self.shakeTimer = self.shakeTimer - dt -- 67
	if self.shakeTimer <= 0 then -- 67
		self.shakeTimer = 0 -- 69
		self.root.position = Vec2(self.baseX, self.baseY) -- 70
		return -- 71
	end -- 71
	local t = self.shakeTimer / self.shakeDuration -- 73
	self.root.position = Vec2( -- 74
		self.baseX + math.sin(self.shakeTimer * 62) * self.shakeAmplitude * t, -- 74
		self.baseY -- 74
	) -- 74
end -- 63
function BaseWidget.prototype.enableTouch(self) -- 94
	self.root.touchEnabled = true -- 95
	self.root:onTapBegan(function(touch) return self:handleTapBegan(touch.location) end) -- 96
	self.root:onTapMoved(function(touch) return self:handleTapMoved(touch.location) end) -- 97
	self.root:onTapEnded(function(touch) return self:handleTapEnded(touch.location) end) -- 98
end -- 94
function BaseWidget.prototype.setSelected(self, on) -- 101
	if self.selected == on then -- 101
		return -- 103
	end -- 103
	self.selected = on -- 105
	self:redraw() -- 106
end -- 101
function BaseWidget.prototype.update(self, _dt) -- 110
end -- 110
function BaseWidget.prototype.redraw(self) -- 113
	self.canvas:clear() -- 114
	self:drawSelf() -- 115
end -- 113
function BaseWidget.prototype.drawSelf(self) -- 119
end -- 119
function BaseWidget.prototype.handleTapBegan(self, _location) -- 122
end -- 122
function BaseWidget.prototype.handleTapMoved(self, _location) -- 125
end -- 125
function BaseWidget.prototype.handleTapEnded(self, _location) -- 128
end -- 128
__TS__SetDescriptor( -- 128
	BaseWidget.prototype, -- 128
	"visible", -- 128
	{ -- 128
		get = function(self) -- 128
			return self.root.visible -- 78
		end, -- 78
		set = function(self, value) -- 78
			self.root.visible = value -- 82
		end -- 82
	}, -- 82
	true -- 82
) -- 82
__TS__SetDescriptor( -- 82
	BaseWidget.prototype, -- 82
	"z", -- 82
	{ -- 82
		get = function(self) -- 82
			return self.root.z -- 86
		end, -- 86
		set = function(self, value) -- 86
			self.root.z = value -- 90
		end -- 90
	}, -- 90
	true -- 90
) -- 90
return ____exports -- 90
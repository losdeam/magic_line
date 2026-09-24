-- [ts]: BlockWidget.ts
local ____lualib = require("lualib_bundle") -- 1
local __TS__Class = ____lualib.__TS__Class -- 1
local __TS__ClassExtends = ____lualib.__TS__ClassExtends -- 1
local __TS__SetDescriptor = ____lualib.__TS__SetDescriptor -- 1
local ____exports = {} -- 1
local ____Dora = require("Dora") -- 4
local Color = ____Dora.Color -- 4
local Label = ____Dora.Label -- 4
local Vec2 = ____Dora.Vec2 -- 4
local ____Widget = require("game.ui.Widget") -- 6
local BaseWidget = ____Widget.BaseWidget -- 6
local colorFromHex = ____Widget.colorFromHex -- 6
--- 把颜色向白色插值，用于方块描边，不改动注册表数据。
local function lighten(hex, ratio) -- 9
	local r = math.floor(hex / 65536) % 256 -- 10
	local g = math.floor(hex / 256) % 256 -- 11
	local b = hex % 256 -- 12
	local nr = math.min( -- 13
		255, -- 13
		math.floor(r + (255 - r) * ratio) -- 13
	) -- 13
	local ng = math.min( -- 14
		255, -- 14
		math.floor(g + (255 - g) * ratio) -- 14
	) -- 14
	local nb = math.min( -- 15
		255, -- 15
		math.floor(b + (255 - b) * ratio) -- 15
	) -- 15
	return nr * 65536 + ng * 256 + nb -- 16
end -- 9
____exports.BlockWidget = __TS__Class() -- 19
local BlockWidget = ____exports.BlockWidget -- 19
BlockWidget.name = "BlockWidget" -- 19
__TS__ClassExtends(BlockWidget, BaseWidget) -- 19
function BlockWidget.prototype.____constructor(self, def, size) -- 31
	BaseWidget.prototype.____constructor(self, size, size) -- 32
	self.lockTurns = 0 -- 24
	self.locked = false -- 26
	self.current = def -- 33
	local label = Label( -- 34
		"sarasa-mono-sc-regular", -- 34
		math.floor(size * 0.4) -- 34
	) -- 34
	if label ~= nil then -- 34
		label.text = def.glyph -- 36
		label.batched = true -- 37
		label.color = Color(255, 255, 255, 255) -- 38
		label.position = Vec2(size / 2, size / 2) -- 39
		label:addTo(self.root) -- 40
	end -- 40
	self.glyph = label -- 42
	local badge = Label( -- 43
		"sarasa-mono-sc-regular", -- 43
		math.max( -- 43
			12, -- 43
			math.floor(size * 0.3) -- 43
		) -- 43
	) -- 43
	if badge ~= nil then -- 43
		badge.text = "" -- 45
		badge.batched = true -- 46
		badge.color = Color(255, 214, 120, 255) -- 47
		badge.position = Vec2(size - size * ____exports.BlockWidget.badgeRatio, size - size * ____exports.BlockWidget.badgeRatio) -- 48
		badge.visible = false -- 49
		badge:addTo(self.root) -- 50
	end -- 50
	self.badge = badge -- 52
	self:redraw() -- 53
end -- 31
function BlockWidget.prototype.setDef(self, def) -- 61
	self.current = def -- 62
	local label = self.glyph -- 63
	if label ~= nil then -- 63
		label.text = def.glyph -- 65
	end -- 65
	self:redraw() -- 67
end -- 61
function BlockWidget.prototype.setLocked(self, on) -- 70
	if self.locked == on then -- 70
		return -- 72
	end -- 72
	self.locked = on -- 74
	if not on then -- 74
		self.lockTurns = 0 -- 77
		self:applyBadge() -- 78
	end -- 78
	self:redraw() -- 80
end -- 70
function BlockWidget.prototype.setLockTurns(self, turns) -- 84
	local next = turns > 0 and math.floor(turns) or 0 -- 85
	if self.lockTurns == next then -- 85
		return -- 87
	end -- 87
	self.lockTurns = next -- 89
	self:applyBadge() -- 90
	self:redraw() -- 91
end -- 84
function BlockWidget.prototype.applyBadge(self) -- 100
	local badge = self.badge -- 101
	if badge == nil then -- 101
		return -- 103
	end -- 103
	local show = self.locked and self.lockTurns > 0 -- 105
	badge.text = show and "" .. tostring(self.lockTurns) or "" -- 106
	badge.visible = show -- 107
	badge.color = self.lockTurns <= 1 and Color(255, 156, 120, 255) or Color(255, 214, 120, 255) -- 109
end -- 100
function BlockWidget.prototype.drawSelf(self) -- 112
	local size = self.width -- 113
	local inset = math.max( -- 114
		2, -- 114
		math.floor(size * 0.06) -- 114
	) -- 114
	local verts = { -- 115
		Vec2(inset, inset), -- 116
		Vec2(size - inset, inset), -- 117
		Vec2(size - inset, size - inset), -- 118
		Vec2(inset, size - inset) -- 119
	} -- 119
	local alpha = self.locked and 130 or 255 -- 121
	local fill = colorFromHex(self.current.color, alpha) -- 122
	if self.selected then -- 122
		self.canvas:drawPolygon( -- 124
			verts, -- 124
			fill, -- 124
			6, -- 124
			Color(255, 255, 255, 255) -- 124
		) -- 124
	else -- 124
		self.canvas:drawPolygon( -- 126
			verts, -- 126
			fill, -- 126
			2, -- 126
			colorFromHex( -- 126
				lighten(self.current.color, 0.35), -- 126
				220 -- 126
			) -- 126
		) -- 126
	end -- 126
	if self.locked and self.lockTurns > 0 then -- 126
		local radius = math.max( -- 130
			9, -- 130
			math.floor(size * 0.2) -- 130
		) -- 130
		self.canvas:drawDot( -- 131
			Vec2(size - size * ____exports.BlockWidget.badgeRatio, size - size * ____exports.BlockWidget.badgeRatio), -- 132
			radius, -- 133
			Color(24, 26, 32, 235) -- 134
		) -- 134
	end -- 134
end -- 112
BlockWidget.badgeRatio = 0.24 -- 112
__TS__SetDescriptor( -- 112
	BlockWidget.prototype, -- 112
	"def", -- 112
	{get = function(self) -- 112
		return self.current -- 57
	end}, -- 57
	true -- 57
) -- 57
__TS__SetDescriptor( -- 57
	BlockWidget.prototype, -- 57
	"badgeText", -- 57
	{get = function(self) -- 57
		local badge = self.badge -- 96
		return badge ~= nil and badge.text or "" -- 97
	end}, -- 97
	true -- 97
) -- 97
return ____exports -- 97
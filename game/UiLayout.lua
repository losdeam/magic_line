-- [ts]: UiLayout.ts
local ____lualib = require("lualib_bundle") -- 1
local __TS__Class = ____lualib.__TS__Class -- 1
local ____exports = {} -- 1
local ____Config = require("game.Config") -- 6
local Config = ____Config.Config -- 6
--- 设计空间安全区：因为 zoom = min(w/基准宽, h/基准高)，
-- 无论窗口宽高比如何，至少 960×1080 设计单位可见（原点为屏幕中心）。
____exports.SafeBox = __TS__Class() -- 12
local SafeBox = ____exports.SafeBox -- 12
SafeBox.name = "SafeBox" -- 12
function SafeBox.prototype.____constructor(self) -- 12
end -- 12
SafeBox.HalfWidth = Config.DesignSceneWidth / 2 -- 12
SafeBox.HalfHeight = Config.DesignSceneHeight / 2 -- 12
--- 由窗口尺寸计算摄像机 zoom（与 init.ts 共用，保证入口与自检用同一套公式）。
-- 窗口未就绪（宽或高 < 1）时按基准尺寸处理，返回 1。
function ____exports.zoomFor(viewWidth, viewHeight) -- 30
	local width = viewWidth -- 31
	local height = viewHeight -- 32
	if width < 1 then -- 32
		width = Config.DesignSceneWidth -- 34
	end -- 34
	if height < 1 then -- 34
		height = Config.DesignSceneHeight -- 37
	end -- 37
	local widthScale = width / Config.DesignSceneWidth -- 39
	local heightScale = height / Config.DesignSceneHeight -- 40
	local scale = widthScale < heightScale and widthScale or heightScale -- 41
	if scale < 0.05 then -- 41
		return 0.05 -- 44
	end -- 44
	return scale -- 46
end -- 30
--- 给定窗口尺寸下实际可见的设计空间半宽/半高（用于极端宽高比检查）。
function ____exports.visibleHalfExtent(viewWidth, viewHeight) -- 50
	local width = viewWidth < 1 and Config.DesignSceneWidth or viewWidth -- 51
	local height = viewHeight < 1 and Config.DesignSceneHeight or viewHeight -- 52
	local zoom = ____exports.zoomFor(viewWidth, viewHeight) -- 53
	return { -- 54
		name = "visible", -- 54
		x = 0, -- 54
		y = 0, -- 54
		width = width / zoom, -- 54
		height = height / zoom -- 54
	} -- 54
end -- 50
--- 矩形是否完全落在安全区内（含 0.01 的浮点容差）。
function ____exports.insideSafeBox(rect) -- 58
	return math.abs(rect.x) + rect.width * 0.5 <= ____exports.SafeBox.HalfWidth + 0.01 and math.abs(rect.y) + rect.height * 0.5 <= ____exports.SafeBox.HalfHeight + 0.01 -- 59
end -- 58
--- HUD/面板配色（与方块配色分开；数值与原硬编码保持一致）。
____exports.Palette = __TS__Class() -- 64
local Palette = ____exports.Palette -- 64
Palette.name = "Palette" -- 64
function Palette.prototype.____constructor(self) -- 64
end -- 64
Palette.EnemyBar = 13649212 -- 64
Palette.PlayerBar = 4633190 -- 64
Palette.ManaBar = 3898336 -- 64
Palette.TimerBar = 14725692 -- 64
Palette.ButtonPrimary = 3108816 -- 64
Palette.ButtonNeutral = 3752271 -- 64
Palette.PanelBackground = 1777968 -- 64
Palette.NoticeDefault = 16770442 -- 64
Palette.NoticeDamage = 16747130 -- 64
Palette.HitFlashPlayer = 16734794 -- 64
Palette.HitFlashEnemy = 16777215 -- 64
Palette.TextOk = 10477728 -- 64
Palette.TextWarn = 16757611 -- 64
--- HUD 排版常量：坐标以屏幕中心为原点、+X 右、+Y 上（设计单位）。
-- 自上而下依次为 关卡标签 → 敌人名 → 敌方血条 → 行动进度条 → 倒计时 → 玩家血条 → 魔力条 → 技能按钮。
____exports.HudLayout = __TS__Class() -- 97
local HudLayout = ____exports.HudLayout -- 97
HudLayout.name = "HudLayout" -- 97
function HudLayout.prototype.____constructor(self) -- 97
end -- 97
HudLayout.FontStage = 24 -- 97
HudLayout.FontName = 28 -- 97
HudLayout.FontLabel = 22 -- 97
HudLayout.FontNotice = 26 -- 97
HudLayout.FontSmall = 20 -- 97
HudLayout.FontPanelTitle = 34 -- 97
HudLayout.FontPanelTitleLarge = 40 -- 97
HudLayout.StageY = 508 -- 97
HudLayout.EnemyNameY = 480 -- 97
HudLayout.EnemyBarY = 448 -- 97
HudLayout.EnemyBarWidth = 520 -- 97
HudLayout.EnemyBarHeight = 26 -- 97
HudLayout.TimerBarY = 428 -- 97
HudLayout.TimerBarWidth = 520 -- 97
HudLayout.TimerBarHeight = 10 -- 97
HudLayout.TimerLabelY = 412 -- 97
HudLayout.PlayerBarY = 372 -- 97
HudLayout.PlayerBarWidth = 460 -- 97
HudLayout.PlayerBarHeight = 26 -- 97
HudLayout.PlayerNameX = -262 -- 97
HudLayout.ManaBarY = 340 -- 97
HudLayout.ManaBarWidth = 460 -- 97
HudLayout.ManaBarHeight = 20 -- 97
HudLayout.SkillButtonY = 292 -- 97
HudLayout.SkillButtonWidth = 220 -- 97
HudLayout.SkillButtonHeight = 56 -- 97
HudLayout.SkillButtonSpacing = 240 -- 97
HudLayout.SettingsButtonX = 370 -- 97
HudLayout.SettingsButtonY = 492 -- 97
HudLayout.SettingsButtonWidth = 140 -- 97
HudLayout.SettingsButtonHeight = 46 -- 97
HudLayout.HintY = -505 -- 97
HudLayout.LaneCount = 3 -- 97
HudLayout.SettingsPanelWidth = 560 -- 97
HudLayout.SettingsPanelHeight = 420 -- 97
HudLayout.SettingsTitleY = 160 -- 97
HudLayout.SettingsRowWidth = 320 -- 97
HudLayout.SettingsRowHeight = 54 -- 97
HudLayout.SettingsModeY = 95 -- 97
HudLayout.SettingsDifficultyY = 25 -- 97
HudLayout.SettingsHintY = -45 -- 97
HudLayout.SettingsCloseY = -130 -- 97
HudLayout.SettingsCloseWidth = 220 -- 97
HudLayout.SettingsCloseHeight = 50 -- 97
HudLayout.SettingsSaveY = -185 -- 97
HudLayout.DefeatPanelWidth = 640 -- 97
HudLayout.DefeatPanelHeight = 360 -- 97
HudLayout.DefeatTitleY = 110 -- 97
HudLayout.DefeatTextY = 20 -- 97
HudLayout.DefeatButtonY = -110 -- 97
HudLayout.DefeatButtonWidth = 260 -- 97
HudLayout.DefeatButtonHeight = 70 -- 97
HudLayout.NoticeRise = 56 -- 97
HudLayout.HintMaxChars = 25 -- 97
HudLayout.StageMaxChars = 16 -- 97
HudLayout.TimerMaxChars = 14 -- 97
HudLayout.NoticeMaxChars = 18 -- 97
HudLayout.PlayerNameMaxChars = 4 -- 97
HudLayout.EnemyNameMaxChars = 6 -- 97
--- 文字行高估算：字号 × 1.5。
local function lineHeight(fontSize) -- 179
	return fontSize * 1.5 -- 180
end -- 179
--- 列出所有 HUD/面板元素的矩形范围（含按最长文本估算的文字宽度），供自检断言
-- 「任何宽高比下都可见、彼此不越界」。新增 HUD 元素时应同步补充此处。
function ____exports.hudLayoutRects() -- 187
	local rects = {} -- 188
	rects[#rects + 1] = { -- 189
		name = "关卡标签", -- 189
		x = 0, -- 189
		y = ____exports.HudLayout.StageY, -- 189
		width = ____exports.HudLayout.StageMaxChars * ____exports.HudLayout.FontStage, -- 189
		height = lineHeight(____exports.HudLayout.FontStage) -- 189
	} -- 189
	rects[#rects + 1] = { -- 190
		name = "敌人名", -- 190
		x = 0, -- 190
		y = ____exports.HudLayout.EnemyNameY, -- 190
		width = ____exports.HudLayout.EnemyNameMaxChars * ____exports.HudLayout.FontName, -- 190
		height = lineHeight(____exports.HudLayout.FontName) -- 190
	} -- 190
	rects[#rects + 1] = { -- 191
		name = "敌方血条", -- 191
		x = 0, -- 191
		y = ____exports.HudLayout.EnemyBarY, -- 191
		width = ____exports.HudLayout.EnemyBarWidth, -- 191
		height = ____exports.HudLayout.EnemyBarHeight -- 191
	} -- 191
	rects[#rects + 1] = { -- 192
		name = "行动进度条", -- 192
		x = 0, -- 192
		y = ____exports.HudLayout.TimerBarY, -- 192
		width = ____exports.HudLayout.TimerBarWidth, -- 192
		height = ____exports.HudLayout.TimerBarHeight -- 192
	} -- 192
	rects[#rects + 1] = { -- 193
		name = "行动倒计时", -- 193
		x = 0, -- 193
		y = ____exports.HudLayout.TimerLabelY, -- 193
		width = ____exports.HudLayout.TimerMaxChars * ____exports.HudLayout.FontLabel, -- 193
		height = lineHeight(____exports.HudLayout.FontLabel) -- 193
	} -- 193
	rects[#rects + 1] = { -- 194
		name = "玩家血条", -- 194
		x = 0, -- 194
		y = ____exports.HudLayout.PlayerBarY, -- 194
		width = ____exports.HudLayout.PlayerBarWidth, -- 194
		height = ____exports.HudLayout.PlayerBarHeight -- 194
	} -- 194
	rects[#rects + 1] = { -- 195
		name = "玩家生命标签", -- 196
		x = ____exports.HudLayout.PlayerNameX - ____exports.HudLayout.PlayerNameMaxChars * ____exports.HudLayout.FontLabel / 2, -- 197
		y = ____exports.HudLayout.PlayerBarY, -- 198
		width = ____exports.HudLayout.PlayerNameMaxChars * ____exports.HudLayout.FontLabel, -- 199
		height = lineHeight(____exports.HudLayout.FontLabel) -- 200
	} -- 200
	rects[#rects + 1] = { -- 202
		name = "魔力条", -- 202
		x = 0, -- 202
		y = ____exports.HudLayout.ManaBarY, -- 202
		width = ____exports.HudLayout.ManaBarWidth, -- 202
		height = ____exports.HudLayout.ManaBarHeight -- 202
	} -- 202
	rects[#rects + 1] = { -- 203
		name = "技能按钮1", -- 203
		x = -____exports.HudLayout.SkillButtonSpacing / 2, -- 203
		y = ____exports.HudLayout.SkillButtonY, -- 203
		width = ____exports.HudLayout.SkillButtonWidth, -- 203
		height = ____exports.HudLayout.SkillButtonHeight -- 203
	} -- 203
	rects[#rects + 1] = { -- 204
		name = "技能按钮2", -- 204
		x = ____exports.HudLayout.SkillButtonSpacing / 2, -- 204
		y = ____exports.HudLayout.SkillButtonY, -- 204
		width = ____exports.HudLayout.SkillButtonWidth, -- 204
		height = ____exports.HudLayout.SkillButtonHeight -- 204
	} -- 204
	rects[#rects + 1] = { -- 205
		name = "设置按钮", -- 205
		x = ____exports.HudLayout.SettingsButtonX, -- 205
		y = ____exports.HudLayout.SettingsButtonY, -- 205
		width = ____exports.HudLayout.SettingsButtonWidth, -- 205
		height = ____exports.HudLayout.SettingsButtonHeight -- 205
	} -- 205
	rects[#rects + 1] = { -- 206
		name = "操作提示", -- 206
		x = 0, -- 206
		y = ____exports.HudLayout.HintY, -- 206
		width = ____exports.HudLayout.HintMaxChars * ____exports.HudLayout.FontLabel, -- 206
		height = lineHeight(____exports.HudLayout.FontLabel) -- 206
	} -- 206
	local noticeWidth = ____exports.HudLayout.NoticeMaxChars * ____exports.HudLayout.FontNotice -- 208
	rects[#rects + 1] = { -- 209
		name = "对敌飘字道", -- 209
		x = Config.NoticeEnemyX, -- 209
		y = Config.NoticeEnemyY + ____exports.HudLayout.NoticeRise / 2, -- 209
		width = noticeWidth, -- 209
		height = ____exports.HudLayout.NoticeRise + lineHeight(____exports.HudLayout.FontNotice) -- 209
	} -- 209
	rects[#rects + 1] = { -- 210
		name = "我方飘字道", -- 210
		x = Config.NoticePlayerX, -- 210
		y = Config.NoticePlayerY + ____exports.HudLayout.NoticeRise / 2, -- 210
		width = noticeWidth, -- 210
		height = ____exports.HudLayout.NoticeRise + lineHeight(____exports.HudLayout.FontNotice) -- 210
	} -- 210
	rects[#rects + 1] = { -- 211
		name = "系统飘字道", -- 211
		x = Config.NoticeSystemX, -- 211
		y = Config.NoticeSystemY + ____exports.HudLayout.NoticeRise / 2, -- 211
		width = noticeWidth, -- 211
		height = ____exports.HudLayout.NoticeRise + lineHeight(____exports.HudLayout.FontNotice) -- 211
	} -- 211
	rects[#rects + 1] = { -- 213
		name = "设置面板", -- 213
		x = 0, -- 213
		y = 0, -- 213
		width = ____exports.HudLayout.SettingsPanelWidth, -- 213
		height = ____exports.HudLayout.SettingsPanelHeight -- 213
	} -- 213
	rects[#rects + 1] = { -- 214
		name = "结算面板", -- 214
		x = 0, -- 214
		y = 0, -- 214
		width = ____exports.HudLayout.DefeatPanelWidth, -- 214
		height = ____exports.HudLayout.DefeatPanelHeight -- 214
	} -- 214
	return rects -- 215
end -- 187
--- 棋盘在设计空间中的矩形范围（容器尺寸 7×格宽，中心位于 Config.BoardCenterY）。
function ____exports.boardLayoutRect() -- 219
	local span = Config.Columns * Config.CellSize -- 220
	return { -- 221
		name = "棋盘", -- 221
		x = 0, -- 221
		y = Config.BoardCenterY, -- 221
		width = span, -- 221
		height = span -- 221
	} -- 221
end -- 219
return ____exports -- 219
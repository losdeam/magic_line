-- [ts]: Settings.ts
local ____lualib = require("lualib_bundle") -- 1
local __TS__StringReplace = ____lualib.__TS__StringReplace -- 1
local __TS__StringTrim = ____lualib.__TS__StringTrim -- 1
local __TS__StringSubstring = ____lualib.__TS__StringSubstring -- 1
local __TS__Class = ____lualib.__TS__Class -- 1
local __TS__New = ____lualib.__TS__New -- 1
local __TS__StringSplit = ____lualib.__TS__StringSplit -- 1
local ____exports = {} -- 1
local ____Dora = require("Dora") -- 4
local Content = ____Dora.Content -- 4
local ____Config = require("game.Config") -- 5
local Config = ____Config.Config -- 5
--- 默认存档文件名（可传入其它文件名以便自检）。
____exports.SettingsFile = "settings.txt" -- 8
local function parseLine(line) -- 15
	local trimmed = __TS__StringTrim(__TS__StringReplace(line, "\r", "")) -- 16
	local at = (string.find(trimmed, "=", nil, true) or 0) - 1 -- 17
	if at < 0 then -- 17
		return {key = "", value = ""} -- 19
	end -- 19
	return { -- 21
		key = __TS__StringSubstring(trimmed, 0, at), -- 21
		value = __TS__StringSubstring(trimmed, at + 1) -- 21
	} -- 21
end -- 15
____exports.Settings = __TS__Class() -- 24
local Settings = ____exports.Settings -- 24
Settings.name = "Settings" -- 24
function Settings.prototype.____constructor(self) -- 24
	self.mode = "turnBased" -- 25
	self.difficulty = "standard" -- 26
	self.showHint = true -- 27
	self.saved = true -- 29
end -- 24
function Settings.load(self, fileName) -- 32
	if fileName == nil then -- 32
		fileName = ____exports.SettingsFile -- 32
	end -- 32
	local settings = __TS__New(____exports.Settings) -- 33
	local text = Content:load(fileName) -- 35
	if text == nil or text == "" then -- 35
		return settings -- 38
	end -- 38
	for ____, line in ipairs(__TS__StringSplit(text, "\n")) do -- 40
		local pair = parseLine(line) -- 41
		if pair.key == "mode" then -- 41
			settings.mode = pair.value == "realtime" and "realtime" or "turnBased" -- 43
		elseif pair.key == "difficulty" then -- 43
			if pair.value == "casual" then -- 43
				settings.difficulty = "casual" -- 46
			elseif pair.value == "hard" then -- 46
				settings.difficulty = "hard" -- 48
			else -- 48
				settings.difficulty = "standard" -- 50
			end -- 50
		elseif pair.key == "hint" then -- 50
			settings.showHint = pair.value ~= "0" -- 53
		end -- 53
	end -- 53
	return settings -- 56
end -- 32
function Settings.prototype.save(self, fileName) -- 60
	if fileName == nil then -- 60
		fileName = ____exports.SettingsFile -- 60
	end -- 60
	local text = ((((("mode=" .. self.mode) .. "\ndifficulty=") .. self.difficulty) .. "\nhint=") .. (self.showHint and "1" or "0")) .. "\n" -- 61
	self.saved = Content:save(fileName, text) -- 62
	return self.saved -- 63
end -- 60
function Settings.prototype.toggleMode(self) -- 66
	self.mode = self.mode == "turnBased" and "realtime" or "turnBased" -- 67
	return self.mode -- 68
end -- 66
function Settings.prototype.cycleDifficulty(self) -- 71
	if self.difficulty == "casual" then -- 71
		self.difficulty = "standard" -- 73
	elseif self.difficulty == "standard" then -- 73
		self.difficulty = "hard" -- 75
	else -- 75
		self.difficulty = "casual" -- 77
	end -- 77
	return self.difficulty -- 79
end -- 71
function Settings.prototype.toggleHint(self) -- 82
	self.showHint = not self.showHint -- 83
	return self.showHint -- 84
end -- 82
function Settings.prototype.modeName(self) -- 87
	return self.mode == "realtime" and "实时战斗" or "回合制" -- 88
end -- 87
function Settings.prototype.difficultyName(self) -- 91
	if self.difficulty == "casual" then -- 91
		return "休闲" -- 93
	end -- 93
	if self.difficulty == "hard" then -- 93
		return "困难" -- 96
	end -- 96
	return "标准" -- 98
end -- 91
function Settings.prototype.difficultyScale(self) -- 101
	return Config:difficultyScale(self.difficulty) -- 102
end -- 101
return ____exports -- 101
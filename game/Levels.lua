-- [ts]: Levels.ts
local ____lualib = require("lualib_bundle") -- 1
local __TS__Class = ____lualib.__TS__Class -- 1
local ____exports = {} -- 1
local ____Config = require("game.Config") -- 6
local Config = ____Config.Config -- 6
--- 构造一条敌人技能。
local function makeSkill(id, name, damage, preparesNext, cooldownActions, effects) -- 46
	return { -- 47
		id = id, -- 47
		name = name, -- 47
		damage = damage, -- 47
		effects = effects == nil and ({}) or effects, -- 47
		preparesNext = preparesNext, -- 47
		cooldownActions = cooldownActions -- 47
	} -- 47
end -- 46
--- 构造波次定义（技能列表必须非空：至少要有一条冷却为 0 的普通攻击，保证敌人永远能出手）。
local function makeWave(name, isElite, hp, attack, armor, actionTurns, actionSeconds, skills) -- 51
	return { -- 52
		name = name, -- 52
		isElite = isElite, -- 52
		hp = hp, -- 52
		attack = attack, -- 52
		armor = armor, -- 52
		actionTurns = actionTurns, -- 52
		actionSeconds = actionSeconds, -- 52
		skills = skills -- 52
	} -- 52
end -- 51
--- 封锁棋盘的效果条目（走统一执行器的棋盘效果，等级数据只给格数与时机）。
local function blockSpec(cells) -- 56
	return {kind = "boardBlock", value = cells, target = "board"} -- 57
end -- 56
--- 默认关卡：数值严格等于 Config.Waves（自检以字面量锁定该等式），
-- 精英技能 = 蓄力重击（伤害 = Config 的重击 24，效果 = 封锁棋盘）在前、普通攻击在后，
-- 因此 `new Combat(new Board())` 保持 M5 已验收的「先蓄力 → 再重击」时序。
local function buildDefaultLevel() -- 65
	local waves = {} -- 66
	do -- 66
		local i = 0 -- 67
		while i < #Config.Waves do -- 67
			local nums = Config.Waves[i + 1] -- 68
			local strike = makeSkill( -- 69
				"strike", -- 69
				"普通攻击", -- 69
				nums.attack, -- 69
				false, -- 69
				0 -- 69
			) -- 69
			if nums.isElite then -- 69
				local heavy = makeSkill( -- 71
					"heavy", -- 71
					"蓄力重击", -- 71
					nums.heavyAttack, -- 71
					true, -- 71
					0, -- 71
					{blockSpec(Config.EliteHeavyBlockCells)} -- 71
				) -- 71
				waves[#waves + 1] = makeWave( -- 72
					nums.name, -- 72
					nums.isElite, -- 72
					nums.hp, -- 72
					nums.attack, -- 72
					nums.armor, -- 72
					nums.actionTurns, -- 72
					nums.actionSeconds, -- 72
					{heavy, strike} -- 72
				) -- 72
			else -- 72
				waves[#waves + 1] = makeWave( -- 74
					nums.name, -- 74
					nums.isElite, -- 74
					nums.hp, -- 74
					nums.attack, -- 74
					nums.armor, -- 74
					nums.actionTurns, -- 74
					nums.actionSeconds, -- 74
					{strike} -- 74
				) -- 74
			end -- 74
			i = i + 1 -- 67
		end -- 67
	end -- 67
	return {id = 0, name = "默认关卡", subtitle = "数值与 Config.Waves 一致的兼容关卡（自检基准）", waves = waves} -- 77
end -- 65
--- 6 个手工关卡：逐关引入新机制 ——
-- 1 关仅普通攻击；2 关节奏加快；3 关首次出现棋盘封锁；4 关封锁常态化；
-- 5 关双精英；6 关高频高压（通关后解锁无尽挑战，复用本关波次表并按轮次放大）。
local function buildLevels() -- 90
	return { -- 91
		{ -- 92
			id = 1, -- 93
			name = "试炼场", -- 94
			subtitle = "敌人只会普通攻击，先熟悉连线与结算节奏", -- 95
			waves = { -- 96
				makeWave( -- 97
					"游荡者", -- 97
					false, -- 97
					36, -- 97
					7, -- 97
					3, -- 97
					3, -- 97
					5, -- 97
					{makeSkill( -- 97
						"strike", -- 97
						"普通攻击", -- 97
						7, -- 97
						false, -- 97
						0 -- 97
					)} -- 97
				), -- 97
				makeWave( -- 98
					"游荡者", -- 98
					false, -- 98
					54, -- 98
					9, -- 98
					5, -- 98
					3, -- 98
					4.5, -- 98
					{makeSkill( -- 98
						"strike", -- 98
						"普通攻击", -- 98
						9, -- 98
						false, -- 98
						0 -- 98
					)} -- 98
				), -- 98
				makeWave( -- 99
					"看门人", -- 99
					true, -- 99
					100, -- 99
					12, -- 99
					8, -- 99
					3, -- 99
					4, -- 99
					{makeSkill( -- 99
						"strike", -- 99
						"普通攻击", -- 99
						12, -- 99
						false, -- 99
						0 -- 99
					)} -- 99
				) -- 99
			} -- 99
		}, -- 99
		{ -- 102
			id = 2, -- 103
			name = "锈蚀回廊", -- 104
			subtitle = "敌人出手更快，需要压缩每次决策时间", -- 105
			waves = { -- 106
				makeWave( -- 107
					"锈蚀兵", -- 107
					false, -- 107
					46, -- 107
					8, -- 107
					4, -- 107
					3, -- 107
					4.5, -- 107
					{makeSkill( -- 107
						"strike", -- 107
						"普通攻击", -- 107
						8, -- 107
						false, -- 107
						0 -- 107
					)} -- 107
				), -- 107
				makeWave( -- 108
					"锈蚀兵", -- 108
					false, -- 108
					68, -- 108
					11, -- 108
					6, -- 108
					2, -- 108
					4, -- 108
					{makeSkill( -- 108
						"strike", -- 108
						"普通攻击", -- 108
						11, -- 108
						false, -- 108
						0 -- 108
					)} -- 108
				), -- 108
				makeWave( -- 109
					"锈蚀队长", -- 109
					true, -- 109
					130, -- 109
					15, -- 109
					10, -- 109
					2, -- 109
					3.5, -- 109
					{ -- 109
						makeSkill( -- 109
							"heavy", -- 109
							"蓄力重击", -- 109
							26, -- 109
							true, -- 109
							0 -- 109
						), -- 109
						makeSkill( -- 109
							"strike", -- 109
							"普通攻击", -- 109
							15, -- 109
							false, -- 109
							0 -- 109
						) -- 109
					} -- 109
				) -- 109
			} -- 109
		}, -- 109
		{ -- 112
			id = 3, -- 113
			name = "封锁者", -- 114
			subtitle = "首次出现棋盘封锁：被锁的格子无法连线", -- 115
			waves = { -- 116
				makeWave( -- 117
					"封锁学徒", -- 117
					false, -- 117
					50, -- 117
					9, -- 117
					4, -- 117
					3, -- 117
					4.5, -- 117
					{makeSkill( -- 117
						"strike", -- 117
						"普通攻击", -- 117
						9, -- 117
						false, -- 117
						0 -- 117
					)} -- 117
				), -- 117
				makeWave( -- 118
					"封锁者", -- 118
					false, -- 118
					74, -- 118
					12, -- 118
					6, -- 118
					3, -- 118
					4, -- 118
					{ -- 118
						makeSkill( -- 119
							"lockPunch", -- 119
							"封锁击", -- 119
							14, -- 119
							true, -- 119
							0, -- 119
							{blockSpec(1)} -- 119
						), -- 119
						makeSkill( -- 120
							"strike", -- 120
							"普通攻击", -- 120
							12, -- 120
							false, -- 120
							0 -- 120
						) -- 120
					} -- 120
				), -- 120
				makeWave( -- 122
					"封锁监工", -- 122
					true, -- 122
					145, -- 122
					16, -- 122
					10, -- 122
					2, -- 122
					3.5, -- 122
					{ -- 122
						makeSkill( -- 123
							"heavy", -- 123
							"蓄力封锁", -- 123
							28, -- 123
							true, -- 123
							0, -- 123
							{blockSpec(2)} -- 123
						), -- 123
						makeSkill( -- 124
							"strike", -- 124
							"普通攻击", -- 124
							16, -- 124
							false, -- 124
							0 -- 124
						) -- 124
					} -- 124
				) -- 124
			} -- 124
		}, -- 124
		{ -- 128
			id = 4, -- 129
			name = "铁壁工事", -- 130
			subtitle = "封锁常态化，场上会长期残留在障碍", -- 131
			waves = { -- 132
				makeWave( -- 133
					"工事兵", -- 133
					false, -- 133
					58, -- 133
					10, -- 133
					5, -- 133
					3, -- 133
					4.5, -- 133
					{ -- 133
						makeSkill( -- 134
							"lockPunch", -- 134
							"封锁击", -- 134
							12, -- 134
							true, -- 134
							1, -- 134
							{blockSpec(1)} -- 134
						), -- 134
						makeSkill( -- 135
							"strike", -- 135
							"普通攻击", -- 135
							10, -- 135
							false, -- 135
							0 -- 135
						) -- 135
					} -- 135
				), -- 135
				makeWave( -- 137
					"工事官", -- 137
					false, -- 137
					82, -- 137
					13, -- 137
					7, -- 137
					3, -- 137
					4, -- 137
					{ -- 137
						makeSkill( -- 138
							"lockPunch", -- 138
							"封锁击", -- 138
							15, -- 138
							true, -- 138
							1, -- 138
							{blockSpec(2)} -- 138
						), -- 138
						makeSkill( -- 139
							"strike", -- 139
							"普通攻击", -- 139
							13, -- 139
							false, -- 139
							0 -- 139
						) -- 139
					} -- 139
				), -- 139
				makeWave( -- 141
					"铁壁统领", -- 141
					true, -- 141
					165, -- 141
					18, -- 141
					12, -- 141
					2, -- 141
					3.5, -- 141
					{ -- 141
						makeSkill( -- 142
							"heavy", -- 142
							"蓄力封锁", -- 142
							32, -- 142
							true, -- 142
							0, -- 142
							{blockSpec(3)} -- 142
						), -- 142
						makeSkill( -- 143
							"strike", -- 143
							"普通攻击", -- 143
							18, -- 143
							false, -- 143
							0 -- 143
						) -- 143
					} -- 143
				) -- 143
			} -- 143
		}, -- 143
		{ -- 147
			id = 5, -- 148
			name = "双生精英", -- 149
			subtitle = "连续两波精英，蓄力重击接踵而至", -- 150
			waves = { -- 151
				makeWave( -- 152
					"双子卫兵", -- 152
					false, -- 152
					62, -- 152
					11, -- 152
					5, -- 152
					3, -- 152
					4, -- 152
					{makeSkill( -- 152
						"strike", -- 152
						"普通攻击", -- 152
						11, -- 152
						false, -- 152
						0 -- 152
					)} -- 152
				), -- 152
				makeWave( -- 153
					"左精英", -- 153
					true, -- 153
					140, -- 153
					16, -- 153
					10, -- 153
					2, -- 153
					3.5, -- 153
					{ -- 153
						makeSkill( -- 154
							"heavy", -- 154
							"蓄力重击", -- 154
							28, -- 154
							true, -- 154
							0 -- 154
						), -- 154
						makeSkill( -- 155
							"strike", -- 155
							"普通攻击", -- 155
							16, -- 155
							false, -- 155
							0 -- 155
						) -- 155
					} -- 155
				), -- 155
				makeWave( -- 157
					"右精英", -- 157
					true, -- 157
					175, -- 157
					20, -- 157
					12, -- 157
					2, -- 157
					3, -- 157
					{ -- 157
						makeSkill( -- 158
							"heavy", -- 158
							"蓄力封锁", -- 158
							34, -- 158
							true, -- 158
							0, -- 158
							{blockSpec(2)} -- 158
						), -- 158
						makeSkill( -- 159
							"strike", -- 159
							"普通攻击", -- 159
							20, -- 159
							false, -- 159
							0 -- 159
						) -- 159
					} -- 159
				) -- 159
			} -- 159
		}, -- 159
		{ -- 163
			id = 6, -- 164
			name = "终局回响", -- 165
			subtitle = "高频出手 + 大范围封锁，通关后解锁无尽挑战", -- 166
			waves = { -- 167
				makeWave( -- 168
					"回响残兵", -- 168
					false, -- 168
					70, -- 168
					13, -- 168
					6, -- 168
					2, -- 168
					4, -- 168
					{makeSkill( -- 168
						"strike", -- 168
						"普通攻击", -- 168
						13, -- 168
						false, -- 168
						0 -- 168
					)} -- 168
				), -- 168
				makeWave( -- 169
					"回响官", -- 169
					true, -- 169
					160, -- 169
					19, -- 169
					11, -- 169
					2, -- 169
					3.5, -- 169
					{ -- 169
						makeSkill( -- 170
							"lockPunch", -- 170
							"封锁击", -- 170
							24, -- 170
							true, -- 170
							1, -- 170
							{blockSpec(2)} -- 170
						), -- 170
						makeSkill( -- 171
							"strike", -- 171
							"普通攻击", -- 171
							19, -- 171
							false, -- 171
							0 -- 171
						) -- 171
					} -- 171
				), -- 171
				makeWave( -- 173
					"回响之主", -- 173
					true, -- 173
					210, -- 173
					23, -- 173
					14, -- 173
					2, -- 173
					3, -- 173
					{ -- 173
						makeSkill( -- 174
							"heavy", -- 174
							"蓄力封锁", -- 174
							40, -- 174
							true, -- 174
							0, -- 174
							{blockSpec(3)} -- 174
						), -- 174
						makeSkill( -- 175
							"strike", -- 175
							"普通攻击", -- 175
							23, -- 175
							false, -- 175
							0 -- 175
						) -- 175
					} -- 175
				) -- 175
			} -- 175
		} -- 175
	} -- 175
end -- 90
--- 关卡注册表：查表即可，不含任何按关卡/按技能的分支逻辑。
____exports.Levels = __TS__Class() -- 183
local Levels = ____exports.Levels -- 183
Levels.name = "Levels" -- 183
function Levels.prototype.____constructor(self) -- 183
end -- 183
function Levels.get(self, id) -- 192
	for ____, level in ipairs(____exports.Levels.List) do -- 193
		if level.id == id then -- 193
			return level -- 195
		end -- 195
	end -- 195
	return ____exports.Levels.List[1] -- 198
end -- 192
function Levels.waveOf(self, level, index) -- 202
	local list = level.waves -- 203
	if index < 0 or index >= #list then -- 203
		return list[#list] -- 205
	end -- 205
	return list[index + 1] -- 207
end -- 202
function Levels.skillOf(self, wave, index) -- 211
	local list = wave.skills -- 212
	if index < 0 or index >= #list then -- 212
		return ____exports.Levels:fallbackSkill(wave) -- 214
	end -- 214
	return list[index + 1] -- 216
end -- 211
function Levels.fallbackSkill(self, wave) -- 223
	return makeSkill( -- 224
		"strike", -- 224
		"普通攻击", -- 224
		wave.attack, -- 224
		false, -- 224
		0 -- 224
	) -- 224
end -- 223
Levels.Default = buildDefaultLevel() -- 223
Levels.List = buildLevels() -- 223
Levels.EndlessBase = ____exports.Levels.List[#____exports.Levels.List] -- 223
return ____exports -- 223
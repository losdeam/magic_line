-- [ts]: Tests.ts
local ____lualib = require("lualib_bundle") -- 1
local __TS__New = ____lualib.__TS__New -- 1
local __TS__ArrayIndexOf = ____lualib.__TS__ArrayIndexOf -- 1
local ____exports = {} -- 1
local collectOption, growPath -- 1
local ____Dora = require("Dora") -- 4
local Content = ____Dora.Content -- 4
local ____Board = require("game.Board") -- 5
local Board = ____Board.Board -- 5
local ____BlockDefs = require("game.BlockDefs") -- 6
local BlockDefs = ____BlockDefs.BlockDefs -- 6
local ____ChainTiers = require("game.ChainTiers") -- 7
local ChainTiers = ____ChainTiers.ChainTiers -- 7
local ____Combat = require("game.Combat") -- 8
local Combat = ____Combat.Combat -- 8
local ____Config = require("game.Config") -- 9
local Config = ____Config.Config -- 9
local ____Levels = require("game.Levels") -- 10
local Levels = ____Levels.Levels -- 10
local ____Effects = require("game.Effects") -- 11
local resolveEffects = ____Effects.resolveEffects -- 11
local unhandledEffectCount = ____Effects.unhandledEffectCount -- 11
local ____Settings = require("game.Settings") -- 12
local Settings = ____Settings.Settings -- 12
local ____Skills = require("game.Skills") -- 13
local Skills = ____Skills.Skills -- 13
local ____UiLayout = require("game.UiLayout") -- 14
local HudLayout = ____UiLayout.HudLayout -- 14
local SafeBox = ____UiLayout.SafeBox -- 14
local boardLayoutRect = ____UiLayout.boardLayoutRect -- 14
local hudLayoutRects = ____UiLayout.hudLayoutRects -- 14
local insideSafeBox = ____UiLayout.insideSafeBox -- 14
local visibleHalfExtent = ____UiLayout.visibleHalfExtent -- 14
function collectOption(board, options, used, col, row, ____type) -- 16
	if not board:inside(col, row) then -- 16
		return -- 18
	end -- 18
	local flat = board:flatIndex(col, row) -- 20
	if used[flat + 1] or board:cellIndex(col, row) ~= ____type then -- 20
		return -- 22
	end -- 22
	options[#options + 1] = flat -- 24
end -- 24
function growPath(board, path, used, ____type, minLength, maxLength) -- 54
	if #path >= minLength then -- 54
		return true -- 56
	end -- 56
	if #path >= maxLength then -- 56
		return false -- 59
	end -- 59
	local last = path[#path] -- 61
	local col = last % board.columns -- 62
	local row = math.floor(last / board.columns) -- 63
	local options = {} -- 64
	collectOption( -- 65
		board, -- 65
		options, -- 65
		used, -- 65
		col - 1, -- 65
		row, -- 65
		____type -- 65
	) -- 65
	collectOption( -- 66
		board, -- 66
		options, -- 66
		used, -- 66
		col + 1, -- 66
		row, -- 66
		____type -- 66
	) -- 66
	collectOption( -- 67
		board, -- 67
		options, -- 67
		used, -- 67
		col, -- 67
		row - 1, -- 67
		____type -- 67
	) -- 67
	collectOption( -- 68
		board, -- 68
		options, -- 68
		used, -- 68
		col, -- 68
		row + 1, -- 68
		____type -- 68
	) -- 68
	for ____, next in ipairs(options) do -- 69
		used[next + 1] = true -- 70
		path[#path + 1] = next -- 71
		if growPath( -- 71
			board, -- 72
			path, -- 72
			used, -- 72
			____type, -- 72
			minLength, -- 72
			maxLength -- 72
		) then -- 72
			return true -- 73
		end -- 73
		table.remove(path) -- 75
		used[next + 1] = false -- 76
	end -- 76
	return false -- 78
end -- 78
--- 确定性地取一条长度 ≥ minLength 的同色相邻链（用于模拟玩家操作与运行时自检）。
-- 逐格起点的深度优先回溯，只要棋盘存在可连线区域就一定能找到，避免随机游走撞死角。
function ____exports.findPlayableChain(board, minLength, maxLength) -- 31
	local total = board.columns * board.rows -- 32
	do -- 32
		local start = 0 -- 33
		while start < total do -- 33
			do -- 33
				local col = start % board.columns -- 34
				local row = math.floor(start / board.columns) -- 35
				local ____type = board:cellIndex(col, row) -- 36
				if ____type < 0 then -- 36
					goto __continue7 -- 38
				end -- 38
				local used = {} -- 40
				do -- 40
					local i = 0 -- 41
					while i < total do -- 41
						used[#used + 1] = false -- 42
						i = i + 1 -- 41
					end -- 41
				end -- 41
				local path = {start} -- 44
				used[start + 1] = true -- 45
				if growPath( -- 45
					board, -- 46
					path, -- 46
					used, -- 46
					____type, -- 46
					minLength, -- 46
					maxLength -- 46
				) then -- 46
					return path -- 47
				end -- 47
			end -- 47
			::__continue7:: -- 47
			start = start + 1 -- 33
		end -- 33
	end -- 33
	return {} -- 50
end -- 31
--- 从指定格子出发游走同色链（长度上限 maxLength），供运行时自检复用。
function ____exports.walkChainFrom(board, flat, maxLength) -- 82
	local ____type = board:cellIndex( -- 83
		flat % board.columns, -- 83
		math.floor(flat / board.columns) -- 83
	) -- 83
	local chain = {} -- 84
	if ____type < 0 then -- 84
		return chain -- 86
	end -- 86
	local total = board.columns * board.rows -- 88
	local used = {} -- 89
	do -- 89
		local i = 0 -- 90
		while i < total do -- 90
			used[#used + 1] = false -- 91
			i = i + 1 -- 90
		end -- 90
	end -- 90
	chain[#chain + 1] = flat -- 93
	used[flat + 1] = true -- 94
	while #chain < maxLength do -- 94
		local last = chain[#chain] -- 96
		local col = last % board.columns -- 97
		local row = math.floor(last / board.columns) -- 98
		local options = {} -- 99
		collectOption( -- 100
			board, -- 100
			options, -- 100
			used, -- 100
			col - 1, -- 100
			row, -- 100
			____type -- 100
		) -- 100
		collectOption( -- 101
			board, -- 101
			options, -- 101
			used, -- 101
			col + 1, -- 101
			row, -- 101
			____type -- 101
		) -- 101
		collectOption( -- 102
			board, -- 102
			options, -- 102
			used, -- 102
			col, -- 102
			row - 1, -- 102
			____type -- 102
		) -- 102
		collectOption( -- 103
			board, -- 103
			options, -- 103
			used, -- 103
			col, -- 103
			row + 1, -- 103
			____type -- 103
		) -- 103
		if #options == 0 then -- 103
			break -- 105
		end -- 105
		local pick = options[math.floor(math.random() * #options) + 1] -- 107
		used[pick + 1] = true -- 108
		chain[#chain + 1] = pick -- 109
	end -- 109
	return chain -- 111
end -- 82
function ____exports.runTests() -- 114
	local failures = {} -- 115
	local checks = 0 -- 116
	local function expect(condition, message) -- 118
		checks = checks + 1 -- 119
		if condition then -- 119
			return -- 121
		end -- 121
		if #failures < 12 then -- 121
			failures[#failures + 1] = message -- 124
		end -- 124
	end -- 118
	expect( -- 129
		BlockDefs:placeableCount() >= 4, -- 129
		"注册表至少应有 4 种可放置方块" -- 129
	) -- 129
	do -- 129
		local i = 0 -- 130
		while i < #BlockDefs.List do -- 130
			do -- 130
				local def = BlockDefs:at(i) -- 131
				if not def.placeable then -- 131
					expect(#def.rules == 0, ("不可放置的方块 " .. def.id) .. " 不应带效果规则") -- 134
					goto __continue29 -- 135
				end -- 135
				expect(#def.rules > 0, ("方块 " .. def.id) .. " 缺少效果规则") -- 137
				expect( -- 138
					#resolveEffects(def.rules, Config.MinChainLength - 1) == 0, -- 138
					("方块 " .. def.id) .. " 在链长低于下限时不应产出效果" -- 138
				) -- 138
				do -- 138
					local n = Config.MinChainLength -- 139
					while n <= 9 do -- 139
						local specs = resolveEffects(def.rules, n) -- 140
						expect( -- 141
							#specs > 0, -- 141
							((("方块 " .. def.id) .. " 链长 ") .. tostring(n)) .. " 未产出效果列表" -- 141
						) -- 141
						for ____, spec in ipairs(specs) do -- 142
							expect( -- 143
								spec.value >= 1, -- 143
								(((("方块 " .. def.id) .. " 链长 ") .. tostring(n)) .. " 的效果数值应 ≥ 1，实际 ") .. tostring(spec.value) -- 143
							) -- 143
						end -- 143
						n = n + 1 -- 139
					end -- 139
				end -- 139
			end -- 139
			::__continue29:: -- 139
			i = i + 1 -- 130
		end -- 130
	end -- 130
	local sampleCount = 30 -- 149
	local fullCount = 0 -- 150
	local strictCount = 0 -- 151
	local boundedCount = 0 -- 152
	local playableCount = 0 -- 153
	do -- 153
		local i = 0 -- 154
		while i < sampleCount do -- 154
			local board = __TS__New(Board) -- 155
			if board:isFull() then -- 155
				fullCount = fullCount + 1 -- 157
			end -- 157
			local maxSize = 0 -- 159
			for ____, size in ipairs(board:maxGroupSizes()) do -- 160
				if size > maxSize then -- 160
					maxSize = size -- 162
				end -- 162
			end -- 162
			if maxSize <= Config.MaxGroupSize then -- 162
				strictCount = strictCount + 1 -- 166
			end -- 166
			if maxSize <= Config.GroupSizeRelaxLimit then -- 166
				boundedCount = boundedCount + 1 -- 169
			end -- 169
			if board:hasPlayableRegion(Config.MinChainLength) then -- 169
				playableCount = playableCount + 1 -- 172
			end -- 172
			i = i + 1 -- 154
		end -- 154
	end -- 154
	expect( -- 175
		fullCount == sampleCount, -- 175
		(("棋盘未满格：" .. tostring(fullCount)) .. "/") .. tostring(sampleCount) -- 175
	) -- 175
	expect( -- 176
		strictCount == sampleCount, -- 176
		((((("C1 最大连通块超过 " .. tostring(Config.MaxGroupSize)) .. "：") .. tostring(strictCount)) .. "/") .. tostring(sampleCount)) .. " 达标" -- 176
	) -- 176
	expect( -- 177
		boundedCount == sampleCount, -- 177
		(((("最大连通块超过放宽上限 " .. tostring(Config.GroupSizeRelaxLimit)) .. "：") .. tostring(boundedCount)) .. "/") .. tostring(sampleCount) -- 177
	) -- 177
	expect( -- 178
		playableCount == sampleCount, -- 178
		(((("C2 缺少可连线区域（所有颜色都无 ≥ " .. tostring(Config.MinChainLength)) .. " 连通）：") .. tostring(playableCount)) .. "/") .. tostring(sampleCount) -- 178
	) -- 178
	expect( -- 181
		Board:areNeighbors(0, 0, 1, 0), -- 181
		"水平相邻判定失败" -- 181
	) -- 181
	expect( -- 182
		Board:areNeighbors(3, 3, 3, 4), -- 182
		"垂直相邻判定失败" -- 182
	) -- 182
	expect( -- 183
		not Board:areNeighbors(0, 0, 1, 1), -- 183
		"斜向不应判为相邻" -- 183
	) -- 183
	expect( -- 184
		not Board:areNeighbors(0, 0, 0, 0), -- 184
		"同一格不应判为相邻" -- 184
	) -- 184
	local workBoard = __TS__New(Board) -- 187
	local applied = 0 -- 188
	local fullFails = 0 -- 189
	local strictViolations = 0 -- 190
	local removedSum = 0 -- 191
	do -- 191
		local i = 0 -- 192
		while i < 200 do -- 192
			do -- 192
				local chain = ____exports.findPlayableChain( -- 193
					workBoard, -- 193
					Config.MinChainLength, -- 193
					3 + math.floor(math.random() * 4) -- 193
				) -- 193
				if #chain < Config.MinChainLength then -- 193
					goto __continue45 -- 195
				end -- 195
				removedSum = removedSum + workBoard:applyChain(chain) -- 197
				applied = applied + 1 -- 198
				if not workBoard:isFull() then -- 198
					fullFails = fullFails + 1 -- 200
				end -- 200
				local maxNow = 0 -- 202
				for ____, size in ipairs(workBoard:maxGroupSizes()) do -- 203
					if size > maxNow then -- 203
						maxNow = size -- 205
					end -- 205
				end -- 205
				if maxNow > Config.MaxGroupSize then -- 205
					strictViolations = strictViolations + 1 -- 209
				end -- 209
			end -- 209
			::__continue45:: -- 209
			i = i + 1 -- 192
		end -- 192
	end -- 192
	expect( -- 212
		applied >= 190, -- 212
		("随机操作实际生效次数应 ≥ 190，实际 " .. tostring(applied)) .. "/200" -- 212
	) -- 212
	expect( -- 213
		fullFails == 0, -- 213
		("消除补充后出现非满格：" .. tostring(fullFails)) .. " 次" -- 213
	) -- 213
	expect( -- 214
		workBoard.deadlockWarningCount == 0, -- 214
		("消除补充后出现无解棋盘：" .. tostring(workBoard.deadlockWarningCount)) .. " 次" -- 214
	) -- 214
	expect( -- 215
		workBoard.clearedTotal == removedSum, -- 215
		(("消除统计应与实际移除数一致：" .. tostring(workBoard.clearedTotal)) .. " vs ") .. tostring(removedSum) -- 215
	) -- 215
	expect( -- 216
		workBoard.chainsTotal == applied, -- 216
		(("连线计数应与生效次数一致：" .. tostring(workBoard.chainsTotal)) .. " vs ") .. tostring(applied) -- 216
	) -- 216
	local oneBoard = __TS__New(Board) -- 219
	local firstColumnCell = oneBoard:flatIndex(0, 0) -- 220
	local beforeEmpty = oneBoard:emptyCount() -- 221
	local removedOne = oneBoard:applyChain({ -- 222
		firstColumnCell, -- 222
		oneBoard:flatIndex(1, 0), -- 222
		oneBoard:flatIndex(2, 0) -- 222
	}) -- 222
	expect( -- 223
		removedOne == 3, -- 223
		"移除 3 格后返回移除数应为 3，实际 " .. tostring(removedOne) -- 223
	) -- 223
	expect( -- 224
		beforeEmpty == 0, -- 224
		"初始棋盘应无空格，实际 " .. tostring(beforeEmpty) -- 224
	) -- 224
	expect( -- 225
		oneBoard:emptyCount() == 0, -- 225
		"补充后应无空格，实际 " .. tostring(oneBoard:emptyCount()) -- 225
	) -- 225
	expect( -- 226
		oneBoard:isFull(), -- 226
		"补充后棋盘应满格" -- 226
	) -- 226
	local physicalIndex = BlockDefs:indexOf(BlockDefs.Physical) -- 229
	local physicalSpecs = resolveEffects( -- 230
		BlockDefs:at(physicalIndex).rules, -- 230
		2 -- 230
	) -- 230
	expect( -- 231
		#resolveEffects( -- 231
			BlockDefs:at(physicalIndex).rules, -- 231
			1 -- 231
		) == 0, -- 231
		"链长 1（低于下限）不应产出效果" -- 231
	) -- 231
	expect( -- 232
		#physicalSpecs == 2, -- 232
		"链长 2 应产出伤害 + 魔力两条效果，实际 " .. tostring(#physicalSpecs) -- 232
	) -- 232
	local damageValue = 0 -- 233
	local manaValue = 0 -- 234
	for ____, spec in ipairs(physicalSpecs) do -- 235
		if spec.kind == "physicalDamage" then -- 235
			damageValue = spec.value -- 237
		end -- 237
		if spec.kind == "manaGain" then -- 237
			manaValue = spec.value -- 240
		end -- 240
	end -- 240
	expect( -- 243
		damageValue == 10, -- 243
		"链长 2 物理伤害应为 4+3×2=10，实际 " .. tostring(damageValue) -- 243
	) -- 243
	expect( -- 244
		manaValue == 7, -- 244
		"链长 2 魔力应为 1+3×2=7，实际 " .. tostring(manaValue) -- 244
	) -- 244
	local manaCombat = __TS__New( -- 246
		Combat, -- 246
		__TS__New(Board) -- 246
	) -- 246
	local manaBefore = manaCombat.player.mana -- 247
	manaCombat:applySpecs(physicalSpecs) -- 248
	expect( -- 249
		manaCombat.player.mana == manaBefore + manaValue, -- 249
		(("消除后魔力应增加 " .. tostring(manaValue)) .. "，实际 ") .. tostring(manaCombat.player.mana - manaBefore) -- 249
	) -- 249
	expect( -- 250
		manaCombat.enemy.hp == 34, -- 250
		"物理伤害 10 受护甲 4 减免后敌人应为 34 HP，实际 " .. tostring(manaCombat.enemy.hp) -- 250
	) -- 250
	manaCombat.player.mana = 0 -- 251
	do -- 251
		local i = 0 -- 252
		while i < 30 do -- 252
			manaCombat:applySpecs(physicalSpecs) -- 253
			i = i + 1 -- 252
		end -- 252
	end -- 252
	expect( -- 255
		manaCombat.player.mana == Config.MaxMana, -- 255
		(("魔力应被夹在上限 " .. tostring(Config.MaxMana)) .. "，实际 ") .. tostring(manaCombat.player.mana) -- 255
	) -- 255
	expect( -- 258
		Skills:find(Skills.Shuffle) ~= nil and Skills:find(Skills.Blast) ~= nil, -- 258
		"技能注册表应包含重排与引爆" -- 258
	) -- 258
	local skillCombat = __TS__New( -- 259
		Combat, -- 259
		__TS__New(Board) -- 259
	) -- 259
	skillCombat.player.mana = 0 -- 260
	expect( -- 261
		not skillCombat:useSkill(Skills.Shuffle).ok, -- 261
		"魔力不足时应拒绝重排" -- 261
	) -- 261
	expect(skillCombat.player.mana == 0, "被拒绝时不应扣除魔力") -- 262
	expect( -- 263
		not skillCombat:useSkill(Skills.Blast).ok, -- 263
		"魔力不足时应拒绝引爆" -- 263
	) -- 263
	expect( -- 264
		not skillCombat:useSkill("not-a-skill").ok, -- 264
		"未知技能应被拒绝" -- 264
	) -- 264
	skillCombat.player.mana = 60 -- 265
	local shuffleResult = skillCombat:useSkill(Skills.Shuffle) -- 266
	expect(shuffleResult.ok, "魔力足够时重排应成功：" .. shuffleResult.message) -- 267
	expect( -- 268
		skillCombat.player.mana == 40, -- 268
		"重排应扣 20 魔力，实际 " .. tostring(skillCombat.player.mana) -- 268
	) -- 268
	expect(skillCombat.player.hp == Config.PlayerMaxHp, "释放技能不应影响玩家生命") -- 269
	local blastBoard = __TS__New(Board) -- 272
	local blastCombat = __TS__New(Combat, blastBoard) -- 273
	blastCombat.player.mana = 100 -- 274
	expect( -- 275
		#blastBoard:largestGroupCells() >= Config.MinChainLength, -- 275
		("棋盘应存在规模 ≥ " .. tostring(Config.MinChainLength)) .. " 的连通块" -- 275
	) -- 275
	local blastResult = blastCombat:useSkill(Skills.Blast) -- 276
	expect(blastResult.ok, "魔力足够时引爆应成功：" .. blastResult.message) -- 277
	expect( -- 278
		blastBoard:isFull(), -- 278
		"引爆后棋盘应满格" -- 278
	) -- 278
	expect( -- 279
		blastBoard:isPlayable(), -- 279
		"引爆后棋盘仍应可执行" -- 279
	) -- 279
	expect( -- 280
		blastCombat.player.mana == 65, -- 280
		"引爆应扣 35 魔力，实际 " .. tostring(blastCombat.player.mana) -- 280
	) -- 280
	local deadBoard = __TS__New(Board) -- 283
	do -- 283
		local row = 0 -- 284
		while row < deadBoard.rows do -- 284
			do -- 284
				local col = 0 -- 285
				while col < deadBoard.columns do -- 285
					deadBoard:setCell(col, row, (col + row) % 2) -- 286
					col = col + 1 -- 285
				end -- 285
			end -- 285
			row = row + 1 -- 284
		end -- 284
	end -- 284
	expect( -- 289
		not deadBoard:isPlayable(), -- 289
		"棋盘格染色（无相邻同色对）应判定为不可执行" -- 289
	) -- 289
	local penaltyCombat = __TS__New(Combat, deadBoard) -- 290
	local hpBeforePenalty = penaltyCombat.player.hp -- 291
	local notice = penaltyCombat:ensureBoardPlayable() -- 292
	expect(notice ~= nil, "不可执行时应返回提示文本") -- 293
	expect( -- 294
		penaltyCombat.boardResetCount == 1, -- 294
		"应记录一次棋盘重排，实际 " .. tostring(penaltyCombat.boardResetCount) -- 294
	) -- 294
	expect( -- 295
		penaltyCombat.player.hp == hpBeforePenalty - Config.BoardResetPenalty, -- 295
		(("应扣除 " .. tostring(Config.BoardResetPenalty)) .. " 点生命，实际 ") .. tostring(penaltyCombat.player.hp) -- 295
	) -- 295
	expect( -- 296
		deadBoard:isFull() and deadBoard:isPlayable(), -- 296
		"重排后棋盘应满格且可执行" -- 296
	) -- 296
	expect( -- 297
		penaltyCombat:ensureBoardPlayable() == nil, -- 297
		"棋盘可执行时不应再触发重排" -- 297
	) -- 297
	local targetCombat = __TS__New( -- 300
		Combat, -- 300
		__TS__New(Board) -- 300
	) -- 300
	targetCombat.player.hp = 50 -- 301
	local magicSpecs = resolveEffects( -- 302
		BlockDefs:at(BlockDefs:indexOf(BlockDefs.Magic)).rules, -- 302
		2 -- 302
	) -- 302
	targetCombat:applySpecs(magicSpecs) -- 303
	expect( -- 304
		targetCombat.player.hp == 50, -- 304
		"魔法伤害不应影响玩家生命，实际 " .. tostring(targetCombat.player.hp) -- 304
	) -- 304
	expect( -- 305
		targetCombat.enemy.hp == 31, -- 305
		"魔法伤害 9 无视护甲，敌人应为 31 HP，实际 " .. tostring(targetCombat.enemy.hp) -- 305
	) -- 305
	local enemyHpBeforeHeal = targetCombat.enemy.hp -- 306
	targetCombat:applySpecs(resolveEffects( -- 307
		BlockDefs:at(BlockDefs:indexOf(BlockDefs.Heal)).rules, -- 307
		2 -- 307
	)) -- 307
	expect( -- 308
		targetCombat.player.hp == 57, -- 308
		"治疗 3+2×2=7 应回复玩家到 57，实际 " .. tostring(targetCombat.player.hp) -- 308
	) -- 308
	expect(targetCombat.enemy.hp == enemyHpBeforeHeal, "治疗不应影响敌人") -- 309
	expect( -- 310
		unhandledEffectCount() == 0, -- 310
		("所用效果种类均应已注册 handler，未注册 " .. tostring(unhandledEffectCount())) .. " 条" -- 310
	) -- 310
	local battle = __TS__New( -- 313
		Combat, -- 313
		__TS__New(Board) -- 313
	) -- 313
	expect( -- 314
		battle.waveNumber == 1 and battle.waveCount == Config.StageWaveCount, -- 314
		("初始应为第 1 波，每关 " .. tostring(Config.StageWaveCount)) .. " 波" -- 314
	) -- 314
	expect( -- 315
		battle.enemyInterval == Config:wave(0).actionTurns, -- 315
		("第 1 波敌人行动间隔应为 " .. tostring(Config:wave(0).actionTurns)) .. " 回合" -- 315
	) -- 315
	local hpBeforeEnemyAct = battle.player.hp -- 316
	local dealt = battle:enemyAct() -- 317
	expect( -- 318
		dealt > 0, -- 318
		"敌人出手应造成伤害，实际 " .. tostring(dealt) -- 318
	) -- 318
	expect( -- 319
		battle.player.hp == hpBeforeEnemyAct - dealt, -- 319
		(("玩家生命应按伤害下降：" .. tostring(hpBeforeEnemyAct)) .. " → ") .. tostring(battle.player.hp) -- 319
	) -- 319
	battle.enemy.hp = 0 -- 320
	expect( -- 321
		not battle:advanceWave(), -- 321
		"第 1 波清完后应还有后续波次" -- 321
	) -- 321
	expect( -- 322
		battle.waveNumber == 2, -- 322
		"应推进到第 2 波，实际 " .. tostring(battle.waveNumber) -- 322
	) -- 322
	expect(battle.enemy.hp == battle.enemy.maxHp and battle.enemy.hp > 0, "新波次敌人应满血") -- 323
	battle.enemy.hp = 0 -- 324
	expect( -- 325
		not battle:advanceWave(), -- 325
		"第 2 波清完后应还有第 3 波" -- 325
	) -- 325
	battle.enemy.hp = 0 -- 326
	expect( -- 327
		battle:advanceWave(), -- 327
		"第 3 波清完应判定本关通关" -- 327
	) -- 327
	local hpBeforeNextStage = battle.player.hp -- 328
	battle:nextStage() -- 329
	expect(battle.stageNumber == 2 and battle.waveNumber == 1, "应进入第 2 关第 1 波") -- 330
	expect(battle.player.hp >= hpBeforeNextStage, "通关后玩家应回复生命") -- 331
	expect( -- 332
		battle.enemy.maxHp > Config:wave(0).hp, -- 332
		"第 2 关敌人数值应按关卡增长，实际 " .. tostring(battle.enemy.maxHp) -- 332
	) -- 332
	battle.player.hp = 0 -- 333
	expect(battle.defeated, "玩家生命为 0 应判定失败") -- 334
	battle:resetBattle() -- 335
	expect(not battle.defeated, "重开后不应处于失败状态") -- 336
	expect(battle.stageNumber == 1 and battle.player.hp == battle.player.maxHp and battle.player.mana == 0, "重开本关应复位关卡与玩家状态") -- 337
	expect(battle.boardResetCount == 0, "重开应清零被动重排计数") -- 338
	local settingsFile = "settings-selftest.txt" -- 341
	local settings = __TS__New(Settings) -- 342
	settings.mode = "realtime" -- 343
	settings.difficulty = "hard" -- 344
	settings.showHint = false -- 345
	local saved = settings:save(settingsFile) -- 346
	expect(saved, "设置应能写入存档文件（若环境不可写则本项会失败）") -- 347
	if saved then -- 347
		local loaded = Settings:load(settingsFile) -- 349
		expect(loaded.mode == "realtime", "模式应往返一致，实际 " .. loaded.mode) -- 350
		expect(loaded.difficulty == "hard", "难度应往返一致，实际 " .. loaded.difficulty) -- 351
		expect(not loaded.showHint, "提示开关应往返一致") -- 352
		if Content:exist(settingsFile) then -- 352
			Content:remove(settingsFile) -- 354
		end -- 354
	else -- 354
		expect( -- 357
			Settings:load(settingsFile).mode == "turnBased", -- 357
			"写入失败时应回退为默认设置" -- 357
		) -- 357
	end -- 357
	local toggled = __TS__New(Settings) -- 359
	expect( -- 360
		toggled:toggleMode() == "realtime", -- 360
		"切换应变为实时模式" -- 360
	) -- 360
	expect( -- 361
		toggled:toggleMode() == "turnBased", -- 361
		"再次切换应回到回合制" -- 361
	) -- 361
	expect( -- 362
		toggled:cycleDifficulty() == "hard", -- 362
		"标准 → 困难" -- 362
	) -- 362
	expect( -- 363
		toggled:cycleDifficulty() == "casual", -- 363
		"困难 → 休闲" -- 363
	) -- 363
	expect( -- 364
		not toggled:toggleHint(), -- 364
		"提示开关应可关闭" -- 364
	) -- 364
	expect( -- 365
		toggled:difficultyScale() == Config:difficultyScale("casual"), -- 365
		"难度缩放应与配置一致" -- 365
	) -- 365
	local realtimeCombat = __TS__New( -- 367
		Combat, -- 367
		__TS__New(Board) -- 367
	) -- 367
	realtimeCombat:setRealtime(true) -- 368
	expect(realtimeCombat.isRealtime, "应处于实时模式") -- 369
	local interval = realtimeCombat.enemyIntervalSeconds -- 370
	expect( -- 371
		interval > 0, -- 371
		"实时间隔应为正数，实际 " .. tostring(interval) -- 371
	) -- 371
	expect( -- 372
		not realtimeCombat:advanceTime(interval * 0.5), -- 372
		"未到时间不应触发敌人行动" -- 372
	) -- 372
	expect( -- 373
		realtimeCombat:advanceTime(interval * 0.5 + 0.01), -- 373
		"累计到间隔应触发敌人行动" -- 373
	) -- 373
	expect( -- 374
		math.abs(realtimeCombat.secondsLeft - interval) < 0.001, -- 374
		(("触发后倒计时应重置为 " .. tostring(interval)) .. "，实际 ") .. tostring(realtimeCombat.secondsLeft) -- 374
	) -- 374
	local turnCombat = __TS__New( -- 375
		Combat, -- 375
		__TS__New(Board) -- 375
	) -- 375
	turnCombat:setRealtime(false) -- 376
	expect( -- 377
		not turnCombat:advanceTime(999), -- 377
		"回合制下推进时间不应触发敌人行动" -- 377
	) -- 377
	expect( -- 378
		turnCombat.enemyInterval == Config:wave(0).actionTurns, -- 378
		"回合制间隔应为回合数 " .. tostring(Config:wave(0).actionTurns) -- 378
	) -- 378
	local hardCombat = __TS__New( -- 379
		Combat, -- 379
		__TS__New(Board) -- 379
	) -- 379
	hardCombat:setDifficultyScale(Config:difficultyScale("hard")) -- 380
	hardCombat:loadWave() -- 381
	expect( -- 382
		hardCombat.enemy.maxHp == math.floor(Config:wave(0).hp * Config:difficultyScale("hard") + 0.5), -- 382
		"难度应缩放敌人生命，实际 " .. tostring(hardCombat.enemy.maxHp) -- 382
	) -- 382
	local lockedIndex = BlockDefs:lockedIndex() -- 385
	expect(lockedIndex >= 0, "注册表应包含封锁格定义") -- 386
	expect( -- 387
		not BlockDefs:isPlaceable(lockedIndex), -- 387
		"封锁格不应可放置" -- 387
	) -- 387
	local lockBoard = __TS__New(Board) -- 388
	local lockPlaced = lockBoard:blockCells(Config.EliteHeavyBlockCells) -- 389
	expect( -- 390
		lockPlaced == Config.EliteHeavyBlockCells, -- 390
		(("应封锁 " .. tostring(Config.EliteHeavyBlockCells)) .. " 格，实际 ") .. tostring(lockPlaced) -- 390
	) -- 390
	expect( -- 391
		lockBoard:isPlayable(), -- 391
		"封锁后棋盘仍应存在可连线区域（硬约束）" -- 391
	) -- 391
	expect( -- 392
		lockBoard:isFull(), -- 392
		"封锁后棋盘仍应满格" -- 392
	) -- 392
	local groupHasLocked = 0 -- 393
	for ____, flat in ipairs(lockBoard:largestGroupCells()) do -- 394
		local groupCol = flat % lockBoard.columns -- 395
		local groupRow = math.floor(flat / lockBoard.columns) -- 396
		if not BlockDefs:isPlaceable(lockBoard:cellIndex(groupCol, groupRow)) then -- 396
			groupHasLocked = groupHasLocked + 1 -- 398
		end -- 398
	end -- 398
	expect( -- 401
		groupHasLocked == 0, -- 401
		("最大连通块候选不应含封锁格，实际含 " .. tostring(groupHasLocked)) .. " 格" -- 401
	) -- 401
	local blastRemoved = lockBoard:blastLargestGroup() -- 402
	expect( -- 403
		blastRemoved > 0, -- 403
		"引爆应移除可放置连通块，实际 " .. tostring(blastRemoved) -- 403
	) -- 403
	expect( -- 404
		lockBoard:isPlayable(), -- 404
		"引爆后棋盘仍应可执行" -- 404
	) -- 404
	expect( -- 405
		lockBoard:isFull(), -- 405
		"引爆后棋盘仍应满格" -- 405
	) -- 405
	local mob = __TS__New( -- 407
		Combat, -- 407
		__TS__New(Board) -- 407
	) -- 407
	local mobDamage = mob:enemyAct() -- 408
	expect(mob.lastEnemyAction == "attack", "小怪行动类别应为普通攻击") -- 409
	expect( -- 410
		mobDamage > 0, -- 410
		"小怪出手应造成伤害，实际 " .. tostring(mobDamage) -- 410
	) -- 410
	local eliteBoard = __TS__New(Board) -- 412
	local elite = __TS__New(Combat, eliteBoard) -- 413
	elite:advanceWave() -- 414
	elite:advanceWave() -- 415
	expect( -- 416
		elite:currentWave().isElite, -- 416
		"第 3 波应为精英" -- 416
	) -- 416
	local unhandledBefore = unhandledEffectCount() -- 417
	local hpBeforeCharge = elite.player.hp -- 418
	expect( -- 419
		elite:enemyAct() == 0, -- 419
		"精英首次行动应为蓄力，不造成伤害" -- 419
	) -- 419
	expect(elite.lastEnemyAction == "prepare", "首次行动类别应为蓄力预告") -- 420
	expect(elite.isPreparing, "蓄力后应处于待释放状态") -- 421
	expect( -- 422
		elite.player.hp == hpBeforeCharge, -- 422
		"蓄力不应扣血，实际 " .. tostring(elite.player.hp) -- 422
	) -- 422
	local heavyDamage = elite:enemyAct() -- 423
	expect(elite.lastEnemyAction == "release", "第二次行动类别应为重击释放") -- 424
	expect( -- 425
		heavyDamage > elite:currentWave().attack, -- 425
		(("重击伤害应高于普通攻击，实际 " .. tostring(heavyDamage)) .. " vs ") .. tostring(elite:currentWave().attack) -- 425
	) -- 425
	expect(not elite.isPreparing, "重击后应清除待释放状态") -- 426
	expect( -- 427
		unhandledEffectCount() == unhandledBefore, -- 427
		"BoardBlock 应已在执行器注册表中（悬空效果数不应增加）" -- 427
	) -- 427
	local eliteLocked = 0 -- 428
	do -- 428
		local row = 0 -- 429
		while row < eliteBoard.rows do -- 429
			do -- 429
				local col = 0 -- 430
				while col < eliteBoard.columns do -- 430
					local index = eliteBoard:cellIndex(col, row) -- 431
					if index >= 0 and not BlockDefs:isPlaceable(index) then -- 431
						eliteLocked = eliteLocked + 1 -- 433
					end -- 433
					col = col + 1 -- 430
				end -- 430
			end -- 430
			row = row + 1 -- 429
		end -- 429
	end -- 429
	expect( -- 437
		eliteLocked == Config.EliteHeavyBlockCells, -- 437
		(("重击应经执行器封锁 " .. tostring(Config.EliteHeavyBlockCells)) .. " 格，实际 ") .. tostring(eliteLocked) -- 437
	) -- 437
	expect( -- 438
		eliteBoard:isPlayable(), -- 438
		"重击封锁后棋盘仍应可执行" -- 438
	) -- 438
	expect( -- 439
		eliteBoard:isFull(), -- 439
		"重击封锁后棋盘仍应满格" -- 439
	) -- 439
	elite:nextStage() -- 440
	expect(not elite.isPreparing and elite.lastEnemyAction == "attack", "进入新关后应复位待释放状态") -- 441
	local effectBoard = __TS__New(Board) -- 444
	local effectCombat = __TS__New(Combat, effectBoard) -- 445
	local boardBlockSpec = {kind = "boardBlock", value = 1, target = "board"} -- 446
	expect( -- 447
		effectCombat:applySpecs({boardBlockSpec}) == 1, -- 447
		"applySpecs 应执行 1 条 BoardBlock 效果" -- 447
	) -- 447
	local effectLocked = 0 -- 448
	do -- 448
		local row = 0 -- 449
		while row < effectBoard.rows do -- 449
			do -- 449
				local col = 0 -- 450
				while col < effectBoard.columns do -- 450
					local index = effectBoard:cellIndex(col, row) -- 451
					if index >= 0 and not BlockDefs:isPlaceable(index) then -- 451
						effectLocked = effectLocked + 1 -- 453
					end -- 453
					col = col + 1 -- 450
				end -- 450
			end -- 450
			row = row + 1 -- 449
		end -- 449
	end -- 449
	expect( -- 457
		effectLocked == 1, -- 457
		"BoardBlock 效果应封锁 1 格，实际 " .. tostring(effectLocked) -- 457
	) -- 457
	local expireBoard = __TS__New(Board) -- 460
	local expireCombat = __TS__New(Combat, expireBoard) -- 461
	expect( -- 462
		expireCombat:applySpecs({boardBlockSpec}) == 1, -- 462
		"封锁效果应经执行器下发到棋盘" -- 462
	) -- 462
	expect( -- 463
		expireBoard:lockedCount() == 1, -- 463
		"封锁后棋盘应有 1 个封锁格，实际 " .. tostring(expireBoard:lockedCount()) -- 463
	) -- 463
	local expireFlat = -1 -- 464
	do -- 464
		local row = 0 -- 465
		while row < expireBoard.rows and expireFlat < 0 do -- 465
			do -- 465
				local col = 0 -- 466
				while col < expireBoard.columns do -- 466
					local index = expireBoard:cellIndex(col, row) -- 467
					if index >= 0 and not BlockDefs:isPlaceable(index) then -- 467
						expireFlat = expireBoard:flatIndex(col, row) -- 469
						break -- 470
					end -- 470
					col = col + 1 -- 466
				end -- 466
			end -- 466
			row = row + 1 -- 465
		end -- 465
	end -- 465
	expect(expireFlat >= 0, "应在棋盘上定位封锁格") -- 474
	expect( -- 475
		expireBoard:lockTurnsAt(expireFlat) == Config.LockDurationActions, -- 475
		(("封锁格应记录 " .. tostring(Config.LockDurationActions)) .. " 次敌人行动计时，实际 ") .. tostring(expireBoard:lockTurnsAt(expireFlat)) -- 475
	) -- 475
	expireCombat:enemyAct() -- 476
	expect( -- 477
		expireBoard:lockedCount() == 1, -- 477
		"第 1 次敌人行动后封锁不应到期，实际剩余 " .. tostring(expireBoard:lockedCount()) -- 477
	) -- 477
	expect( -- 478
		expireCombat.lastExpiredLocks == 0, -- 478
		"未到期时 lastExpiredLocks 应为 0，实际 " .. tostring(expireCombat.lastExpiredLocks) -- 478
	) -- 478
	expireCombat:enemyAct() -- 479
	expect( -- 480
		expireBoard:lockedCount() == 0, -- 480
		(("第 " .. tostring(Config.LockDurationActions)) .. " 次敌人行动后封锁应自动恢复，实际剩余 ") .. tostring(expireBoard:lockedCount()) -- 480
	) -- 480
	expect( -- 481
		expireCombat.lastExpiredLocks == 1, -- 481
		"到期恢复数应为 1，实际 " .. tostring(expireCombat.lastExpiredLocks) -- 481
	) -- 481
	expect( -- 482
		BlockDefs:isPlaceable(expireBoard:cellIndex( -- 482
			expireFlat % expireBoard.columns, -- 482
			math.floor(expireFlat / expireBoard.columns) -- 482
		)), -- 482
		"恢复后的格子应为可放置方块" -- 482
	) -- 482
	expect( -- 483
		expireBoard:isFull(), -- 483
		"封锁恢复后棋盘应仍满格" -- 483
	) -- 483
	expect( -- 484
		expireBoard:isPlayable(), -- 484
		"封锁恢复后棋盘应仍可执行" -- 484
	) -- 484
	expect( -- 485
		expireBoard:satisfiesGroupLimit(Config.GroupSizeRelaxLimit), -- 485
		"封锁恢复后棋盘应满足连通块上限" -- 485
	) -- 485
	local viewSizes = { -- 490
		{5120, 1440}, -- 491
		{3440, 1440}, -- 491
		{2560, 1080}, -- 491
		{1920, 1080}, -- 491
		{1280, 960}, -- 491
		{1024, 768}, -- 492
		{960, 1080}, -- 492
		{900, 1200}, -- 492
		{800, 1280}, -- 492
		{720, 1600}, -- 492
		{600, 1040}, -- 492
		{0, 0} -- 492
	} -- 492
	local minHalfWidth = 999999 -- 494
	local minHalfHeight = 999999 -- 495
	for ____, viewSize in ipairs(viewSizes) do -- 496
		local extent = visibleHalfExtent(viewSize[1], viewSize[2]) -- 497
		local halfWidth = extent.width * 0.5 -- 498
		local halfHeight = extent.height * 0.5 -- 499
		if halfWidth < minHalfWidth then -- 499
			minHalfWidth = halfWidth -- 501
		end -- 501
		if halfHeight < minHalfHeight then -- 501
			minHalfHeight = halfHeight -- 504
		end -- 504
		expect( -- 506
			halfWidth >= SafeBox.HalfWidth - 0.01, -- 506
			(((((("窗口 " .. tostring(viewSize[1])) .. "×") .. tostring(viewSize[2])) .. " 可见半宽 ") .. tostring(math.floor(halfWidth))) .. " 应 ≥ 安全区 ") .. tostring(SafeBox.HalfWidth) -- 506
		) -- 506
		expect( -- 507
			halfHeight >= SafeBox.HalfHeight - 0.01, -- 507
			(((((("窗口 " .. tostring(viewSize[1])) .. "×") .. tostring(viewSize[2])) .. " 可见半高 ") .. tostring(math.floor(halfHeight))) .. " 应 ≥ 安全区 ") .. tostring(SafeBox.HalfHeight) -- 507
		) -- 507
	end -- 507
	local layoutRects = hudLayoutRects() -- 509
	for ____, rect in ipairs(layoutRects) do -- 510
		expect( -- 511
			insideSafeBox(rect), -- 511
			((((((((("HUD 元素「" .. rect.name) .. "」（x ") .. tostring(math.floor(rect.x))) .. "±") .. tostring(math.floor(rect.width / 2))) .. "，y ") .. tostring(math.floor(rect.y))) .. "±") .. tostring(math.floor(rect.height / 2))) .. "）越出安全区" -- 511
		) -- 511
	end -- 511
	local layoutBoard = boardLayoutRect() -- 513
	expect( -- 514
		insideSafeBox(layoutBoard), -- 514
		"棋盘应完整落在安全区内" -- 514
	) -- 514
	local boardBottom = layoutBoard.y - layoutBoard.height * 0.5 -- 515
	local hintTop = HudLayout.HintY + HudLayout.FontLabel * 0.75 -- 516
	expect( -- 517
		hintTop <= boardBottom, -- 517
		((("底部操作提示（顶边 " .. tostring(math.floor(hintTop))) .. "）不应与棋盘（底边 ") .. tostring(math.floor(boardBottom))) .. "）重叠" -- 517
	) -- 517
	local skillBottom = HudLayout.SkillButtonY - HudLayout.SkillButtonHeight * 0.5 -- 518
	local laneTop = Config.NoticeEnemyY + HudLayout.NoticeRise + HudLayout.FontNotice * 0.75 -- 519
	expect( -- 520
		laneTop <= skillBottom, -- 520
		((("对敌飘字道（上浮终点 " .. tostring(math.floor(laneTop))) .. "）不应升进技能按钮区（下沿 ") .. tostring(math.floor(skillBottom))) .. "）" -- 520
	) -- 520
	local laneBottom = Config.NoticePlayerY - HudLayout.FontNotice * 0.75 -- 521
	expect( -- 522
		laneBottom >= hintTop + 0.01 + HudLayout.FontLabel * 1.5, -- 522
		("我方飘字道（下沿 " .. tostring(math.floor(laneBottom))) .. "）不应压到底部提示行" -- 522
	) -- 522
	expect( -- 525
		#Levels.List == 6, -- 525
		"应有 6 个手工关卡，实际 " .. tostring(#Levels.List) -- 525
	) -- 525
	local levelsOk = true -- 526
	for ____, level in ipairs(Levels.List) do -- 527
		if #level.waves ~= Config.StageWaveCount then -- 527
			levelsOk = false -- 529
		end -- 529
		for ____, wave in ipairs(level.waves) do -- 531
			if #wave.skills == 0 then -- 531
				levelsOk = false -- 533
			end -- 533
		end -- 533
	end -- 533
	expect( -- 537
		levelsOk, -- 537
		("每关应为 " .. tostring(Config.StageWaveCount)) .. " 波且每波至少 1 条技能" -- 537
	) -- 537
	local defaultWaves = Levels.Default.waves -- 538
	expect(#defaultWaves == #Config.Waves, "默认关卡波数应等于 Config.Waves") -- 539
	local defaultEq = true -- 540
	do -- 540
		local i = 0 -- 541
		while i < #Config.Waves do -- 541
			local a = Config.Waves[i + 1] -- 542
			local b = defaultWaves[i + 1] -- 543
			if a.hp ~= b.hp or a.attack ~= b.attack or a.armor ~= b.armor or a.actionTurns ~= b.actionTurns or a.actionSeconds ~= b.actionSeconds or a.isElite ~= b.isElite then -- 543
				defaultEq = false -- 545
			end -- 545
			i = i + 1 -- 541
		end -- 541
	end -- 541
	expect(defaultEq, "默认关卡数值应逐项等于 Config.Waves（迁移等式）") -- 548
	local rotBoard = __TS__New(Board) -- 549
	local rot = __TS__New( -- 550
		Combat, -- 550
		rotBoard, -- 550
		Levels:get(3) -- 550
	) -- 550
	rot:advanceWave() -- 551
	expect( -- 552
		#rot:currentWave().skills == 2, -- 552
		"第 3 关第 2 波应有 2 条技能，实际 " .. tostring(#rot:currentWave().skills) -- 552
	) -- 552
	expect( -- 553
		rot:enemyAct() == 0, -- 553
		"带预告的首条技能首次行动不应造成伤害" -- 553
	) -- 553
	expect(rot.lastEnemyAction == "prepare" and rot.isPreparing, "首条技能应先进入预告状态") -- 554
	local firstSkill = rot.lastSkillName -- 555
	rot:enemyAct() -- 556
	expect(rot.lastEnemyAction == "release", "预告后的下一次行动应释放技能，实际 " .. rot.lastEnemyAction) -- 557
	expect(rot.lastSkillName == firstSkill and not rot.isPreparing, "释放的技能应与预告一致且清除预告") -- 558
	rot:enemyAct() -- 559
	expect(rot.lastEnemyAction == "attack", "轮转应切换到本波下一条普通技能，实际 " .. rot.lastEnemyAction) -- 560
	local cov = __TS__New( -- 561
		Combat, -- 561
		__TS__New(Board), -- 561
		Levels:get(1) -- 561
	) -- 561
	local seen = {} -- 562
	do -- 562
		local i = 0 -- 563
		while i < 12 do -- 563
			cov:enemyAct() -- 564
			if __TS__ArrayIndexOf(seen, cov.lastSkillName) < 0 then -- 564
				seen[#seen + 1] = cov.lastSkillName -- 566
			end -- 566
			i = i + 1 -- 563
		end -- 563
	end -- 563
	expect(#seen >= 1, "连续敌人行动应至少覆盖 1 条技能") -- 569
	expect(#Levels.EndlessBase.waves == Config.StageWaveCount, "无尽挑战应复用最后一关的波次表") -- 570
	expect( -- 571
		Levels:get(999) == Levels.List[1], -- 571
		"越界关卡 id 应回退到第 1 关" -- 571
	) -- 571
	expect( -- 572
		Levels:skillOf(Levels.List[1].waves[1], 999).id == "strike", -- 572
		"越界技能下标应回退到普通攻击" -- 572
	) -- 572
	expect( -- 575
		ChainTiers:count() == 4, -- 575
		"链长档位应为 4 档，实际 " .. tostring(ChainTiers:count()) -- 575
	) -- 575
	expect( -- 576
		ChainTiers:isStrictlyIncreasing(), -- 576
		"档位倍率必须严格单调递增且区间连续：" .. ChainTiers:describeAll() -- 576
	) -- 576
	expect( -- 577
		ChainTiers:tierOf(2).id == ChainTiers.Contact and ChainTiers:tierOf(3).id == ChainTiers.Contact, -- 577
		"链长 2-3 应落在接触档" -- 577
	) -- 577
	expect( -- 578
		ChainTiers:tierOf(4).id == ChainTiers.Combo and ChainTiers:tierOf(5).id == ChainTiers.Combo, -- 578
		"链长 4-5 应落在连击档" -- 578
	) -- 578
	expect( -- 579
		ChainTiers:tierOf(6).id == ChainTiers.Resonance and ChainTiers:tierOf(7).id == ChainTiers.Resonance, -- 579
		"链长 6-7 应落在共鸣档" -- 579
	) -- 579
	expect( -- 580
		ChainTiers:tierOf(8).id == ChainTiers.Overload and ChainTiers:tierOf(999).id == ChainTiers.Overload, -- 580
		"链长 8+ 应落在超载档" -- 580
	) -- 580
	expect( -- 581
		ChainTiers:multiplierOf(2) == 1, -- 581
		"接触档倍率应为 1.0，实际 " .. tostring(ChainTiers:multiplierOf(2)) -- 581
	) -- 581
	local function specValue(specs, kind, target) -- 582
		for ____, spec in ipairs(specs) do -- 583
			if spec.kind == kind and spec.target == target then -- 583
				return spec.value -- 585
			end -- 585
		end -- 585
		return 0 -- 588
	end -- 582
	expect( -- 590
		BlockDefs:indexOf(BlockDefs.Physical) >= 0 and BlockDefs:indexOf(BlockDefs.Heal) >= 0, -- 590
		"注册表应包含物攻与治疗方块" -- 590
	) -- 590
	local physicalRules = BlockDefs:at(BlockDefs:indexOf(BlockDefs.Physical)).rules -- 591
	local healRules = BlockDefs:at(BlockDefs:indexOf(BlockDefs.Heal)).rules -- 592
	local contactSpecs = resolveEffects(physicalRules, 2) -- 593
	local comboSpecs = resolveEffects(physicalRules, 4) -- 594
	local resonanceSpecs = resolveEffects(physicalRules, 6) -- 595
	local overloadSpecs = resolveEffects(physicalRules, 8) -- 596
	local contactDamage = specValue(contactSpecs, "physicalDamage", "currentEnemy") -- 598
	local comboDamage = specValue(comboSpecs, "physicalDamage", "currentEnemy") -- 599
	local resonanceDamage = specValue(resonanceSpecs, "physicalDamage", "currentEnemy") -- 600
	local overloadDamage = specValue(overloadSpecs, "physicalDamage", "currentEnemy") -- 601
	expect( -- 602
		contactDamage == 10, -- 602
		"接触档物伤应为 round(4+3×2)=10，实际 " .. tostring(contactDamage) -- 602
	) -- 602
	expect( -- 603
		comboDamage == 20, -- 603
		"连击档物伤应为 round(16×1.25)=20，实际 " .. tostring(comboDamage) -- 603
	) -- 603
	expect( -- 604
		resonanceDamage == 35, -- 604
		"共鸣档物伤应为 round(22×1.6)=35，实际 " .. tostring(resonanceDamage) -- 604
	) -- 604
	expect( -- 605
		overloadDamage == 59, -- 605
		"超载档物伤应为 round(28×2.1)=59，实际 " .. tostring(overloadDamage) -- 605
	) -- 605
	expect( -- 606
		comboDamage > contactDamage and resonanceDamage > comboDamage and overloadDamage > resonanceDamage, -- 606
		(((((("高链长档位的数值应严格更大：" .. tostring(contactDamage)) .. "/") .. tostring(comboDamage)) .. "/") .. tostring(resonanceDamage)) .. "/") .. tostring(overloadDamage) -- 606
	) -- 606
	local comboMana = specValue(comboSpecs, "manaGain", "self") -- 608
	local overloadMana = specValue(overloadSpecs, "manaGain", "self") -- 609
	expect( -- 610
		comboMana == 13, -- 610
		"魔力不应受倍率影响，链长 4 应为 1+3×4=13，实际 " .. tostring(comboMana) -- 610
	) -- 610
	expect( -- 611
		overloadMana == 25, -- 611
		"魔力不应受倍率影响，链长 8 应为 1+3×8=25，实际 " .. tostring(overloadMana) -- 611
	) -- 611
	expect( -- 613
		specValue(contactSpecs, "debuffArmor", "currentEnemy") == 0, -- 613
		"接触档不应解锁破甲" -- 613
	) -- 613
	expect( -- 614
		specValue(resonanceSpecs, "debuffArmor", "currentEnemy") > 0, -- 614
		"共鸣档应解锁破甲" -- 614
	) -- 614
	expect( -- 615
		specValue(resonanceSpecs, "physicalDamage", "allEnemies") == 0, -- 615
		"共鸣档不应有全体溅射" -- 615
	) -- 615
	expect( -- 616
		specValue(overloadSpecs, "physicalDamage", "allEnemies") > 0, -- 616
		"超载档应解锁全体溅射" -- 616
	) -- 616
	expect( -- 617
		specValue( -- 617
			resolveEffects(healRules, 3), -- 617
			"dispel", -- 617
			"self" -- 617
		) == 0, -- 617
		"链长 3 不应解锁净化" -- 617
	) -- 617
	expect( -- 618
		specValue( -- 618
			resolveEffects(healRules, 4), -- 618
			"dispel", -- 618
			"self" -- 618
		) > 0, -- 618
		"链长 4 应解锁净化" -- 618
	) -- 618
	expect( -- 619
		specValue( -- 619
			resolveEffects(healRules, 8), -- 619
			"shield", -- 619
			"self" -- 619
		) > 0, -- 619
		"链长 8 应解锁护盾" -- 619
	) -- 619
	local specsMonotonic = true -- 620
	do -- 620
		local n = Config.MinChainLength -- 621
		while n < 9 do -- 621
			if #resolveEffects(physicalRules, n) > #resolveEffects(physicalRules, n + 1) then -- 621
				specsMonotonic = false -- 623
			end -- 623
			n = n + 1 -- 621
		end -- 621
	end -- 621
	expect(specsMonotonic, "效果条数应随链长单调不减") -- 626
	local head = #failures == 0 and "passed" or "failed" -- 628
	local lines = {head} -- 629
	lines[#lines + 1] = ((("检查项 " .. tostring(checks)) .. " 项，失败 ") .. tostring(#failures)) .. " 项" -- 630
	lines[#lines + 1] = ((((((("链长下限 " .. tostring(Config.MinChainLength)) .. "；链长2 物伤 ") .. tostring(damageValue)) .. "、魔力 ") .. tostring(manaValue)) .. "；无解重排惩罚 ") .. tostring(Config.BoardResetPenalty)) .. " 生命；波次/失败切换与设置/实时模式已校验" -- 631
	local sizes = {} -- 632
	for ____, size in ipairs(workBoard:maxGroupSizes()) do -- 633
		sizes[#sizes + 1] = "" .. tostring(size) -- 634
	end -- 634
	lines[#lines + 1] = ((((((((((("200 次随机操作后：生效 " .. tostring(applied)) .. " 次，各类型最大连通块 ") .. table.concat(sizes, ",")) .. "，严格上限越界 ") .. tostring(strictViolations)) .. " 次，放宽上限告警 ") .. tostring(workBoard.limitWarningCount)) .. " 次，无解告警 ") .. tostring(workBoard.deadlockWarningCount)) .. " 次，强制修复 ") .. tostring(workBoard.forcedRepairs)) .. " 次" -- 636
	lines[#lines + 1] = ((((((("M5 封锁/蓄力：blockCells " .. tostring(lockPlaced)) .. " 格，精英蓄力→重击 ") .. tostring(heavyDamage)) .. " 伤害并封锁 ") .. tostring(eliteLocked)) .. " 格；封锁经 ") .. tostring(Config.LockDurationActions)) .. " 次敌人行动后自动恢复" -- 637
	lines[#lines + 1] = ((((((("M8 关卡：" .. tostring(#Levels.List)) .. " 个手工关卡，每关 ") .. tostring(Config.StageWaveCount)) .. " 波；默认关卡数值等于 Config.Waves；第 3 关第 2 波「") .. firstSkill) .. "」先预告后释放，轮转覆盖 ") .. tostring(#seen)) .. " 条技能" -- 638
	lines[#lines + 1] = ((((((((((((("M9 分阶段强化：" .. ChainTiers:describeAll()) .. "；物伤 链长2/4/6/8 = ") .. tostring(contactDamage)) .. "/") .. tostring(comboDamage)) .. "/") .. tostring(resonanceDamage)) .. "/") .. tostring(overloadDamage)) .. "；魔力不受倍率影响（链长4 = ") .. tostring(comboMana)) .. "，链长8 = ") .. tostring(overloadMana)) .. "）" -- 639
	lines[#lines + 1] = ((((((((((((((((((("M6 排版：" .. tostring(#viewSizes)) .. " 种窗口（含 0×0 未就绪）下最小可见区 ") .. tostring(math.floor(minHalfWidth * 2))) .. "×") .. tostring(math.floor(minHalfHeight * 2))) .. " ≥ 安全区 ") .. tostring(Config.DesignSceneWidth)) .. "×") .. tostring(Config.DesignSceneHeight)) .. "，HUD/面板 ") .. tostring(#layoutRects)) .. " 个元素与棋盘均在安全区内；棋盘底边 ") .. tostring(math.floor(boardBottom))) .. "，提示行上沿 ") .. tostring(math.floor(hintTop))) .. "，对敌飘字上浮终点 ") .. tostring(math.floor(laneTop))) .. "（技能按钮下沿 ") .. tostring(math.floor(skillBottom))) .. "）" -- 640
	for ____, failure in ipairs(failures) do -- 641
		lines[#lines + 1] = " - " .. failure -- 642
	end -- 642
	return table.concat(lines, "\n") -- 644
end -- 114
return ____exports -- 114
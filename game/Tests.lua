-- [ts]: Tests.ts
local ____lualib = require("lualib_bundle") -- 1
local __TS__New = ____lualib.__TS__New -- 1
local ____exports = {} -- 1
local collectOption, growPath -- 1
local ____Dora = require("Dora") -- 4
local Content = ____Dora.Content -- 4
local ____Board = require("game.Board") -- 5
local Board = ____Board.Board -- 5
local ____BlockDefs = require("game.BlockDefs") -- 6
local BlockDefs = ____BlockDefs.BlockDefs -- 6
local ____Combat = require("game.Combat") -- 7
local Combat = ____Combat.Combat -- 7
local ____Config = require("game.Config") -- 8
local Config = ____Config.Config -- 8
local ____Effects = require("game.Effects") -- 9
local resolveEffects = ____Effects.resolveEffects -- 9
local unhandledEffectCount = ____Effects.unhandledEffectCount -- 9
local ____Settings = require("game.Settings") -- 10
local Settings = ____Settings.Settings -- 10
local ____Skills = require("game.Skills") -- 11
local Skills = ____Skills.Skills -- 11
local ____UiLayout = require("game.UiLayout") -- 12
local HudLayout = ____UiLayout.HudLayout -- 12
local SafeBox = ____UiLayout.SafeBox -- 12
local boardLayoutRect = ____UiLayout.boardLayoutRect -- 12
local hudLayoutRects = ____UiLayout.hudLayoutRects -- 12
local insideSafeBox = ____UiLayout.insideSafeBox -- 12
local visibleHalfExtent = ____UiLayout.visibleHalfExtent -- 12
function collectOption(board, options, used, col, row, ____type) -- 14
	if not board:inside(col, row) then -- 14
		return -- 16
	end -- 16
	local flat = board:flatIndex(col, row) -- 18
	if used[flat + 1] or board:cellIndex(col, row) ~= ____type then -- 18
		return -- 20
	end -- 20
	options[#options + 1] = flat -- 22
end -- 22
function growPath(board, path, used, ____type, minLength, maxLength) -- 52
	if #path >= minLength then -- 52
		return true -- 54
	end -- 54
	if #path >= maxLength then -- 54
		return false -- 57
	end -- 57
	local last = path[#path] -- 59
	local col = last % board.columns -- 60
	local row = math.floor(last / board.columns) -- 61
	local options = {} -- 62
	collectOption( -- 63
		board, -- 63
		options, -- 63
		used, -- 63
		col - 1, -- 63
		row, -- 63
		____type -- 63
	) -- 63
	collectOption( -- 64
		board, -- 64
		options, -- 64
		used, -- 64
		col + 1, -- 64
		row, -- 64
		____type -- 64
	) -- 64
	collectOption( -- 65
		board, -- 65
		options, -- 65
		used, -- 65
		col, -- 65
		row - 1, -- 65
		____type -- 65
	) -- 65
	collectOption( -- 66
		board, -- 66
		options, -- 66
		used, -- 66
		col, -- 66
		row + 1, -- 66
		____type -- 66
	) -- 66
	for ____, next in ipairs(options) do -- 67
		used[next + 1] = true -- 68
		path[#path + 1] = next -- 69
		if growPath( -- 69
			board, -- 70
			path, -- 70
			used, -- 70
			____type, -- 70
			minLength, -- 70
			maxLength -- 70
		) then -- 70
			return true -- 71
		end -- 71
		table.remove(path) -- 73
		used[next + 1] = false -- 74
	end -- 74
	return false -- 76
end -- 76
--- 确定性地取一条长度 ≥ minLength 的同色相邻链（用于模拟玩家操作与运行时自检）。
-- 逐格起点的深度优先回溯，只要棋盘存在可连线区域就一定能找到，避免随机游走撞死角。
function ____exports.findPlayableChain(board, minLength, maxLength) -- 29
	local total = board.columns * board.rows -- 30
	do -- 30
		local start = 0 -- 31
		while start < total do -- 31
			do -- 31
				local col = start % board.columns -- 32
				local row = math.floor(start / board.columns) -- 33
				local ____type = board:cellIndex(col, row) -- 34
				if ____type < 0 then -- 34
					goto __continue7 -- 36
				end -- 36
				local used = {} -- 38
				do -- 38
					local i = 0 -- 39
					while i < total do -- 39
						used[#used + 1] = false -- 40
						i = i + 1 -- 39
					end -- 39
				end -- 39
				local path = {start} -- 42
				used[start + 1] = true -- 43
				if growPath( -- 43
					board, -- 44
					path, -- 44
					used, -- 44
					____type, -- 44
					minLength, -- 44
					maxLength -- 44
				) then -- 44
					return path -- 45
				end -- 45
			end -- 45
			::__continue7:: -- 45
			start = start + 1 -- 31
		end -- 31
	end -- 31
	return {} -- 48
end -- 29
--- 从指定格子出发游走同色链（长度上限 maxLength），供运行时自检复用。
function ____exports.walkChainFrom(board, flat, maxLength) -- 80
	local ____type = board:cellIndex( -- 81
		flat % board.columns, -- 81
		math.floor(flat / board.columns) -- 81
	) -- 81
	local chain = {} -- 82
	if ____type < 0 then -- 82
		return chain -- 84
	end -- 84
	local total = board.columns * board.rows -- 86
	local used = {} -- 87
	do -- 87
		local i = 0 -- 88
		while i < total do -- 88
			used[#used + 1] = false -- 89
			i = i + 1 -- 88
		end -- 88
	end -- 88
	chain[#chain + 1] = flat -- 91
	used[flat + 1] = true -- 92
	while #chain < maxLength do -- 92
		local last = chain[#chain] -- 94
		local col = last % board.columns -- 95
		local row = math.floor(last / board.columns) -- 96
		local options = {} -- 97
		collectOption( -- 98
			board, -- 98
			options, -- 98
			used, -- 98
			col - 1, -- 98
			row, -- 98
			____type -- 98
		) -- 98
		collectOption( -- 99
			board, -- 99
			options, -- 99
			used, -- 99
			col + 1, -- 99
			row, -- 99
			____type -- 99
		) -- 99
		collectOption( -- 100
			board, -- 100
			options, -- 100
			used, -- 100
			col, -- 100
			row - 1, -- 100
			____type -- 100
		) -- 100
		collectOption( -- 101
			board, -- 101
			options, -- 101
			used, -- 101
			col, -- 101
			row + 1, -- 101
			____type -- 101
		) -- 101
		if #options == 0 then -- 101
			break -- 103
		end -- 103
		local pick = options[math.floor(math.random() * #options) + 1] -- 105
		used[pick + 1] = true -- 106
		chain[#chain + 1] = pick -- 107
	end -- 107
	return chain -- 109
end -- 80
function ____exports.runTests() -- 112
	local failures = {} -- 113
	local checks = 0 -- 114
	local function expect(condition, message) -- 116
		checks = checks + 1 -- 117
		if condition then -- 117
			return -- 119
		end -- 119
		if #failures < 12 then -- 119
			failures[#failures + 1] = message -- 122
		end -- 122
	end -- 116
	expect( -- 127
		BlockDefs:placeableCount() >= 4, -- 127
		"注册表至少应有 4 种可放置方块" -- 127
	) -- 127
	do -- 127
		local i = 0 -- 128
		while i < #BlockDefs.List do -- 128
			do -- 128
				local def = BlockDefs:at(i) -- 129
				if not def.placeable then -- 129
					expect(#def.rules == 0, ("不可放置的方块 " .. def.id) .. " 不应带效果规则") -- 132
					goto __continue29 -- 133
				end -- 133
				expect(#def.rules > 0, ("方块 " .. def.id) .. " 缺少效果规则") -- 135
				expect( -- 136
					#resolveEffects(def.rules, Config.MinChainLength - 1) == 0, -- 136
					("方块 " .. def.id) .. " 在链长低于下限时不应产出效果" -- 136
				) -- 136
				do -- 136
					local n = Config.MinChainLength -- 137
					while n <= 9 do -- 137
						local specs = resolveEffects(def.rules, n) -- 138
						expect( -- 139
							#specs > 0, -- 139
							((("方块 " .. def.id) .. " 链长 ") .. tostring(n)) .. " 未产出效果列表" -- 139
						) -- 139
						for ____, spec in ipairs(specs) do -- 140
							expect( -- 141
								spec.value >= 1, -- 141
								(((("方块 " .. def.id) .. " 链长 ") .. tostring(n)) .. " 的效果数值应 ≥ 1，实际 ") .. tostring(spec.value) -- 141
							) -- 141
						end -- 141
						n = n + 1 -- 137
					end -- 137
				end -- 137
			end -- 137
			::__continue29:: -- 137
			i = i + 1 -- 128
		end -- 128
	end -- 128
	local sampleCount = 30 -- 147
	local fullCount = 0 -- 148
	local strictCount = 0 -- 149
	local boundedCount = 0 -- 150
	local playableCount = 0 -- 151
	do -- 151
		local i = 0 -- 152
		while i < sampleCount do -- 152
			local board = __TS__New(Board) -- 153
			if board:isFull() then -- 153
				fullCount = fullCount + 1 -- 155
			end -- 155
			local maxSize = 0 -- 157
			for ____, size in ipairs(board:maxGroupSizes()) do -- 158
				if size > maxSize then -- 158
					maxSize = size -- 160
				end -- 160
			end -- 160
			if maxSize <= Config.MaxGroupSize then -- 160
				strictCount = strictCount + 1 -- 164
			end -- 164
			if maxSize <= Config.GroupSizeRelaxLimit then -- 164
				boundedCount = boundedCount + 1 -- 167
			end -- 167
			if board:hasPlayableRegion(Config.MinChainLength) then -- 167
				playableCount = playableCount + 1 -- 170
			end -- 170
			i = i + 1 -- 152
		end -- 152
	end -- 152
	expect( -- 173
		fullCount == sampleCount, -- 173
		(("棋盘未满格：" .. tostring(fullCount)) .. "/") .. tostring(sampleCount) -- 173
	) -- 173
	expect( -- 174
		strictCount == sampleCount, -- 174
		((((("C1 最大连通块超过 " .. tostring(Config.MaxGroupSize)) .. "：") .. tostring(strictCount)) .. "/") .. tostring(sampleCount)) .. " 达标" -- 174
	) -- 174
	expect( -- 175
		boundedCount == sampleCount, -- 175
		(((("最大连通块超过放宽上限 " .. tostring(Config.GroupSizeRelaxLimit)) .. "：") .. tostring(boundedCount)) .. "/") .. tostring(sampleCount) -- 175
	) -- 175
	expect( -- 176
		playableCount == sampleCount, -- 176
		(((("C2 缺少可连线区域（所有颜色都无 ≥ " .. tostring(Config.MinChainLength)) .. " 连通）：") .. tostring(playableCount)) .. "/") .. tostring(sampleCount) -- 176
	) -- 176
	expect( -- 179
		Board:areNeighbors(0, 0, 1, 0), -- 179
		"水平相邻判定失败" -- 179
	) -- 179
	expect( -- 180
		Board:areNeighbors(3, 3, 3, 4), -- 180
		"垂直相邻判定失败" -- 180
	) -- 180
	expect( -- 181
		not Board:areNeighbors(0, 0, 1, 1), -- 181
		"斜向不应判为相邻" -- 181
	) -- 181
	expect( -- 182
		not Board:areNeighbors(0, 0, 0, 0), -- 182
		"同一格不应判为相邻" -- 182
	) -- 182
	local workBoard = __TS__New(Board) -- 185
	local applied = 0 -- 186
	local fullFails = 0 -- 187
	local strictViolations = 0 -- 188
	local removedSum = 0 -- 189
	do -- 189
		local i = 0 -- 190
		while i < 200 do -- 190
			do -- 190
				local chain = ____exports.findPlayableChain( -- 191
					workBoard, -- 191
					Config.MinChainLength, -- 191
					3 + math.floor(math.random() * 4) -- 191
				) -- 191
				if #chain < Config.MinChainLength then -- 191
					goto __continue45 -- 193
				end -- 193
				removedSum = removedSum + workBoard:applyChain(chain) -- 195
				applied = applied + 1 -- 196
				if not workBoard:isFull() then -- 196
					fullFails = fullFails + 1 -- 198
				end -- 198
				local maxNow = 0 -- 200
				for ____, size in ipairs(workBoard:maxGroupSizes()) do -- 201
					if size > maxNow then -- 201
						maxNow = size -- 203
					end -- 203
				end -- 203
				if maxNow > Config.MaxGroupSize then -- 203
					strictViolations = strictViolations + 1 -- 207
				end -- 207
			end -- 207
			::__continue45:: -- 207
			i = i + 1 -- 190
		end -- 190
	end -- 190
	expect( -- 210
		applied >= 190, -- 210
		("随机操作实际生效次数应 ≥ 190，实际 " .. tostring(applied)) .. "/200" -- 210
	) -- 210
	expect( -- 211
		fullFails == 0, -- 211
		("消除补充后出现非满格：" .. tostring(fullFails)) .. " 次" -- 211
	) -- 211
	expect( -- 212
		workBoard.deadlockWarningCount == 0, -- 212
		("消除补充后出现无解棋盘：" .. tostring(workBoard.deadlockWarningCount)) .. " 次" -- 212
	) -- 212
	expect( -- 213
		workBoard.clearedTotal == removedSum, -- 213
		(("消除统计应与实际移除数一致：" .. tostring(workBoard.clearedTotal)) .. " vs ") .. tostring(removedSum) -- 213
	) -- 213
	expect( -- 214
		workBoard.chainsTotal == applied, -- 214
		(("连线计数应与生效次数一致：" .. tostring(workBoard.chainsTotal)) .. " vs ") .. tostring(applied) -- 214
	) -- 214
	local oneBoard = __TS__New(Board) -- 217
	local firstColumnCell = oneBoard:flatIndex(0, 0) -- 218
	local beforeEmpty = oneBoard:emptyCount() -- 219
	local removedOne = oneBoard:applyChain({ -- 220
		firstColumnCell, -- 220
		oneBoard:flatIndex(1, 0), -- 220
		oneBoard:flatIndex(2, 0) -- 220
	}) -- 220
	expect( -- 221
		removedOne == 3, -- 221
		"移除 3 格后返回移除数应为 3，实际 " .. tostring(removedOne) -- 221
	) -- 221
	expect( -- 222
		beforeEmpty == 0, -- 222
		"初始棋盘应无空格，实际 " .. tostring(beforeEmpty) -- 222
	) -- 222
	expect( -- 223
		oneBoard:emptyCount() == 0, -- 223
		"补充后应无空格，实际 " .. tostring(oneBoard:emptyCount()) -- 223
	) -- 223
	expect( -- 224
		oneBoard:isFull(), -- 224
		"补充后棋盘应满格" -- 224
	) -- 224
	local physicalIndex = BlockDefs:indexOf(BlockDefs.Physical) -- 227
	local physicalSpecs = resolveEffects( -- 228
		BlockDefs:at(physicalIndex).rules, -- 228
		2 -- 228
	) -- 228
	expect( -- 229
		#resolveEffects( -- 229
			BlockDefs:at(physicalIndex).rules, -- 229
			1 -- 229
		) == 0, -- 229
		"链长 1（低于下限）不应产出效果" -- 229
	) -- 229
	expect( -- 230
		#physicalSpecs == 2, -- 230
		"链长 2 应产出伤害 + 魔力两条效果，实际 " .. tostring(#physicalSpecs) -- 230
	) -- 230
	local damageValue = 0 -- 231
	local manaValue = 0 -- 232
	for ____, spec in ipairs(physicalSpecs) do -- 233
		if spec.kind == "physicalDamage" then -- 233
			damageValue = spec.value -- 235
		end -- 235
		if spec.kind == "manaGain" then -- 235
			manaValue = spec.value -- 238
		end -- 238
	end -- 238
	expect( -- 241
		damageValue == 10, -- 241
		"链长 2 物理伤害应为 4+3×2=10，实际 " .. tostring(damageValue) -- 241
	) -- 241
	expect( -- 242
		manaValue == 7, -- 242
		"链长 2 魔力应为 1+3×2=7，实际 " .. tostring(manaValue) -- 242
	) -- 242
	local manaCombat = __TS__New( -- 244
		Combat, -- 244
		__TS__New(Board) -- 244
	) -- 244
	local manaBefore = manaCombat.player.mana -- 245
	manaCombat:applySpecs(physicalSpecs) -- 246
	expect( -- 247
		manaCombat.player.mana == manaBefore + manaValue, -- 247
		(("消除后魔力应增加 " .. tostring(manaValue)) .. "，实际 ") .. tostring(manaCombat.player.mana - manaBefore) -- 247
	) -- 247
	expect( -- 248
		manaCombat.enemy.hp == 34, -- 248
		"物理伤害 10 受护甲 4 减免后敌人应为 34 HP，实际 " .. tostring(manaCombat.enemy.hp) -- 248
	) -- 248
	manaCombat.player.mana = 0 -- 249
	do -- 249
		local i = 0 -- 250
		while i < 30 do -- 250
			manaCombat:applySpecs(physicalSpecs) -- 251
			i = i + 1 -- 250
		end -- 250
	end -- 250
	expect( -- 253
		manaCombat.player.mana == Config.MaxMana, -- 253
		(("魔力应被夹在上限 " .. tostring(Config.MaxMana)) .. "，实际 ") .. tostring(manaCombat.player.mana) -- 253
	) -- 253
	expect( -- 256
		Skills:find(Skills.Shuffle) ~= nil and Skills:find(Skills.Blast) ~= nil, -- 256
		"技能注册表应包含重排与引爆" -- 256
	) -- 256
	local skillCombat = __TS__New( -- 257
		Combat, -- 257
		__TS__New(Board) -- 257
	) -- 257
	skillCombat.player.mana = 0 -- 258
	expect( -- 259
		not skillCombat:useSkill(Skills.Shuffle).ok, -- 259
		"魔力不足时应拒绝重排" -- 259
	) -- 259
	expect(skillCombat.player.mana == 0, "被拒绝时不应扣除魔力") -- 260
	expect( -- 261
		not skillCombat:useSkill(Skills.Blast).ok, -- 261
		"魔力不足时应拒绝引爆" -- 261
	) -- 261
	expect( -- 262
		not skillCombat:useSkill("not-a-skill").ok, -- 262
		"未知技能应被拒绝" -- 262
	) -- 262
	skillCombat.player.mana = 60 -- 263
	local shuffleResult = skillCombat:useSkill(Skills.Shuffle) -- 264
	expect(shuffleResult.ok, "魔力足够时重排应成功：" .. shuffleResult.message) -- 265
	expect( -- 266
		skillCombat.player.mana == 40, -- 266
		"重排应扣 20 魔力，实际 " .. tostring(skillCombat.player.mana) -- 266
	) -- 266
	expect(skillCombat.player.hp == Config.PlayerMaxHp, "释放技能不应影响玩家生命") -- 267
	local blastBoard = __TS__New(Board) -- 270
	local blastCombat = __TS__New(Combat, blastBoard) -- 271
	blastCombat.player.mana = 100 -- 272
	expect( -- 273
		#blastBoard:largestGroupCells() >= Config.MinChainLength, -- 273
		("棋盘应存在规模 ≥ " .. tostring(Config.MinChainLength)) .. " 的连通块" -- 273
	) -- 273
	local blastResult = blastCombat:useSkill(Skills.Blast) -- 274
	expect(blastResult.ok, "魔力足够时引爆应成功：" .. blastResult.message) -- 275
	expect( -- 276
		blastBoard:isFull(), -- 276
		"引爆后棋盘应满格" -- 276
	) -- 276
	expect( -- 277
		blastBoard:isPlayable(), -- 277
		"引爆后棋盘仍应可执行" -- 277
	) -- 277
	expect( -- 278
		blastCombat.player.mana == 65, -- 278
		"引爆应扣 35 魔力，实际 " .. tostring(blastCombat.player.mana) -- 278
	) -- 278
	local deadBoard = __TS__New(Board) -- 281
	do -- 281
		local row = 0 -- 282
		while row < deadBoard.rows do -- 282
			do -- 282
				local col = 0 -- 283
				while col < deadBoard.columns do -- 283
					deadBoard:setCell(col, row, (col + row) % 2) -- 284
					col = col + 1 -- 283
				end -- 283
			end -- 283
			row = row + 1 -- 282
		end -- 282
	end -- 282
	expect( -- 287
		not deadBoard:isPlayable(), -- 287
		"棋盘格染色（无相邻同色对）应判定为不可执行" -- 287
	) -- 287
	local penaltyCombat = __TS__New(Combat, deadBoard) -- 288
	local hpBeforePenalty = penaltyCombat.player.hp -- 289
	local notice = penaltyCombat:ensureBoardPlayable() -- 290
	expect(notice ~= nil, "不可执行时应返回提示文本") -- 291
	expect( -- 292
		penaltyCombat.boardResetCount == 1, -- 292
		"应记录一次棋盘重排，实际 " .. tostring(penaltyCombat.boardResetCount) -- 292
	) -- 292
	expect( -- 293
		penaltyCombat.player.hp == hpBeforePenalty - Config.BoardResetPenalty, -- 293
		(("应扣除 " .. tostring(Config.BoardResetPenalty)) .. " 点生命，实际 ") .. tostring(penaltyCombat.player.hp) -- 293
	) -- 293
	expect( -- 294
		deadBoard:isFull() and deadBoard:isPlayable(), -- 294
		"重排后棋盘应满格且可执行" -- 294
	) -- 294
	expect( -- 295
		penaltyCombat:ensureBoardPlayable() == nil, -- 295
		"棋盘可执行时不应再触发重排" -- 295
	) -- 295
	local targetCombat = __TS__New( -- 298
		Combat, -- 298
		__TS__New(Board) -- 298
	) -- 298
	targetCombat.player.hp = 50 -- 299
	local magicSpecs = resolveEffects( -- 300
		BlockDefs:at(BlockDefs:indexOf(BlockDefs.Magic)).rules, -- 300
		2 -- 300
	) -- 300
	targetCombat:applySpecs(magicSpecs) -- 301
	expect( -- 302
		targetCombat.player.hp == 50, -- 302
		"魔法伤害不应影响玩家生命，实际 " .. tostring(targetCombat.player.hp) -- 302
	) -- 302
	expect( -- 303
		targetCombat.enemy.hp == 31, -- 303
		"魔法伤害 9 无视护甲，敌人应为 31 HP，实际 " .. tostring(targetCombat.enemy.hp) -- 303
	) -- 303
	local enemyHpBeforeHeal = targetCombat.enemy.hp -- 304
	targetCombat:applySpecs(resolveEffects( -- 305
		BlockDefs:at(BlockDefs:indexOf(BlockDefs.Heal)).rules, -- 305
		2 -- 305
	)) -- 305
	expect( -- 306
		targetCombat.player.hp == 57, -- 306
		"治疗 3+2×2=7 应回复玩家到 57，实际 " .. tostring(targetCombat.player.hp) -- 306
	) -- 306
	expect(targetCombat.enemy.hp == enemyHpBeforeHeal, "治疗不应影响敌人") -- 307
	expect( -- 308
		unhandledEffectCount() == 0, -- 308
		("所用效果种类均应已注册 handler，未注册 " .. tostring(unhandledEffectCount())) .. " 条" -- 308
	) -- 308
	local battle = __TS__New( -- 311
		Combat, -- 311
		__TS__New(Board) -- 311
	) -- 311
	expect( -- 312
		battle.waveNumber == 1 and battle.waveCount == Config.StageWaveCount, -- 312
		("初始应为第 1 波，每关 " .. tostring(Config.StageWaveCount)) .. " 波" -- 312
	) -- 312
	expect( -- 313
		battle.enemyInterval == Config:wave(0).actionTurns, -- 313
		("第 1 波敌人行动间隔应为 " .. tostring(Config:wave(0).actionTurns)) .. " 回合" -- 313
	) -- 313
	local hpBeforeEnemyAct = battle.player.hp -- 314
	local dealt = battle:enemyAct() -- 315
	expect( -- 316
		dealt > 0, -- 316
		"敌人出手应造成伤害，实际 " .. tostring(dealt) -- 316
	) -- 316
	expect( -- 317
		battle.player.hp == hpBeforeEnemyAct - dealt, -- 317
		(("玩家生命应按伤害下降：" .. tostring(hpBeforeEnemyAct)) .. " → ") .. tostring(battle.player.hp) -- 317
	) -- 317
	battle.enemy.hp = 0 -- 318
	expect( -- 319
		not battle:advanceWave(), -- 319
		"第 1 波清完后应还有后续波次" -- 319
	) -- 319
	expect( -- 320
		battle.waveNumber == 2, -- 320
		"应推进到第 2 波，实际 " .. tostring(battle.waveNumber) -- 320
	) -- 320
	expect(battle.enemy.hp == battle.enemy.maxHp and battle.enemy.hp > 0, "新波次敌人应满血") -- 321
	battle.enemy.hp = 0 -- 322
	expect( -- 323
		not battle:advanceWave(), -- 323
		"第 2 波清完后应还有第 3 波" -- 323
	) -- 323
	battle.enemy.hp = 0 -- 324
	expect( -- 325
		battle:advanceWave(), -- 325
		"第 3 波清完应判定本关通关" -- 325
	) -- 325
	local hpBeforeNextStage = battle.player.hp -- 326
	battle:nextStage() -- 327
	expect(battle.stageNumber == 2 and battle.waveNumber == 1, "应进入第 2 关第 1 波") -- 328
	expect(battle.player.hp >= hpBeforeNextStage, "通关后玩家应回复生命") -- 329
	expect( -- 330
		battle.enemy.maxHp > Config:wave(0).hp, -- 330
		"第 2 关敌人数值应按关卡增长，实际 " .. tostring(battle.enemy.maxHp) -- 330
	) -- 330
	battle.player.hp = 0 -- 331
	expect(battle.defeated, "玩家生命为 0 应判定失败") -- 332
	battle:resetBattle() -- 333
	expect(not battle.defeated, "重开后不应处于失败状态") -- 334
	expect(battle.stageNumber == 1 and battle.player.hp == battle.player.maxHp and battle.player.mana == 0, "重开本关应复位关卡与玩家状态") -- 335
	expect(battle.boardResetCount == 0, "重开应清零被动重排计数") -- 336
	local settingsFile = "settings-selftest.txt" -- 339
	local settings = __TS__New(Settings) -- 340
	settings.mode = "realtime" -- 341
	settings.difficulty = "hard" -- 342
	settings.showHint = false -- 343
	local saved = settings:save(settingsFile) -- 344
	expect(saved, "设置应能写入存档文件（若环境不可写则本项会失败）") -- 345
	if saved then -- 345
		local loaded = Settings:load(settingsFile) -- 347
		expect(loaded.mode == "realtime", "模式应往返一致，实际 " .. loaded.mode) -- 348
		expect(loaded.difficulty == "hard", "难度应往返一致，实际 " .. loaded.difficulty) -- 349
		expect(not loaded.showHint, "提示开关应往返一致") -- 350
		if Content:exist(settingsFile) then -- 350
			Content:remove(settingsFile) -- 352
		end -- 352
	else -- 352
		expect( -- 355
			Settings:load(settingsFile).mode == "turnBased", -- 355
			"写入失败时应回退为默认设置" -- 355
		) -- 355
	end -- 355
	local toggled = __TS__New(Settings) -- 357
	expect( -- 358
		toggled:toggleMode() == "realtime", -- 358
		"切换应变为实时模式" -- 358
	) -- 358
	expect( -- 359
		toggled:toggleMode() == "turnBased", -- 359
		"再次切换应回到回合制" -- 359
	) -- 359
	expect( -- 360
		toggled:cycleDifficulty() == "hard", -- 360
		"标准 → 困难" -- 360
	) -- 360
	expect( -- 361
		toggled:cycleDifficulty() == "casual", -- 361
		"困难 → 休闲" -- 361
	) -- 361
	expect( -- 362
		not toggled:toggleHint(), -- 362
		"提示开关应可关闭" -- 362
	) -- 362
	expect( -- 363
		toggled:difficultyScale() == Config:difficultyScale("casual"), -- 363
		"难度缩放应与配置一致" -- 363
	) -- 363
	local realtimeCombat = __TS__New( -- 365
		Combat, -- 365
		__TS__New(Board) -- 365
	) -- 365
	realtimeCombat:setRealtime(true) -- 366
	expect(realtimeCombat.isRealtime, "应处于实时模式") -- 367
	local interval = realtimeCombat.enemyIntervalSeconds -- 368
	expect( -- 369
		interval > 0, -- 369
		"实时间隔应为正数，实际 " .. tostring(interval) -- 369
	) -- 369
	expect( -- 370
		not realtimeCombat:advanceTime(interval * 0.5), -- 370
		"未到时间不应触发敌人行动" -- 370
	) -- 370
	expect( -- 371
		realtimeCombat:advanceTime(interval * 0.5 + 0.01), -- 371
		"累计到间隔应触发敌人行动" -- 371
	) -- 371
	expect( -- 372
		math.abs(realtimeCombat.secondsLeft - interval) < 0.001, -- 372
		(("触发后倒计时应重置为 " .. tostring(interval)) .. "，实际 ") .. tostring(realtimeCombat.secondsLeft) -- 372
	) -- 372
	local turnCombat = __TS__New( -- 373
		Combat, -- 373
		__TS__New(Board) -- 373
	) -- 373
	turnCombat:setRealtime(false) -- 374
	expect( -- 375
		not turnCombat:advanceTime(999), -- 375
		"回合制下推进时间不应触发敌人行动" -- 375
	) -- 375
	expect( -- 376
		turnCombat.enemyInterval == Config:wave(0).actionTurns, -- 376
		"回合制间隔应为回合数 " .. tostring(Config:wave(0).actionTurns) -- 376
	) -- 376
	local hardCombat = __TS__New( -- 377
		Combat, -- 377
		__TS__New(Board) -- 377
	) -- 377
	hardCombat:setDifficultyScale(Config:difficultyScale("hard")) -- 378
	hardCombat:loadWave() -- 379
	expect( -- 380
		hardCombat.enemy.maxHp == math.floor(Config:wave(0).hp * Config:difficultyScale("hard") + 0.5), -- 380
		"难度应缩放敌人生命，实际 " .. tostring(hardCombat.enemy.maxHp) -- 380
	) -- 380
	local lockedIndex = BlockDefs:lockedIndex() -- 383
	expect(lockedIndex >= 0, "注册表应包含封锁格定义") -- 384
	expect( -- 385
		not BlockDefs:isPlaceable(lockedIndex), -- 385
		"封锁格不应可放置" -- 385
	) -- 385
	local lockBoard = __TS__New(Board) -- 386
	local lockPlaced = lockBoard:blockCells(Config.EliteHeavyBlockCells) -- 387
	expect( -- 388
		lockPlaced == Config.EliteHeavyBlockCells, -- 388
		(("应封锁 " .. tostring(Config.EliteHeavyBlockCells)) .. " 格，实际 ") .. tostring(lockPlaced) -- 388
	) -- 388
	expect( -- 389
		lockBoard:isPlayable(), -- 389
		"封锁后棋盘仍应存在可连线区域（硬约束）" -- 389
	) -- 389
	expect( -- 390
		lockBoard:isFull(), -- 390
		"封锁后棋盘仍应满格" -- 390
	) -- 390
	local groupHasLocked = 0 -- 391
	for ____, flat in ipairs(lockBoard:largestGroupCells()) do -- 392
		local groupCol = flat % lockBoard.columns -- 393
		local groupRow = math.floor(flat / lockBoard.columns) -- 394
		if not BlockDefs:isPlaceable(lockBoard:cellIndex(groupCol, groupRow)) then -- 394
			groupHasLocked = groupHasLocked + 1 -- 396
		end -- 396
	end -- 396
	expect( -- 399
		groupHasLocked == 0, -- 399
		("最大连通块候选不应含封锁格，实际含 " .. tostring(groupHasLocked)) .. " 格" -- 399
	) -- 399
	local blastRemoved = lockBoard:blastLargestGroup() -- 400
	expect( -- 401
		blastRemoved > 0, -- 401
		"引爆应移除可放置连通块，实际 " .. tostring(blastRemoved) -- 401
	) -- 401
	expect( -- 402
		lockBoard:isPlayable(), -- 402
		"引爆后棋盘仍应可执行" -- 402
	) -- 402
	expect( -- 403
		lockBoard:isFull(), -- 403
		"引爆后棋盘仍应满格" -- 403
	) -- 403
	local mob = __TS__New( -- 405
		Combat, -- 405
		__TS__New(Board) -- 405
	) -- 405
	local mobDamage = mob:enemyAct() -- 406
	expect(mob.lastEnemyAction == "attack", "小怪行动类别应为普通攻击") -- 407
	expect( -- 408
		mobDamage > 0, -- 408
		"小怪出手应造成伤害，实际 " .. tostring(mobDamage) -- 408
	) -- 408
	local eliteBoard = __TS__New(Board) -- 410
	local elite = __TS__New(Combat, eliteBoard) -- 411
	elite:advanceWave() -- 412
	elite:advanceWave() -- 413
	expect( -- 414
		elite:currentWave().isElite, -- 414
		"第 3 波应为精英" -- 414
	) -- 414
	local unhandledBefore = unhandledEffectCount() -- 415
	local hpBeforeCharge = elite.player.hp -- 416
	expect( -- 417
		elite:enemyAct() == 0, -- 417
		"精英首次行动应为蓄力，不造成伤害" -- 417
	) -- 417
	expect(elite.lastEnemyAction == "charge", "首次行动类别应为蓄力") -- 418
	expect(elite.isCharged, "蓄力后应处于蓄力状态") -- 419
	expect( -- 420
		elite.player.hp == hpBeforeCharge, -- 420
		"蓄力不应扣血，实际 " .. tostring(elite.player.hp) -- 420
	) -- 420
	local heavyDamage = elite:enemyAct() -- 421
	expect(elite.lastEnemyAction == "heavy", "第二次行动类别应为重击") -- 422
	expect( -- 423
		heavyDamage > elite:currentWave().attack, -- 423
		(("重击伤害应高于普通攻击，实际 " .. tostring(heavyDamage)) .. " vs ") .. tostring(elite:currentWave().attack) -- 423
	) -- 423
	expect(not elite.isCharged, "重击后应清除蓄力状态") -- 424
	expect( -- 425
		unhandledEffectCount() == unhandledBefore, -- 425
		"BoardBlock 应已在执行器注册表中（悬空效果数不应增加）" -- 425
	) -- 425
	local eliteLocked = 0 -- 426
	do -- 426
		local row = 0 -- 427
		while row < eliteBoard.rows do -- 427
			do -- 427
				local col = 0 -- 428
				while col < eliteBoard.columns do -- 428
					local index = eliteBoard:cellIndex(col, row) -- 429
					if index >= 0 and not BlockDefs:isPlaceable(index) then -- 429
						eliteLocked = eliteLocked + 1 -- 431
					end -- 431
					col = col + 1 -- 428
				end -- 428
			end -- 428
			row = row + 1 -- 427
		end -- 427
	end -- 427
	expect( -- 435
		eliteLocked == Config.EliteHeavyBlockCells, -- 435
		(("重击应经执行器封锁 " .. tostring(Config.EliteHeavyBlockCells)) .. " 格，实际 ") .. tostring(eliteLocked) -- 435
	) -- 435
	expect( -- 436
		eliteBoard:isPlayable(), -- 436
		"重击封锁后棋盘仍应可执行" -- 436
	) -- 436
	expect( -- 437
		eliteBoard:isFull(), -- 437
		"重击封锁后棋盘仍应满格" -- 437
	) -- 437
	elite:nextStage() -- 438
	expect(not elite.isCharged and elite.lastEnemyAction == "attack", "进入新关后应复位蓄力状态") -- 439
	local effectBoard = __TS__New(Board) -- 442
	local effectCombat = __TS__New(Combat, effectBoard) -- 443
	local boardBlockSpec = {kind = "boardBlock", value = 1, target = "board"} -- 444
	expect( -- 445
		effectCombat:applySpecs({boardBlockSpec}) == 1, -- 445
		"applySpecs 应执行 1 条 BoardBlock 效果" -- 445
	) -- 445
	local effectLocked = 0 -- 446
	do -- 446
		local row = 0 -- 447
		while row < effectBoard.rows do -- 447
			do -- 447
				local col = 0 -- 448
				while col < effectBoard.columns do -- 448
					local index = effectBoard:cellIndex(col, row) -- 449
					if index >= 0 and not BlockDefs:isPlaceable(index) then -- 449
						effectLocked = effectLocked + 1 -- 451
					end -- 451
					col = col + 1 -- 448
				end -- 448
			end -- 448
			row = row + 1 -- 447
		end -- 447
	end -- 447
	expect( -- 455
		effectLocked == 1, -- 455
		"BoardBlock 效果应封锁 1 格，实际 " .. tostring(effectLocked) -- 455
	) -- 455
	local expireBoard = __TS__New(Board) -- 458
	local expireCombat = __TS__New(Combat, expireBoard) -- 459
	expect( -- 460
		expireCombat:applySpecs({boardBlockSpec}) == 1, -- 460
		"封锁效果应经执行器下发到棋盘" -- 460
	) -- 460
	expect( -- 461
		expireBoard:lockedCount() == 1, -- 461
		"封锁后棋盘应有 1 个封锁格，实际 " .. tostring(expireBoard:lockedCount()) -- 461
	) -- 461
	local expireFlat = -1 -- 462
	do -- 462
		local row = 0 -- 463
		while row < expireBoard.rows and expireFlat < 0 do -- 463
			do -- 463
				local col = 0 -- 464
				while col < expireBoard.columns do -- 464
					local index = expireBoard:cellIndex(col, row) -- 465
					if index >= 0 and not BlockDefs:isPlaceable(index) then -- 465
						expireFlat = expireBoard:flatIndex(col, row) -- 467
						break -- 468
					end -- 468
					col = col + 1 -- 464
				end -- 464
			end -- 464
			row = row + 1 -- 463
		end -- 463
	end -- 463
	expect(expireFlat >= 0, "应在棋盘上定位封锁格") -- 472
	expect( -- 473
		expireBoard:lockTurnsAt(expireFlat) == Config.LockDurationActions, -- 473
		(("封锁格应记录 " .. tostring(Config.LockDurationActions)) .. " 次敌人行动计时，实际 ") .. tostring(expireBoard:lockTurnsAt(expireFlat)) -- 473
	) -- 473
	expireCombat:enemyAct() -- 474
	expect( -- 475
		expireBoard:lockedCount() == 1, -- 475
		"第 1 次敌人行动后封锁不应到期，实际剩余 " .. tostring(expireBoard:lockedCount()) -- 475
	) -- 475
	expect( -- 476
		expireCombat.lastExpiredLocks == 0, -- 476
		"未到期时 lastExpiredLocks 应为 0，实际 " .. tostring(expireCombat.lastExpiredLocks) -- 476
	) -- 476
	expireCombat:enemyAct() -- 477
	expect( -- 478
		expireBoard:lockedCount() == 0, -- 478
		(("第 " .. tostring(Config.LockDurationActions)) .. " 次敌人行动后封锁应自动恢复，实际剩余 ") .. tostring(expireBoard:lockedCount()) -- 478
	) -- 478
	expect( -- 479
		expireCombat.lastExpiredLocks == 1, -- 479
		"到期恢复数应为 1，实际 " .. tostring(expireCombat.lastExpiredLocks) -- 479
	) -- 479
	expect( -- 480
		BlockDefs:isPlaceable(expireBoard:cellIndex( -- 480
			expireFlat % expireBoard.columns, -- 480
			math.floor(expireFlat / expireBoard.columns) -- 480
		)), -- 480
		"恢复后的格子应为可放置方块" -- 480
	) -- 480
	expect( -- 481
		expireBoard:isFull(), -- 481
		"封锁恢复后棋盘应仍满格" -- 481
	) -- 481
	expect( -- 482
		expireBoard:isPlayable(), -- 482
		"封锁恢复后棋盘应仍可执行" -- 482
	) -- 482
	expect( -- 483
		expireBoard:satisfiesGroupLimit(Config.GroupSizeRelaxLimit), -- 483
		"封锁恢复后棋盘应满足连通块上限" -- 483
	) -- 483
	local viewSizes = { -- 488
		{5120, 1440}, -- 489
		{3440, 1440}, -- 489
		{2560, 1080}, -- 489
		{1920, 1080}, -- 489
		{1280, 960}, -- 489
		{1024, 768}, -- 490
		{960, 1080}, -- 490
		{900, 1200}, -- 490
		{800, 1280}, -- 490
		{720, 1600}, -- 490
		{600, 1040}, -- 490
		{0, 0} -- 490
	} -- 490
	local minHalfWidth = 999999 -- 492
	local minHalfHeight = 999999 -- 493
	for ____, viewSize in ipairs(viewSizes) do -- 494
		local extent = visibleHalfExtent(viewSize[1], viewSize[2]) -- 495
		local halfWidth = extent.width * 0.5 -- 496
		local halfHeight = extent.height * 0.5 -- 497
		if halfWidth < minHalfWidth then -- 497
			minHalfWidth = halfWidth -- 499
		end -- 499
		if halfHeight < minHalfHeight then -- 499
			minHalfHeight = halfHeight -- 502
		end -- 502
		expect( -- 504
			halfWidth >= SafeBox.HalfWidth - 0.01, -- 504
			(((((("窗口 " .. tostring(viewSize[1])) .. "×") .. tostring(viewSize[2])) .. " 可见半宽 ") .. tostring(math.floor(halfWidth))) .. " 应 ≥ 安全区 ") .. tostring(SafeBox.HalfWidth) -- 504
		) -- 504
		expect( -- 505
			halfHeight >= SafeBox.HalfHeight - 0.01, -- 505
			(((((("窗口 " .. tostring(viewSize[1])) .. "×") .. tostring(viewSize[2])) .. " 可见半高 ") .. tostring(math.floor(halfHeight))) .. " 应 ≥ 安全区 ") .. tostring(SafeBox.HalfHeight) -- 505
		) -- 505
	end -- 505
	local layoutRects = hudLayoutRects() -- 507
	for ____, rect in ipairs(layoutRects) do -- 508
		expect( -- 509
			insideSafeBox(rect), -- 509
			((((((((("HUD 元素「" .. rect.name) .. "」（x ") .. tostring(math.floor(rect.x))) .. "±") .. tostring(math.floor(rect.width / 2))) .. "，y ") .. tostring(math.floor(rect.y))) .. "±") .. tostring(math.floor(rect.height / 2))) .. "）越出安全区" -- 509
		) -- 509
	end -- 509
	local layoutBoard = boardLayoutRect() -- 511
	expect( -- 512
		insideSafeBox(layoutBoard), -- 512
		"棋盘应完整落在安全区内" -- 512
	) -- 512
	local boardBottom = layoutBoard.y - layoutBoard.height * 0.5 -- 513
	local hintTop = HudLayout.HintY + HudLayout.FontLabel * 0.75 -- 514
	expect( -- 515
		hintTop <= boardBottom, -- 515
		((("底部操作提示（顶边 " .. tostring(math.floor(hintTop))) .. "）不应与棋盘（底边 ") .. tostring(math.floor(boardBottom))) .. "）重叠" -- 515
	) -- 515
	local skillBottom = HudLayout.SkillButtonY - HudLayout.SkillButtonHeight * 0.5 -- 516
	local laneTop = Config.NoticeEnemyY + HudLayout.NoticeRise + HudLayout.FontNotice * 0.75 -- 517
	expect( -- 518
		laneTop <= skillBottom, -- 518
		((("对敌飘字道（上浮终点 " .. tostring(math.floor(laneTop))) .. "）不应升进技能按钮区（下沿 ") .. tostring(math.floor(skillBottom))) .. "）" -- 518
	) -- 518
	local laneBottom = Config.NoticePlayerY - HudLayout.FontNotice * 0.75 -- 519
	expect( -- 520
		laneBottom >= hintTop + 0.01 + HudLayout.FontLabel * 1.5, -- 520
		("我方飘字道（下沿 " .. tostring(math.floor(laneBottom))) .. "）不应压到底部提示行" -- 520
	) -- 520
	local head = #failures == 0 and "passed" or "failed" -- 522
	local lines = {head} -- 523
	lines[#lines + 1] = ((("检查项 " .. tostring(checks)) .. " 项，失败 ") .. tostring(#failures)) .. " 项" -- 524
	lines[#lines + 1] = ((((((("链长下限 " .. tostring(Config.MinChainLength)) .. "；链长2 物伤 ") .. tostring(damageValue)) .. "、魔力 ") .. tostring(manaValue)) .. "；无解重排惩罚 ") .. tostring(Config.BoardResetPenalty)) .. " 生命；波次/失败切换与设置/实时模式已校验" -- 525
	local sizes = {} -- 526
	for ____, size in ipairs(workBoard:maxGroupSizes()) do -- 527
		sizes[#sizes + 1] = "" .. tostring(size) -- 528
	end -- 528
	lines[#lines + 1] = ((((((((((("200 次随机操作后：生效 " .. tostring(applied)) .. " 次，各类型最大连通块 ") .. table.concat(sizes, ",")) .. "，严格上限越界 ") .. tostring(strictViolations)) .. " 次，放宽上限告警 ") .. tostring(workBoard.limitWarningCount)) .. " 次，无解告警 ") .. tostring(workBoard.deadlockWarningCount)) .. " 次，强制修复 ") .. tostring(workBoard.forcedRepairs)) .. " 次" -- 530
	lines[#lines + 1] = ((((((("M5 封锁/蓄力：blockCells " .. tostring(lockPlaced)) .. " 格，精英蓄力→重击 ") .. tostring(heavyDamage)) .. " 伤害并封锁 ") .. tostring(eliteLocked)) .. " 格；封锁经 ") .. tostring(Config.LockDurationActions)) .. " 次敌人行动后自动恢复" -- 531
	lines[#lines + 1] = ((((((((((((((((((("M6 排版：" .. tostring(#viewSizes)) .. " 种窗口（含 0×0 未就绪）下最小可见区 ") .. tostring(math.floor(minHalfWidth * 2))) .. "×") .. tostring(math.floor(minHalfHeight * 2))) .. " ≥ 安全区 ") .. tostring(Config.DesignSceneWidth)) .. "×") .. tostring(Config.DesignSceneHeight)) .. "，HUD/面板 ") .. tostring(#layoutRects)) .. " 个元素与棋盘均在安全区内；棋盘底边 ") .. tostring(math.floor(boardBottom))) .. "，提示行上沿 ") .. tostring(math.floor(hintTop))) .. "，对敌飘字上浮终点 ") .. tostring(math.floor(laneTop))) .. "（技能按钮下沿 ") .. tostring(math.floor(skillBottom))) .. "）" -- 532
	for ____, failure in ipairs(failures) do -- 533
		lines[#lines + 1] = " - " .. failure -- 534
	end -- 534
	return table.concat(lines, "\n") -- 536
end -- 112
return ____exports -- 112
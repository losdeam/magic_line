-- [ts]: Entry.ts
local ____lualib = require("lualib_bundle") -- 1
local __TS__New = ____lualib.__TS__New -- 1
local ____exports = {} -- 1
local ____Dora = require("Dora") -- 5
local App = ____Dora.App -- 5
local Content = ____Dora.Content -- 5
local Director = ____Dora.Director -- 5
local Node = ____Dora.Node -- 5
local Path = ____Dora.Path -- 5
local Size = ____Dora.Size -- 5
local Vec2 = ____Dora.Vec2 -- 5
local ____Board = require("game.Board") -- 6
local Board = ____Board.Board -- 6
local ____BlockDefs = require("game.BlockDefs") -- 7
local BlockDefs = ____BlockDefs.BlockDefs -- 7
local ____BoardView = require("game.BoardView") -- 8
local BoardView = ____BoardView.BoardView -- 8
local ____ChainTiers = require("game.ChainTiers") -- 9
local ChainTiers = ____ChainTiers.ChainTiers -- 9
local ____Combat = require("game.Combat") -- 10
local Combat = ____Combat.Combat -- 10
local ____Config = require("game.Config") -- 11
local Config = ____Config.Config -- 11
local ____Effects = require("game.Effects") -- 12
local formatEffects = ____Effects.formatEffects -- 12
local resolveEffects = ____Effects.resolveEffects -- 12
local ____Game = require("game.Game") -- 13
local Game = ____Game.Game -- 13
local ____Skills = require("game.Skills") -- 14
local Skills = ____Skills.Skills -- 14
local ____Tests = require("game.Tests") -- 15
local findPlayableChain = ____Tests.findPlayableChain -- 15
local runTests = ____Tests.runTests -- 15
local function cellCenterPointFromFlat(flat) -- 17
	local col = flat % Config.Columns -- 18
	local row = math.floor(flat / Config.Columns) -- 19
	return Vec2((col + 0.5) * Config.CellSize, (row + 0.5) * Config.CellSize) -- 20
end -- 17
--- 视图交互自检：用确定性图案验证“触点 → 格子 → 连线 → 效果三元组”全链路。
local function runViewChecks() -- 24
	local failures = {} -- 25
	local checks = 0 -- 26
	local function expect(condition, message) -- 27
		checks = checks + 1 -- 28
		if not condition and #failures < 12 then -- 28
			failures[#failures + 1] = message -- 30
		end -- 30
	end -- 27
	local physical = BlockDefs:indexOf(BlockDefs.Physical) -- 34
	local magic = BlockDefs:indexOf(BlockDefs.Magic) -- 35
	local status = BlockDefs:indexOf(BlockDefs.Status) -- 36
	local heal = BlockDefs:indexOf(BlockDefs.Heal) -- 37
	expect(physical >= 0 and magic >= 0 and status >= 0 and heal >= 0, "注册表缺少基础方块类型") -- 38
	local board = __TS__New(Board) -- 41
	local pattern = { -- 42
		physical, -- 42
		magic, -- 42
		status, -- 42
		heal, -- 42
		physical, -- 42
		magic, -- 42
		status -- 42
	} -- 42
	do -- 42
		local row = 0 -- 43
		while row < board.rows do -- 43
			do -- 43
				local col = 0 -- 44
				while col < board.columns do -- 44
					board:setCell(col, row, pattern[row + 1]) -- 45
					col = col + 1 -- 44
				end -- 44
			end -- 44
			row = row + 1 -- 43
		end -- 43
	end -- 43
	local view = __TS__New(BoardView, board) -- 49
	view.root:addTo(Director.entry) -- 50
	view:press(cellCenterPointFromFlat(board:flatIndex(0, 0))) -- 52
	expect( -- 53
		view.chainLength == 1, -- 53
		"按下后连线长度应为 1，实际 " .. tostring(view.chainLength) -- 53
	) -- 53
	expect( -- 54
		view:selectedCount() == 1, -- 54
		"按下后高亮选中数应为 1，实际 " .. tostring(view:selectedCount()) -- 54
	) -- 54
	view:release(cellCenterPointFromFlat(board:flatIndex(0, 0))) -- 57
	expect( -- 58
		view:takePendingResult() == nil, -- 58
		"单格连线不应产出结果" -- 58
	) -- 58
	view:press(cellCenterPointFromFlat(board:flatIndex(0, 0))) -- 60
	view:move(cellCenterPointFromFlat(board:flatIndex(1, 0))) -- 61
	view:move(cellCenterPointFromFlat(board:flatIndex(2, 0))) -- 62
	view:move(cellCenterPointFromFlat(board:flatIndex(3, 0))) -- 63
	expect( -- 64
		view.chainLength == 4, -- 64
		"滑过 4 格同色后连线长度应为 4，实际 " .. tostring(view.chainLength) -- 64
	) -- 64
	view:move(cellCenterPointFromFlat(board:flatIndex(3, 1))) -- 66
	expect( -- 67
		view.chainLength == 4, -- 67
		"跨类型滑入不应增加连线，实际 " .. tostring(view.chainLength) -- 67
	) -- 67
	view:move(cellCenterPointFromFlat(board:flatIndex(6, 6))) -- 69
	expect( -- 70
		view.chainLength == 4, -- 70
		"非相邻格不应加入连线，实际 " .. tostring(view.chainLength) -- 70
	) -- 70
	view:move(cellCenterPointFromFlat(board:flatIndex(2, 0))) -- 72
	expect( -- 73
		view.chainLength == 3, -- 73
		"回退一格后连线长度应为 3，实际 " .. tostring(view.chainLength) -- 73
	) -- 73
	view:release(cellCenterPointFromFlat(board:flatIndex(3, 0))) -- 75
	local result = view:takePendingResult() -- 76
	expect(result ~= nil, "松手后应产出连线结果") -- 77
	if result ~= nil then -- 77
		expect(result.blockId == BlockDefs.Physical, "连线类型应为 physical，实际 " .. result.blockId) -- 79
		expect( -- 80
			result.chainLength == 4, -- 80
			"松手时连线长度应为 4，实际 " .. tostring(result.chainLength) -- 80
		) -- 80
		local expected = resolveEffects( -- 81
			BlockDefs:at(physical).rules, -- 81
			4 -- 81
		) -- 81
		expect(#result.specs == #expected, "效果条目数应与规则解析一致") -- 82
		local first = result.specs[1] -- 83
		expect(first.kind == "physicalDamage", "物理方块应产出 physicalDamage") -- 84
		expect(first.target == "currentEnemy", "物理伤害应作用于当前敌人") -- 85
		local expectedDamage = math.floor((4 + 3 * 4) * ChainTiers:multiplierOf(4) + 0.5) -- 87
		expect( -- 88
			first.value == expectedDamage, -- 88
			(("物理伤害 4+3×4 乘连击档倍率应为 " .. tostring(expectedDamage)) .. "，实际 ") .. tostring(first.value) -- 88
		) -- 88
		expect( -- 89
			(string.find( -- 89
				formatEffects(result.specs), -- 89
				"物理伤害 " .. tostring(expectedDamage), -- 89
				nil, -- 89
				true -- 89
			) or 0) - 1 == 0, -- 89
			(("效果文本应为“物理伤害 " .. tostring(expectedDamage)) .. " …”，实际 ") .. formatEffects(result.specs) -- 89
		) -- 89
	end -- 89
	view:press(cellCenterPointFromFlat(board:flatIndex(5, 0))) -- 93
	view:move(cellCenterPointFromFlat(board:flatIndex(6, 0))) -- 94
	view:release(cellCenterPointFromFlat(board:flatIndex(6, 0))) -- 95
	local shortResult = view:takePendingResult() -- 96
	expect( -- 97
		shortResult ~= nil, -- 97
		("链长 2 应产出结果（链长下限为 " .. tostring(Config.MinChainLength)) .. "）" -- 97
	) -- 97
	if shortResult ~= nil then -- 97
		expect( -- 99
			shortResult.chainLength == 2, -- 99
			"短链长度应为 2，实际 " .. tostring(shortResult.chainLength) -- 99
		) -- 99
	end -- 99
	expect( -- 101
		view:selectedCount() == 0, -- 101
		"结算后应清除全部高亮，实际 " .. tostring(view:selectedCount()) -- 101
	) -- 101
	local lockedIndex = BlockDefs:lockedIndex() -- 104
	expect(lockedIndex >= 0, "注册表应包含封锁格定义") -- 105
	local lockBoard = __TS__New(Board) -- 106
	do -- 106
		local row = 0 -- 107
		while row < lockBoard.rows do -- 107
			do -- 107
				local col = 0 -- 108
				while col < lockBoard.columns do -- 108
					lockBoard:setCell(col, row, pattern[row + 1]) -- 109
					col = col + 1 -- 108
				end -- 108
			end -- 108
			row = row + 1 -- 107
		end -- 107
	end -- 107
	lockBoard:setCell(0, 0, lockedIndex) -- 112
	local lockView = __TS__New(BoardView, lockBoard) -- 113
	lockView.root:addTo(Director.entry) -- 114
	lockView:refreshFromBoard() -- 115
	expect( -- 116
		lockView:isLockedAt(lockBoard:flatIndex(0, 0)), -- 116
		"封锁格应在视图中标记为锁定" -- 116
	) -- 116
	expect( -- 117
		not lockView:isLockedAt(lockBoard:flatIndex(1, 0)), -- 117
		"普通方块不应被标记为锁定" -- 117
	) -- 117
	lockView:press(cellCenterPointFromFlat(lockBoard:flatIndex(0, 0))) -- 118
	expect( -- 119
		lockView.chainLength == 0, -- 119
		"封锁格不应能作为连线起点，实际 " .. tostring(lockView.chainLength) -- 119
	) -- 119
	lockView:release(cellCenterPointFromFlat(lockBoard:flatIndex(0, 0))) -- 120
	expect( -- 121
		lockView:takePendingResult() == nil, -- 121
		"从封锁格起手不应产出连线结果" -- 121
	) -- 121
	lockView:press(cellCenterPointFromFlat(lockBoard:flatIndex(1, 0))) -- 122
	lockView:move(cellCenterPointFromFlat(lockBoard:flatIndex(0, 0))) -- 123
	expect( -- 124
		lockView.chainLength == 1, -- 124
		"封锁格不应可途经，实际 " .. tostring(lockView.chainLength) -- 124
	) -- 124
	lockView:release(cellCenterPointFromFlat(lockBoard:flatIndex(0, 0))) -- 125
	expect( -- 126
		lockView:takePendingResult() == nil, -- 126
		"仅 1 格连线不应产出结果" -- 126
	) -- 126
	lockView:refreshFromBoard() -- 127
	expect( -- 128
		lockView:isLockedAt(lockBoard:flatIndex(0, 0)), -- 128
		"刷新棋盘后封锁格应仍为锁定表现" -- 128
	) -- 128
	local head = #failures == 0 and "passed" or "failed" -- 130
	local lines = {head} -- 131
	lines[#lines + 1] = ((("交互检查 " .. tostring(checks)) .. " 项，失败 ") .. tostring(#failures)) .. " 项" -- 132
	for ____, failure in ipairs(failures) do -- 133
		lines[#lines + 1] = " - " .. failure -- 134
	end -- 134
	return table.concat(lines, "\n") -- 136
end -- 24
--- 运行时观测：用真实触点坐标注入连线，并把效果交给 Combat 结算；
-- 最后强制制造“不可执行棋盘”，验证重排惩罚与视图刷新集成。
local function runRuntimeChecks() -- 143
	local failures = {} -- 144
	local checks = 0 -- 145
	local function expect(condition, message) -- 146
		checks = checks + 1 -- 147
		if not condition and #failures < 12 then -- 147
			failures[#failures + 1] = message -- 149
		end -- 149
	end -- 146
	local board = __TS__New(Board) -- 153
	local view = __TS__New(BoardView, board) -- 154
	view.root:addTo(Director.entry) -- 155
	local combat = __TS__New(Combat, board) -- 156
	local operations = 0 -- 158
	local resolved = 0 -- 159
	local rejected = 0 -- 160
	local fullFails = 0 -- 161
	local autoResets = 0 -- 162
	local enemyHpStart = combat.enemy.hp -- 163
	do -- 163
		local i = 0 -- 165
		while i < 40 do -- 165
			do -- 165
				local chain = findPlayableChain( -- 166
					board, -- 166
					Config.MinChainLength, -- 166
					3 + math.floor(math.random() * 4) -- 166
				) -- 166
				if #chain == 0 then -- 166
					goto __continue22 -- 168
				end -- 168
				view:press(cellCenterPointFromFlat(chain[1])) -- 170
				do -- 170
					local k = 1 -- 171
					while k < #chain do -- 171
						view:move(cellCenterPointFromFlat(chain[k + 1])) -- 172
						k = k + 1 -- 171
					end -- 171
				end -- 171
				view:release(cellCenterPointFromFlat(chain[#chain])) -- 174
				operations = operations + 1 -- 175
				local result = view:takePendingResult() -- 176
				if result == nil then -- 176
					rejected = rejected + 1 -- 178
					goto __continue22 -- 179
				end -- 179
				resolved = resolved + 1 -- 181
				local cellCol = result.cells[1] % board.columns -- 182
				local cellRow = math.floor(result.cells[1] / board.columns) -- 183
				local index = board:cellIndex(cellCol, cellRow) -- 184
				if index >= 0 then -- 184
					combat:applySpecs(resolveEffects( -- 186
						BlockDefs:at(index).rules, -- 186
						result.chainLength -- 186
					)) -- 186
				end -- 186
				board:applyChain(result.cells) -- 188
				view:refreshFromBoard() -- 189
				local notice = combat:ensureBoardPlayable() -- 190
				if notice ~= nil then -- 190
					autoResets = autoResets + 1 -- 192
					view:refreshFromBoard() -- 193
				end -- 193
				if not board:isFull() then -- 193
					fullFails = fullFails + 1 -- 196
				end -- 196
			end -- 196
			::__continue22:: -- 196
			i = i + 1 -- 165
		end -- 165
	end -- 165
	expect( -- 200
		operations >= 35, -- 200
		"运行时注入操作次数应 ≥ 35，实际 " .. tostring(operations) -- 200
	) -- 200
	expect( -- 201
		resolved >= 35, -- 201
		"经真实触点链路解析的连线应 ≥ 35，实际 " .. tostring(resolved) -- 201
	) -- 201
	expect(resolved + rejected == operations, "解析与被拒次数之和应等于操作次数") -- 202
	expect( -- 203
		fullFails == 0, -- 203
		("连续消除后出现非满格：" .. tostring(fullFails)) .. " 次" -- 203
	) -- 203
	expect( -- 204
		combat.player.mana > 0, -- 204
		"连续消除后魔力应大于 0，实际 " .. tostring(combat.player.mana) -- 204
	) -- 204
	expect( -- 205
		combat.enemy.hp < enemyHpStart, -- 205
		(("连续消除后敌人生命应下降：" .. tostring(enemyHpStart)) .. " → ") .. tostring(combat.enemy.hp) -- 205
	) -- 205
	expect( -- 206
		board.deadlockWarningCount == 0, -- 206
		("补充后出现无解棋盘：" .. tostring(board.deadlockWarningCount)) .. " 次" -- 206
	) -- 206
	local manaBeforePenalty = combat.player.mana -- 209
	do -- 209
		local row = 0 -- 210
		while row < board.rows do -- 210
			do -- 210
				local col = 0 -- 211
				while col < board.columns do -- 211
					board:setCell(col, row, (col + row) % 2) -- 212
					col = col + 1 -- 211
				end -- 211
			end -- 211
			row = row + 1 -- 210
		end -- 210
	end -- 210
	expect( -- 215
		not board:isPlayable(), -- 215
		"强制制造的棋盘应不可执行" -- 215
	) -- 215
	local hpBeforePenalty = combat.player.hp -- 216
	local notice = combat:ensureBoardPlayable() -- 217
	expect(notice ~= nil, "不可执行时应返回提示文本") -- 218
	expect( -- 219
		combat.boardResetCount == 1, -- 219
		"应记录一次棋盘重排，实际 " .. tostring(combat.boardResetCount) -- 219
	) -- 219
	expect( -- 220
		combat.player.hp == hpBeforePenalty - Config.BoardResetPenalty, -- 220
		(("重排惩罚应扣除 " .. tostring(Config.BoardResetPenalty)) .. " 点生命，实际 ") .. tostring(hpBeforePenalty - combat.player.hp) -- 220
	) -- 220
	expect( -- 221
		board:isFull() and board:isPlayable(), -- 221
		"重排后棋盘应满格且可执行" -- 221
	) -- 221
	expect(combat.player.mana == manaBeforePenalty, "重排惩罚不应扣魔力") -- 222
	view:refreshFromBoard() -- 225
	local afterResetChain = findPlayableChain(board, Config.MinChainLength, 4) -- 226
	view:press(cellCenterPointFromFlat(afterResetChain[1])) -- 227
	if #afterResetChain > 1 then -- 227
		view:move(cellCenterPointFromFlat(afterResetChain[2])) -- 229
	end -- 229
	view:release(cellCenterPointFromFlat(afterResetChain[#afterResetChain])) -- 231
	expect( -- 232
		view:takePendingResult() ~= nil, -- 232
		"重排后仍应能通过触点产出连线结果" -- 232
	) -- 232
	combat.player.mana = 60 -- 235
	local shuffleResult = combat:useSkill(Skills.Shuffle) -- 236
	expect(shuffleResult.ok, "魔力足够时重排技能应成功：" .. shuffleResult.message) -- 237
	expect( -- 238
		combat.player.mana == 40, -- 238
		"重排技能应扣 20 魔力，实际 " .. tostring(combat.player.mana) -- 238
	) -- 238
	expect( -- 239
		board:isFull() and board:isPlayable(), -- 239
		"重排技能后棋盘应满格且可执行" -- 239
	) -- 239
	view:refreshFromBoard() -- 240
	view:skillCast({}) -- 243
	expect(view.isCasting, "技能扫光应进入播放状态") -- 244
	view:update(1.2) -- 245
	expect(not view.isCasting, "技能扫光应在时长结束后自动停止") -- 246
	view:flashCleared({ -- 249
		board:flatIndex(0, 0), -- 249
		board:flatIndex(1, 0) -- 249
	}) -- 249
	expect(view.isFlashing, "消除爆点应进入播放状态") -- 250
	view:update(1.2) -- 251
	expect(not view.isFlashing, "消除爆点应在时长结束后自动停止") -- 252
	view:refreshFromBoard() -- 253
	local fallBoard = __TS__New(Board) -- 256
	local fallChain = findPlayableChain(fallBoard, Config.MinChainLength, 5) -- 257
	expect(#fallChain >= Config.MinChainLength, "掉落夹具应能取到一条可消除连线") -- 258
	fallBoard:applyChain(fallChain) -- 259
	expect( -- 260
		#fallBoard.collapseMoves % 2 == 0 and #fallBoard.collapseMoves > 0, -- 260
		"塌落应记录成对移动轨迹，实际 " .. tostring(#fallBoard.collapseMoves) -- 260
	) -- 260
	expect(#fallBoard.collapseSpawns > 0, "塌落应记录腾空格子供落下动画使用") -- 261
	view:animateFall( -- 262
		{ -- 262
			board:flatIndex(0, 6), -- 262
			board:flatIndex(0, 0) -- 262
		}, -- 262
		{board:flatIndex(0, 6)} -- 262
	) -- 262
	expect(view.isFalling, "掉落动画应进入播放状态") -- 263
	view:update(0.05) -- 264
	local midOffset = view:fallOffset(board:flatIndex(0, 0)) -- 265
	expect( -- 266
		math.abs(midOffset.y) > 1, -- 266
		"掉落动画中途应产生可见位移，实际 " .. tostring(midOffset.y) -- 266
	) -- 266
	view:update(1.2) -- 267
	expect(not view.isFalling, "掉落动画应在时长结束后自动停止并复位位置") -- 268
	local endOffset = view:fallOffset(board:flatIndex(0, 0)) -- 269
	expect( -- 270
		math.abs(endOffset.x) < 0.01 and math.abs(endOffset.y) < 0.01, -- 270
		"掉落动画结束后方块应精确归位到格中心" -- 270
	) -- 270
	local lockedPlaced = board:blockCells(Config.EliteHeavyBlockCells) -- 273
	expect( -- 274
		lockedPlaced == Config.EliteHeavyBlockCells, -- 274
		(("封锁 " .. tostring(Config.EliteHeavyBlockCells)) .. " 格应全部成功，实际 ") .. tostring(lockedPlaced) -- 274
	) -- 274
	expect( -- 275
		board:isFull() and board:isPlayable(), -- 275
		"封锁后棋盘应仍满格且可执行" -- 275
	) -- 275
	view:refreshFromBoard() -- 276
	local lockedFlats = {} -- 277
	do -- 277
		local flat = 0 -- 278
		while flat < board.columns * board.rows do -- 278
			if view:isLockedAt(flat) then -- 278
				lockedFlats[#lockedFlats + 1] = flat -- 280
			end -- 280
			flat = flat + 1 -- 278
		end -- 278
	end -- 278
	expect( -- 283
		#lockedFlats == lockedPlaced, -- 283
		(("视图中的锁定格数应与棋盘一致，实际 " .. tostring(#lockedFlats)) .. "/") .. tostring(lockedPlaced) -- 283
	) -- 283
	local lockedFlat = lockedFlats[1] -- 284
	view:press(cellCenterPointFromFlat(lockedFlat)) -- 285
	expect( -- 286
		view.chainLength == 0, -- 286
		"封锁格不应能作为连线起点，实际 " .. tostring(view.chainLength) -- 286
	) -- 286
	view:release(cellCenterPointFromFlat(lockedFlat)) -- 287
	expect( -- 288
		view:takePendingResult() == nil, -- 288
		"从封锁格起手不应产出连线结果" -- 288
	) -- 288
	local lockedCol = lockedFlat % board.columns -- 289
	local lockedRow = math.floor(lockedFlat / board.columns) -- 290
	local nearFlat = -1 -- 292
	local deltaCols = {-1, 1, 0, 0} -- 293
	local deltaRows = {0, 0, -1, 1} -- 294
	do -- 294
		local i = 0 -- 295
		while i < #deltaCols do -- 295
			do -- 295
				local col = lockedCol + deltaCols[i + 1] -- 296
				local row = lockedRow + deltaRows[i + 1] -- 297
				if col < 0 or col >= board.columns or row < 0 or row >= board.rows then -- 297
					goto __continue39 -- 299
				end -- 299
				if BlockDefs:isPlaceable(board:cellIndex(col, row)) then -- 299
					nearFlat = board:flatIndex(col, row) -- 302
					break -- 303
				end -- 303
			end -- 303
			::__continue39:: -- 303
			i = i + 1 -- 295
		end -- 295
	end -- 295
	expect(nearFlat >= 0, "封锁格应至少存在一个非封锁邻格") -- 306
	view:press(cellCenterPointFromFlat(nearFlat)) -- 307
	expect( -- 308
		view.chainLength == 1, -- 308
		"非封锁邻格起手应形成 1 长连线，实际 " .. tostring(view.chainLength) -- 308
	) -- 308
	view:move(cellCenterPointFromFlat(lockedFlat)) -- 309
	expect( -- 310
		view.chainLength == 1, -- 310
		"封锁格不应可途经，实际 " .. tostring(view.chainLength) -- 310
	) -- 310
	view:release(cellCenterPointFromFlat(lockedFlat)) -- 311
	view:takePendingResult() -- 312
	local largest = board:largestGroupCells() -- 313
	local largestLocked = 0 -- 314
	for ____, flat in ipairs(largest) do -- 315
		local col = flat % board.columns -- 316
		local row = math.floor(flat / board.columns) -- 317
		if not BlockDefs:isPlaceable(board:cellIndex(col, row)) then -- 317
			largestLocked = largestLocked + 1 -- 319
		end -- 319
	end -- 319
	expect( -- 322
		largestLocked == 0, -- 322
		"最大连通块不应包含封锁格，实际 " .. tostring(largestLocked) -- 322
	) -- 322
	expect( -- 325
		board:lockedCount() == #lockedFlats, -- 325
		"封锁计数应与棋盘一致，实际 " .. tostring(board:lockedCount()) -- 325
	) -- 325
	local lockTurnsNow = 0 -- 326
	for ____, flat in ipairs(lockedFlats) do -- 327
		if board:lockTurnsAt(flat) > lockTurnsNow then -- 327
			lockTurnsNow = board:lockTurnsAt(flat) -- 329
		end -- 329
	end -- 329
	expect( -- 332
		lockTurnsNow == Config.LockDurationActions, -- 332
		(("封锁格应记录 " .. tostring(Config.LockDurationActions)) .. " 次敌人行动计时，实际 ") .. tostring(lockTurnsNow) -- 332
	) -- 332
	view:refreshFromBoard() -- 333
	expect( -- 334
		view:lockTurnsLabelAt(lockedFlat) == "" .. tostring(Config.LockDurationActions), -- 334
		((("封锁格应显示剩余 " .. tostring(Config.LockDurationActions)) .. " 次敌人行动，实际「") .. view:lockTurnsLabelAt(lockedFlat)) .. "」" -- 334
	) -- 334
	local badgeStart = view:lockTurnsLabelAt(lockedFlat) -- 335
	board:expireLocks() -- 336
	expect( -- 337
		board:lockedCount() == #lockedFlats, -- 337
		"未到期时封锁不应解除，实际剩余 " .. tostring(board:lockedCount()) -- 337
	) -- 337
	view:refreshFromBoard() -- 338
	expect( -- 339
		view:lockTurnsLabelAt(lockedFlat) == "" .. tostring(Config.LockDurationActions - 1), -- 339
		("封锁剩余次数应随敌人行动递减显示，实际「" .. view:lockTurnsLabelAt(lockedFlat)) .. "」" -- 339
	) -- 339
	local badgeAfterOne = view:lockTurnsLabelAt(lockedFlat) -- 340
	do -- 340
		local i = 1 -- 341
		while i < Config.LockDurationActions do -- 341
			board:expireLocks() -- 342
			i = i + 1 -- 341
		end -- 341
	end -- 341
	expect( -- 344
		board:lockedCount() == 0, -- 344
		"到期后封锁应全部自动恢复，实际剩余 " .. tostring(board:lockedCount()) -- 344
	) -- 344
	expect( -- 345
		board:isFull() and board:isPlayable(), -- 345
		"封锁恢复后棋盘应仍满格且可执行" -- 345
	) -- 345
	view:refreshFromBoard() -- 346
	local stillLocked = 0 -- 347
	do -- 347
		local flat = 0 -- 348
		while flat < board.columns * board.rows do -- 348
			if view:isLockedAt(flat) then -- 348
				stillLocked = stillLocked + 1 -- 350
			end -- 350
			flat = flat + 1 -- 348
		end -- 348
	end -- 348
	expect( -- 353
		stillLocked == 0, -- 353
		"封锁恢复后视图不应再标记锁定，实际 " .. tostring(stillLocked) -- 353
	) -- 353
	expect( -- 354
		view:lockTurnsLabelAt(lockedFlat) == "", -- 354
		("封锁恢复后不应再显示剩余次数角标，实际「" .. view:lockTurnsLabelAt(lockedFlat)) .. "」" -- 354
	) -- 354
	local badgeAfterExpire = view:lockTurnsLabelAt(lockedFlat) -- 355
	view:refreshFromBoard() -- 356
	local head = #failures == 0 and "passed" or "failed" -- 358
	local lines = {head} -- 359
	lines[#lines + 1] = ((((((((("运行时操作 " .. tostring(operations)) .. " 次，解析连线 ") .. tostring(resolved)) .. " 次，低于下限被拒 ") .. tostring(rejected)) .. " 次，自动兑底 ") .. tostring(autoResets)) .. " 次，检查 ") .. tostring(checks)) .. " 项" -- 360
	lines[#lines + 1] = ((((((((("M5 封锁角标：封锁 " .. tostring(#lockedFlats)) .. " 格，剩余次数「") .. badgeStart) .. "」→「") .. badgeAfterOne) .. "」→到期恢复后「") .. badgeAfterExpire) .. "」；到期后视图锁定格 ") .. tostring(stillLocked)) .. " 个" -- 361
	local sizes = {} -- 362
	for ____, size in ipairs(board:maxGroupSizes()) do -- 363
		sizes[#sizes + 1] = "" .. tostring(size) -- 364
	end -- 364
	lines[#lines + 1] = ((((((((((((("棋盘：满格=" .. tostring(board:isFull())) .. " 可执行=") .. tostring(board:isPlayable())) .. " 各类型最大连通块 ") .. table.concat(sizes, ",")) .. "；玩家 HP=") .. tostring(combat.player.hp)) .. " 魔力=") .. tostring(combat.player.mana)) .. " 敌人 HP=") .. tostring(combat.enemy.hp)) .. "（起始 ") .. tostring(enemyHpStart)) .. "）" -- 366
	lines[#lines + 1] = (((((((("已消除=" .. tostring(board.clearedTotal)) .. " 连线次数=") .. tostring(board.chainsTotal)) .. " 无解告警=") .. tostring(board.deadlockWarningCount)) .. " 强制修复=") .. tostring(board.forcedRepairs)) .. " 被动重排=") .. tostring(combat.boardResetCount) -- 367
	for ____, failure in ipairs(failures) do -- 368
		lines[#lines + 1] = " - " .. failure -- 369
	end -- 369
	return table.concat(lines, "\n") -- 371
end -- 143
--- 主循环自检：直接驱动 Game + Hud 的完整结算路径（等价于玩家每次松手），
-- 用于覆盖“真实输入接入后才会走到”的代码，而不只是底层 Board/Combat。
local function runGameLoopChecks() -- 378
	local failures = {} -- 379
	local checks = 0 -- 380
	local function expect(condition, message) -- 381
		checks = checks + 1 -- 382
		if not condition and #failures < 12 then -- 382
			failures[#failures + 1] = message -- 384
		end -- 384
	end -- 381
	local scene = Node() -- 388
	scene:addTo(Director.entry) -- 389
	local game = __TS__New(Game, scene) -- 390
	local injected = 0 -- 392
	do -- 392
		local i = 0 -- 393
		while i < 40 do -- 393
			do -- 393
				local chain = findPlayableChain(game.board, Config.MinChainLength, 4) -- 394
				if #chain == 0 then -- 394
					goto __continue61 -- 396
				end -- 396
				game:submitChain(chain) -- 398
				injected = injected + 1 -- 399
				expect( -- 400
					game.board:isFull(), -- 400
					("第 " .. tostring(i)) .. " 次结算后棋盘非满格" -- 400
				) -- 400
				expect( -- 401
					game.board:isPlayable(), -- 401
					("第 " .. tostring(i)) .. " 次结算后棋盘不可执行" -- 401
				) -- 401
			end -- 401
			::__continue61:: -- 401
			i = i + 1 -- 393
		end -- 393
	end -- 393
	expect( -- 404
		injected >= 35, -- 404
		"注入结算次数应 ≥ 35，实际 " .. tostring(injected) -- 404
	) -- 404
	expect( -- 405
		game.combat.enemy.hp >= 0, -- 405
		"敌人生命不应为负，实际 " .. tostring(game.combat.enemy.hp) -- 405
	) -- 405
	expect( -- 406
		game.combat.player.hp >= 0, -- 406
		"玩家生命不应为负，实际 " .. tostring(game.combat.player.hp) -- 406
	) -- 406
	expect(game.combat.stageNumber >= 1 and game.combat.waveNumber >= 1, "关卡/波次状态应有效") -- 407
	expect( -- 408
		game.combat.player.mana >= 0 and game.combat.player.mana <= Config.MaxMana, -- 408
		("魔力应在 [0," .. tostring(Config.MaxMana)) .. "] 内" -- 408
	) -- 408
	game:toggleMode() -- 411
	expect(game.combat.isRealtime, "切换后应处于实时模式") -- 412
	expect(game.settings.mode == "realtime", "设置对象应记录为实时模式") -- 413
	local realtimeEnemyHp = game.combat.enemy.maxHp -- 414
	game:toggleMode() -- 415
	expect(not game.combat.isRealtime, "再次切换应回到回合制") -- 416
	expect(game.settings.mode == "turnBased", "设置对象应记录为回合制") -- 417
	local beforeDifficulty = game.combat.enemy.maxHp -- 418
	game:cycleDifficulty() -- 419
	expect( -- 420
		game.combat.enemy.maxHp ~= beforeDifficulty or game.settings.difficulty ~= "standard", -- 420
		(("切换难度后应刷新或记录难度，实际 HP " .. tostring(game.combat.enemy.maxHp)) .. "/") .. tostring(beforeDifficulty) -- 420
	) -- 420
	game:toggleHint() -- 421
	expect(not game.settings.showHint, "提示开关应可关闭") -- 422
	game:toggleHint() -- 423
	expect(game.settings.showHint, "提示开关应可重新打开") -- 424
	expect(game.settings.saved, "设置应已成功写入存档") -- 425
	expect(realtimeEnemyHp > 0, "实时模式下敌人最大生命应为正数") -- 426
	local head = #failures == 0 and "passed" or "failed" -- 428
	local lines = {head} -- 429
	lines[#lines + 1] = ((((("主循环检查 " .. tostring(checks)) .. " 项，失败 ") .. tostring(#failures)) .. " 项；注入结算 ") .. tostring(injected)) .. " 次" -- 430
	lines[#lines + 1] = (((((((((((((("状态：第 " .. tostring(game.combat.stageNumber)) .. " 关第 ") .. tostring(game.combat.waveNumber)) .. "/") .. tostring(game.combat.waveCount)) .. " 波，玩家 HP=") .. tostring(game.combat.player.hp)) .. " 魔力=") .. tostring(game.combat.player.mana)) .. "，敌人 HP=") .. tostring(game.combat.enemy.hp)) .. "/") .. tostring(game.combat.enemy.maxHp)) .. "，被动重排=") .. tostring(game.combat.boardResetCount) -- 431
	for ____, failure in ipairs(failures) do -- 432
		lines[#lines + 1] = " - " .. failure -- 433
	end -- 433
	return table.concat(lines, "\n") -- 435
end -- 378
--- 诊断信息：不参与 pass/fail 判定。
local function runDiagnostics() -- 439
	local lines = {} -- 440
	lines[#lines + 1] = (((((("Config：MinChainLength=" .. tostring(Config.MinChainLength)) .. " MaxGroupSize=") .. tostring(Config.MaxGroupSize)) .. " MaxMana=") .. tostring(Config.MaxMana)) .. " 技能数=") .. tostring(Skills:count()) -- 441
	local fresh = __TS__New(Board) -- 442
	local sizes = {} -- 443
	for ____, size in ipairs(fresh:maxGroupSizes()) do -- 444
		sizes[#sizes + 1] = "" .. tostring(size) -- 445
	end -- 445
	lines[#lines + 1] = (((("新棋盘各类型最大连通块 " .. table.concat(sizes, ",")) .. "；满格=") .. tostring(fresh:isFull())) .. " 可执行=") .. tostring(fresh:isPlayable()) -- 447
	local peak = 0 -- 448
	local boardsWithThree = 0 -- 449
	local playableCount = 0 -- 450
	do -- 450
		local i = 0 -- 451
		while i < 20 do -- 451
			local board = __TS__New(Board) -- 452
			local maxSize = 0 -- 453
			for ____, size in ipairs(board:maxGroupSizes()) do -- 454
				if size > maxSize then -- 454
					maxSize = size -- 456
				end -- 456
			end -- 456
			if maxSize > peak then -- 456
				peak = maxSize -- 460
			end -- 460
			if maxSize >= 3 then -- 460
				boardsWithThree = boardsWithThree + 1 -- 463
			end -- 463
			if board:isPlayable() then -- 463
				playableCount = playableCount + 1 -- 466
			end -- 466
			i = i + 1 -- 451
		end -- 451
	end -- 451
	lines[#lines + 1] = ((((("20 个新棋盘：最大连通块峰值 " .. tostring(peak)) .. "，含 ≥3 连的棋盘 ") .. tostring(boardsWithThree)) .. "/20，可执行 ") .. tostring(playableCount)) .. "/20" -- 469
	lines[#lines + 1] = "新棋盘字形图（上到下 = row6 → row0）:" -- 470
	lines[#lines + 1] = fresh:toText() -- 471
	return table.concat(lines, "\n") -- 472
end -- 439
local resultDir = Path(Content.searchPaths[1], ".agent", "test-results") -- 475
if not Content:exist(resultDir) then -- 475
	Content:mkdir(resultDir) -- 477
end -- 477
local node = Node() -- 480
node:addTo(Director.entry) -- 481
local probe = Node() -- 484
probe.size = Size(200, 100) -- 485
probe.anchor = Vec2(0.5, 0.5) -- 486
probe.position = Vec2(0, 0) -- 487
probe:addTo(Director.entry) -- 488
local probeOrigin = probe:convertToWorldSpace(Vec2(0, 0)) -- 489
local reported = false -- 491
node:schedule(function(_dt) -- 492
	if reported then -- 492
		return true -- 494
	end -- 494
	reported = true -- 496
	local logic = runTests() -- 497
	local view = runViewChecks() -- 498
	local runtime = runRuntimeChecks() -- 499
	local loop = runGameLoopChecks() -- 500
	local ok = (string.find(logic, "failed", nil, true) or 0) - 1 ~= 0 and (string.find(view, "failed", nil, true) or 0) - 1 ~= 0 and (string.find(runtime, "failed", nil, true) or 0) - 1 ~= 0 and (string.find(loop, "failed", nil, true) or 0) - 1 ~= 0 -- 501
	local lines = {ok and "passed" or "failed"} -- 502
	lines[#lines + 1] = ("runTime=" .. tostring(App.runningTime)) .. "（用于区分旧报告文件）" -- 503
	lines[#lines + 1] = "--- 逻辑自检（game/Tests.ts） ---"
	lines[#lines + 1] = logic -- 505
	lines[#lines + 1] = "--- 视图交互自检（触点→格子→连线→效果三元组） ---"
	lines[#lines + 1] = view -- 507
	lines[#lines + 1] = "--- 运行时链路观测（含魔力/伤害/棋盘兑底） ---"
	lines[#lines + 1] = runtime -- 509
	lines[#lines + 1] = "--- 主循环自检（Game + Hud 完整结算路径） ---"
	lines[#lines + 1] = loop -- 511
	lines[#lines + 1] = "--- 坐标原点探针 ---"
	lines[#lines + 1] = ((("localOrigin=(" .. tostring(probeOrigin.x)) .. ",") .. tostring(probeOrigin.y)) .. ")；(-100,-50) 表示子节点原点在矩形左下角" -- 513
	lines[#lines + 1] = "--- 诊断（不参与判定） ---"
	lines[#lines + 1] = runDiagnostics() -- 515
	Content:save( -- 516
		Path(resultDir, "m3.txt"), -- 516
		table.concat(lines, "\n") -- 516
	) -- 516
	return true -- 517
end) -- 492
return ____exports -- 492
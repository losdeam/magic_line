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
local ____Combat = require("game.Combat") -- 9
local Combat = ____Combat.Combat -- 9
local ____Config = require("game.Config") -- 10
local Config = ____Config.Config -- 10
local ____Effects = require("game.Effects") -- 11
local formatEffects = ____Effects.formatEffects -- 11
local resolveEffects = ____Effects.resolveEffects -- 11
local ____Game = require("game.Game") -- 12
local Game = ____Game.Game -- 12
local ____Skills = require("game.Skills") -- 13
local Skills = ____Skills.Skills -- 13
local ____Tests = require("game.Tests") -- 14
local findPlayableChain = ____Tests.findPlayableChain -- 14
local runTests = ____Tests.runTests -- 14
local function cellCenterPointFromFlat(flat) -- 16
	local col = flat % Config.Columns -- 17
	local row = math.floor(flat / Config.Columns) -- 18
	return Vec2((col + 0.5) * Config.CellSize, (row + 0.5) * Config.CellSize) -- 19
end -- 16
--- 视图交互自检：用确定性图案验证“触点 → 格子 → 连线 → 效果三元组”全链路。
local function runViewChecks() -- 23
	local failures = {} -- 24
	local checks = 0 -- 25
	local function expect(condition, message) -- 26
		checks = checks + 1 -- 27
		if not condition and #failures < 12 then -- 27
			failures[#failures + 1] = message -- 29
		end -- 29
	end -- 26
	local physical = BlockDefs:indexOf(BlockDefs.Physical) -- 33
	local magic = BlockDefs:indexOf(BlockDefs.Magic) -- 34
	local status = BlockDefs:indexOf(BlockDefs.Status) -- 35
	local heal = BlockDefs:indexOf(BlockDefs.Heal) -- 36
	expect(physical >= 0 and magic >= 0 and status >= 0 and heal >= 0, "注册表缺少基础方块类型") -- 37
	local board = __TS__New(Board) -- 40
	local pattern = { -- 41
		physical, -- 41
		magic, -- 41
		status, -- 41
		heal, -- 41
		physical, -- 41
		magic, -- 41
		status -- 41
	} -- 41
	do -- 41
		local row = 0 -- 42
		while row < board.rows do -- 42
			do -- 42
				local col = 0 -- 43
				while col < board.columns do -- 43
					board:setCell(col, row, pattern[row + 1]) -- 44
					col = col + 1 -- 43
				end -- 43
			end -- 43
			row = row + 1 -- 42
		end -- 42
	end -- 42
	local view = __TS__New(BoardView, board) -- 48
	view.root:addTo(Director.entry) -- 49
	view:press(cellCenterPointFromFlat(board:flatIndex(0, 0))) -- 51
	expect( -- 52
		view.chainLength == 1, -- 52
		"按下后连线长度应为 1，实际 " .. tostring(view.chainLength) -- 52
	) -- 52
	expect( -- 53
		view:selectedCount() == 1, -- 53
		"按下后高亮选中数应为 1，实际 " .. tostring(view:selectedCount()) -- 53
	) -- 53
	view:release(cellCenterPointFromFlat(board:flatIndex(0, 0))) -- 56
	expect( -- 57
		view:takePendingResult() == nil, -- 57
		"单格连线不应产出结果" -- 57
	) -- 57
	view:press(cellCenterPointFromFlat(board:flatIndex(0, 0))) -- 59
	view:move(cellCenterPointFromFlat(board:flatIndex(1, 0))) -- 60
	view:move(cellCenterPointFromFlat(board:flatIndex(2, 0))) -- 61
	view:move(cellCenterPointFromFlat(board:flatIndex(3, 0))) -- 62
	expect( -- 63
		view.chainLength == 4, -- 63
		"滑过 4 格同色后连线长度应为 4，实际 " .. tostring(view.chainLength) -- 63
	) -- 63
	view:move(cellCenterPointFromFlat(board:flatIndex(3, 1))) -- 65
	expect( -- 66
		view.chainLength == 4, -- 66
		"跨类型滑入不应增加连线，实际 " .. tostring(view.chainLength) -- 66
	) -- 66
	view:move(cellCenterPointFromFlat(board:flatIndex(6, 6))) -- 68
	expect( -- 69
		view.chainLength == 4, -- 69
		"非相邻格不应加入连线，实际 " .. tostring(view.chainLength) -- 69
	) -- 69
	view:move(cellCenterPointFromFlat(board:flatIndex(2, 0))) -- 71
	expect( -- 72
		view.chainLength == 3, -- 72
		"回退一格后连线长度应为 3，实际 " .. tostring(view.chainLength) -- 72
	) -- 72
	view:release(cellCenterPointFromFlat(board:flatIndex(3, 0))) -- 74
	local result = view:takePendingResult() -- 75
	expect(result ~= nil, "松手后应产出连线结果") -- 76
	if result ~= nil then -- 76
		expect(result.blockId == BlockDefs.Physical, "连线类型应为 physical，实际 " .. result.blockId) -- 78
		expect( -- 79
			result.chainLength == 4, -- 79
			"松手时连线长度应为 4，实际 " .. tostring(result.chainLength) -- 79
		) -- 79
		local expected = resolveEffects( -- 80
			BlockDefs:at(physical).rules, -- 80
			4 -- 80
		) -- 80
		expect(#result.specs == #expected, "效果条目数应与规则解析一致") -- 81
		local first = result.specs[1] -- 82
		expect(first.kind == "physicalDamage", "物理方块应产出 physicalDamage") -- 83
		expect(first.target == "currentEnemy", "物理伤害应作用于当前敌人") -- 84
		expect( -- 85
			first.value == 16, -- 85
			"物理伤害 4+3×4 应为 16，实际 " .. tostring(first.value) -- 85
		) -- 85
		expect( -- 86
			(string.find( -- 86
				formatEffects(result.specs), -- 86
				"物理伤害 16", -- 86
				nil, -- 86
				true -- 86
			) or 0) - 1 == 0, -- 86
			"效果文本应为“物理伤害 16 …”，实际 " .. formatEffects(result.specs) -- 86
		) -- 86
	end -- 86
	view:press(cellCenterPointFromFlat(board:flatIndex(5, 0))) -- 90
	view:move(cellCenterPointFromFlat(board:flatIndex(6, 0))) -- 91
	view:release(cellCenterPointFromFlat(board:flatIndex(6, 0))) -- 92
	local shortResult = view:takePendingResult() -- 93
	expect( -- 94
		shortResult ~= nil, -- 94
		("链长 2 应产出结果（链长下限为 " .. tostring(Config.MinChainLength)) .. "）" -- 94
	) -- 94
	if shortResult ~= nil then -- 94
		expect( -- 96
			shortResult.chainLength == 2, -- 96
			"短链长度应为 2，实际 " .. tostring(shortResult.chainLength) -- 96
		) -- 96
	end -- 96
	expect( -- 98
		view:selectedCount() == 0, -- 98
		"结算后应清除全部高亮，实际 " .. tostring(view:selectedCount()) -- 98
	) -- 98
	local lockedIndex = BlockDefs:lockedIndex() -- 101
	expect(lockedIndex >= 0, "注册表应包含封锁格定义") -- 102
	local lockBoard = __TS__New(Board) -- 103
	do -- 103
		local row = 0 -- 104
		while row < lockBoard.rows do -- 104
			do -- 104
				local col = 0 -- 105
				while col < lockBoard.columns do -- 105
					lockBoard:setCell(col, row, pattern[row + 1]) -- 106
					col = col + 1 -- 105
				end -- 105
			end -- 105
			row = row + 1 -- 104
		end -- 104
	end -- 104
	lockBoard:setCell(0, 0, lockedIndex) -- 109
	local lockView = __TS__New(BoardView, lockBoard) -- 110
	lockView.root:addTo(Director.entry) -- 111
	lockView:refreshFromBoard() -- 112
	expect( -- 113
		lockView:isLockedAt(lockBoard:flatIndex(0, 0)), -- 113
		"封锁格应在视图中标记为锁定" -- 113
	) -- 113
	expect( -- 114
		not lockView:isLockedAt(lockBoard:flatIndex(1, 0)), -- 114
		"普通方块不应被标记为锁定" -- 114
	) -- 114
	lockView:press(cellCenterPointFromFlat(lockBoard:flatIndex(0, 0))) -- 115
	expect( -- 116
		lockView.chainLength == 0, -- 116
		"封锁格不应能作为连线起点，实际 " .. tostring(lockView.chainLength) -- 116
	) -- 116
	lockView:release(cellCenterPointFromFlat(lockBoard:flatIndex(0, 0))) -- 117
	expect( -- 118
		lockView:takePendingResult() == nil, -- 118
		"从封锁格起手不应产出连线结果" -- 118
	) -- 118
	lockView:press(cellCenterPointFromFlat(lockBoard:flatIndex(1, 0))) -- 119
	lockView:move(cellCenterPointFromFlat(lockBoard:flatIndex(0, 0))) -- 120
	expect( -- 121
		lockView.chainLength == 1, -- 121
		"封锁格不应可途经，实际 " .. tostring(lockView.chainLength) -- 121
	) -- 121
	lockView:release(cellCenterPointFromFlat(lockBoard:flatIndex(0, 0))) -- 122
	expect( -- 123
		lockView:takePendingResult() == nil, -- 123
		"仅 1 格连线不应产出结果" -- 123
	) -- 123
	lockView:refreshFromBoard() -- 124
	expect( -- 125
		lockView:isLockedAt(lockBoard:flatIndex(0, 0)), -- 125
		"刷新棋盘后封锁格应仍为锁定表现" -- 125
	) -- 125
	local head = #failures == 0 and "passed" or "failed" -- 127
	local lines = {head} -- 128
	lines[#lines + 1] = ((("交互检查 " .. tostring(checks)) .. " 项，失败 ") .. tostring(#failures)) .. " 项" -- 129
	for ____, failure in ipairs(failures) do -- 130
		lines[#lines + 1] = " - " .. failure -- 131
	end -- 131
	return table.concat(lines, "\n") -- 133
end -- 23
--- 运行时观测：用真实触点坐标注入连线，并把效果交给 Combat 结算；
-- 最后强制制造“不可执行棋盘”，验证重排惩罚与视图刷新集成。
local function runRuntimeChecks() -- 140
	local failures = {} -- 141
	local checks = 0 -- 142
	local function expect(condition, message) -- 143
		checks = checks + 1 -- 144
		if not condition and #failures < 12 then -- 144
			failures[#failures + 1] = message -- 146
		end -- 146
	end -- 143
	local board = __TS__New(Board) -- 150
	local view = __TS__New(BoardView, board) -- 151
	view.root:addTo(Director.entry) -- 152
	local combat = __TS__New(Combat, board) -- 153
	local operations = 0 -- 155
	local resolved = 0 -- 156
	local rejected = 0 -- 157
	local fullFails = 0 -- 158
	local autoResets = 0 -- 159
	local enemyHpStart = combat.enemy.hp -- 160
	do -- 160
		local i = 0 -- 162
		while i < 40 do -- 162
			do -- 162
				local chain = findPlayableChain( -- 163
					board, -- 163
					Config.MinChainLength, -- 163
					3 + math.floor(math.random() * 4) -- 163
				) -- 163
				if #chain == 0 then -- 163
					goto __continue22 -- 165
				end -- 165
				view:press(cellCenterPointFromFlat(chain[1])) -- 167
				do -- 167
					local k = 1 -- 168
					while k < #chain do -- 168
						view:move(cellCenterPointFromFlat(chain[k + 1])) -- 169
						k = k + 1 -- 168
					end -- 168
				end -- 168
				view:release(cellCenterPointFromFlat(chain[#chain])) -- 171
				operations = operations + 1 -- 172
				local result = view:takePendingResult() -- 173
				if result == nil then -- 173
					rejected = rejected + 1 -- 175
					goto __continue22 -- 176
				end -- 176
				resolved = resolved + 1 -- 178
				local cellCol = result.cells[1] % board.columns -- 179
				local cellRow = math.floor(result.cells[1] / board.columns) -- 180
				local index = board:cellIndex(cellCol, cellRow) -- 181
				if index >= 0 then -- 181
					combat:applySpecs(resolveEffects( -- 183
						BlockDefs:at(index).rules, -- 183
						result.chainLength -- 183
					)) -- 183
				end -- 183
				board:applyChain(result.cells) -- 185
				view:refreshFromBoard() -- 186
				local notice = combat:ensureBoardPlayable() -- 187
				if notice ~= nil then -- 187
					autoResets = autoResets + 1 -- 189
					view:refreshFromBoard() -- 190
				end -- 190
				if not board:isFull() then -- 190
					fullFails = fullFails + 1 -- 193
				end -- 193
			end -- 193
			::__continue22:: -- 193
			i = i + 1 -- 162
		end -- 162
	end -- 162
	expect( -- 197
		operations >= 35, -- 197
		"运行时注入操作次数应 ≥ 35，实际 " .. tostring(operations) -- 197
	) -- 197
	expect( -- 198
		resolved >= 35, -- 198
		"经真实触点链路解析的连线应 ≥ 35，实际 " .. tostring(resolved) -- 198
	) -- 198
	expect(resolved + rejected == operations, "解析与被拒次数之和应等于操作次数") -- 199
	expect( -- 200
		fullFails == 0, -- 200
		("连续消除后出现非满格：" .. tostring(fullFails)) .. " 次" -- 200
	) -- 200
	expect( -- 201
		combat.player.mana > 0, -- 201
		"连续消除后魔力应大于 0，实际 " .. tostring(combat.player.mana) -- 201
	) -- 201
	expect( -- 202
		combat.enemy.hp < enemyHpStart, -- 202
		(("连续消除后敌人生命应下降：" .. tostring(enemyHpStart)) .. " → ") .. tostring(combat.enemy.hp) -- 202
	) -- 202
	expect( -- 203
		board.deadlockWarningCount == 0, -- 203
		("补充后出现无解棋盘：" .. tostring(board.deadlockWarningCount)) .. " 次" -- 203
	) -- 203
	local manaBeforePenalty = combat.player.mana -- 206
	do -- 206
		local row = 0 -- 207
		while row < board.rows do -- 207
			do -- 207
				local col = 0 -- 208
				while col < board.columns do -- 208
					board:setCell(col, row, (col + row) % 2) -- 209
					col = col + 1 -- 208
				end -- 208
			end -- 208
			row = row + 1 -- 207
		end -- 207
	end -- 207
	expect( -- 212
		not board:isPlayable(), -- 212
		"强制制造的棋盘应不可执行" -- 212
	) -- 212
	local hpBeforePenalty = combat.player.hp -- 213
	local notice = combat:ensureBoardPlayable() -- 214
	expect(notice ~= nil, "不可执行时应返回提示文本") -- 215
	expect( -- 216
		combat.boardResetCount == 1, -- 216
		"应记录一次棋盘重排，实际 " .. tostring(combat.boardResetCount) -- 216
	) -- 216
	expect( -- 217
		combat.player.hp == hpBeforePenalty - Config.BoardResetPenalty, -- 217
		(("重排惩罚应扣除 " .. tostring(Config.BoardResetPenalty)) .. " 点生命，实际 ") .. tostring(hpBeforePenalty - combat.player.hp) -- 217
	) -- 217
	expect( -- 218
		board:isFull() and board:isPlayable(), -- 218
		"重排后棋盘应满格且可执行" -- 218
	) -- 218
	expect(combat.player.mana == manaBeforePenalty, "重排惩罚不应扣魔力") -- 219
	view:refreshFromBoard() -- 222
	local afterResetChain = findPlayableChain(board, Config.MinChainLength, 4) -- 223
	view:press(cellCenterPointFromFlat(afterResetChain[1])) -- 224
	if #afterResetChain > 1 then -- 224
		view:move(cellCenterPointFromFlat(afterResetChain[2])) -- 226
	end -- 226
	view:release(cellCenterPointFromFlat(afterResetChain[#afterResetChain])) -- 228
	expect( -- 229
		view:takePendingResult() ~= nil, -- 229
		"重排后仍应能通过触点产出连线结果" -- 229
	) -- 229
	combat.player.mana = 60 -- 232
	local shuffleResult = combat:useSkill(Skills.Shuffle) -- 233
	expect(shuffleResult.ok, "魔力足够时重排技能应成功：" .. shuffleResult.message) -- 234
	expect( -- 235
		combat.player.mana == 40, -- 235
		"重排技能应扣 20 魔力，实际 " .. tostring(combat.player.mana) -- 235
	) -- 235
	expect( -- 236
		board:isFull() and board:isPlayable(), -- 236
		"重排技能后棋盘应满格且可执行" -- 236
	) -- 236
	view:refreshFromBoard() -- 237
	view:skillCast({}) -- 240
	expect(view.isCasting, "技能扫光应进入播放状态") -- 241
	view:update(1.2) -- 242
	expect(not view.isCasting, "技能扫光应在时长结束后自动停止") -- 243
	view:flashCleared({ -- 246
		board:flatIndex(0, 0), -- 246
		board:flatIndex(1, 0) -- 246
	}) -- 246
	expect(view.isFlashing, "消除爆点应进入播放状态") -- 247
	view:update(1.2) -- 248
	expect(not view.isFlashing, "消除爆点应在时长结束后自动停止") -- 249
	view:refreshFromBoard() -- 250
	local fallBoard = __TS__New(Board) -- 253
	local fallChain = findPlayableChain(fallBoard, Config.MinChainLength, 5) -- 254
	expect(#fallChain >= Config.MinChainLength, "掉落夹具应能取到一条可消除连线") -- 255
	fallBoard:applyChain(fallChain) -- 256
	expect( -- 257
		#fallBoard.collapseMoves % 2 == 0 and #fallBoard.collapseMoves > 0, -- 257
		"塌落应记录成对移动轨迹，实际 " .. tostring(#fallBoard.collapseMoves) -- 257
	) -- 257
	expect(#fallBoard.collapseSpawns > 0, "塌落应记录腾空格子供落下动画使用") -- 258
	view:animateFall( -- 259
		{ -- 259
			board:flatIndex(0, 6), -- 259
			board:flatIndex(0, 0) -- 259
		}, -- 259
		{board:flatIndex(0, 6)} -- 259
	) -- 259
	expect(view.isFalling, "掉落动画应进入播放状态") -- 260
	view:update(0.05) -- 261
	local midOffset = view:fallOffset(board:flatIndex(0, 0)) -- 262
	expect( -- 263
		math.abs(midOffset.y) > 1, -- 263
		"掉落动画中途应产生可见位移，实际 " .. tostring(midOffset.y) -- 263
	) -- 263
	view:update(1.2) -- 264
	expect(not view.isFalling, "掉落动画应在时长结束后自动停止并复位位置") -- 265
	local endOffset = view:fallOffset(board:flatIndex(0, 0)) -- 266
	expect( -- 267
		math.abs(endOffset.x) < 0.01 and math.abs(endOffset.y) < 0.01, -- 267
		"掉落动画结束后方块应精确归位到格中心" -- 267
	) -- 267
	local lockedPlaced = board:blockCells(Config.EliteHeavyBlockCells) -- 270
	expect( -- 271
		lockedPlaced == Config.EliteHeavyBlockCells, -- 271
		(("封锁 " .. tostring(Config.EliteHeavyBlockCells)) .. " 格应全部成功，实际 ") .. tostring(lockedPlaced) -- 271
	) -- 271
	expect( -- 272
		board:isFull() and board:isPlayable(), -- 272
		"封锁后棋盘应仍满格且可执行" -- 272
	) -- 272
	view:refreshFromBoard() -- 273
	local lockedFlats = {} -- 274
	do -- 274
		local flat = 0 -- 275
		while flat < board.columns * board.rows do -- 275
			if view:isLockedAt(flat) then -- 275
				lockedFlats[#lockedFlats + 1] = flat -- 277
			end -- 277
			flat = flat + 1 -- 275
		end -- 275
	end -- 275
	expect( -- 280
		#lockedFlats == lockedPlaced, -- 280
		(("视图中的锁定格数应与棋盘一致，实际 " .. tostring(#lockedFlats)) .. "/") .. tostring(lockedPlaced) -- 280
	) -- 280
	local lockedFlat = lockedFlats[1] -- 281
	view:press(cellCenterPointFromFlat(lockedFlat)) -- 282
	expect( -- 283
		view.chainLength == 0, -- 283
		"封锁格不应能作为连线起点，实际 " .. tostring(view.chainLength) -- 283
	) -- 283
	view:release(cellCenterPointFromFlat(lockedFlat)) -- 284
	expect( -- 285
		view:takePendingResult() == nil, -- 285
		"从封锁格起手不应产出连线结果" -- 285
	) -- 285
	local lockedCol = lockedFlat % board.columns -- 286
	local lockedRow = math.floor(lockedFlat / board.columns) -- 287
	local nearFlat = -1 -- 289
	local deltaCols = {-1, 1, 0, 0} -- 290
	local deltaRows = {0, 0, -1, 1} -- 291
	do -- 291
		local i = 0 -- 292
		while i < #deltaCols do -- 292
			do -- 292
				local col = lockedCol + deltaCols[i + 1] -- 293
				local row = lockedRow + deltaRows[i + 1] -- 294
				if col < 0 or col >= board.columns or row < 0 or row >= board.rows then -- 294
					goto __continue39 -- 296
				end -- 296
				if BlockDefs:isPlaceable(board:cellIndex(col, row)) then -- 296
					nearFlat = board:flatIndex(col, row) -- 299
					break -- 300
				end -- 300
			end -- 300
			::__continue39:: -- 300
			i = i + 1 -- 292
		end -- 292
	end -- 292
	expect(nearFlat >= 0, "封锁格应至少存在一个非封锁邻格") -- 303
	view:press(cellCenterPointFromFlat(nearFlat)) -- 304
	expect( -- 305
		view.chainLength == 1, -- 305
		"非封锁邻格起手应形成 1 长连线，实际 " .. tostring(view.chainLength) -- 305
	) -- 305
	view:move(cellCenterPointFromFlat(lockedFlat)) -- 306
	expect( -- 307
		view.chainLength == 1, -- 307
		"封锁格不应可途经，实际 " .. tostring(view.chainLength) -- 307
	) -- 307
	view:release(cellCenterPointFromFlat(lockedFlat)) -- 308
	view:takePendingResult() -- 309
	local largest = board:largestGroupCells() -- 310
	local largestLocked = 0 -- 311
	for ____, flat in ipairs(largest) do -- 312
		local col = flat % board.columns -- 313
		local row = math.floor(flat / board.columns) -- 314
		if not BlockDefs:isPlaceable(board:cellIndex(col, row)) then -- 314
			largestLocked = largestLocked + 1 -- 316
		end -- 316
	end -- 316
	expect( -- 319
		largestLocked == 0, -- 319
		"最大连通块不应包含封锁格，实际 " .. tostring(largestLocked) -- 319
	) -- 319
	expect( -- 322
		board:lockedCount() == #lockedFlats, -- 322
		"封锁计数应与棋盘一致，实际 " .. tostring(board:lockedCount()) -- 322
	) -- 322
	local lockTurnsNow = 0 -- 323
	for ____, flat in ipairs(lockedFlats) do -- 324
		if board:lockTurnsAt(flat) > lockTurnsNow then -- 324
			lockTurnsNow = board:lockTurnsAt(flat) -- 326
		end -- 326
	end -- 326
	expect( -- 329
		lockTurnsNow == Config.LockDurationActions, -- 329
		(("封锁格应记录 " .. tostring(Config.LockDurationActions)) .. " 次敌人行动计时，实际 ") .. tostring(lockTurnsNow) -- 329
	) -- 329
	view:refreshFromBoard() -- 330
	expect( -- 331
		view:lockTurnsLabelAt(lockedFlat) == "" .. tostring(Config.LockDurationActions), -- 331
		((("封锁格应显示剩余 " .. tostring(Config.LockDurationActions)) .. " 次敌人行动，实际「") .. view:lockTurnsLabelAt(lockedFlat)) .. "」" -- 331
	) -- 331
	local badgeStart = view:lockTurnsLabelAt(lockedFlat) -- 332
	board:expireLocks() -- 333
	expect( -- 334
		board:lockedCount() == #lockedFlats, -- 334
		"未到期时封锁不应解除，实际剩余 " .. tostring(board:lockedCount()) -- 334
	) -- 334
	view:refreshFromBoard() -- 335
	expect( -- 336
		view:lockTurnsLabelAt(lockedFlat) == "" .. tostring(Config.LockDurationActions - 1), -- 336
		("封锁剩余次数应随敌人行动递减显示，实际「" .. view:lockTurnsLabelAt(lockedFlat)) .. "」" -- 336
	) -- 336
	local badgeAfterOne = view:lockTurnsLabelAt(lockedFlat) -- 337
	do -- 337
		local i = 1 -- 338
		while i < Config.LockDurationActions do -- 338
			board:expireLocks() -- 339
			i = i + 1 -- 338
		end -- 338
	end -- 338
	expect( -- 341
		board:lockedCount() == 0, -- 341
		"到期后封锁应全部自动恢复，实际剩余 " .. tostring(board:lockedCount()) -- 341
	) -- 341
	expect( -- 342
		board:isFull() and board:isPlayable(), -- 342
		"封锁恢复后棋盘应仍满格且可执行" -- 342
	) -- 342
	view:refreshFromBoard() -- 343
	local stillLocked = 0 -- 344
	do -- 344
		local flat = 0 -- 345
		while flat < board.columns * board.rows do -- 345
			if view:isLockedAt(flat) then -- 345
				stillLocked = stillLocked + 1 -- 347
			end -- 347
			flat = flat + 1 -- 345
		end -- 345
	end -- 345
	expect( -- 350
		stillLocked == 0, -- 350
		"封锁恢复后视图不应再标记锁定，实际 " .. tostring(stillLocked) -- 350
	) -- 350
	expect( -- 351
		view:lockTurnsLabelAt(lockedFlat) == "", -- 351
		("封锁恢复后不应再显示剩余次数角标，实际「" .. view:lockTurnsLabelAt(lockedFlat)) .. "」" -- 351
	) -- 351
	local badgeAfterExpire = view:lockTurnsLabelAt(lockedFlat) -- 352
	view:refreshFromBoard() -- 353
	local head = #failures == 0 and "passed" or "failed" -- 355
	local lines = {head} -- 356
	lines[#lines + 1] = ((((((((("运行时操作 " .. tostring(operations)) .. " 次，解析连线 ") .. tostring(resolved)) .. " 次，低于下限被拒 ") .. tostring(rejected)) .. " 次，自动兑底 ") .. tostring(autoResets)) .. " 次，检查 ") .. tostring(checks)) .. " 项" -- 357
	lines[#lines + 1] = ((((((((("M5 封锁角标：封锁 " .. tostring(#lockedFlats)) .. " 格，剩余次数「") .. badgeStart) .. "」→「") .. badgeAfterOne) .. "」→到期恢复后「") .. badgeAfterExpire) .. "」；到期后视图锁定格 ") .. tostring(stillLocked)) .. " 个" -- 358
	local sizes = {} -- 359
	for ____, size in ipairs(board:maxGroupSizes()) do -- 360
		sizes[#sizes + 1] = "" .. tostring(size) -- 361
	end -- 361
	lines[#lines + 1] = ((((((((((((("棋盘：满格=" .. tostring(board:isFull())) .. " 可执行=") .. tostring(board:isPlayable())) .. " 各类型最大连通块 ") .. table.concat(sizes, ",")) .. "；玩家 HP=") .. tostring(combat.player.hp)) .. " 魔力=") .. tostring(combat.player.mana)) .. " 敌人 HP=") .. tostring(combat.enemy.hp)) .. "（起始 ") .. tostring(enemyHpStart)) .. "）" -- 363
	lines[#lines + 1] = (((((((("已消除=" .. tostring(board.clearedTotal)) .. " 连线次数=") .. tostring(board.chainsTotal)) .. " 无解告警=") .. tostring(board.deadlockWarningCount)) .. " 强制修复=") .. tostring(board.forcedRepairs)) .. " 被动重排=") .. tostring(combat.boardResetCount) -- 364
	for ____, failure in ipairs(failures) do -- 365
		lines[#lines + 1] = " - " .. failure -- 366
	end -- 366
	return table.concat(lines, "\n") -- 368
end -- 140
--- 主循环自检：直接驱动 Game + Hud 的完整结算路径（等价于玩家每次松手），
-- 用于覆盖“真实输入接入后才会走到”的代码，而不只是底层 Board/Combat。
local function runGameLoopChecks() -- 375
	local failures = {} -- 376
	local checks = 0 -- 377
	local function expect(condition, message) -- 378
		checks = checks + 1 -- 379
		if not condition and #failures < 12 then -- 379
			failures[#failures + 1] = message -- 381
		end -- 381
	end -- 378
	local scene = Node() -- 385
	scene:addTo(Director.entry) -- 386
	local game = __TS__New(Game, scene) -- 387
	local injected = 0 -- 389
	do -- 389
		local i = 0 -- 390
		while i < 40 do -- 390
			do -- 390
				local chain = findPlayableChain(game.board, Config.MinChainLength, 4) -- 391
				if #chain == 0 then -- 391
					goto __continue61 -- 393
				end -- 393
				game:submitChain(chain) -- 395
				injected = injected + 1 -- 396
				expect( -- 397
					game.board:isFull(), -- 397
					("第 " .. tostring(i)) .. " 次结算后棋盘非满格" -- 397
				) -- 397
				expect( -- 398
					game.board:isPlayable(), -- 398
					("第 " .. tostring(i)) .. " 次结算后棋盘不可执行" -- 398
				) -- 398
			end -- 398
			::__continue61:: -- 398
			i = i + 1 -- 390
		end -- 390
	end -- 390
	expect( -- 401
		injected >= 35, -- 401
		"注入结算次数应 ≥ 35，实际 " .. tostring(injected) -- 401
	) -- 401
	expect( -- 402
		game.combat.enemy.hp >= 0, -- 402
		"敌人生命不应为负，实际 " .. tostring(game.combat.enemy.hp) -- 402
	) -- 402
	expect( -- 403
		game.combat.player.hp >= 0, -- 403
		"玩家生命不应为负，实际 " .. tostring(game.combat.player.hp) -- 403
	) -- 403
	expect(game.combat.stageNumber >= 1 and game.combat.waveNumber >= 1, "关卡/波次状态应有效") -- 404
	expect( -- 405
		game.combat.player.mana >= 0 and game.combat.player.mana <= Config.MaxMana, -- 405
		("魔力应在 [0," .. tostring(Config.MaxMana)) .. "] 内" -- 405
	) -- 405
	game:toggleMode() -- 408
	expect(game.combat.isRealtime, "切换后应处于实时模式") -- 409
	expect(game.settings.mode == "realtime", "设置对象应记录为实时模式") -- 410
	local realtimeEnemyHp = game.combat.enemy.maxHp -- 411
	game:toggleMode() -- 412
	expect(not game.combat.isRealtime, "再次切换应回到回合制") -- 413
	expect(game.settings.mode == "turnBased", "设置对象应记录为回合制") -- 414
	local beforeDifficulty = game.combat.enemy.maxHp -- 415
	game:cycleDifficulty() -- 416
	expect( -- 417
		game.combat.enemy.maxHp ~= beforeDifficulty or game.settings.difficulty ~= "standard", -- 417
		(("切换难度后应刷新或记录难度，实际 HP " .. tostring(game.combat.enemy.maxHp)) .. "/") .. tostring(beforeDifficulty) -- 417
	) -- 417
	game:toggleHint() -- 418
	expect(not game.settings.showHint, "提示开关应可关闭") -- 419
	game:toggleHint() -- 420
	expect(game.settings.showHint, "提示开关应可重新打开") -- 421
	expect(game.settings.saved, "设置应已成功写入存档") -- 422
	expect(realtimeEnemyHp > 0, "实时模式下敌人最大生命应为正数") -- 423
	local head = #failures == 0 and "passed" or "failed" -- 425
	local lines = {head} -- 426
	lines[#lines + 1] = ((((("主循环检查 " .. tostring(checks)) .. " 项，失败 ") .. tostring(#failures)) .. " 项；注入结算 ") .. tostring(injected)) .. " 次" -- 427
	lines[#lines + 1] = (((((((((((((("状态：第 " .. tostring(game.combat.stageNumber)) .. " 关第 ") .. tostring(game.combat.waveNumber)) .. "/") .. tostring(game.combat.waveCount)) .. " 波，玩家 HP=") .. tostring(game.combat.player.hp)) .. " 魔力=") .. tostring(game.combat.player.mana)) .. "，敌人 HP=") .. tostring(game.combat.enemy.hp)) .. "/") .. tostring(game.combat.enemy.maxHp)) .. "，被动重排=") .. tostring(game.combat.boardResetCount) -- 428
	for ____, failure in ipairs(failures) do -- 429
		lines[#lines + 1] = " - " .. failure -- 430
	end -- 430
	return table.concat(lines, "\n") -- 432
end -- 375
--- 诊断信息：不参与 pass/fail 判定。
local function runDiagnostics() -- 436
	local lines = {} -- 437
	lines[#lines + 1] = (((((("Config：MinChainLength=" .. tostring(Config.MinChainLength)) .. " MaxGroupSize=") .. tostring(Config.MaxGroupSize)) .. " MaxMana=") .. tostring(Config.MaxMana)) .. " 技能数=") .. tostring(Skills:count()) -- 438
	local fresh = __TS__New(Board) -- 439
	local sizes = {} -- 440
	for ____, size in ipairs(fresh:maxGroupSizes()) do -- 441
		sizes[#sizes + 1] = "" .. tostring(size) -- 442
	end -- 442
	lines[#lines + 1] = (((("新棋盘各类型最大连通块 " .. table.concat(sizes, ",")) .. "；满格=") .. tostring(fresh:isFull())) .. " 可执行=") .. tostring(fresh:isPlayable()) -- 444
	local peak = 0 -- 445
	local boardsWithThree = 0 -- 446
	local playableCount = 0 -- 447
	do -- 447
		local i = 0 -- 448
		while i < 20 do -- 448
			local board = __TS__New(Board) -- 449
			local maxSize = 0 -- 450
			for ____, size in ipairs(board:maxGroupSizes()) do -- 451
				if size > maxSize then -- 451
					maxSize = size -- 453
				end -- 453
			end -- 453
			if maxSize > peak then -- 453
				peak = maxSize -- 457
			end -- 457
			if maxSize >= 3 then -- 457
				boardsWithThree = boardsWithThree + 1 -- 460
			end -- 460
			if board:isPlayable() then -- 460
				playableCount = playableCount + 1 -- 463
			end -- 463
			i = i + 1 -- 448
		end -- 448
	end -- 448
	lines[#lines + 1] = ((((("20 个新棋盘：最大连通块峰值 " .. tostring(peak)) .. "，含 ≥3 连的棋盘 ") .. tostring(boardsWithThree)) .. "/20，可执行 ") .. tostring(playableCount)) .. "/20" -- 466
	lines[#lines + 1] = "新棋盘字形图（上到下 = row6 → row0）:" -- 467
	lines[#lines + 1] = fresh:toText() -- 468
	return table.concat(lines, "\n") -- 469
end -- 436
local resultDir = Path(Content.searchPaths[1], ".agent", "test-results") -- 472
if not Content:exist(resultDir) then -- 472
	Content:mkdir(resultDir) -- 474
end -- 474
local node = Node() -- 477
node:addTo(Director.entry) -- 478
local probe = Node() -- 481
probe.size = Size(200, 100) -- 482
probe.anchor = Vec2(0.5, 0.5) -- 483
probe.position = Vec2(0, 0) -- 484
probe:addTo(Director.entry) -- 485
local probeOrigin = probe:convertToWorldSpace(Vec2(0, 0)) -- 486
local reported = false -- 488
node:schedule(function(_dt) -- 489
	if reported then -- 489
		return true -- 491
	end -- 491
	reported = true -- 493
	local logic = runTests() -- 494
	local view = runViewChecks() -- 495
	local runtime = runRuntimeChecks() -- 496
	local loop = runGameLoopChecks() -- 497
	local ok = (string.find(logic, "failed", nil, true) or 0) - 1 ~= 0 and (string.find(view, "failed", nil, true) or 0) - 1 ~= 0 and (string.find(runtime, "failed", nil, true) or 0) - 1 ~= 0 and (string.find(loop, "failed", nil, true) or 0) - 1 ~= 0 -- 498
	local lines = {ok and "passed" or "failed"} -- 499
	lines[#lines + 1] = ("runTime=" .. tostring(App.runningTime)) .. "（用于区分旧报告文件）" -- 500
	lines[#lines + 1] = "--- 逻辑自检（game/Tests.ts） ---"
	lines[#lines + 1] = logic -- 502
	lines[#lines + 1] = "--- 视图交互自检（触点→格子→连线→效果三元组） ---"
	lines[#lines + 1] = view -- 504
	lines[#lines + 1] = "--- 运行时链路观测（含魔力/伤害/棋盘兑底） ---"
	lines[#lines + 1] = runtime -- 506
	lines[#lines + 1] = "--- 主循环自检（Game + Hud 完整结算路径） ---"
	lines[#lines + 1] = loop -- 508
	lines[#lines + 1] = "--- 坐标原点探针 ---"
	lines[#lines + 1] = ((("localOrigin=(" .. tostring(probeOrigin.x)) .. ",") .. tostring(probeOrigin.y)) .. ")；(-100,-50) 表示子节点原点在矩形左下角" -- 510
	lines[#lines + 1] = "--- 诊断（不参与判定） ---"
	lines[#lines + 1] = runDiagnostics() -- 512
	Content:save( -- 513
		Path(resultDir, "m3.txt"), -- 513
		table.concat(lines, "\n") -- 513
	) -- 513
	return true -- 514
end) -- 489
return ____exports -- 489
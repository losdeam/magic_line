-- [ts]: BoardView.ts
local ____lualib = require("lualib_bundle") -- 1
local __TS__Class = ____lualib.__TS__Class -- 1
local __TS__New = ____lualib.__TS__New -- 1
local __TS__SetDescriptor = ____lualib.__TS__SetDescriptor -- 1
local ____exports = {} -- 1
local ____Dora = require("Dora") -- 4
local Color = ____Dora.Color -- 4
local DrawNode = ____Dora.DrawNode -- 4
local Node = ____Dora.Node -- 4
local Size = ____Dora.Size -- 4
local Vec2 = ____Dora.Vec2 -- 4
local ____Board = require("game.Board") -- 5
local Board = ____Board.Board -- 5
local ____BlockDefs = require("game.BlockDefs") -- 6
local BlockDefs = ____BlockDefs.BlockDefs -- 6
local ____Config = require("game.Config") -- 7
local Config = ____Config.Config -- 7
local ____Effects = require("game.Effects") -- 8
local resolveEffects = ____Effects.resolveEffects -- 8
local ____BlockWidget = require("game.ui.BlockWidget") -- 9
local BlockWidget = ____BlockWidget.BlockWidget -- 9
____exports.BoardView = __TS__Class() -- 19
local BoardView = ____exports.BoardView -- 19
BoardView.name = "BoardView" -- 19
function BoardView.prototype.____constructor(self, board) -- 49
	self.widgets = {} -- 22
	self.chain = {} -- 27
	self.flashCells = {} -- 29
	self.flashTimer = 0 -- 30
	self.flashDuration = 0.22 -- 31
	self.pulseCells = {} -- 33
	self.pulseTimer = 0 -- 34
	self.pulseDuration = 0.8 -- 35
	self.fallCells = {} -- 40
	self.fallOffsetsX = {} -- 41
	self.fallOffsetsY = {} -- 42
	self.fallTimer = 0 -- 43
	self.fallDuration = 0.18 -- 44
	self.lastX = 0 -- 46
	self.lastY = 0 -- 47
	self.board = board -- 50
	local span = Config.Columns * Config.CellSize -- 51
	local root = Node() -- 52
	root.size = Size(span, span) -- 53
	root.anchor = Vec2(0.5, 0.5) -- 54
	root.touchEnabled = true -- 55
	self.root = root -- 56
	do -- 56
		local row = 0 -- 58
		while row < board.rows do -- 58
			do -- 58
				local col = 0 -- 59
				while col < board.columns do -- 59
					local index = board:cellIndex(col, row) -- 60
					local widget = __TS__New( -- 61
						BlockWidget, -- 61
						BlockDefs:at(index), -- 61
						Config.CellSize -- 61
					) -- 61
					widget:addTo(root) -- 62
					widget:setPosition( -- 63
						self:cellCenterX(col), -- 63
						self:cellCenterY(row) -- 63
					) -- 63
					local ____self_widgets_0 = self.widgets -- 63
					____self_widgets_0[#____self_widgets_0 + 1] = widget -- 64
					col = col + 1 -- 59
				end -- 59
			end -- 59
			row = row + 1 -- 58
		end -- 58
	end -- 58
	local flashLayer = DrawNode() -- 69
	flashLayer.z = 10 -- 70
	flashLayer:addTo(root) -- 71
	self.flashLayer = flashLayer -- 72
	local highlight = DrawNode() -- 74
	highlight.z = 11 -- 75
	highlight:addTo(root) -- 76
	self.highlight = highlight -- 77
	local pulseLayer = DrawNode() -- 79
	pulseLayer.z = 12 -- 80
	pulseLayer:addTo(root) -- 81
	self.pulseLayer = pulseLayer -- 82
	root:onTapBegan(function(touch) return self:press(touch.location) end) -- 84
	root:onTapMoved(function(touch) return self:move(touch.location) end) -- 85
	root:onTapEnded(function(touch) return self:release(touch.location) end) -- 86
end -- 49
function BoardView.prototype.takePendingResult(self) -- 94
	local result = self.pending -- 95
	self.pending = nil -- 96
	return result -- 97
end -- 94
function BoardView.prototype.submitChain(self, cells) -- 101
	self:endFlash() -- 102
	self.chain = {} -- 103
	for ____, cell in ipairs(cells) do -- 104
		self:appendCell(cell) -- 105
	end -- 105
	self:finish() -- 107
end -- 101
function BoardView.prototype.update(self, dt) -- 110
	self:advancePulse(dt) -- 111
	self:advanceFall(dt) -- 112
	if self.flashTimer <= 0 then -- 112
		return -- 114
	end -- 114
	self.flashTimer = self.flashTimer - dt -- 116
	if self.flashTimer <= 0 then -- 116
		self:endFlash() -- 118
		return -- 119
	end -- 119
	local alpha = math.floor(255 * (self.flashTimer / self.flashDuration)) -- 123
	local half = Config.CellSize * 0.34 -- 124
	self.flashLayer:clear() -- 125
	for ____, flat in ipairs(self.flashCells) do -- 126
		local center = self:cellCenter(flat) -- 127
		self.flashLayer:drawPolygon( -- 128
			{ -- 129
				Vec2(center.x - half, center.y - half), -- 130
				Vec2(center.x + half, center.y - half), -- 131
				Vec2(center.x + half, center.y + half), -- 132
				Vec2(center.x - half, center.y + half) -- 133
			}, -- 133
			Color(255, 255, 255, alpha) -- 135
		) -- 135
	end -- 135
end -- 110
function BoardView.prototype.skillCast(self, cells) -- 144
	self.pulseCells = {} -- 145
	if #cells == 0 then -- 145
		do -- 145
			local flat = 0 -- 147
			while flat < #self.widgets do -- 147
				local ____self_pulseCells_1 = self.pulseCells -- 147
				____self_pulseCells_1[#____self_pulseCells_1 + 1] = flat -- 148
				flat = flat + 1 -- 147
			end -- 147
		end -- 147
	else -- 147
		for ____, flat in ipairs(cells) do -- 151
			if flat >= 0 and flat < #self.widgets then -- 151
				local ____self_pulseCells_2 = self.pulseCells -- 151
				____self_pulseCells_2[#____self_pulseCells_2 + 1] = flat -- 153
			end -- 153
		end -- 153
	end -- 153
	self.pulseTimer = #self.pulseCells > 0 and self.pulseDuration or 0 -- 157
end -- 144
function BoardView.prototype.advancePulse(self, dt) -- 166
	if self.pulseTimer <= 0 then -- 166
		return -- 168
	end -- 168
	self.pulseTimer = self.pulseTimer - dt -- 170
	if self.pulseTimer <= 0 then -- 170
		self.pulseTimer = 0 -- 172
		self.pulseLayer:clear() -- 173
		return -- 174
	end -- 174
	local progress = 1 - self.pulseTimer / self.pulseDuration -- 176
	local columns = self.board.columns -- 177
	local half = Config.CellSize * 0.42 -- 178
	self.pulseLayer:clear() -- 179
	for ____, flat in ipairs(self.pulseCells) do -- 180
		do -- 180
			local col = flat % columns -- 181
			local ____local = (progress - col / columns * 0.45) / 0.45 -- 182
			if ____local <= 0 or ____local >= 1 then -- 182
				goto __continue30 -- 184
			end -- 184
			local alpha = math.floor(180 * (1 - ____local)) -- 186
			local center = self:cellCenter(flat) -- 187
			self.pulseLayer:drawPolygon( -- 188
				{ -- 189
					Vec2(center.x - half, center.y - half), -- 190
					Vec2(center.x + half, center.y - half), -- 191
					Vec2(center.x + half, center.y + half), -- 192
					Vec2(center.x - half, center.y + half) -- 193
				}, -- 193
				Color(120, 220, 255, alpha), -- 195
				3, -- 196
				Color( -- 197
					210, -- 197
					245, -- 197
					255, -- 197
					math.floor(alpha * 0.8) -- 197
				) -- 197
			) -- 197
		end -- 197
		::__continue30:: -- 197
	end -- 197
end -- 166
function BoardView.prototype.animateFall(self, moves, spawns) -- 206
	self.fallCells = {} -- 207
	self.fallOffsetsX = {} -- 208
	self.fallOffsetsY = {} -- 209
	local columns = self.board.columns -- 210
	do -- 210
		local i = 0 -- 211
		while i + 1 < #moves do -- 211
			do -- 211
				local from = moves[i + 1] -- 212
				local to = moves[i + 1 + 1] -- 213
				if to < 0 or to >= #self.widgets then -- 213
					goto __continue35 -- 215
				end -- 215
				local target = self:cellCenter(to) -- 217
				local source = self:cellCenter(from) -- 218
				local ____self_fallCells_3 = self.fallCells -- 218
				____self_fallCells_3[#____self_fallCells_3 + 1] = to -- 219
				local ____self_fallOffsetsX_4 = self.fallOffsetsX -- 219
				____self_fallOffsetsX_4[#____self_fallOffsetsX_4 + 1] = source.x - target.x -- 220
				local ____self_fallOffsetsY_5 = self.fallOffsetsY -- 220
				____self_fallOffsetsY_5[#____self_fallOffsetsY_5 + 1] = source.y - target.y -- 221
			end -- 221
			::__continue35:: -- 221
			i = i + 2 -- 211
		end -- 211
	end -- 211
	for ____, flat in ipairs(spawns) do -- 223
		do -- 223
			if flat < 0 or flat >= #self.widgets then -- 223
				goto __continue37 -- 225
			end -- 225
			local row = math.floor(flat / columns) -- 227
			local ____self_fallCells_6 = self.fallCells -- 227
			____self_fallCells_6[#____self_fallCells_6 + 1] = flat -- 228
			local ____self_fallOffsetsX_7 = self.fallOffsetsX -- 228
			____self_fallOffsetsX_7[#____self_fallOffsetsX_7 + 1] = 0 -- 229
			local ____self_fallOffsetsY_8 = self.fallOffsetsY -- 229
			____self_fallOffsetsY_8[#____self_fallOffsetsY_8 + 1] = (self.board.rows - row) * Config.CellSize -- 230
		end -- 230
		::__continue37:: -- 230
	end -- 230
	self.fallTimer = #self.fallCells > 0 and self.fallDuration or 0 -- 232
	if self.fallTimer <= 0 then -- 232
		self:resetFallPositions() -- 234
	end -- 234
end -- 206
function BoardView.prototype.finishFall(self) -- 244
	self.fallTimer = 0 -- 245
	self:resetFallPositions() -- 246
end -- 244
function BoardView.prototype.fallOffset(self, flat) -- 250
	if flat < 0 or flat >= #self.widgets then -- 250
		return Vec2(0, 0) -- 252
	end -- 252
	local col = flat % self.board.columns -- 254
	local row = math.floor(flat / self.board.columns) -- 255
	local position = self.widgets[flat + 1].root.position -- 256
	return Vec2( -- 257
		position.x - self:cellCenterX(col), -- 257
		position.y - self:cellCenterY(row) -- 257
	) -- 257
end -- 250
function BoardView.prototype.resetFallPositions(self) -- 260
	for ____, flat in ipairs(self.fallCells) do -- 261
		do -- 261
			if flat < 0 or flat >= #self.widgets then -- 261
				goto __continue45 -- 263
			end -- 263
			local col = flat % self.board.columns -- 265
			local row = math.floor(flat / self.board.columns) -- 266
			self.widgets[flat + 1]:setPosition( -- 267
				self:cellCenterX(col), -- 267
				self:cellCenterY(row) -- 267
			) -- 267
		end -- 267
		::__continue45:: -- 267
	end -- 267
end -- 260
function BoardView.prototype.advanceFall(self, dt) -- 272
	if self.fallTimer <= 0 then -- 272
		return -- 274
	end -- 274
	self.fallTimer = self.fallTimer - dt -- 276
	local progress = self.fallTimer <= 0 and 1 or 1 - self.fallTimer / self.fallDuration -- 277
	local inv = 1 - progress -- 278
	local eased = 1 - inv * inv -- 279
	local remain = 1 - eased -- 280
	do -- 280
		local i = 0 -- 281
		while i < #self.fallCells do -- 281
			local flat = self.fallCells[i + 1] -- 282
			local col = flat % self.board.columns -- 283
			local row = math.floor(flat / self.board.columns) -- 284
			self.widgets[flat + 1]:setPosition( -- 285
				self:cellCenterX(col) + self.fallOffsetsX[i + 1] * remain, -- 286
				self:cellCenterY(row) + self.fallOffsetsY[i + 1] * remain -- 287
			) -- 287
			i = i + 1 -- 281
		end -- 281
	end -- 281
	if self.fallTimer <= 0 then -- 281
		self.fallTimer = 0 -- 291
		self:resetFallPositions() -- 292
	end -- 292
end -- 272
function BoardView.prototype.endFlash(self) -- 300
	if self.flashTimer <= 0 and #self.flashCells == 0 then -- 300
		return -- 302
	end -- 302
	self.flashTimer = 0 -- 304
	self.flashCells = {} -- 305
	self.flashLayer:clear() -- 306
	self:refreshFromBoard() -- 307
end -- 300
function BoardView.prototype.flashCleared(self, cells) -- 311
	self.flashCells = {} -- 312
	for ____, flat in ipairs(cells) do -- 313
		do -- 313
			if flat < 0 or flat >= #self.widgets then -- 313
				goto __continue56 -- 315
			end -- 315
			local ____self_flashCells_9 = self.flashCells -- 315
			____self_flashCells_9[#____self_flashCells_9 + 1] = flat -- 317
			self.widgets[flat + 1].visible = false -- 318
		end -- 318
		::__continue56:: -- 318
	end -- 318
	self.flashTimer = #self.flashCells > 0 and self.flashDuration or 0 -- 320
end -- 311
function BoardView.prototype.refreshFromBoard(self) -- 329
	do -- 329
		local row = 0 -- 330
		while row < self.board.rows do -- 330
			do -- 330
				local col = 0 -- 331
				while col < self.board.columns do -- 331
					do -- 331
						local flat = self.board:flatIndex(col, row) -- 332
						local index = self.board:cellIndex(col, row) -- 333
						local widget = self.widgets[flat + 1] -- 334
						if self.isFlashing and self:isFlashingCell(flat) then -- 334
							widget.visible = false -- 336
							goto __continue63 -- 337
						end -- 337
						if index < 0 then -- 337
							widget.visible = false -- 340
							goto __continue63 -- 341
						end -- 341
						widget.visible = true -- 343
						widget:setDef(BlockDefs:at(index)) -- 344
						widget:setLocked(not BlockDefs:isPlaceable(index)) -- 346
						widget:setLockTurns(widget.locked and self.board:lockTurnsAt(flat) or 0) -- 348
					end -- 348
					::__continue63:: -- 348
					col = col + 1 -- 331
				end -- 331
			end -- 331
			row = row + 1 -- 330
		end -- 330
	end -- 330
end -- 329
function BoardView.prototype.isFlashingCell(self, flat) -- 353
	for ____, cell in ipairs(self.flashCells) do -- 354
		if cell == flat then -- 354
			return true -- 356
		end -- 356
	end -- 356
	return false -- 359
end -- 353
function BoardView.prototype.cellCenterX(self, col) -- 362
	return (col + 0.5) * Config.CellSize -- 363
end -- 362
function BoardView.prototype.cellCenterY(self, row) -- 366
	return (row + 0.5) * Config.CellSize -- 367
end -- 366
function BoardView.prototype.cellCenter(self, flat) -- 370
	local col = flat % self.board.columns -- 371
	local row = math.floor(flat / self.board.columns) -- 372
	return Vec2( -- 373
		self:cellCenterX(col), -- 373
		self:cellCenterY(row) -- 373
	) -- 373
end -- 370
function BoardView.prototype.cellAt(self, location) -- 377
	local col = math.floor(location.x / Config.CellSize) -- 378
	local row = math.floor(location.y / Config.CellSize) -- 379
	if not self.board:inside(col, row) then -- 379
		return -1 -- 381
	end -- 381
	return self.board:flatIndex(col, row) -- 383
end -- 377
function BoardView.prototype.press(self, location) -- 387
	self:endFlash() -- 388
	self:finishFall() -- 389
	self.chain = {} -- 390
	self.lastX = location.x -- 391
	self.lastY = location.y -- 392
	self:appendCell(self:cellAt(location)) -- 393
end -- 387
function BoardView.prototype.move(self, location) -- 396
	if #self.chain == 0 then -- 396
		return -- 398
	end -- 398
	self:trackTo(location) -- 400
end -- 396
function BoardView.prototype.release(self, location) -- 403
	if #self.chain > 0 then -- 403
		self:trackTo(location) -- 405
	end -- 405
	self:finish() -- 407
end -- 403
function BoardView.prototype.trackTo(self, location) -- 411
	local dx = location.x - self.lastX -- 412
	local dy = location.y - self.lastY -- 413
	local dist = math.sqrt(dx * dx + dy * dy) -- 414
	local step = Config.CellSize * 0.5 -- 415
	if dist > step then -- 415
		local samples = math.floor(dist / step) -- 417
		if samples > 16 then -- 417
			samples = 16 -- 419
		end -- 419
		do -- 419
			local i = 1 -- 421
			while i <= samples do -- 421
				local t = i * step / dist -- 422
				self:appendToward(self:cellAt(Vec2(self.lastX + dx * t, self.lastY + dy * t))) -- 423
				i = i + 1 -- 421
			end -- 421
		end -- 421
	end -- 421
	self.lastX = location.x -- 426
	self.lastY = location.y -- 427
	self:appendToward(self:cellAt(location)) -- 428
end -- 411
function BoardView.prototype.appendToward(self, flat) -- 432
	if flat < 0 then -- 432
		return -- 434
	end -- 434
	local columns = self.board.columns -- 436
	do -- 436
		local guard = 0 -- 437
		while guard < 3 do -- 437
			local chain = self.chain -- 438
			if #chain == 0 then -- 438
				self:appendCell(flat) -- 440
				return -- 441
			end -- 441
			local tail = chain[#chain] -- 443
			if tail == flat then -- 443
				return -- 445
			end -- 445
			local tailCol = tail % columns -- 447
			local tailRow = math.floor(tail / columns) -- 448
			local col = flat % columns -- 449
			local row = math.floor(flat / columns) -- 450
			local dc = col - tailCol -- 451
			local dr = row - tailRow -- 452
			local distance = math.abs(dc) + math.abs(dr) -- 453
			if distance > 2 then -- 453
				return -- 455
			end -- 455
			local nextCol = col -- 457
			local nextRow = row -- 458
			if distance == 2 then -- 458
				if math.abs(dc) >= math.abs(dr) then -- 458
					nextCol = tailCol + (dc > 0 and 1 or -1) -- 462
					nextRow = tailRow -- 463
				else -- 463
					nextCol = tailCol -- 465
					nextRow = tailRow + (dr > 0 and 1 or -1) -- 466
				end -- 466
			end -- 466
			local before = #chain -- 469
			self:appendCell(self.board:flatIndex(nextCol, nextRow)) -- 470
			if #self.chain == before then -- 470
				return -- 472
			end -- 472
			guard = guard + 1 -- 437
		end -- 437
	end -- 437
end -- 432
function BoardView.prototype.selectedCount(self) -- 478
	local count = 0 -- 479
	for ____, widget in ipairs(self.widgets) do -- 480
		if widget.selected then -- 480
			count = count + 1 -- 482
		end -- 482
	end -- 482
	return count -- 485
end -- 478
function BoardView.prototype.appendCell(self, flat) -- 489
	if flat < 0 then -- 489
		return -- 491
	end -- 491
	local startCol = flat % self.board.columns -- 493
	local startRow = math.floor(flat / self.board.columns) -- 494
	if not BlockDefs:isPlaceable(self.board:cellIndex(startCol, startRow)) then -- 494
		return -- 497
	end -- 497
	local chain = self.chain -- 499
	local length = #chain -- 500
	if length == 0 then -- 500
		chain[#chain + 1] = flat -- 502
		self:refreshHighlight() -- 503
		return -- 504
	end -- 504
	if chain[length] == flat then -- 504
		return -- 507
	end -- 507
	if length >= 2 and chain[length - 2 + 1] == flat then -- 507
		table.remove(chain) -- 510
		self:refreshHighlight() -- 511
		return -- 512
	end -- 512
	for ____, cell in ipairs(chain) do -- 514
		if cell == flat then -- 514
			return -- 516
		end -- 516
	end -- 516
	if not self:canFollow(chain[length], flat) then -- 516
		return -- 520
	end -- 520
	chain[#chain + 1] = flat -- 522
	self:refreshHighlight() -- 523
end -- 489
function BoardView.prototype.canFollow(self, from, to) -- 526
	local columns = self.board.columns -- 527
	local fromCol = from % columns -- 528
	local fromRow = math.floor(from / columns) -- 529
	local toCol = to % columns -- 530
	local toRow = math.floor(to / columns) -- 531
	if not Board:areNeighbors(fromCol, fromRow, toCol, toRow) then -- 531
		return false -- 533
	end -- 533
	local fromIndex = self.board:cellIndex(fromCol, fromRow) -- 535
	local toIndex = self.board:cellIndex(toCol, toRow) -- 536
	if not BlockDefs:isPlaceable(fromIndex) or not BlockDefs:isPlaceable(toIndex) then -- 536
		return false -- 539
	end -- 539
	return fromIndex == toIndex -- 541
end -- 526
function BoardView.prototype.isLockedAt(self, flat) -- 545
	if flat < 0 or flat >= #self.widgets then -- 545
		return false -- 547
	end -- 547
	return self.widgets[flat + 1].locked -- 549
end -- 545
function BoardView.prototype.lockTurnsLabelAt(self, flat) -- 553
	if flat < 0 or flat >= #self.widgets then -- 553
		return "" -- 555
	end -- 555
	return self.widgets[flat + 1].badgeText -- 557
end -- 553
function BoardView.prototype.finish(self) -- 560
	local chain = self.chain -- 561
	local length = #chain -- 562
	self.chain = {} -- 563
	self:refreshHighlight() -- 564
	if length < Config.MinChainLength then -- 564
		return -- 566
	end -- 566
	local first = chain[1] -- 568
	local col = first % self.board.columns -- 569
	local row = math.floor(first / self.board.columns) -- 570
	local index = self.board:cellIndex(col, row) -- 571
	if index < 0 then -- 571
		return -- 573
	end -- 573
	local def = BlockDefs:at(index) -- 575
	local cells = {} -- 576
	for ____, cell in ipairs(chain) do -- 577
		cells[#cells + 1] = cell -- 578
	end -- 578
	self.pending = { -- 580
		blockId = def.id, -- 580
		chainLength = length, -- 580
		cells = cells, -- 580
		specs = resolveEffects(def.rules, length) -- 580
	} -- 580
end -- 560
function BoardView.prototype.refreshHighlight(self) -- 583
	do -- 583
		local i = 0 -- 584
		while i < #self.widgets do -- 584
			self.widgets[i + 1]:setSelected(false) -- 585
			i = i + 1 -- 584
		end -- 584
	end -- 584
	self.highlight:clear() -- 587
	local chain = self.chain -- 588
	for ____, flat in ipairs(chain) do -- 589
		self.widgets[flat + 1]:setSelected(true) -- 590
	end -- 590
	do -- 590
		local i = 0 -- 592
		while i + 1 < #chain do -- 592
			self.highlight:drawSegment( -- 593
				self:cellCenter(chain[i + 1]), -- 593
				self:cellCenter(chain[i + 1 + 1]), -- 593
				9, -- 593
				Color(255, 255, 255, 190) -- 593
			) -- 593
			i = i + 1 -- 592
		end -- 592
	end -- 592
end -- 583
__TS__SetDescriptor( -- 583
	BoardView.prototype, -- 583
	"chainLength", -- 583
	{get = function(self) -- 583
		return #self.chain -- 90
	end}, -- 90
	true -- 90
) -- 90
__TS__SetDescriptor( -- 90
	BoardView.prototype, -- 90
	"isCasting", -- 90
	{get = function(self) -- 90
		return self.pulseTimer > 0 -- 162
	end}, -- 162
	true -- 162
) -- 162
__TS__SetDescriptor( -- 162
	BoardView.prototype, -- 162
	"isFalling", -- 162
	{get = function(self) -- 162
		return self.fallTimer > 0 -- 240
	end}, -- 240
	true -- 240
) -- 240
__TS__SetDescriptor( -- 240
	BoardView.prototype, -- 240
	"isFlashing", -- 240
	{get = function(self) -- 240
		return self.flashTimer > 0 -- 325
	end}, -- 325
	true -- 325
) -- 325
return ____exports -- 325
-- [ts]: Board.ts
local ____lualib = require("lualib_bundle") -- 1
local __TS__Class = ____lualib.__TS__Class -- 1
local __TS__SetDescriptor = ____lualib.__TS__SetDescriptor -- 1
local ____exports = {} -- 1
local ____BlockDefs = require("game.BlockDefs") -- 4
local BlockDefs = ____BlockDefs.BlockDefs -- 4
local ____Config = require("game.Config") -- 5
local Config = ____Config.Config -- 5
____exports.Board = __TS__Class() -- 7
local Board = ____exports.Board -- 7
Board.name = "Board" -- 7
function Board.prototype.____constructor(self) -- 31
	self.columns = Config.Columns -- 8
	self.rows = Config.Rows -- 9
	self.cells = {} -- 11
	self.clearedCount = 0 -- 13
	self.chainCount = 0 -- 15
	self.forcedRepairCount = 0 -- 17
	self.lastMoves = {} -- 19
	self.lastSpawns = {} -- 21
	self.limitWarnings = 0 -- 23
	self.deadlockWarnings = 0 -- 25
	self.lockTimers = {} -- 27
	self.lastExpired = 0 -- 29
	self:resetCells() -- 32
	self:fill() -- 33
end -- 31
function Board.areNeighbors(self, colA, rowA, colB, rowB) -- 37
	return math.abs(colA - colB) + math.abs(rowA - rowB) == 1 -- 38
end -- 37
function Board.prototype.inside(self, col, row) -- 41
	return col >= 0 and col < self.columns and row >= 0 and row < self.rows -- 42
end -- 41
function Board.prototype.flatIndex(self, col, row) -- 45
	return row * self.columns + col -- 46
end -- 45
function Board.prototype.cellIndex(self, col, row) -- 50
	if not self:inside(col, row) then -- 50
		return -1 -- 52
	end -- 52
	return self.cells[self:flatIndex(col, row) + 1] -- 54
end -- 50
function Board.prototype.setCell(self, col, row, index) -- 57
	if not self:inside(col, row) then -- 57
		return -- 59
	end -- 59
	self.cells[self:flatIndex(col, row) + 1] = index -- 61
end -- 57
function Board.prototype.isFull(self) -- 64
	do -- 64
		local i = 0 -- 65
		while i < #self.cells do -- 65
			if self.cells[i + 1] < 0 then -- 65
				return false -- 67
			end -- 67
			i = i + 1 -- 65
		end -- 65
	end -- 65
	return true -- 70
end -- 64
function Board.prototype.connectedSize(self, col, row) -- 74
	local target = self:cellIndex(col, row) -- 75
	if target < 0 then -- 75
		return 0 -- 77
	end -- 77
	local visited = self:makeVisited() -- 79
	return self:measureGroup(col, row, visited, target) -- 80
end -- 74
function Board.prototype.maxGroupSizes(self) -- 84
	local result = {} -- 85
	do -- 85
		local i = 0 -- 86
		while i < BlockDefs:placeableCount() do -- 86
			result[#result + 1] = 0 -- 87
			i = i + 1 -- 86
		end -- 86
	end -- 86
	local visited = self:makeVisited() -- 89
	do -- 89
		local row = 0 -- 90
		while row < self.rows do -- 90
			do -- 90
				local col = 0 -- 91
				while col < self.columns do -- 91
					do -- 91
						local flat = self:flatIndex(col, row) -- 92
						if visited[flat + 1] then -- 92
							goto __continue22 -- 94
						end -- 94
						local target = self.cells[flat + 1] -- 96
						if target < 0 or not BlockDefs:isPlaceable(target) then -- 96
							visited[flat + 1] = true -- 99
							goto __continue22 -- 100
						end -- 100
						local size = self:measureGroup(col, row, visited, target) -- 102
						if size > result[target + 1] then -- 102
							result[target + 1] = size -- 104
						end -- 104
					end -- 104
					::__continue22:: -- 104
					col = col + 1 -- 91
				end -- 91
			end -- 91
			row = row + 1 -- 90
		end -- 90
	end -- 90
	return result -- 108
end -- 84
function Board.prototype.satisfiesGroupLimit(self, maxGroup) -- 112
	for ____, size in ipairs(self:maxGroupSizes()) do -- 113
		if size > maxGroup then -- 113
			return false -- 115
		end -- 115
	end -- 115
	return true -- 118
end -- 112
function Board.prototype.fill(self) -- 125
	local maxGroup = Config.MaxGroupSize -- 126
	do -- 126
		local attempt = 0 -- 127
		while attempt < Config.BoardRefillRetries do -- 127
			self:randomFill(maxGroup) -- 128
			if self:hasPlayableRegion(Config.MinChainLength) then -- 128
				return -- 130
			end -- 130
			if attempt % 6 == 5 and maxGroup < Config.GroupSizeRelaxLimit then -- 130
				maxGroup = maxGroup + 1 -- 133
			end -- 133
			attempt = attempt + 1 -- 127
		end -- 127
	end -- 127
	self:randomFill(Config.GroupSizeRelaxLimit) -- 137
	self:applyPlayableGroup(self:lineCells()) -- 138
end -- 125
function Board.prototype.removeCells(self, cells) -- 152
	local removed = 0 -- 153
	for ____, flat in ipairs(cells) do -- 154
		do -- 154
			if flat < 0 or flat >= #self.cells then -- 154
				goto __continue36 -- 156
			end -- 156
			if self.cells[flat + 1] < 0 then -- 156
				goto __continue36 -- 159
			end -- 159
			if not BlockDefs:isPlaceable(self.cells[flat + 1]) then -- 159
				goto __continue36 -- 163
			end -- 163
			self.cells[flat + 1] = -1 -- 165
			removed = removed + 1 -- 166
		end -- 166
		::__continue36:: -- 166
	end -- 166
	return removed -- 168
end -- 152
function Board.prototype.collapse(self) -- 172
	self.lastMoves = {} -- 173
	self.lastSpawns = {} -- 174
	do -- 174
		local col = 0 -- 175
		while col < self.columns do -- 175
			local write = 0 -- 176
			do -- 176
				local row = 0 -- 177
				while row < self.rows do -- 177
					do -- 177
						local value = self:cellIndex(col, row) -- 178
						if value < 0 then -- 178
							goto __continue45 -- 180
						end -- 180
						if not BlockDefs:isPlaceable(value) then -- 180
							do -- 180
								local clear = write -- 184
								while clear < row do -- 184
									self:setCell(col, clear, -1) -- 185
									local ____self_lastSpawns_0 = self.lastSpawns -- 185
									____self_lastSpawns_0[#____self_lastSpawns_0 + 1] = self:flatIndex(col, clear) -- 187
									clear = clear + 1 -- 184
								end -- 184
							end -- 184
							write = row + 1 -- 189
							goto __continue45 -- 190
						end -- 190
						if write ~= row then -- 190
							self:setCell(col, write, value) -- 193
							self:setCell(col, row, -1) -- 194
							local ____self_lastMoves_1 = self.lastMoves -- 194
							____self_lastMoves_1[#____self_lastMoves_1 + 1] = self:flatIndex(col, row) -- 196
							local ____self_lastMoves_2 = self.lastMoves -- 196
							____self_lastMoves_2[#____self_lastMoves_2 + 1] = self:flatIndex(col, write) -- 197
						end -- 197
						write = write + 1 -- 199
					end -- 199
					::__continue45:: -- 199
					row = row + 1 -- 177
				end -- 177
			end -- 177
			do -- 177
				local row = write -- 202
				while row < self.rows do -- 202
					self:setCell(col, row, -1) -- 203
					local ____self_lastSpawns_3 = self.lastSpawns -- 203
					____self_lastSpawns_3[#____self_lastSpawns_3 + 1] = self:flatIndex(col, row) -- 204
					row = row + 1 -- 202
				end -- 202
			end -- 202
			col = col + 1 -- 175
		end -- 175
	end -- 175
end -- 172
function Board.prototype.applyChain(self, cells) -- 220
	local removed = self:removeCells(cells) -- 221
	if removed == 0 then -- 221
		return 0 -- 223
	end -- 223
	self.clearedCount = self.clearedCount + removed -- 225
	self.chainCount = self.chainCount + 1 -- 226
	self:collapse() -- 227
	self:refillRestore() -- 228
	if not self:satisfiesGroupLimit(Config.GroupSizeRelaxLimit) then -- 228
		self.limitWarnings = self.limitWarnings + 1 -- 231
	end -- 231
	if not self:hasPlayableRegion(Config.MinChainLength) then -- 231
		self.deadlockWarnings = self.deadlockWarnings + 1 -- 234
	end -- 234
	return removed -- 236
end -- 220
function Board.prototype.emptyCount(self) -- 240
	local count = 0 -- 241
	do -- 241
		local i = 0 -- 242
		while i < #self.cells do -- 242
			if self.cells[i + 1] < 0 then -- 242
				count = count + 1 -- 244
			end -- 244
			i = i + 1 -- 242
		end -- 242
	end -- 242
	return count -- 247
end -- 240
function Board.prototype.hasPlayableRegion(self, minSize) -- 251
	for ____, size in ipairs(self:maxGroupSizes()) do -- 252
		if size >= minSize then -- 252
			return true -- 254
		end -- 254
	end -- 254
	return false -- 257
end -- 251
function Board.prototype.refillRestore(self) -- 265
	local slots = {} -- 266
	do -- 266
		local i = 0 -- 267
		while i < #self.cells do -- 267
			if self.cells[i + 1] < 0 then -- 267
				slots[#slots + 1] = i -- 269
			end -- 269
			i = i + 1 -- 267
		end -- 267
	end -- 267
	if #slots == 0 then -- 267
		return -- 273
	end -- 273
	local maxGroup = Config.MaxGroupSize -- 275
	do -- 275
		local attempt = 0 -- 276
		while attempt < Config.BoardRefillRetries do -- 276
			self:fillSlots(slots, maxGroup) -- 277
			if self:satisfiesGroupLimit(maxGroup) and self:hasPlayableRegion(Config.MinChainLength) then -- 277
				return -- 279
			end -- 279
			self:discardSlots(slots) -- 281
			if attempt % 6 == 5 and maxGroup < Config.GroupSizeRelaxLimit then -- 281
				maxGroup = maxGroup + 1 -- 283
			end -- 283
			attempt = attempt + 1 -- 276
		end -- 276
	end -- 276
	do -- 276
		local attempt = 0 -- 286
		while attempt < Config.RefillFallbackRetries do -- 286
			self:fillSlots(slots, Config.GroupSizeRelaxLimit) -- 287
			if self:satisfiesGroupLimit(Config.GroupSizeRelaxLimit) and self:hasPlayableRegion(Config.MinChainLength) then -- 287
				return -- 289
			end -- 289
			self:discardSlots(slots) -- 291
			attempt = attempt + 1 -- 286
		end -- 286
	end -- 286
	self:fillSlots(slots, Config.GroupSizeRelaxLimit) -- 294
	if self:applyPlayableGroup(self:findRunInSlots(slots, Config.MinChainLength)) then -- 294
		self.forcedRepairCount = self.forcedRepairCount + 1 -- 296
	end -- 296
end -- 265
function Board.prototype.isPlayable(self) -- 316
	return self:hasPlayableRegion(Config.MinChainLength) -- 317
end -- 316
function Board.prototype.reset(self) -- 321
	self:resetCells() -- 322
	self:fill() -- 323
end -- 321
function Board.prototype.shuffle(self) -- 327
	self:reset() -- 328
end -- 327
function Board.prototype.largestGroupCells(self) -- 335
	local visited = self:makeVisited() -- 336
	local best = {} -- 337
	do -- 337
		local row = 0 -- 338
		while row < self.rows do -- 338
			do -- 338
				local col = 0 -- 339
				while col < self.columns do -- 339
					do -- 339
						local flat = self:flatIndex(col, row) -- 340
						if visited[flat + 1] then -- 340
							goto __continue85 -- 342
						end -- 342
						local target = self.cells[flat + 1] -- 344
						if target < 0 or not BlockDefs:isPlaceable(target) then -- 344
							visited[flat + 1] = true -- 346
							goto __continue85 -- 347
						end -- 347
						local group = self:collectGroup(col, row, visited, target) -- 349
						if #group > #best then -- 349
							best = group -- 351
						end -- 351
					end -- 351
					::__continue85:: -- 351
					col = col + 1 -- 339
				end -- 339
			end -- 339
			row = row + 1 -- 338
		end -- 338
	end -- 338
	if #best < Config.MinChainLength then -- 338
		return {} -- 356
	end -- 356
	return best -- 358
end -- 335
function Board.prototype.blastLargestGroup(self) -- 362
	local cells = self:largestGroupCells() -- 363
	if #cells == 0 then -- 363
		return 0 -- 365
	end -- 365
	local removed = self:removeCells(cells) -- 367
	if removed == 0 then -- 367
		return 0 -- 369
	end -- 369
	self.clearedCount = self.clearedCount + removed -- 371
	self:collapse() -- 372
	self:refillRestore() -- 373
	return removed -- 374
end -- 362
function Board.prototype.blockCells(self, count) -- 382
	local locked = BlockDefs:lockedIndex() -- 383
	if locked < 0 or count <= 0 then -- 383
		return 0 -- 385
	end -- 385
	local placed = 0 -- 387
	while placed < count do -- 387
		local group = self:largestGroupCells() -- 389
		if #group == 0 then -- 389
			break -- 391
		end -- 391
		local progressed = false -- 393
		for ____, flat in ipairs(group) do -- 394
			do -- 394
				if placed >= count then -- 394
					break -- 396
				end -- 396
				local previous = self.cells[flat + 1] -- 398
				if previous == locked or not BlockDefs:isPlaceable(previous) then -- 398
					goto __continue97 -- 400
				end -- 400
				self.cells[flat + 1] = locked -- 402
				if self:isPlayable() then -- 402
					self.lockTimers[flat + 1] = Config.LockDurationActions -- 405
					placed = placed + 1 -- 406
					progressed = true -- 407
				else -- 407
					self.cells[flat + 1] = previous -- 409
				end -- 409
			end -- 409
			::__continue97:: -- 409
		end -- 409
		if not progressed then -- 409
			break -- 413
		end -- 413
	end -- 413
	return placed -- 416
end -- 382
function Board.prototype.lockedCount(self) -- 420
	local count = 0 -- 421
	do -- 421
		local i = 0 -- 422
		while i < #self.cells do -- 422
			if self.cells[i + 1] >= 0 and not BlockDefs:isPlaceable(self.cells[i + 1]) then -- 422
				count = count + 1 -- 424
			end -- 424
			i = i + 1 -- 422
		end -- 422
	end -- 422
	return count -- 427
end -- 420
function Board.prototype.lockTurnsAt(self, flat) -- 431
	if flat < 0 or flat >= #self.lockTimers then -- 431
		return 0 -- 433
	end -- 433
	return self.lockTimers[flat + 1] -- 435
end -- 431
function Board.prototype.expireLocks(self) -- 449
	local expired = 0 -- 450
	do -- 450
		local i = 0 -- 451
		while i < #self.cells do -- 451
			do -- 451
				if self.lockTimers[i + 1] <= 0 then -- 451
					goto __continue112 -- 453
				end -- 453
				local ____self_lockTimers_4, ____temp_5 = self.lockTimers, i + 1 -- 453
				____self_lockTimers_4[____temp_5] = ____self_lockTimers_4[____temp_5] - 1 -- 455
				if self.lockTimers[i + 1] <= 0 then -- 455
					self.cells[i + 1] = -1 -- 457
					expired = expired + 1 -- 458
				end -- 458
			end -- 458
			::__continue112:: -- 458
			i = i + 1 -- 451
		end -- 451
	end -- 451
	self.lastExpired = expired -- 461
	if expired > 0 then -- 461
		self:refillRestore() -- 463
	end -- 463
	return expired -- 465
end -- 449
function Board.prototype.discardSlots(self, slots) -- 468
	for ____, flat in ipairs(slots) do -- 469
		self.cells[flat + 1] = -1 -- 470
	end -- 470
end -- 468
function Board.prototype.findRunInSlots(self, slots, length) -- 475
	local inSlots = {} -- 476
	do -- 476
		local i = 0 -- 477
		while i < #self.cells do -- 477
			inSlots[#inSlots + 1] = false -- 478
			i = i + 1 -- 477
		end -- 477
	end -- 477
	for ____, flat in ipairs(slots) do -- 480
		inSlots[flat + 1] = true -- 481
	end -- 481
	for ____, flat in ipairs(slots) do -- 483
		local col = flat % self.columns -- 484
		local row = math.floor(flat / self.columns) -- 485
		do -- 485
			local dir = 0 -- 486
			while dir < 2 do -- 486
				local run = {flat} -- 487
				local complete = true -- 488
				do -- 488
					local step = 1 -- 489
					while step < length do -- 489
						local c = col + (dir == 0 and step or 0) -- 490
						local r = row + (dir == 1 and step or 0) -- 491
						if not self:inside(c, r) then -- 491
							complete = false -- 493
							break -- 494
						end -- 494
						local next = self:flatIndex(c, r) -- 496
						if not inSlots[next + 1] then -- 496
							complete = false -- 498
							break -- 499
						end -- 499
						run[#run + 1] = next -- 501
						step = step + 1 -- 489
					end -- 489
				end -- 489
				if complete then -- 489
					return run -- 504
				end -- 504
				dir = dir + 1 -- 486
			end -- 486
		end -- 486
	end -- 486
	return {} -- 508
end -- 475
function Board.prototype.lineCells(self) -- 512
	local cells = {} -- 513
	do -- 513
		local i = 0 -- 514
		while i < Config.MinChainLength and i < self.columns do -- 514
			cells[#cells + 1] = self:flatIndex(i, 0) -- 515
			i = i + 1 -- 514
		end -- 514
	end -- 514
	return cells -- 517
end -- 512
function Board.prototype.applyPlayableGroup(self, cells) -- 524
	local length = Config.MinChainLength -- 525
	if #cells < length then -- 525
		return false -- 527
	end -- 527
	local total = BlockDefs:placeableCount() -- 530
	local bestColor = -1 -- 531
	local bestMax = 0 -- 532
	do -- 532
		local color = 0 -- 533
		while color < total do -- 533
			do -- 533
				local i = 0 -- 534
				while i < length do -- 534
					self.cells[cells[i + 1] + 1] = color -- 535
					i = i + 1 -- 534
				end -- 534
			end -- 534
			local maxSize = 0 -- 537
			for ____, size in ipairs(self:maxGroupSizes()) do -- 538
				if size > maxSize then -- 538
					maxSize = size -- 540
				end -- 540
			end -- 540
			if bestColor < 0 or maxSize < bestMax then -- 540
				bestColor = color -- 544
				bestMax = maxSize -- 545
			end -- 545
			color = color + 1 -- 533
		end -- 533
	end -- 533
	do -- 533
		local i = 0 -- 548
		while i < length do -- 548
			self.cells[cells[i + 1] + 1] = bestColor -- 549
			i = i + 1 -- 548
		end -- 548
	end -- 548
	return true -- 551
end -- 524
function Board.prototype.fillSlots(self, slots, maxGroup) -- 555
	local total = BlockDefs:placeableCount() -- 556
	do -- 556
		local i = #slots - 1 -- 557
		while i >= 0 do -- 557
			local flat = slots[i + 1] -- 558
			local col = flat % self.columns -- 559
			local row = math.floor(flat / self.columns) -- 560
			local best = math.floor(math.random() * total) -- 561
			local bestSize = 0 -- 562
			do -- 562
				local retry = 0 -- 563
				while retry < Config.CellColorRetries do -- 563
					local candidate = math.floor(math.random() * total) -- 564
					self.cells[flat + 1] = candidate -- 565
					local size = self:connectedSize(col, row) -- 566
					if size <= maxGroup then -- 566
						best = candidate -- 568
						break -- 569
					end -- 569
					if best < 0 or size < bestSize then -- 569
						best = candidate -- 572
						bestSize = size -- 573
					end -- 573
					retry = retry + 1 -- 563
				end -- 563
			end -- 563
			self.cells[flat + 1] = best -- 576
			i = i - 1 -- 557
		end -- 557
	end -- 557
end -- 555
function Board.prototype.toText(self) -- 581
	local lines = {} -- 582
	do -- 582
		local row = self.rows - 1 -- 583
		while row >= 0 do -- 583
			local line = "" -- 584
			do -- 584
				local col = 0 -- 585
				while col < self.columns do -- 585
					local index = self:cellIndex(col, row) -- 586
					line = line .. (index < 0 and "." or BlockDefs:at(index).glyph) -- 587
					col = col + 1 -- 585
				end -- 585
			end -- 585
			lines[#lines + 1] = line -- 589
			row = row - 1 -- 583
		end -- 583
	end -- 583
	return table.concat(lines, "\n") -- 591
end -- 581
function Board.prototype.resetCells(self) -- 594
	self.cells = {} -- 595
	self.lockTimers = {} -- 596
	local total = self.columns * self.rows -- 597
	do -- 597
		local i = 0 -- 598
		while i < total do -- 598
			local ____self_cells_6 = self.cells -- 598
			____self_cells_6[#____self_cells_6 + 1] = -1 -- 599
			local ____self_lockTimers_7 = self.lockTimers -- 599
			____self_lockTimers_7[#____self_lockTimers_7 + 1] = 0 -- 600
			i = i + 1 -- 598
		end -- 598
	end -- 598
	self.lastExpired = 0 -- 602
end -- 594
function Board.prototype.makeVisited(self) -- 605
	local visited = {} -- 606
	do -- 606
		local i = 0 -- 607
		while i < #self.cells do -- 607
			visited[#visited + 1] = false -- 608
			i = i + 1 -- 607
		end -- 607
	end -- 607
	return visited -- 610
end -- 605
function Board.prototype.measureGroup(self, col, row, visited, target) -- 614
	local stack = {self:flatIndex(col, row)} -- 615
	visited[self:flatIndex(col, row) + 1] = true -- 616
	local count = 0 -- 617
	while #stack > 0 do -- 617
		local current = table.remove(stack) -- 619
		if current == nil then -- 619
			break -- 621
		end -- 621
		count = count + 1 -- 623
		local c = current % self.columns -- 624
		local r = math.floor(current / self.columns) -- 625
		self:pushNeighbor( -- 626
			stack, -- 626
			visited, -- 626
			c - 1, -- 626
			r, -- 626
			target -- 626
		) -- 626
		self:pushNeighbor( -- 627
			stack, -- 627
			visited, -- 627
			c + 1, -- 627
			r, -- 627
			target -- 627
		) -- 627
		self:pushNeighbor( -- 628
			stack, -- 628
			visited, -- 628
			c, -- 628
			r - 1, -- 628
			target -- 628
		) -- 628
		self:pushNeighbor( -- 629
			stack, -- 629
			visited, -- 629
			c, -- 629
			r + 1, -- 629
			target -- 629
		) -- 629
	end -- 629
	return count -- 631
end -- 614
function Board.prototype.collectGroup(self, col, row, visited, target) -- 635
	local stack = {self:flatIndex(col, row)} -- 636
	local group = {} -- 637
	visited[self:flatIndex(col, row) + 1] = true -- 638
	while #stack > 0 do -- 638
		local current = table.remove(stack) -- 640
		if current == nil then -- 640
			break -- 642
		end -- 642
		group[#group + 1] = current -- 644
		local c = current % self.columns -- 645
		local r = math.floor(current / self.columns) -- 646
		self:pushNeighbor( -- 647
			stack, -- 647
			visited, -- 647
			c - 1, -- 647
			r, -- 647
			target -- 647
		) -- 647
		self:pushNeighbor( -- 648
			stack, -- 648
			visited, -- 648
			c + 1, -- 648
			r, -- 648
			target -- 648
		) -- 648
		self:pushNeighbor( -- 649
			stack, -- 649
			visited, -- 649
			c, -- 649
			r - 1, -- 649
			target -- 649
		) -- 649
		self:pushNeighbor( -- 650
			stack, -- 650
			visited, -- 650
			c, -- 650
			r + 1, -- 650
			target -- 650
		) -- 650
	end -- 650
	return group -- 652
end -- 635
function Board.prototype.pushNeighbor(self, stack, visited, col, row, target) -- 655
	if not self:inside(col, row) then -- 655
		return -- 657
	end -- 657
	local flat = self:flatIndex(col, row) -- 659
	if visited[flat + 1] or self.cells[flat + 1] ~= target then -- 659
		return -- 661
	end -- 661
	visited[flat + 1] = true -- 663
	stack[#stack + 1] = flat -- 664
end -- 655
function Board.prototype.randomFill(self, maxGroup) -- 667
	local total = BlockDefs:placeableCount() -- 668
	do -- 668
		local row = 0 -- 669
		while row < self.rows do -- 669
			do -- 669
				local col = 0 -- 670
				while col < self.columns do -- 670
					local flat = self:flatIndex(col, row) -- 671
					local best = -1 -- 672
					local bestSize = 0 -- 673
					do -- 673
						local retry = 0 -- 674
						while retry < Config.CellColorRetries do -- 674
							local candidate = math.floor(math.random() * total) -- 675
							self.cells[flat + 1] = candidate -- 676
							local size = self:connectedSize(col, row) -- 677
							if size <= maxGroup then -- 677
								best = candidate -- 679
								bestSize = size -- 680
								break -- 681
							end -- 681
							if best < 0 or size < bestSize then -- 681
								best = candidate -- 684
								bestSize = size -- 685
							end -- 685
							retry = retry + 1 -- 674
						end -- 674
					end -- 674
					self.cells[flat + 1] = best -- 688
					col = col + 1 -- 670
				end -- 670
			end -- 670
			row = row + 1 -- 669
		end -- 669
	end -- 669
end -- 667
__TS__SetDescriptor( -- 667
	Board.prototype, -- 667
	"clearedTotal", -- 667
	{get = function(self) -- 667
		return self.clearedCount -- 143
	end}, -- 143
	true -- 143
) -- 143
__TS__SetDescriptor( -- 143
	Board.prototype, -- 143
	"chainsTotal", -- 143
	{get = function(self) -- 143
		return self.chainCount -- 148
	end}, -- 148
	true -- 148
) -- 148
__TS__SetDescriptor( -- 148
	Board.prototype, -- 148
	"collapseMoves", -- 148
	{get = function(self) -- 148
		return self.lastMoves -- 211
	end}, -- 211
	true -- 211
) -- 211
__TS__SetDescriptor( -- 211
	Board.prototype, -- 211
	"collapseSpawns", -- 211
	{get = function(self) -- 211
		return self.lastSpawns -- 216
	end}, -- 216
	true -- 216
) -- 216
__TS__SetDescriptor( -- 216
	Board.prototype, -- 216
	"forcedRepairs", -- 216
	{get = function(self) -- 216
		return self.forcedRepairCount -- 302
	end}, -- 302
	true -- 302
) -- 302
__TS__SetDescriptor( -- 302
	Board.prototype, -- 302
	"limitWarningCount", -- 302
	{get = function(self) -- 302
		return self.limitWarnings -- 307
	end}, -- 307
	true -- 307
) -- 307
__TS__SetDescriptor( -- 307
	Board.prototype, -- 307
	"deadlockWarningCount", -- 307
	{get = function(self) -- 307
		return self.deadlockWarnings -- 312
	end}, -- 312
	true -- 312
) -- 312
__TS__SetDescriptor( -- 312
	Board.prototype, -- 312
	"lastExpiredLocks", -- 312
	{get = function(self) -- 312
		return self.lastExpired -- 440
	end}, -- 440
	true -- 440
) -- 440
return ____exports -- 440
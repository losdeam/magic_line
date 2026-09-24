// 棋盘数据模型（纯逻辑，可单独测试）：生成、约束校验、连通块统计。
// 消除/塌落/补充在 M2 扩展，本文件在 M1 只负责“生成 + 约束”。

import { BlockDefs } from 'game/BlockDefs';
import { Config } from 'game/Config';

export class Board {
	readonly columns = Config.Columns;
	readonly rows = Config.Rows;
	/** 每格的方块类型在注册表中的下标；-1 表示空格。始终满长度，不留 Lua 空洞。 */
	private cells: number[] = [];
	/** 累计消除块数（消除统计）。 */
	private clearedCount = 0;
	/** 累计有效连线次数（消除统计）。 */
	private chainCount = 0;
	/** 棋盘无解时被迫强行修复的次数。 */
	private forcedRepairCount = 0;
	/** 最近一次重力塌落的移动记录，成对存放：from、to（flat 下标）。 */
	private lastMoves: number[] = [];
	/** 最近一次塌落后腾空的格子（flat 下标）：这些格子将由新方块补充，用于掉落动画。 */
	private lastSpawns: number[] = [];
	/** 重力合流导致连通块超过放宽上限的告警次数。 */
	private limitWarnings = 0;
	/** 补充后仍无解（无可连线区域）的告警次数。 */
	private deadlockWarnings = 0;
	/** 每格的封锁剩余敌人行动次数；未封锁为 0。与 cells 等长，不留 Lua 空洞。 */
	private lockTimers: number[] = [];
	/** 最近一次 expireLocks() 自动恢复的格子数。 */
	private lastExpired = 0;

	constructor() {
		this.resetCells();
		this.fill();
	}

	/** 两格是否正交相邻。 */
	static areNeighbors(colA: number, rowA: number, colB: number, rowB: number): boolean {
		return Math.abs(colA - colB) + Math.abs(rowA - rowB) === 1;
	}

	inside(col: number, row: number): boolean {
		return col >= 0 && col < this.columns && row >= 0 && row < this.rows;
	}

	flatIndex(col: number, row: number): number {
		return row * this.columns + col;
	}

	/** 返回注册表下标；越界或空格返回 -1。 */
	cellIndex(col: number, row: number): number {
		if (!this.inside(col, row)) {
			return -1;
		}
		return this.cells[this.flatIndex(col, row)];
	}

	setCell(col: number, row: number, index: number): void {
		if (!this.inside(col, row)) {
			return;
		}
		this.cells[this.flatIndex(col, row)] = index;
	}

	isFull(): boolean {
		for (let i = 0; i < this.cells.length; i++) {
			if (this.cells[i] < 0) {
				return false;
			}
		}
		return true;
	}

	/** 包含指定格子的同色连通块规模（空格或越界返回 0）。 */
	connectedSize(col: number, row: number): number {
		const target = this.cellIndex(col, row);
		if (target < 0) {
			return 0;
		}
		const visited = this.makeVisited();
		return this.measureGroup(col, row, visited, target);
	}

	/** 每种可放置方块的最大连通块规模（按注册表下标；封锁格不计入）。 */
	maxGroupSizes(): number[] {
		const result: number[] = [];
		for (let i = 0; i < BlockDefs.placeableCount(); i++) {
			result.push(0);
		}
		const visited = this.makeVisited();
		for (let row = 0; row < this.rows; row++) {
			for (let col = 0; col < this.columns; col++) {
				const flat = this.flatIndex(col, row);
				if (visited[flat]) {
					continue;
				}
				const target = this.cells[flat];
				if (target < 0 || !BlockDefs.isPlaceable(target)) {
					// 空格与封锁格（固定障碍）都不参与“可连线区域”统计
					visited[flat] = true;
					continue;
				}
				const size = this.measureGroup(col, row, visited, target);
				if (size > result[target]) {
					result[target] = size;
				}
			}
		}
		return result;
	}

	/** C1：任一颜色的最大连通块规模不得超过 maxGroup。 */
	satisfiesGroupLimit(maxGroup: number): boolean {
		for (const size of this.maxGroupSizes()) {
			if (size > maxGroup) {
				return false;
			}
		}
		return true;
	}

	/**
	 * 生成满足约束的满格棋盘；带重试上限与逐级放宽，绝不死循环。
	 * 约束：只要存在一条长度 ≥ MinChainLength 的可连线区域即可（不要求每种颜色都有）。
	 */
	fill(): void {
		let maxGroup = Config.MaxGroupSize;
		for (let attempt = 0; attempt < Config.BoardRefillRetries; attempt++) {
			this.randomFill(maxGroup);
			if (this.hasPlayableRegion(Config.MinChainLength)) {
				return;
			}
			if (attempt % 6 === 5 && maxGroup < Config.GroupSizeRelaxLimit) {
				maxGroup++;
			}
		}
		// 兜底：放宽到上限后随机填充，并强行构造一条可连线区域，保证棋盘可玩。
		this.randomFill(Config.GroupSizeRelaxLimit);
		this.applyPlayableGroup(this.lineCells());
	}

	/** 累计消除块数。 */
	get clearedTotal(): number {
		return this.clearedCount;
	}

	/** 累计有效连线次数。 */
	get chainsTotal(): number {
		return this.chainCount;
	}

	/** 移除一组格子（按连线路径），返回实际移除数量。 */
	removeCells(cells: number[]): number {
		let removed = 0;
		for (const flat of cells) {
			if (flat < 0 || flat >= this.cells.length) {
				continue;
			}
			if (this.cells[flat] < 0) {
				continue;
			}
			if (!BlockDefs.isPlaceable(this.cells[flat])) {
				// 封锁格是固定障碍：不可被消除
				continue;
			}
			this.cells[flat] = -1;
			removed++;
		}
		return removed;
	}

	/** 重力塌落：每列的空格上方方块依次下移；同时记录移动轨迹供视图播放掉落动画。 */
	collapse(): void {
		this.lastMoves = [];
		this.lastSpawns = [];
		for (let col = 0; col < this.columns; col++) {
			let write = 0;
			for (let row = 0; row < this.rows; row++) {
				const value = this.cellIndex(col, row);
				if (value < 0) {
					continue;
				}
				if (!BlockDefs.isPlaceable(value)) {
					// 封锁格是固定墙：作为分段边界，清掉本段尾部残留后从下一行重新开始
					for (let clear = write; clear < row; clear++) {
						this.setCell(col, clear, -1);
						// 被清掉的格子同样会由新方块补充，纳入掉落动画
						this.lastSpawns.push(this.flatIndex(col, clear));
					}
					write = row + 1;
					continue;
				}
				if (write !== row) {
					this.setCell(col, write, value);
					this.setCell(col, row, -1);
					// 成对记录：from（原格）→ to（落点）
					this.lastMoves.push(this.flatIndex(col, row));
					this.lastMoves.push(this.flatIndex(col, write));
				}
				write++;
			}
			// 本段顶部剩余的空格由新方块从上方补充
			for (let row = write; row < this.rows; row++) {
				this.setCell(col, row, -1);
				this.lastSpawns.push(this.flatIndex(col, row));
			}
		}
	}

	/** 最近一次塌落的移动轨迹（from、to 成对，flat 下标）；供掉落动画使用。 */
	get collapseMoves(): number[] {
		return this.lastMoves;
	}

	/** 最近一次塌落腾空、随后被新方块填充的格子（flat 下标）。 */
	get collapseSpawns(): number[] {
		return this.lastSpawns;
	}

	/** 应用一次消除：移除 → 塌落 → 补充；返回实际移除数量。 */
	applyChain(cells: number[]): number {
		const removed = this.removeCells(cells);
		if (removed === 0) {
			return 0;
		}
		this.clearedCount += removed;
		this.chainCount++;
		this.collapse();
		this.refillRestore();
		// 重力合流可能让同色块跨过被消除的空隙合并，属于涌现结果，仅记录告警
		if (!this.satisfiesGroupLimit(Config.GroupSizeRelaxLimit)) {
			this.limitWarnings++;
		}
		if (!this.hasPlayableRegion(Config.MinChainLength)) {
			this.deadlockWarnings++;
		}
		return removed;
	}

	/** 当前空格数量。 */
	emptyCount(): number {
		let count = 0;
		for (let i = 0; i < this.cells.length; i++) {
			if (this.cells[i] < 0) {
				count++;
			}
		}
		return count;
	}

	/** C2：是否存在长度 ≥ minSize 的可连线区域（保证棋盘始终有可下的连线）。 */
	hasPlayableRegion(minSize: number): boolean {
		for (const size of this.maxGroupSizes()) {
			if (size >= minSize) {
				return true;
			}
		}
		return false;
	}

	/**
	 * 补充全部空格：只重试新补充的格子，不改动玩家已有的方块。
	 * 接受条件：C1 + 棋盘仍可连线（只要有一种颜色存在 ≥ MinChainLength 的区域即可，
	 * 不要求每种颜色都保留储备）；均为有限次，绝不死循环。
	 */
	refillRestore(): void {
		const slots: number[] = [];
		for (let i = 0; i < this.cells.length; i++) {
			if (this.cells[i] < 0) {
				slots.push(i);
			}
		}
		if (slots.length === 0) {
			return;
		}
		let maxGroup = Config.MaxGroupSize;
		for (let attempt = 0; attempt < Config.BoardRefillRetries; attempt++) {
			this.fillSlots(slots, maxGroup);
			if (this.satisfiesGroupLimit(maxGroup) && this.hasPlayableRegion(Config.MinChainLength)) {
				return;
			}
			this.discardSlots(slots);
			if (attempt % 6 === 5 && maxGroup < Config.GroupSizeRelaxLimit) {
				maxGroup++;
			}
		}
		for (let attempt = 0; attempt < Config.RefillFallbackRetries; attempt++) {
			this.fillSlots(slots, Config.GroupSizeRelaxLimit);
			if (this.satisfiesGroupLimit(Config.GroupSizeRelaxLimit) && this.hasPlayableRegion(Config.MinChainLength)) {
				return;
			}
			this.discardSlots(slots);
		}
		// 最后兜底：强行构造一条可连线区域，保证棋盘不会无解
		this.fillSlots(slots, Config.GroupSizeRelaxLimit);
		if (this.applyPlayableGroup(this.findRunInSlots(slots, Config.MinChainLength))) {
			this.forcedRepairCount++;
		}
	}

	/** 强制修复（棋盘无解时）发生次数，供自检观测。 */
	get forcedRepairs(): number {
		return this.forcedRepairCount;
	}

	/** 重力合流导致连通块超过放宽上限的告警次数。 */
	get limitWarningCount(): number {
		return this.limitWarnings;
	}

	/** 补充后仍然无解（无可连线区域）的告警次数；正常情况应为 0。 */
	get deadlockWarningCount(): number {
		return this.deadlockWarnings;
	}

	/** 当前棋盘是否可执行：存在长度 ≥ MinChainLength 的可连线区域。 */
	isPlayable(): boolean {
		return this.hasPlayableRegion(Config.MinChainLength);
	}

	/** 重排整盘（保持满格）；用于技能与“不可执行”兜底；同时清除全部封锁。 */
	reset(): void {
		this.resetCells();
		this.fill();
	}

	/** `BoardOps` 实现：重排整盘。 */
	shuffle(): void {
		this.reset();
	}

	/**
	 * 找出规模最大的可放置连通块（规模需 ≥ MinChainLength），返回其格子下标。
	 * 封锁格（固定障碍）不计入候选，否则引爆技能会把封锁格当作最大块。
	 */
	largestGroupCells(): number[] {
		const visited = this.makeVisited();
		let best: number[] = [];
		for (let row = 0; row < this.rows; row++) {
			for (let col = 0; col < this.columns; col++) {
				const flat = this.flatIndex(col, row);
				if (visited[flat]) {
					continue;
				}
				const target = this.cells[flat];
				if (target < 0 || !BlockDefs.isPlaceable(target)) {
					visited[flat] = true;
					continue;
				}
				const group = this.collectGroup(col, row, visited, target);
				if (group.length > best.length) {
					best = group;
				}
			}
		}
		if (best.length < Config.MinChainLength) {
			return [];
		}
		return best;
	}

	/** `BoardOps` 实现：清除场上最大的连通块（引爆技能），返回移除块数。 */
	blastLargestGroup(): number {
		const cells = this.largestGroupCells();
		if (cells.length === 0) {
			return 0;
		}
		const removed = this.removeCells(cells);
		if (removed === 0) {
			return 0;
		}
		this.clearedCount += removed;
		this.collapse();
		this.refillRestore();
		return removed;
	}

	/**
	 * `BoardOps` 实现：把 count 个格子封锁为固定障碍（精英重击的棋盘效果）。
	 * 逐格试锁并立即校验 `isPlayable()`，失败即回滚该格，
	 * 因此无论封锁多少格，棋盘始终保持至少一条 ≥ MinChainLength 的可连线区域。
	 */
	blockCells(count: number): number {
		const locked = BlockDefs.lockedIndex();
		if (locked < 0 || count <= 0) {
			return 0;
		}
		let placed = 0;
		while (placed < count) {
			const group = this.largestGroupCells();
			if (group.length === 0) {
				break;
			}
			let progressed = false;
			for (const flat of group) {
				if (placed >= count) {
					break;
				}
				const previous = this.cells[flat];
				if (previous === locked || !BlockDefs.isPlaceable(previous)) {
					continue;
				}
				this.cells[flat] = locked;
				if (this.isPlayable()) {
					// 记录封锁计时：经过 LockDurationActions 次敌人行动后自动恢复
					this.lockTimers[flat] = Config.LockDurationActions;
					placed++;
					progressed = true;
				} else {
					this.cells[flat] = previous;
				}
			}
			if (!progressed) {
				break;
			}
		}
		return placed;
	}

	/** 当前被封锁的格子数（固定障碍数量）。 */
	lockedCount(): number {
		let count = 0;
		for (let i = 0; i < this.cells.length; i++) {
			if (this.cells[i] >= 0 && !BlockDefs.isPlaceable(this.cells[i])) {
				count++;
			}
		}
		return count;
	}

	/** 指定格子的封锁剩余行动次数；越界或未封锁返回 0（自检观测用）。 */
	lockTurnsAt(flat: number): number {
		if (flat < 0 || flat >= this.lockTimers.length) {
			return 0;
		}
		return this.lockTimers[flat];
	}

	/** 最近一次 expireLocks() 自动恢复的格子数。 */
	get lastExpiredLocks(): number {
		return this.lastExpired;
	}

	/**
	 * 推进封锁计时（每次敌人行动调用一次）：到期的封锁格自动恢复为常规方块。
	 * 恢复方式是把格子先腾空、再交给标准补充流程（refillRestore），
	 * 因此恢复后 C1/C2/C3 依旧成立，不需要任何针对封锁的特例逻辑。
	 * 返回本次恢复的格子数。
	 */
	expireLocks(): number {
		let expired = 0;
		for (let i = 0; i < this.cells.length; i++) {
			if (this.lockTimers[i] <= 0) {
				continue;
			}
			this.lockTimers[i]--;
			if (this.lockTimers[i] <= 0) {
				this.cells[i] = -1;
				expired++;
			}
		}
		this.lastExpired = expired;
		if (expired > 0) {
			this.refillRestore();
		}
		return expired;
	}

	private discardSlots(slots: number[]): void {
		for (const flat of slots) {
			this.cells[flat] = -1;
		}
	}

	/** 在空格集合中找一条长度为 length 的直线；找不到返回空数组。 */
	private findRunInSlots(slots: number[], length: number): number[] {
		const inSlots: boolean[] = [];
		for (let i = 0; i < this.cells.length; i++) {
			inSlots.push(false);
		}
		for (const flat of slots) {
			inSlots[flat] = true;
		}
		for (const flat of slots) {
			const col = flat % this.columns;
			const row = Math.floor(flat / this.columns);
			for (let dir = 0; dir < 2; dir++) {
				const run: number[] = [flat];
				let complete = true;
				for (let step = 1; step < length; step++) {
					const c = col + (dir === 0 ? step : 0);
					const r = row + (dir === 1 ? step : 0);
					if (!this.inside(c, r)) {
						complete = false;
						break;
					}
					const next = this.flatIndex(c, r);
					if (!inSlots[next]) {
						complete = false;
						break;
					}
					run.push(next);
				}
				if (complete) {
					return run;
				}
			}
		}
		return [];
	}

	/** 取棋盘左下方第一行的前 MinChainLength 个格子（用于强行构造可连线区域）。 */
	private lineCells(): number[] {
		const cells: number[] = [];
		for (let i = 0; i < Config.MinChainLength && i < this.columns; i++) {
			cells.push(this.flatIndex(i, 0));
		}
		return cells;
	}

	/**
	 * 把给定的 MinChainLength 个格子设为同一颜色，强行构造可连线区域。
	 * 颜色取“使全盘最大连通块最小”的那个，避免接上已有大色块。
	 */
	private applyPlayableGroup(cells: number[]): boolean {
		const length = Config.MinChainLength;
		if (cells.length < length) {
			return false;
		}
		// 只用可放置方块的颜色（封锁格不是备选颜色）
		const total = BlockDefs.placeableCount();
		let bestColor = -1;
		let bestMax = 0;
		for (let color = 0; color < total; color++) {
			for (let i = 0; i < length; i++) {
				this.cells[cells[i]] = color;
			}
			let maxSize = 0;
			for (const size of this.maxGroupSizes()) {
				if (size > maxSize) {
					maxSize = size;
				}
			}
			if (bestColor < 0 || maxSize < bestMax) {
				bestColor = color;
				bestMax = maxSize;
			}
		}
		for (let i = 0; i < length; i++) {
			this.cells[cells[i]] = bestColor;
		}
		return true;
	}

	/** 从高处向下填充指定空格（视觉上像从顶部落下）。 */
	private fillSlots(slots: number[], maxGroup: number): void {
		const total = BlockDefs.placeableCount();
		for (let i = slots.length - 1; i >= 0; i--) {
			const flat = slots[i];
			const col = flat % this.columns;
			const row = Math.floor(flat / this.columns);
			let best = Math.floor(Math.random() * total);
			let bestSize = 0;
			for (let retry = 0; retry < Config.CellColorRetries; retry++) {
				const candidate = Math.floor(Math.random() * total);
				this.cells[flat] = candidate;
				const size = this.connectedSize(col, row);
				if (size <= maxGroup) {
					best = candidate;
					break;
				}
				if (best < 0 || size < bestSize) {
					best = candidate;
					bestSize = size;
				}
			}
			this.cells[flat] = best;
		}
	}

	/** 以“字形文字”输出棋盘，便于日志、自检与人工核对。 */
	toText(): string {
		const lines: string[] = [];
		for (let row = this.rows - 1; row >= 0; row--) {
			let line = '';
			for (let col = 0; col < this.columns; col++) {
				const index = this.cellIndex(col, row);
				line += index < 0 ? '.' : BlockDefs.at(index).glyph;
			}
			lines.push(line);
		}
		return lines.join('\n');
	}

	private resetCells(): void {
		this.cells = [];
		this.lockTimers = [];
		const total = this.columns * this.rows;
		for (let i = 0; i < total; i++) {
			this.cells.push(-1);
			this.lockTimers.push(0);
		}
		this.lastExpired = 0;
	}

	private makeVisited(): boolean[] {
		const visited: boolean[] = [];
		for (let i = 0; i < this.cells.length; i++) {
			visited.push(false);
		}
		return visited;
	}

	/** 广度优先统计并标记同色连通块。 */
	private measureGroup(col: number, row: number, visited: boolean[], target: number): number {
		const stack: number[] = [this.flatIndex(col, row)];
		visited[this.flatIndex(col, row)] = true;
		let count = 0;
		while (stack.length > 0) {
			const current = stack.pop();
			if (current === undefined) {
				break;
			}
			count++;
			const c = current % this.columns;
			const r = Math.floor(current / this.columns);
			this.pushNeighbor(stack, visited, c - 1, r, target);
			this.pushNeighbor(stack, visited, c + 1, r, target);
			this.pushNeighbor(stack, visited, c, r - 1, target);
			this.pushNeighbor(stack, visited, c, r + 1, target);
		}
		return count;
	}

	/** 收集并标记同色连通块的全部格子。 */
	private collectGroup(col: number, row: number, visited: boolean[], target: number): number[] {
		const stack: number[] = [this.flatIndex(col, row)];
		const group: number[] = [];
		visited[this.flatIndex(col, row)] = true;
		while (stack.length > 0) {
			const current = stack.pop();
			if (current === undefined) {
				break;
			}
			group.push(current);
			const c = current % this.columns;
			const r = Math.floor(current / this.columns);
			this.pushNeighbor(stack, visited, c - 1, r, target);
			this.pushNeighbor(stack, visited, c + 1, r, target);
			this.pushNeighbor(stack, visited, c, r - 1, target);
			this.pushNeighbor(stack, visited, c, r + 1, target);
		}
		return group;
	}

	private pushNeighbor(stack: number[], visited: boolean[], col: number, row: number, target: number): void {
		if (!this.inside(col, row)) {
			return;
		}
		const flat = this.flatIndex(col, row);
		if (visited[flat] || this.cells[flat] !== target) {
			return;
		}
		visited[flat] = true;
		stack.push(flat);
	}

	private randomFill(maxGroup: number): void {
		const total = BlockDefs.placeableCount();
		for (let row = 0; row < this.rows; row++) {
			for (let col = 0; col < this.columns; col++) {
				const flat = this.flatIndex(col, row);
				let best = -1;
				let bestSize = 0;
				for (let retry = 0; retry < Config.CellColorRetries; retry++) {
					const candidate = Math.floor(Math.random() * total);
					this.cells[flat] = candidate;
					const size = this.connectedSize(col, row);
					if (size <= maxGroup) {
						best = candidate;
						bestSize = size;
						break;
					}
					if (best < 0 || size < bestSize) {
						best = candidate;
						bestSize = size;
					}
				}
				this.cells[flat] = best;
			}
		}
	}
}

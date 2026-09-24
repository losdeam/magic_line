// 棋盘视图与手势：7×7 BlockWidget 池、路径高亮、touch.location → 格子换算。
// 松手时把连线解析为效果列表（M1 只产出结果，M2 起负责移除与补充）。

import { Color, DrawNode, Node, Size, Vec2 } from 'Dora';
import { Board } from 'game/Board';
import { BlockDefs } from 'game/BlockDefs';
import { Config } from 'game/Config';
import { EffectSpec, resolveEffects } from 'game/Effects';
import { BlockWidget } from 'game/ui/BlockWidget';

/** 一次松手结算出来的连线结果。 */
export interface ChainResult {
	blockId: string;
	chainLength: number;
	cells: number[];
	specs: EffectSpec[];
}

export class BoardView {
	readonly root: Node.Type;
	readonly board: Board;
	private readonly widgets: BlockWidget[] = [];
	private readonly highlight: DrawNode.Type;
	private readonly flashLayer: DrawNode.Type;
	/** 技能释放动画层：在受影响格子上扫过一片亮光（位于高亮之上）。 */
	private readonly pulseLayer: DrawNode.Type;
	private chain: number[] = [];
	private pending: ChainResult | undefined;
	private flashCells: number[] = [];
	private flashTimer = 0;
	private readonly flashDuration = 0.22;
	/** 技能扫光：剩余时间、受影响格子与总时长。 */
	private pulseCells: number[] = [];
	private pulseTimer = 0;
	private readonly pulseDuration = 0.8;
	/**
	 * 掉落动画：目标格（flat 下标）、每格的起始偏移量与剩余时间。
	 * 有目标格的方块会从旧格中心滑向自己的格中心，避免塔落后"瞬移"。
	 */
	private fallCells: number[] = [];
	private fallOffsetsX: number[] = [];
	private fallOffsetsY: number[] = [];
	private fallTimer = 0;
	private readonly fallDuration = 0.18;
	/** 上一次触点位置：用于快速滑动时的逐格插值采样。 */
	private lastX = 0;
	private lastY = 0;

	constructor(board: Board) {
		this.board = board;
		const span = Config.Columns * Config.CellSize;
		const root = Node();
		root.size = Size(span, span);
		root.anchor = Vec2(0.5, 0.5);
		root.touchEnabled = true;
		this.root = root;

		for (let row = 0; row < board.rows; row++) {
			for (let col = 0; col < board.columns; col++) {
				const index = board.cellIndex(col, row);
				const widget = new BlockWidget(BlockDefs.at(index), Config.CellSize);
				widget.addTo(root);
				widget.setPosition(this.cellCenterX(col), this.cellCenterY(row));
				this.widgets.push(widget);
			}
		}

		// 消除爆点与路径高亮各用一个画布：互不擦除，爆点未播完也能继续拖动
		const flashLayer = DrawNode();
		flashLayer.z = 10;
		flashLayer.addTo(root);
		this.flashLayer = flashLayer;

		const highlight = DrawNode();
		highlight.z = 11;
		highlight.addTo(root);
		this.highlight = highlight;

		const pulseLayer = DrawNode();
		pulseLayer.z = 12;
		pulseLayer.addTo(root);
		this.pulseLayer = pulseLayer;

		root.onTapBegan((touch) => this.press(touch.location));
		root.onTapMoved((touch) => this.move(touch.location));
		root.onTapEnded((touch) => this.release(touch.location));
	}

	get chainLength(): number {
		return this.chain.length;
	}

	/** 取出并清空待结算的连线结果（由 Game 的单一循环消费）。 */
	takePendingResult(): ChainResult | undefined {
		const result = this.pending;
		this.pending = undefined;
		return result;
	}

	/** 直接提交一条路径并立即结算，供自动化测试注入“真实连线”。 */
	submitChain(cells: number[]): void {
		this.endFlash();
		this.chain = [];
		for (const cell of cells) {
			this.appendCell(cell);
		}
		this.finish();
	}

	update(dt: number): void {
		this.advancePulse(dt);
		this.advanceFall(dt);
		if (this.flashTimer <= 0) {
			return;
		}
		this.flashTimer -= dt;
		if (this.flashTimer <= 0) {
			this.endFlash();
			return;
		}
		// 淡出的白色爆点：让“哪些块被消除”一眼可见（必须画在 flashLayer，
		// 画到 highlight 会永久残留白块并在下一帧叠成不透明色块）
		const alpha = Math.floor(255 * (this.flashTimer / this.flashDuration));
		const half = Config.CellSize * 0.34;
		this.flashLayer.clear();
		for (const flat of this.flashCells) {
			const center = this.cellCenter(flat);
			this.flashLayer.drawPolygon(
				[
					Vec2(center.x - half, center.y - half),
					Vec2(center.x + half, center.y - half),
					Vec2(center.x + half, center.y + half),
					Vec2(center.x - half, center.y + half),
				],
				Color(255, 255, 255, alpha)
			);
		}
	}

	/**
	 * 技能释放动画：在被技能改动的格子上从左向右扫过一片亮光。
	 * 传入空列表（例如重排后无法逐格比对）时整盘横扫。
	 */
	skillCast(cells: number[]): void {
		this.pulseCells = [];
		if (cells.length === 0) {
			for (let flat = 0; flat < this.widgets.length; flat++) {
				this.pulseCells.push(flat);
			}
		} else {
			for (const flat of cells) {
				if (flat >= 0 && flat < this.widgets.length) {
					this.pulseCells.push(flat);
				}
			}
		}
		this.pulseTimer = this.pulseCells.length > 0 ? this.pulseDuration : 0;
	}

	/** 是否正在播放技能扫光（自检与调试用）。 */
	get isCasting(): boolean {
		return this.pulseTimer > 0;
	}

	/** 推进技能扫光：每格按列号延迟出现，亮起后淡出，形成一道横扫的亮光。 */
	private advancePulse(dt: number): void {
		if (this.pulseTimer <= 0) {
			return;
		}
		this.pulseTimer -= dt;
		if (this.pulseTimer <= 0) {
			this.pulseTimer = 0;
			this.pulseLayer.clear();
			return;
		}
		const progress = 1 - this.pulseTimer / this.pulseDuration;
		const columns = this.board.columns;
		const half = Config.CellSize * 0.42;
		this.pulseLayer.clear();
		for (const flat of this.pulseCells) {
			const col = flat % columns;
			const local = (progress - (col / columns) * 0.45) / 0.45;
			if (local <= 0 || local >= 1) {
				continue;
			}
			const alpha = Math.floor(180 * (1 - local));
			const center = this.cellCenter(flat);
			this.pulseLayer.drawPolygon(
				[
					Vec2(center.x - half, center.y - half),
					Vec2(center.x + half, center.y - half),
					Vec2(center.x + half, center.y + half),
					Vec2(center.x - half, center.y + half),
				],
				Color(120, 220, 255, alpha),
				3,
				Color(210, 245, 255, Math.floor(alpha * 0.8))
			);
		}
	}

	/**
	 * 掉落动画：按棋盘给出的塔落轨迹，让方块从旧格中心滑到新格中心；
	 * 新补充的方块从棋盘上方落下。必须在 refreshFromBoard() 之前调用。
	 */
	animateFall(moves: number[], spawns: number[]): void {
		this.fallCells = [];
		this.fallOffsetsX = [];
		this.fallOffsetsY = [];
		const columns = this.board.columns;
		for (let i = 0; i + 1 < moves.length; i += 2) {
			const from = moves[i];
			const to = moves[i + 1];
			if (to < 0 || to >= this.widgets.length) {
				continue;
			}
			const target = this.cellCenter(to);
			const source = this.cellCenter(from);
			this.fallCells.push(to);
			this.fallOffsetsX.push(source.x - target.x);
			this.fallOffsetsY.push(source.y - target.y);
		}
		for (const flat of spawns) {
			if (flat < 0 || flat >= this.widgets.length) {
				continue;
			}
			const row = Math.floor(flat / columns);
			this.fallCells.push(flat);
			this.fallOffsetsX.push(0);
			this.fallOffsetsY.push((this.board.rows - row) * Config.CellSize);
		}
		this.fallTimer = this.fallCells.length > 0 ? this.fallDuration : 0;
		if (this.fallTimer <= 0) {
			this.resetFallPositions();
		}
	}

	/** 是否正在播放掉落动画（自检与调试用）。 */
	get isFalling(): boolean {
		return this.fallTimer > 0;
	}

	/** 立即结束掉落动画并复位位置（玩家抢在动画结束前操作时调用）。 */
	finishFall(): void {
		this.fallTimer = 0;
		this.resetFallPositions();
	}

	/** 指定格子控件当前相对格中心的偏移量（自检用：验证掉落动画确实产生了位移）。 */
	fallOffset(flat: number): Vec2.Type {
		if (flat < 0 || flat >= this.widgets.length) {
			return Vec2(0, 0);
		}
		const col = flat % this.board.columns;
		const row = Math.floor(flat / this.board.columns);
		const position = this.widgets[flat].root.position;
		return Vec2(position.x - this.cellCenterX(col), position.y - this.cellCenterY(row));
	}

	private resetFallPositions(): void {
		for (const flat of this.fallCells) {
			if (flat < 0 || flat >= this.widgets.length) {
				continue;
			}
			const col = flat % this.board.columns;
			const row = Math.floor(flat / this.board.columns);
			this.widgets[flat].setPosition(this.cellCenterX(col), this.cellCenterY(row));
		}
	}

	/** 推进掉落动画：先用靠近就位的缓出插值，到位后把位置精确归位。 */
	private advanceFall(dt: number): void {
		if (this.fallTimer <= 0) {
			return;
		}
		this.fallTimer -= dt;
		const progress = this.fallTimer <= 0 ? 1 : 1 - this.fallTimer / this.fallDuration;
		const inv = 1 - progress;
		const eased = 1 - inv * inv;
		const remain = 1 - eased;
		for (let i = 0; i < this.fallCells.length; i++) {
			const flat = this.fallCells[i];
			const col = flat % this.board.columns;
			const row = Math.floor(flat / this.board.columns);
			this.widgets[flat].setPosition(
				this.cellCenterX(col) + this.fallOffsetsX[i] * remain,
				this.cellCenterY(row) + this.fallOffsetsY[i] * remain
			);
		}
		if (this.fallTimer <= 0) {
			this.fallTimer = 0;
			this.resetFallPositions();
		}
	}

	/**
	 * 结束消除爆点：清空闪光并重新按棋盘同步外观。
	 * 必须重新同步 setDef —— 否则被消除位置的格子会残留消除前的旧方块外观。
	 */
	endFlash(): void {
		if (this.flashTimer <= 0 && this.flashCells.length === 0) {
			return;
		}
		this.flashTimer = 0;
		this.flashCells = [];
		this.flashLayer.clear();
		this.refreshFromBoard();
	}

	/** 消除爆点反馈：短暂隐藏被消除格子的控件并叠加一次淡出闪光。 */
	flashCleared(cells: number[]): void {
		this.flashCells = [];
		for (const flat of cells) {
			if (flat < 0 || flat >= this.widgets.length) {
				continue;
			}
			this.flashCells.push(flat);
			this.widgets[flat].visible = false;
		}
		this.flashTimer = this.flashCells.length > 0 ? this.flashDuration : 0;
	}

	/** 是否正在播放消除反馈（其间忽略新的手势）。 */
	get isFlashing(): boolean {
		return this.flashTimer > 0;
	}

	/** 依据棋盘数据刷新全部方块控件（消除/塌落后调用；爆点中的格子暂不显示）。 */
	refreshFromBoard(): void {
		for (let row = 0; row < this.board.rows; row++) {
			for (let col = 0; col < this.board.columns; col++) {
				const flat = this.board.flatIndex(col, row);
				const index = this.board.cellIndex(col, row);
				const widget = this.widgets[flat];
				if (this.isFlashing && this.isFlashingCell(flat)) {
					widget.visible = false;
					continue;
				}
				if (index < 0) {
					widget.visible = false;
					continue;
				}
				widget.visible = true;
				widget.setDef(BlockDefs.at(index));
				// 封锁格（固定障碍）使用置暗表现；其余方块恢常。
				widget.setLocked(!BlockDefs.isPlaceable(index));
				// 剩余解除次数完全由棋盘计时数据驱动（未封锁格恒为 0）
				widget.setLockTurns(widget.locked ? this.board.lockTurnsAt(flat) : 0);
			}
		}
	}

	private isFlashingCell(flat: number): boolean {
		for (const cell of this.flashCells) {
			if (cell === flat) {
				return true;
			}
		}
		return false;
	}

	private cellCenterX(col: number): number {
		return (col + 0.5) * Config.CellSize;
	}

	private cellCenterY(row: number): number {
		return (row + 0.5) * Config.CellSize;
	}

	private cellCenter(flat: number): Vec2.Type {
		const col = flat % this.board.columns;
		const row = Math.floor(flat / this.board.columns);
		return Vec2(this.cellCenterX(col), this.cellCenterY(row));
	}

	/** 把触点位置换算为格子下标；越界返回 -1。 */
	private cellAt(location: Vec2.Type): number {
		const col = Math.floor(location.x / Config.CellSize);
		const row = Math.floor(location.y / Config.CellSize);
		if (!this.board.inside(col, row)) {
			return -1;
		}
		return this.board.flatIndex(col, row);
	}

	/** 手势入口（公开以便在无指针环境下做确定性自检）；爆点播放中同样可以操作。 */
	press(location: Vec2.Type): void {
		this.endFlash();
		this.finishFall();
		this.chain = [];
		this.lastX = location.x;
		this.lastY = location.y;
		this.appendCell(this.cellAt(location));
	}

	move(location: Vec2.Type): void {
		if (this.chain.length === 0) {
			return;
		}
		this.trackTo(location);
	}

	release(location: Vec2.Type): void {
		if (this.chain.length > 0) {
			this.trackTo(location);
		}
		this.finish();
	}

	/** 沿「上一次触点 → 当前触点」的线段按半格步长采样，快速滑动也能逐格选中。 */
	private trackTo(location: Vec2.Type): void {
		const dx = location.x - this.lastX;
		const dy = location.y - this.lastY;
		const dist = Math.sqrt(dx * dx + dy * dy);
		const step = Config.CellSize * 0.5;
		if (dist > step) {
			let samples = Math.floor(dist / step);
			if (samples > 16) {
				samples = 16;
			}
			for (let i = 1; i <= samples; i++) {
				const t = (i * step) / dist;
				this.appendToward(this.cellAt(Vec2(this.lastX + dx * t, this.lastY + dy * t)));
			}
		}
		this.lastX = location.x;
		this.lastY = location.y;
		this.appendToward(this.cellAt(location));
	}

	/** 追加目标格：跨格时先补中间格（最多 2 步），避免快速滑过导致链中断。 */
	private appendToward(flat: number): void {
		if (flat < 0) {
			return;
		}
		const columns = this.board.columns;
		for (let guard = 0; guard < 3; guard++) {
			const chain = this.chain;
			if (chain.length === 0) {
				this.appendCell(flat);
				return;
			}
			const tail = chain[chain.length - 1];
			if (tail === flat) {
				return;
			}
			const tailCol = tail % columns;
			const tailRow = Math.floor(tail / columns);
			const col = flat % columns;
			const row = Math.floor(flat / columns);
			const dc = col - tailCol;
			const dr = row - tailRow;
			const distance = Math.abs(dc) + Math.abs(dr);
			if (distance > 2) {
				return;
			}
			let nextCol = col;
			let nextRow = row;
			if (distance === 2) {
				// 斜向跨格：先沿变化较大的分量走一格，再由下一轮走到目标格
				if (Math.abs(dc) >= Math.abs(dr)) {
					nextCol = tailCol + (dc > 0 ? 1 : -1);
					nextRow = tailRow;
				} else {
					nextCol = tailCol;
					nextRow = tailRow + (dr > 0 ? 1 : -1);
				}
			}
			const before = chain.length;
			this.appendCell(this.board.flatIndex(nextCol, nextRow));
			if (this.chain.length === before) {
				return;
			}
		}
	}

	/** 当前被高亮选中的格子数量（自检与调试用）。 */
	selectedCount(): number {
		let count = 0;
		for (const widget of this.widgets) {
			if (widget.selected) {
				count++;
			}
		}
		return count;
	}

	/** 追加一格：支持原路回退，禁止斜向、跨越类型与重复经过。 */
	private appendCell(flat: number): void {
		if (flat < 0) {
			return;
		}
		const startCol = flat % this.board.columns;
		const startRow = Math.floor(flat / this.board.columns);
		if (!BlockDefs.isPlaceable(this.board.cellIndex(startCol, startRow))) {
			// 封锁格不可作为连线起点或途经格
			return;
		}
		const chain = this.chain;
		const length = chain.length;
		if (length === 0) {
			chain.push(flat);
			this.refreshHighlight();
			return;
		}
		if (chain[length - 1] === flat) {
			return;
		}
		if (length >= 2 && chain[length - 2] === flat) {
			chain.pop();
			this.refreshHighlight();
			return;
		}
		for (const cell of chain) {
			if (cell === flat) {
				return;
			}
		}
		if (!this.canFollow(chain[length - 1], flat)) {
			return;
		}
		chain.push(flat);
		this.refreshHighlight();
	}

	private canFollow(from: number, to: number): boolean {
		const columns = this.board.columns;
		const fromCol = from % columns;
		const fromRow = Math.floor(from / columns);
		const toCol = to % columns;
		const toRow = Math.floor(to / columns);
		if (!Board.areNeighbors(fromCol, fromRow, toCol, toRow)) {
			return false;
		}
		const fromIndex = this.board.cellIndex(fromCol, fromRow);
		const toIndex = this.board.cellIndex(toCol, toRow);
		if (!BlockDefs.isPlaceable(fromIndex) || !BlockDefs.isPlaceable(toIndex)) {
			// 封锁格不参与连线（两个封锁格的 cellIndex 相同，必须显式排除）
			return false;
		}
		return fromIndex === toIndex;
	}

	/** 指定格子是否处于封锁（不可连线）状态（自检与调试用）。 */
	isLockedAt(flat: number): boolean {
		if (flat < 0 || flat >= this.widgets.length) {
			return false;
		}
		return this.widgets[flat].locked;
	}

	/** 封锁格角标当前显示的剩余解除次数文本（自检与调试用；未封锁/越界为空串）。 */
	lockTurnsLabelAt(flat: number): string {
		if (flat < 0 || flat >= this.widgets.length) {
			return '';
		}
		return this.widgets[flat].badgeText;
	}

	private finish(): void {
		const chain = this.chain;
		const length = chain.length;
		this.chain = [];
		this.refreshHighlight();
		if (length < Config.MinChainLength) {
			return;
		}
		const first = chain[0];
		const col = first % this.board.columns;
		const row = Math.floor(first / this.board.columns);
		const index = this.board.cellIndex(col, row);
		if (index < 0) {
			return;
		}
		const def = BlockDefs.at(index);
		const cells: number[] = [];
		for (const cell of chain) {
			cells.push(cell);
		}
		this.pending = { blockId: def.id, chainLength: length, cells, specs: resolveEffects(def.rules, length) };
	}

	private refreshHighlight(): void {
		for (let i = 0; i < this.widgets.length; i++) {
			this.widgets[i].setSelected(false);
		}
		this.highlight.clear();
		const chain = this.chain;
		for (const flat of chain) {
			this.widgets[flat].setSelected(true);
		}
		for (let i = 0; i + 1 < chain.length; i++) {
			this.highlight.drawSegment(this.cellCenter(chain[i]), this.cellCenter(chain[i + 1]), 9, Color(255, 255, 255, 190));
		}
	}
}

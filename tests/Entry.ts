// 运行时自检入口（仅用于 Agent 验证，不参与正式游戏流程）。
// 报告写入项目根 .agent/test-results/m3.txt，首行为 passed / failed。
// 覆盖：纯逻辑自检 + 视图交互自检 + 运行时链路观测（魔力/伤害/棋盘兑底）+ 坐标探针。

import { App, Content, Director, Node, Path, Size, Vec2 } from 'Dora';
import { Board } from 'game/Board';
import { BlockDefs } from 'game/BlockDefs';
import { BoardView } from 'game/BoardView';
import { Combat } from 'game/Combat';
import { Config, Difficulty, GameMode } from 'game/Config';
import { EffectKind, EffectTarget, formatEffects, resolveEffects } from 'game/Effects';
import { Game } from 'game/Game';
import { Skills } from 'game/Skills';
import { findPlayableChain, runTests } from 'game/Tests';

function cellCenterPointFromFlat(flat: number): Vec2.Type {
	const col = flat % Config.Columns;
	const row = Math.floor(flat / Config.Columns);
	return Vec2((col + 0.5) * Config.CellSize, (row + 0.5) * Config.CellSize);
}

/** 视图交互自检：用确定性图案验证“触点 → 格子 → 连线 → 效果三元组”全链路。 */
function runViewChecks(): string {
	const failures: string[] = [];
	let checks = 0;
	const expect = (condition: boolean, message: string): void => {
		checks++;
		if (!condition && failures.length < 12) {
			failures.push(message);
		}
	};

	const physical = BlockDefs.indexOf(BlockDefs.Physical);
	const magic = BlockDefs.indexOf(BlockDefs.Magic);
	const status = BlockDefs.indexOf(BlockDefs.Status);
	const heal = BlockDefs.indexOf(BlockDefs.Heal);
	expect(physical >= 0 && magic >= 0 && status >= 0 && heal >= 0, '注册表缺少基础方块类型');

	// 确定性图案：逐行铺设固定类型，便于精确断言
	const board = new Board();
	const pattern: number[] = [physical, magic, status, heal, physical, magic, status];
	for (let row = 0; row < board.rows; row++) {
		for (let col = 0; col < board.columns; col++) {
			board.setCell(col, row, pattern[row]);
		}
	}

	const view = new BoardView(board);
	view.root.addTo(Director.entry);

	view.press(cellCenterPointFromFlat(board.flatIndex(0, 0)));
	expect(view.chainLength === 1, '按下后连线长度应为 1，实际 ' + view.chainLength);
	expect(view.selectedCount() === 1, '按下后高亮选中数应为 1，实际 ' + view.selectedCount());

	// 单格连线不满足链长下限
	view.release(cellCenterPointFromFlat(board.flatIndex(0, 0)));
	expect(view.takePendingResult() === undefined, '单格连线不应产出结果');

	view.press(cellCenterPointFromFlat(board.flatIndex(0, 0)));
	view.move(cellCenterPointFromFlat(board.flatIndex(1, 0)));
	view.move(cellCenterPointFromFlat(board.flatIndex(2, 0)));
	view.move(cellCenterPointFromFlat(board.flatIndex(3, 0)));
	expect(view.chainLength === 4, '滑过 4 格同色后连线长度应为 4，实际 ' + view.chainLength);

	view.move(cellCenterPointFromFlat(board.flatIndex(3, 1)));
	expect(view.chainLength === 4, '跨类型滑入不应增加连线，实际 ' + view.chainLength);

	view.move(cellCenterPointFromFlat(board.flatIndex(6, 6)));
	expect(view.chainLength === 4, '非相邻格不应加入连线，实际 ' + view.chainLength);

	view.move(cellCenterPointFromFlat(board.flatIndex(2, 0)));
	expect(view.chainLength === 3, '回退一格后连线长度应为 3，实际 ' + view.chainLength);

	view.release(cellCenterPointFromFlat(board.flatIndex(3, 0)));
	const result = view.takePendingResult();
	expect(result !== undefined, '松手后应产出连线结果');
	if (result !== undefined) {
		expect(result.blockId === BlockDefs.Physical, '连线类型应为 physical，实际 ' + result.blockId);
		expect(result.chainLength === 4, '松手时连线长度应为 4，实际 ' + result.chainLength);
		const expected = resolveEffects(BlockDefs.at(physical).rules, 4);
		expect(result.specs.length === expected.length, '效果条目数应与规则解析一致');
		const first = result.specs[0];
		expect(first.kind === EffectKind.PhysicalDamage, '物理方块应产出 physicalDamage');
		expect(first.target === EffectTarget.CurrentEnemy, '物理伤害应作用于当前敌人');
		expect(first.value === 16, '物理伤害 4+3×4 应为 16，实际 ' + first.value);
		expect(formatEffects(result.specs).indexOf('物理伤害 16') === 0, '效果文本应为“物理伤害 16 …”，实际 ' + formatEffects(result.specs));
	}

	// 链长下限为 2：两格连线即可生效
	view.press(cellCenterPointFromFlat(board.flatIndex(5, 0)));
	view.move(cellCenterPointFromFlat(board.flatIndex(6, 0)));
	view.release(cellCenterPointFromFlat(board.flatIndex(6, 0)));
	const shortResult = view.takePendingResult();
	expect(shortResult !== undefined, '链长 2 应产出结果（链长下限为 ' + Config.MinChainLength + '）');
	if (shortResult !== undefined) {
		expect(shortResult.chainLength === 2, '短链长度应为 2，实际 ' + shortResult.chainLength);
	}
	expect(view.selectedCount() === 0, '结算后应清除全部高亮，实际 ' + view.selectedCount());

	// M5 封锁格：视图应反映锁定状态，且封锁格不可作为连线起点或途经格
	const lockedIndex = BlockDefs.lockedIndex();
	expect(lockedIndex >= 0, '注册表应包含封锁格定义');
	const lockBoard = new Board();
	for (let row = 0; row < lockBoard.rows; row++) {
		for (let col = 0; col < lockBoard.columns; col++) {
			lockBoard.setCell(col, row, pattern[row]);
		}
	}
	lockBoard.setCell(0, 0, lockedIndex);
	const lockView = new BoardView(lockBoard);
	lockView.root.addTo(Director.entry);
	lockView.refreshFromBoard();
	expect(lockView.isLockedAt(lockBoard.flatIndex(0, 0)), '封锁格应在视图中标记为锁定');
	expect(!lockView.isLockedAt(lockBoard.flatIndex(1, 0)), '普通方块不应被标记为锁定');
	lockView.press(cellCenterPointFromFlat(lockBoard.flatIndex(0, 0)));
	expect(lockView.chainLength === 0, '封锁格不应能作为连线起点，实际 ' + lockView.chainLength);
	lockView.release(cellCenterPointFromFlat(lockBoard.flatIndex(0, 0)));
	expect(lockView.takePendingResult() === undefined, '从封锁格起手不应产出连线结果');
	lockView.press(cellCenterPointFromFlat(lockBoard.flatIndex(1, 0)));
	lockView.move(cellCenterPointFromFlat(lockBoard.flatIndex(0, 0)));
	expect(lockView.chainLength === 1, '封锁格不应可途经，实际 ' + lockView.chainLength);
	lockView.release(cellCenterPointFromFlat(lockBoard.flatIndex(0, 0)));
	expect(lockView.takePendingResult() === undefined, '仅 1 格连线不应产出结果');
	lockView.refreshFromBoard();
	expect(lockView.isLockedAt(lockBoard.flatIndex(0, 0)), '刷新棋盘后封锁格应仍为锁定表现');

	const head = failures.length === 0 ? 'passed' : 'failed';
	const lines: string[] = [head];
	lines.push('交互检查 ' + checks + ' 项，失败 ' + failures.length + ' 项');
	for (const failure of failures) {
		lines.push(' - ' + failure);
	}
	return lines.join('\n');
}

/**
 * 运行时观测：用真实触点坐标注入连线，并把效果交给 Combat 结算；
 * 最后强制制造“不可执行棋盘”，验证重排惩罚与视图刷新集成。
 */
function runRuntimeChecks(): string {
	const failures: string[] = [];
	let checks = 0;
	const expect = (condition: boolean, message: string): void => {
		checks++;
		if (!condition && failures.length < 12) {
			failures.push(message);
		}
	};

	const board = new Board();
	const view = new BoardView(board);
	view.root.addTo(Director.entry);
	const combat = new Combat(board);

	let operations = 0;
	let resolved = 0;
	let rejected = 0;
	let fullFails = 0;
	let autoResets = 0;
	const enemyHpStart = combat.enemy.hp;

	for (let i = 0; i < 40; i++) {
		const chain = findPlayableChain(board, Config.MinChainLength, 3 + Math.floor(Math.random() * 4));
		if (chain.length === 0) {
			continue;
		}
		view.press(cellCenterPointFromFlat(chain[0]));
		for (let k = 1; k < chain.length; k++) {
			view.move(cellCenterPointFromFlat(chain[k]));
		}
		view.release(cellCenterPointFromFlat(chain[chain.length - 1]));
		operations++;
		const result = view.takePendingResult();
		if (result === undefined) {
			rejected++;
			continue;
		}
		resolved++;
		const cellCol = result.cells[0] % board.columns;
		const cellRow = Math.floor(result.cells[0] / board.columns);
		const index = board.cellIndex(cellCol, cellRow);
		if (index >= 0) {
			combat.applySpecs(resolveEffects(BlockDefs.at(index).rules, result.chainLength));
		}
		board.applyChain(result.cells);
		view.refreshFromBoard();
		const notice = combat.ensureBoardPlayable();
		if (notice !== undefined) {
			autoResets++;
			view.refreshFromBoard();
		}
		if (!board.isFull()) {
			fullFails++;
		}
	}

	expect(operations >= 35, '运行时注入操作次数应 ≥ 35，实际 ' + operations);
	expect(resolved >= 35, '经真实触点链路解析的连线应 ≥ 35，实际 ' + resolved);
	expect(resolved + rejected === operations, '解析与被拒次数之和应等于操作次数');
	expect(fullFails === 0, '连续消除后出现非满格：' + fullFails + ' 次');
	expect(combat.player.mana > 0, '连续消除后魔力应大于 0，实际 ' + combat.player.mana);
	expect(combat.enemy.hp < enemyHpStart, '连续消除后敌人生命应下降：' + enemyHpStart + ' → ' + combat.enemy.hp);
	expect(board.deadlockWarningCount === 0, '补充后出现无解棋盘：' + board.deadlockWarningCount + ' 次');

	// 强制兑底：把现场棋盘改成无相邻同色对，触发重排 + 惩罚
	const manaBeforePenalty = combat.player.mana;
	for (let row = 0; row < board.rows; row++) {
		for (let col = 0; col < board.columns; col++) {
			board.setCell(col, row, (col + row) % 2);
		}
	}
	expect(!board.isPlayable(), '强制制造的棋盘应不可执行');
	const hpBeforePenalty = combat.player.hp;
	const notice = combat.ensureBoardPlayable();
	expect(notice !== undefined, '不可执行时应返回提示文本');
	expect(combat.boardResetCount === 1, '应记录一次棋盘重排，实际 ' + combat.boardResetCount);
	expect(combat.player.hp === hpBeforePenalty - Config.BoardResetPenalty, '重排惩罚应扣除 ' + Config.BoardResetPenalty + ' 点生命，实际 ' + (hpBeforePenalty - combat.player.hp));
	expect(board.isFull() && board.isPlayable(), '重排后棋盘应满格且可执行');
	expect(combat.player.mana === manaBeforePenalty, '重排惩罚不应扣魔力');

	// 兑底后视图可正常刷新并可继续连线
	view.refreshFromBoard();
	const afterResetChain = findPlayableChain(board, Config.MinChainLength, 4);
	view.press(cellCenterPointFromFlat(afterResetChain[0]));
	if (afterResetChain.length > 1) {
		view.move(cellCenterPointFromFlat(afterResetChain[1]));
	}
	view.release(cellCenterPointFromFlat(afterResetChain[afterResetChain.length - 1]));
	expect(view.takePendingResult() !== undefined, '重排后仍应能通过触点产出连线结果');

	// 技能：攒够魔力后释放（重排棋盘）
	combat.player.mana = 60;
	const shuffleResult = combat.useSkill(Skills.Shuffle);
	expect(shuffleResult.ok, '魔力足够时重排技能应成功：' + shuffleResult.message);
	expect(combat.player.mana === 40, '重排技能应扣 20 魔力，实际 ' + combat.player.mana);
	expect(board.isFull() && board.isPlayable(), '重排技能后棋盘应满格且可执行');
	view.refreshFromBoard();

	// 技能扫光动画：启动后应处于播放中，推进后自动结束（不留残影层）
	view.skillCast([]);
	expect(view.isCasting, '技能扫光应进入播放状态');
	view.update(1.2);
	expect(!view.isCasting, '技能扫光应在时长结束后自动停止');

	// 消除爆点动画：同样应在推进后自动结束并恢复棋盘外观
	view.flashCleared([board.flatIndex(0, 0), board.flatIndex(1, 0)]);
	expect(view.isFlashing, '消除爆点应进入播放状态');
	view.update(1.2);
	expect(!view.isFlashing, '消除爆点应在时长结束后自动停止');
	view.refreshFromBoard();

	// 掉落动画：塌落轨迹应被记录，动画应能启动并在推进后自动结束（不残留位移）
	const fallBoard = new Board();
	const fallChain = findPlayableChain(fallBoard, Config.MinChainLength, 5);
	expect(fallChain.length >= Config.MinChainLength, '掉落夹具应能取到一条可消除连线');
	fallBoard.applyChain(fallChain);
	expect(fallBoard.collapseMoves.length % 2 === 0 && fallBoard.collapseMoves.length > 0, '塌落应记录成对移动轨迹，实际 ' + fallBoard.collapseMoves.length);
	expect(fallBoard.collapseSpawns.length > 0, '塌落应记录腾空格子供落下动画使用');
	view.animateFall([board.flatIndex(0, 6), board.flatIndex(0, 0)], [board.flatIndex(0, 6)]);
	expect(view.isFalling, '掉落动画应进入播放状态');
	view.update(0.05);
	const midOffset = view.fallOffset(board.flatIndex(0, 0));
	expect(Math.abs(midOffset.y) > 1, '掉落动画中途应产生可见位移，实际 ' + midOffset.y);
	view.update(1.2);
	expect(!view.isFalling, '掉落动画应在时长结束后自动停止并复位位置');
	const endOffset = view.fallOffset(board.flatIndex(0, 0));
	expect(Math.abs(endOffset.x) < 0.01 && Math.abs(endOffset.y) < 0.01, '掉落动画结束后方块应精确归位到格中心');

	// M5 封锁格（棋盘效果）：封锁后视图应反映锁定外观，且封锁格不得参与连线或计入最大块
	const lockedPlaced = board.blockCells(Config.EliteHeavyBlockCells);
	expect(lockedPlaced === Config.EliteHeavyBlockCells, '封锁 ' + Config.EliteHeavyBlockCells + ' 格应全部成功，实际 ' + lockedPlaced);
	expect(board.isFull() && board.isPlayable(), '封锁后棋盘应仍满格且可执行');
	view.refreshFromBoard();
	const lockedFlats: number[] = [];
	for (let flat = 0; flat < board.columns * board.rows; flat++) {
		if (view.isLockedAt(flat)) {
			lockedFlats.push(flat);
		}
	}
	expect(lockedFlats.length === lockedPlaced, '视图中的锁定格数应与棋盘一致，实际 ' + lockedFlats.length + '/' + lockedPlaced);
	const lockedFlat = lockedFlats[0];
	view.press(cellCenterPointFromFlat(lockedFlat));
	expect(view.chainLength === 0, '封锁格不应能作为连线起点，实际 ' + view.chainLength);
	view.release(cellCenterPointFromFlat(lockedFlat));
	expect(view.takePendingResult() === undefined, '从封锁格起手不应产出连线结果');
	const lockedCol = lockedFlat % board.columns;
	const lockedRow = Math.floor(lockedFlat / board.columns);
	// 两个封锁格可能彼此相邻，因此不能固定取某一方向：挑一个非封锁的上下左右邻格作起手点
	let nearFlat = -1;
	const deltaCols = [-1, 1, 0, 0];
	const deltaRows = [0, 0, -1, 1];
	for (let i = 0; i < deltaCols.length; i++) {
		const col = lockedCol + deltaCols[i];
		const row = lockedRow + deltaRows[i];
		if (col < 0 || col >= board.columns || row < 0 || row >= board.rows) {
			continue;
		}
		if (BlockDefs.isPlaceable(board.cellIndex(col, row))) {
			nearFlat = board.flatIndex(col, row);
			break;
		}
	}
	expect(nearFlat >= 0, '封锁格应至少存在一个非封锁邻格');
	view.press(cellCenterPointFromFlat(nearFlat));
	expect(view.chainLength === 1, '非封锁邻格起手应形成 1 长连线，实际 ' + view.chainLength);
	view.move(cellCenterPointFromFlat(lockedFlat));
	expect(view.chainLength === 1, '封锁格不应可途经，实际 ' + view.chainLength);
	view.release(cellCenterPointFromFlat(lockedFlat));
	view.takePendingResult();
	const largest = board.largestGroupCells();
	let largestLocked = 0;
	for (const flat of largest) {
		const col = flat % board.columns;
		const row = Math.floor(flat / board.columns);
		if (!BlockDefs.isPlaceable(board.cellIndex(col, row))) {
			largestLocked++;
		}
	}
	expect(largestLocked === 0, '最大连通块不应包含封锁格，实际 ' + largestLocked);

	// M5 封锁到期：计时随敌人行动递减，到期后自动恢复为常规方块且视图同步解除锁定
	expect(board.lockedCount() === lockedFlats.length, '封锁计数应与棋盘一致，实际 ' + board.lockedCount());
	let lockTurnsNow = 0;
	for (const flat of lockedFlats) {
		if (board.lockTurnsAt(flat) > lockTurnsNow) {
			lockTurnsNow = board.lockTurnsAt(flat);
		}
	}
	expect(lockTurnsNow === Config.LockDurationActions, '封锁格应记录 ' + Config.LockDurationActions + ' 次敌人行动计时，实际 ' + lockTurnsNow);
	view.refreshFromBoard();
	expect(view.lockTurnsLabelAt(lockedFlat) === '' + Config.LockDurationActions, '封锁格应显示剩余 ' + Config.LockDurationActions + ' 次敌人行动，实际「' + view.lockTurnsLabelAt(lockedFlat) + '」');
	const badgeStart = view.lockTurnsLabelAt(lockedFlat);
	board.expireLocks();
	expect(board.lockedCount() === lockedFlats.length, '未到期时封锁不应解除，实际剩余 ' + board.lockedCount());
	view.refreshFromBoard();
	expect(view.lockTurnsLabelAt(lockedFlat) === '' + (Config.LockDurationActions - 1), '封锁剩余次数应随敌人行动递减显示，实际「' + view.lockTurnsLabelAt(lockedFlat) + '」');
	const badgeAfterOne = view.lockTurnsLabelAt(lockedFlat);
	for (let i = 1; i < Config.LockDurationActions; i++) {
		board.expireLocks();
	}
	expect(board.lockedCount() === 0, '到期后封锁应全部自动恢复，实际剩余 ' + board.lockedCount());
	expect(board.isFull() && board.isPlayable(), '封锁恢复后棋盘应仍满格且可执行');
	view.refreshFromBoard();
	let stillLocked = 0;
	for (let flat = 0; flat < board.columns * board.rows; flat++) {
		if (view.isLockedAt(flat)) {
			stillLocked++;
		}
	}
	expect(stillLocked === 0, '封锁恢复后视图不应再标记锁定，实际 ' + stillLocked);
	expect(view.lockTurnsLabelAt(lockedFlat) === '', '封锁恢复后不应再显示剩余次数角标，实际「' + view.lockTurnsLabelAt(lockedFlat) + '」');
	const badgeAfterExpire = view.lockTurnsLabelAt(lockedFlat);
	view.refreshFromBoard();

	const head = failures.length === 0 ? 'passed' : 'failed';
	const lines: string[] = [head];
	lines.push('运行时操作 ' + operations + ' 次，解析连线 ' + resolved + ' 次，低于下限被拒 ' + rejected + ' 次，自动兑底 ' + autoResets + ' 次，检查 ' + checks + ' 项');
	lines.push('M5 封锁角标：封锁 ' + lockedFlats.length + ' 格，剩余次数「' + badgeStart + '」→「' + badgeAfterOne + '」→到期恢复后「' + badgeAfterExpire + '」；到期后视图锁定格 ' + stillLocked + ' 个');
	const sizes: string[] = [];
	for (const size of board.maxGroupSizes()) {
		sizes.push('' + size);
	}
	lines.push('棋盘：满格=' + board.isFull() + ' 可执行=' + board.isPlayable() + ' 各类型最大连通块 ' + sizes.join(',') + '；玩家 HP=' + combat.player.hp + ' 魔力=' + combat.player.mana + ' 敌人 HP=' + combat.enemy.hp + '（起始 ' + enemyHpStart + '）');
	lines.push('已消除=' + board.clearedTotal + ' 连线次数=' + board.chainsTotal + ' 无解告警=' + board.deadlockWarningCount + ' 强制修复=' + board.forcedRepairs + ' 被动重排=' + combat.boardResetCount);
	for (const failure of failures) {
		lines.push(' - ' + failure);
	}
	return lines.join('\n');
}

/**
 * 主循环自检：直接驱动 Game + Hud 的完整结算路径（等价于玩家每次松手），
 * 用于覆盖“真实输入接入后才会走到”的代码，而不只是底层 Board/Combat。
 */
function runGameLoopChecks(): string {
	const failures: string[] = [];
	let checks = 0;
	const expect = (condition: boolean, message: string): void => {
		checks++;
		if (!condition && failures.length < 12) {
			failures.push(message);
		}
	};

	const scene = Node();
	scene.addTo(Director.entry);
	const game = new Game(scene);

	let injected = 0;
	for (let i = 0; i < 40; i++) {
		const chain = findPlayableChain(game.board, Config.MinChainLength, 4);
		if (chain.length === 0) {
			continue;
		}
		game.submitChain(chain);
		injected++;
		expect(game.board.isFull(), '第 ' + i + ' 次结算后棋盘非满格');
		expect(game.board.isPlayable(), '第 ' + i + ' 次结算后棋盘不可执行');
	}

	expect(injected >= 35, '注入结算次数应 ≥ 35，实际 ' + injected);
	expect(game.combat.enemy.hp >= 0, '敌人生命不应为负，实际 ' + game.combat.enemy.hp);
	expect(game.combat.player.hp >= 0, '玩家生命不应为负，实际 ' + game.combat.player.hp);
	expect(game.combat.stageNumber >= 1 && game.combat.waveNumber >= 1, '关卡/波次状态应有效');
	expect(game.combat.player.mana >= 0 && game.combat.player.mana <= Config.MaxMana, '魔力应在 [0,' + Config.MaxMana + '] 内');

	// 设置切换（运行时观测）：模式切换后战斗应改用秒级时间源，难度切换后敌人数值随之变化
	game.toggleMode();
	expect(game.combat.isRealtime, '切换后应处于实时模式');
	expect(game.settings.mode === GameMode.Realtime, '设置对象应记录为实时模式');
	const realtimeEnemyHp = game.combat.enemy.maxHp;
	game.toggleMode();
	expect(!game.combat.isRealtime, '再次切换应回到回合制');
	expect(game.settings.mode === GameMode.TurnBased, '设置对象应记录为回合制');
	const beforeDifficulty = game.combat.enemy.maxHp;
	game.cycleDifficulty();
	expect(game.combat.enemy.maxHp !== beforeDifficulty || game.settings.difficulty !== Difficulty.Standard, '切换难度后应刷新或记录难度，实际 HP ' + game.combat.enemy.maxHp + '/' + beforeDifficulty);
	game.toggleHint();
	expect(!game.settings.showHint, '提示开关应可关闭');
	game.toggleHint();
	expect(game.settings.showHint, '提示开关应可重新打开');
	expect(game.settings.saved, '设置应已成功写入存档');
	expect(realtimeEnemyHp > 0, '实时模式下敌人最大生命应为正数');

	const head = failures.length === 0 ? 'passed' : 'failed';
	const lines: string[] = [head];
	lines.push('主循环检查 ' + checks + ' 项，失败 ' + failures.length + ' 项；注入结算 ' + injected + ' 次');
	lines.push('状态：第 ' + game.combat.stageNumber + ' 关第 ' + game.combat.waveNumber + '/' + game.combat.waveCount + ' 波，玩家 HP=' + game.combat.player.hp + ' 魔力=' + game.combat.player.mana + '，敌人 HP=' + game.combat.enemy.hp + '/' + game.combat.enemy.maxHp + '，被动重排=' + game.combat.boardResetCount);
	for (const failure of failures) {
		lines.push(' - ' + failure);
	}
	return lines.join('\n');
}

/** 诊断信息：不参与 pass/fail 判定。 */
function runDiagnostics(): string {
	const lines: string[] = [];
	lines.push('Config：MinChainLength=' + Config.MinChainLength + ' MaxGroupSize=' + Config.MaxGroupSize + ' MaxMana=' + Config.MaxMana + ' 技能数=' + Skills.count());
	const fresh = new Board();
	const sizes: string[] = [];
	for (const size of fresh.maxGroupSizes()) {
		sizes.push('' + size);
	}
	lines.push('新棋盘各类型最大连通块 ' + sizes.join(',') + '；满格=' + fresh.isFull() + ' 可执行=' + fresh.isPlayable());
	let peak = 0;
	let boardsWithThree = 0;
	let playableCount = 0;
	for (let i = 0; i < 20; i++) {
		const board = new Board();
		let maxSize = 0;
		for (const size of board.maxGroupSizes()) {
			if (size > maxSize) {
				maxSize = size;
			}
		}
		if (maxSize > peak) {
			peak = maxSize;
		}
		if (maxSize >= 3) {
			boardsWithThree++;
		}
		if (board.isPlayable()) {
			playableCount++;
		}
	}
	lines.push('20 个新棋盘：最大连通块峰值 ' + peak + '，含 ≥3 连的棋盘 ' + boardsWithThree + '/20，可执行 ' + playableCount + '/20');
	lines.push('新棋盘字形图（上到下 = row6 → row0）:');
	lines.push(fresh.toText());
	return lines.join('\n');
}

const resultDir = Path(Content.searchPaths[0], '.agent', 'test-results');
if (!Content.exist(resultDir)) {
	Content.mkdir(resultDir);
}

const node = Node();
node.addTo(Director.entry);

// 坐标约定探针：确认“有尺寸节点的子节点局部原点”在矩形左下角还是节点中心。
const probe = Node();
probe.size = Size(200, 100);
probe.anchor = Vec2(0.5, 0.5);
probe.position = Vec2(0, 0);
probe.addTo(Director.entry);
const probeOrigin = probe.convertToWorldSpace(Vec2(0, 0));

let reported = false;
node.schedule((_dt) => {
	if (reported) {
		return true;
	}
	reported = true;
	const logic = runTests();
	const view = runViewChecks();
	const runtime = runRuntimeChecks();
	const loop = runGameLoopChecks();
	const ok = logic.indexOf('failed') !== 0 && view.indexOf('failed') !== 0 && runtime.indexOf('failed') !== 0 && loop.indexOf('failed') !== 0;
	const lines: string[] = [ok ? 'passed' : 'failed'];
	lines.push('runTime=' + App.runningTime + '（用于区分旧报告文件）');
	lines.push('--- 逻辑自检（game/Tests.ts） ---');
	lines.push(logic);
	lines.push('--- 视图交互自检（触点→格子→连线→效果三元组） ---');
	lines.push(view);
	lines.push('--- 运行时链路观测（含魔力/伤害/棋盘兑底） ---');
	lines.push(runtime);
	lines.push('--- 主循环自检（Game + Hud 完整结算路径） ---');
	lines.push(loop);
	lines.push('--- 坐标原点探针 ---');
	lines.push('localOrigin=(' + probeOrigin.x + ',' + probeOrigin.y + ')；(-100,-50) 表示子节点原点在矩形左下角');
	lines.push('--- 诊断（不参与判定） ---');
	lines.push(runDiagnostics());
	Content.save(Path(resultDir, 'm3.txt'), lines.join('\n'));
	return true;
});

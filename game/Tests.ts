// 自动化自检：导出 runTests()，返回首行为 passed / failed 的报告。
// 只做纯逻辑校验，不创建任何场景节点（运行存活由真实入口单独验证）。

import { Content } from 'Dora';
import { Board } from 'game/Board';
import { BlockDefs } from 'game/BlockDefs';
import { Combat, EnemyAction } from 'game/Combat';
import { Config, Difficulty, GameMode } from 'game/Config';
import { EffectKind, EffectSpec, EffectTarget, resolveEffects, unhandledEffectCount } from 'game/Effects';
import { Settings } from 'game/Settings';
import { Skills } from 'game/Skills';
import { HudLayout, SafeBox, boardLayoutRect, hudLayoutRects, insideSafeBox, visibleHalfExtent } from 'game/UiLayout';

function collectOption(board: Board, options: number[], used: boolean[], col: number, row: number, type: number): void {
	if (!board.inside(col, row)) {
		return;
	}
	const flat = board.flatIndex(col, row);
	if (used[flat] || board.cellIndex(col, row) !== type) {
		return;
	}
	options.push(flat);
}

/**
 * 确定性地取一条长度 ≥ minLength 的同色相邻链（用于模拟玩家操作与运行时自检）。
 * 逐格起点的深度优先回溯，只要棋盘存在可连线区域就一定能找到，避免随机游走撞死角。
 */
export function findPlayableChain(board: Board, minLength: number, maxLength: number): number[] {
	const total = board.columns * board.rows;
	for (let start = 0; start < total; start++) {
		const col = start % board.columns;
		const row = Math.floor(start / board.columns);
		const type = board.cellIndex(col, row);
		if (type < 0) {
			continue;
		}
		const used: boolean[] = [];
		for (let i = 0; i < total; i++) {
			used.push(false);
		}
		const path: number[] = [start];
		used[start] = true;
		if (growPath(board, path, used, type, minLength, maxLength)) {
			return path;
		}
	}
	return [];
}

/** 深度优先扩展路径，直到长度达到 minLength（上限 maxLength）。 */
function growPath(board: Board, path: number[], used: boolean[], type: number, minLength: number, maxLength: number): boolean {
	if (path.length >= minLength) {
		return true;
	}
	if (path.length >= maxLength) {
		return false;
	}
	const last = path[path.length - 1];
	const col = last % board.columns;
	const row = Math.floor(last / board.columns);
	const options: number[] = [];
	collectOption(board, options, used, col - 1, row, type);
	collectOption(board, options, used, col + 1, row, type);
	collectOption(board, options, used, col, row - 1, type);
	collectOption(board, options, used, col, row + 1, type);
	for (const next of options) {
		used[next] = true;
		path.push(next);
		if (growPath(board, path, used, type, minLength, maxLength)) {
			return true;
		}
		path.pop();
		used[next] = false;
	}
	return false;
}

/** 从指定格子出发游走同色链（长度上限 maxLength），供运行时自检复用。 */
export function walkChainFrom(board: Board, flat: number, maxLength: number): number[] {
	const type = board.cellIndex(flat % board.columns, Math.floor(flat / board.columns));
	const chain: number[] = [];
	if (type < 0) {
		return chain;
	}
	const total = board.columns * board.rows;
	const used: boolean[] = [];
	for (let i = 0; i < total; i++) {
		used.push(false);
	}
	chain.push(flat);
	used[flat] = true;
	while (chain.length < maxLength) {
		const last = chain[chain.length - 1];
		const col = last % board.columns;
		const row = Math.floor(last / board.columns);
		const options: number[] = [];
		collectOption(board, options, used, col - 1, row, type);
		collectOption(board, options, used, col + 1, row, type);
		collectOption(board, options, used, col, row - 1, type);
		collectOption(board, options, used, col, row + 1, type);
		if (options.length === 0) {
			break;
		}
		const pick = options[Math.floor(Math.random() * options.length)];
		used[pick] = true;
		chain.push(pick);
	}
	return chain;
}

export function runTests(): string {
	const failures: string[] = [];
	let checks = 0;

	const expect = (condition: boolean, message: string): void => {
		checks++;
		if (condition) {
			return;
		}
		if (failures.length < 12) {
			failures.push(message);
		}
	};

	// 1. 注册表完整性：每个方块类型都能由链长产出非空的效果列表
	expect(BlockDefs.placeableCount() >= 4, '注册表至少应有 4 种可放置方块');
	for (let i = 0; i < BlockDefs.List.length; i++) {
		const def = BlockDefs.at(i);
		if (!def.placeable) {
			// 固定障碍（封锁格）：不参与生成与消除，因此也不应有效果规则
			expect(def.rules.length === 0, '不可放置的方块 ' + def.id + ' 不应带效果规则');
			continue;
		}
		expect(def.rules.length > 0, '方块 ' + def.id + ' 缺少效果规则');
		expect(resolveEffects(def.rules, Config.MinChainLength - 1).length === 0, '方块 ' + def.id + ' 在链长低于下限时不应产出效果');
		for (let n = Config.MinChainLength; n <= 9; n++) {
			const specs = resolveEffects(def.rules, n);
			expect(specs.length > 0, '方块 ' + def.id + ' 链长 ' + n + ' 未产出效果列表');
			for (const spec of specs) {
				expect(spec.value >= 1, '方块 ' + def.id + ' 链长 ' + n + ' 的效果数值应 ≥ 1，实际 ' + spec.value);
			}
		}
	}

	// 2. 棋盘生成约束 C1 / C2
	const sampleCount = 30;
	let fullCount = 0;
	let strictCount = 0;
	let boundedCount = 0;
	let playableCount = 0;
	for (let i = 0; i < sampleCount; i++) {
		const board = new Board();
		if (board.isFull()) {
			fullCount++;
		}
		let maxSize = 0;
		for (const size of board.maxGroupSizes()) {
			if (size > maxSize) {
				maxSize = size;
			}
		}
		if (maxSize <= Config.MaxGroupSize) {
			strictCount++;
		}
		if (maxSize <= Config.GroupSizeRelaxLimit) {
			boundedCount++;
		}
		if (board.hasPlayableRegion(Config.MinChainLength)) {
			playableCount++;
		}
	}
	expect(fullCount === sampleCount, '棋盘未满格：' + fullCount + '/' + sampleCount);
	expect(strictCount === sampleCount, 'C1 最大连通块超过 ' + Config.MaxGroupSize + '：' + strictCount + '/' + sampleCount + ' 达标');
	expect(boundedCount === sampleCount, '最大连通块超过放宽上限 ' + Config.GroupSizeRelaxLimit + '：' + boundedCount + '/' + sampleCount);
	expect(playableCount === sampleCount, 'C2 缺少可连线区域（所有颜色都无 ≥ ' + Config.MinChainLength + ' 连通）：' + playableCount + '/' + sampleCount);

	// 3. 相邻判定（连线合法性的基础）
	expect(Board.areNeighbors(0, 0, 1, 0), '水平相邻判定失败');
	expect(Board.areNeighbors(3, 3, 3, 4), '垂直相邻判定失败');
	expect(!Board.areNeighbors(0, 0, 1, 1), '斜向不应判为相邻');
	expect(!Board.areNeighbors(0, 0, 0, 0), '同一格不应判为相邻');

	// 4. 消除→塌落→补充：200 次随机操作后仍满格且约束成立
	const workBoard = new Board();
	let applied = 0;
	let fullFails = 0;
	let strictViolations = 0;
	let removedSum = 0;
	for (let i = 0; i < 200; i++) {
		const chain = findPlayableChain(workBoard, Config.MinChainLength, 3 + Math.floor(Math.random() * 4));
		if (chain.length < Config.MinChainLength) {
			continue;
		}
		removedSum += workBoard.applyChain(chain);
		applied++;
		if (!workBoard.isFull()) {
			fullFails++;
		}
		let maxNow = 0;
		for (const size of workBoard.maxGroupSizes()) {
			if (size > maxNow) {
				maxNow = size;
			}
		}
		if (maxNow > Config.MaxGroupSize) {
			strictViolations++;
		}
	}
	expect(applied >= 190, '随机操作实际生效次数应 ≥ 190，实际 ' + applied + '/200');
	expect(fullFails === 0, '消除补充后出现非满格：' + fullFails + ' 次');
	expect(workBoard.deadlockWarningCount === 0, '消除补充后出现无解棋盘：' + workBoard.deadlockWarningCount + ' 次');
	expect(workBoard.clearedTotal === removedSum, '消除统计应与实际移除数一致：' + workBoard.clearedTotal + ' vs ' + removedSum);
	expect(workBoard.chainsTotal === applied, '连线计数应与生效次数一致：' + workBoard.chainsTotal + ' vs ' + applied);

	// 5. 单次消除的确定性断言：移除 → 塌落 → 补充后仍满格
	const oneBoard = new Board();
	const firstColumnCell = oneBoard.flatIndex(0, 0);
	const beforeEmpty = oneBoard.emptyCount();
	const removedOne = oneBoard.applyChain([firstColumnCell, oneBoard.flatIndex(1, 0), oneBoard.flatIndex(2, 0)]);
	expect(removedOne === 3, '移除 3 格后返回移除数应为 3，实际 ' + removedOne);
	expect(beforeEmpty === 0, '初始棋盘应无空格，实际 ' + beforeEmpty);
	expect(oneBoard.emptyCount() === 0, '补充后应无空格，实际 ' + oneBoard.emptyCount());
	expect(oneBoard.isFull(), '补充后棋盘应满格');

	// 6. 链长下限 2 + 魔力值
	const physicalIndex = BlockDefs.indexOf(BlockDefs.Physical);
	const physicalSpecs = resolveEffects(BlockDefs.at(physicalIndex).rules, 2);
	expect(resolveEffects(BlockDefs.at(physicalIndex).rules, 1).length === 0, '链长 1（低于下限）不应产出效果');
	expect(physicalSpecs.length === 2, '链长 2 应产出伤害 + 魔力两条效果，实际 ' + physicalSpecs.length);
	let damageValue = 0;
	let manaValue = 0;
	for (const spec of physicalSpecs) {
		if (spec.kind === EffectKind.PhysicalDamage) {
			damageValue = spec.value;
		}
		if (spec.kind === EffectKind.ManaGain) {
			manaValue = spec.value;
		}
	}
	expect(damageValue === 10, '链长 2 物理伤害应为 4+3×2=10，实际 ' + damageValue);
	expect(manaValue === 7, '链长 2 魔力应为 1+3×2=7，实际 ' + manaValue);

	const manaCombat = new Combat(new Board());
	const manaBefore = manaCombat.player.mana;
	manaCombat.applySpecs(physicalSpecs);
	expect(manaCombat.player.mana === manaBefore + manaValue, '消除后魔力应增加 ' + manaValue + '，实际 ' + (manaCombat.player.mana - manaBefore));
	expect(manaCombat.enemy.hp === 34, '物理伤害 10 受护甲 4 减免后敌人应为 34 HP，实际 ' + manaCombat.enemy.hp);
	manaCombat.player.mana = 0;
	for (let i = 0; i < 30; i++) {
		manaCombat.applySpecs(physicalSpecs);
	}
	expect(manaCombat.player.mana === Config.MaxMana, '魔力应被夹在上限 ' + Config.MaxMana + '，实际 ' + manaCombat.player.mana);

	// 7. 技能：魔力不足拒绝、足够则扣魔并生效
	expect(Skills.find(Skills.Shuffle) !== undefined && Skills.find(Skills.Blast) !== undefined, '技能注册表应包含重排与引爆');
	const skillCombat = new Combat(new Board());
	skillCombat.player.mana = 0;
	expect(!skillCombat.useSkill(Skills.Shuffle).ok, '魔力不足时应拒绝重排');
	expect(skillCombat.player.mana === 0, '被拒绝时不应扣除魔力');
	expect(!skillCombat.useSkill(Skills.Blast).ok, '魔力不足时应拒绝引爆');
	expect(!skillCombat.useSkill('not-a-skill').ok, '未知技能应被拒绝');
	skillCombat.player.mana = 60;
	const shuffleResult = skillCombat.useSkill(Skills.Shuffle);
	expect(shuffleResult.ok, '魔力足够时重排应成功：' + shuffleResult.message);
	expect(skillCombat.player.mana === 40, '重排应扣 20 魔力，实际 ' + skillCombat.player.mana);
	expect(skillCombat.player.hp === Config.PlayerMaxHp, '释放技能不应影响玩家生命');

	// 8. 引爆技能：移除最大连通块并保持满格
	const blastBoard = new Board();
	const blastCombat = new Combat(blastBoard);
	blastCombat.player.mana = 100;
	expect(blastBoard.largestGroupCells().length >= Config.MinChainLength, '棋盘应存在规模 ≥ ' + Config.MinChainLength + ' 的连通块');
	const blastResult = blastCombat.useSkill(Skills.Blast);
	expect(blastResult.ok, '魔力足够时引爆应成功：' + blastResult.message);
	expect(blastBoard.isFull(), '引爆后棋盘应满格');
	expect(blastBoard.isPlayable(), '引爆后棋盘仍应可执行');
	expect(blastCombat.player.mana === 65, '引爆应扣 35 魔力，实际 ' + blastCombat.player.mana);

	// 9. 棋盘可执行性兜底：无相邻同色对 → 直接重排 + 惩罚
	const deadBoard = new Board();
	for (let row = 0; row < deadBoard.rows; row++) {
		for (let col = 0; col < deadBoard.columns; col++) {
			deadBoard.setCell(col, row, (col + row) % 2);
		}
	}
	expect(!deadBoard.isPlayable(), '棋盘格染色（无相邻同色对）应判定为不可执行');
	const penaltyCombat = new Combat(deadBoard);
	const hpBeforePenalty = penaltyCombat.player.hp;
	const notice = penaltyCombat.ensureBoardPlayable();
	expect(notice !== undefined, '不可执行时应返回提示文本');
	expect(penaltyCombat.boardResetCount === 1, '应记录一次棋盘重排，实际 ' + penaltyCombat.boardResetCount);
	expect(penaltyCombat.player.hp === hpBeforePenalty - Config.BoardResetPenalty, '应扣除 ' + Config.BoardResetPenalty + ' 点生命，实际 ' + penaltyCombat.player.hp);
	expect(deadBoard.isFull() && deadBoard.isPlayable(), '重排后棋盘应满格且可执行');
	expect(penaltyCombat.ensureBoardPlayable() === undefined, '棋盘可执行时不应再触发重排');

	// 10. target 分发：魔法伤害只作用于敌人、治疗只作用于玩家
	const targetCombat = new Combat(new Board());
	targetCombat.player.hp = 50;
	const magicSpecs = resolveEffects(BlockDefs.at(BlockDefs.indexOf(BlockDefs.Magic)).rules, 2);
	targetCombat.applySpecs(magicSpecs);
	expect(targetCombat.player.hp === 50, '魔法伤害不应影响玩家生命，实际 ' + targetCombat.player.hp);
	expect(targetCombat.enemy.hp === 31, '魔法伤害 9 无视护甲，敌人应为 31 HP，实际 ' + targetCombat.enemy.hp);
	const enemyHpBeforeHeal = targetCombat.enemy.hp;
	targetCombat.applySpecs(resolveEffects(BlockDefs.at(BlockDefs.indexOf(BlockDefs.Heal)).rules, 2));
	expect(targetCombat.player.hp === 57, '治疗 3+2×2=7 应回复玩家到 57，实际 ' + targetCombat.player.hp);
	expect(targetCombat.enemy.hp === enemyHpBeforeHeal, '治疗不应影响敌人');
	expect(unhandledEffectCount() === 0, '所用效果种类均应已注册 handler，未注册 ' + unhandledEffectCount() + ' 条');

	// 11. 波次推进、敌人行动与失败/重开
	const battle = new Combat(new Board());
	expect(battle.waveNumber === 1 && battle.waveCount === Config.StageWaveCount, '初始应为第 1 波，每关 ' + Config.StageWaveCount + ' 波');
	expect(battle.enemyInterval === Config.wave(0).actionTurns, '第 1 波敌人行动间隔应为 ' + Config.wave(0).actionTurns + ' 回合');
	const hpBeforeEnemyAct = battle.player.hp;
	const dealt = battle.enemyAct();
	expect(dealt > 0, '敌人出手应造成伤害，实际 ' + dealt);
	expect(battle.player.hp === hpBeforeEnemyAct - dealt, '玩家生命应按伤害下降：' + hpBeforeEnemyAct + ' → ' + battle.player.hp);
	battle.enemy.hp = 0;
	expect(!battle.advanceWave(), '第 1 波清完后应还有后续波次');
	expect(battle.waveNumber === 2, '应推进到第 2 波，实际 ' + battle.waveNumber);
	expect(battle.enemy.hp === battle.enemy.maxHp && battle.enemy.hp > 0, '新波次敌人应满血');
	battle.enemy.hp = 0;
	expect(!battle.advanceWave(), '第 2 波清完后应还有第 3 波');
	battle.enemy.hp = 0;
	expect(battle.advanceWave(), '第 3 波清完应判定本关通关');
	const hpBeforeNextStage = battle.player.hp;
	battle.nextStage();
	expect(battle.stageNumber === 2 && battle.waveNumber === 1, '应进入第 2 关第 1 波');
	expect(battle.player.hp >= hpBeforeNextStage, '通关后玩家应回复生命');
	expect(battle.enemy.maxHp > Config.wave(0).hp, '第 2 关敌人数值应按关卡增长，实际 ' + battle.enemy.maxHp);
	battle.player.hp = 0;
	expect(battle.defeated, '玩家生命为 0 应判定失败');
	battle.resetBattle();
	expect(!battle.defeated, '重开后不应处于失败状态');
	expect(battle.stageNumber === 1 && battle.player.hp === battle.player.maxHp && battle.player.mana === 0, '重开本关应复位关卡与玩家状态');
	expect(battle.boardResetCount === 0, '重开应清零被动重排计数');

	// 12. 设置读写、模式切换与实时模式时间源
	const settingsFile = 'settings-selftest.txt';
	const settings = new Settings();
	settings.mode = GameMode.Realtime;
	settings.difficulty = Difficulty.Hard;
	settings.showHint = false;
	const saved = settings.save(settingsFile);
	expect(saved, '设置应能写入存档文件（若环境不可写则本项会失败）');
	if (saved) {
		const loaded = Settings.load(settingsFile);
		expect(loaded.mode === GameMode.Realtime, '模式应往返一致，实际 ' + loaded.mode);
		expect(loaded.difficulty === Difficulty.Hard, '难度应往返一致，实际 ' + loaded.difficulty);
		expect(!loaded.showHint, '提示开关应往返一致');
		if (Content.exist(settingsFile)) {
			Content.remove(settingsFile);
		}
	} else {
		expect(Settings.load(settingsFile).mode === GameMode.TurnBased, '写入失败时应回退为默认设置');
	}
	const toggled = new Settings();
	expect(toggled.toggleMode() === GameMode.Realtime, '切换应变为实时模式');
	expect(toggled.toggleMode() === GameMode.TurnBased, '再次切换应回到回合制');
	expect(toggled.cycleDifficulty() === Difficulty.Hard, '标准 → 困难');
	expect(toggled.cycleDifficulty() === Difficulty.Casual, '困难 → 休闲');
	expect(!toggled.toggleHint(), '提示开关应可关闭');
	expect(toggled.difficultyScale() === Config.difficultyScale(Difficulty.Casual), '难度缩放应与配置一致');

	const realtimeCombat = new Combat(new Board());
	realtimeCombat.setRealtime(true);
	expect(realtimeCombat.isRealtime, '应处于实时模式');
	const interval = realtimeCombat.enemyIntervalSeconds;
	expect(interval > 0, '实时间隔应为正数，实际 ' + interval);
	expect(!realtimeCombat.advanceTime(interval * 0.5), '未到时间不应触发敌人行动');
	expect(realtimeCombat.advanceTime(interval * 0.5 + 0.01), '累计到间隔应触发敌人行动');
	expect(Math.abs(realtimeCombat.secondsLeft - interval) < 0.001, '触发后倒计时应重置为 ' + interval + '，实际 ' + realtimeCombat.secondsLeft);
	const turnCombat = new Combat(new Board());
	turnCombat.setRealtime(false);
	expect(!turnCombat.advanceTime(999), '回合制下推进时间不应触发敌人行动');
	expect(turnCombat.enemyInterval === Config.wave(0).actionTurns, '回合制间隔应为回合数 ' + Config.wave(0).actionTurns);
	const hardCombat = new Combat(new Board());
	hardCombat.setDifficultyScale(Config.difficultyScale(Difficulty.Hard));
	hardCombat.loadWave();
	expect(hardCombat.enemy.maxHp === Math.round(Config.wave(0).hp * Config.difficultyScale(Difficulty.Hard)), '难度应缩放敌人生命，实际 ' + hardCombat.enemy.maxHp);

	// 13. M5：封锁块（走统一执行器的棋盘效果）与精英蓄力/重击
	const lockedIndex = BlockDefs.lockedIndex();
	expect(lockedIndex >= 0, '注册表应包含封锁格定义');
	expect(!BlockDefs.isPlaceable(lockedIndex), '封锁格不应可放置');
	const lockBoard = new Board();
	const lockPlaced = lockBoard.blockCells(Config.EliteHeavyBlockCells);
	expect(lockPlaced === Config.EliteHeavyBlockCells, '应封锁 ' + Config.EliteHeavyBlockCells + ' 格，实际 ' + lockPlaced);
	expect(lockBoard.isPlayable(), '封锁后棋盘仍应存在可连线区域（硬约束）');
	expect(lockBoard.isFull(), '封锁后棋盘仍应满格');
	let groupHasLocked = 0;
	for (const flat of lockBoard.largestGroupCells()) {
		const groupCol = flat % lockBoard.columns;
		const groupRow = Math.floor(flat / lockBoard.columns);
		if (!BlockDefs.isPlaceable(lockBoard.cellIndex(groupCol, groupRow))) {
			groupHasLocked++;
		}
	}
	expect(groupHasLocked === 0, '最大连通块候选不应含封锁格，实际含 ' + groupHasLocked + ' 格');
	const blastRemoved = lockBoard.blastLargestGroup();
	expect(blastRemoved > 0, '引爆应移除可放置连通块，实际 ' + blastRemoved);
	expect(lockBoard.isPlayable(), '引爆后棋盘仍应可执行');
	expect(lockBoard.isFull(), '引爆后棋盘仍应满格');

	const mob = new Combat(new Board());
	const mobDamage = mob.enemyAct();
	expect(mob.lastEnemyAction === EnemyAction.Attack, '小怪行动类别应为普通攻击');
	expect(mobDamage > 0, '小怪出手应造成伤害，实际 ' + mobDamage);

	const eliteBoard = new Board();
	const elite = new Combat(eliteBoard);
	elite.advanceWave();
	elite.advanceWave();
	expect(elite.currentWave().isElite, '第 3 波应为精英');
	const unhandledBefore = unhandledEffectCount();
	const hpBeforeCharge = elite.player.hp;
	expect(elite.enemyAct() === 0, '精英首次行动应为蓄力，不造成伤害');
	expect(elite.lastEnemyAction === EnemyAction.Charge, '首次行动类别应为蓄力');
	expect(elite.isCharged, '蓄力后应处于蓄力状态');
	expect(elite.player.hp === hpBeforeCharge, '蓄力不应扣血，实际 ' + elite.player.hp);
	const heavyDamage = elite.enemyAct();
	expect(elite.lastEnemyAction === EnemyAction.Heavy, '第二次行动类别应为重击');
	expect(heavyDamage > elite.currentWave().attack, '重击伤害应高于普通攻击，实际 ' + heavyDamage + ' vs ' + elite.currentWave().attack);
	expect(!elite.isCharged, '重击后应清除蓄力状态');
	expect(unhandledEffectCount() === unhandledBefore, 'BoardBlock 应已在执行器注册表中（悬空效果数不应增加）');
	let eliteLocked = 0;
	for (let row = 0; row < eliteBoard.rows; row++) {
		for (let col = 0; col < eliteBoard.columns; col++) {
			const index = eliteBoard.cellIndex(col, row);
			if (index >= 0 && !BlockDefs.isPlaceable(index)) {
				eliteLocked++;
			}
		}
	}
	expect(eliteLocked === Config.EliteHeavyBlockCells, '重击应经执行器封锁 ' + Config.EliteHeavyBlockCells + ' 格，实际 ' + eliteLocked);
	expect(eliteBoard.isPlayable(), '重击封锁后棋盘仍应可执行');
	expect(eliteBoard.isFull(), '重击封锁后棋盘仍应满格');
	elite.nextStage();
	expect(!elite.isCharged && elite.lastEnemyAction === EnemyAction.Attack, '进入新关后应复位蓄力状态');

	// 13b. 执行器路径：BoardBlock 效果经 executeEffects 到达棋盘（而非直接调用）
	const effectBoard = new Board();
	const effectCombat = new Combat(effectBoard);
	const boardBlockSpec: EffectSpec = { kind: EffectKind.BoardBlock, value: 1, target: EffectTarget.Board };
	expect(effectCombat.applySpecs([boardBlockSpec]) === 1, 'applySpecs 应执行 1 条 BoardBlock 效果');
	let effectLocked = 0;
	for (let row = 0; row < effectBoard.rows; row++) {
		for (let col = 0; col < effectBoard.columns; col++) {
			const index = effectBoard.cellIndex(col, row);
			if (index >= 0 && !BlockDefs.isPlaceable(index)) {
				effectLocked++;
			}
		}
	}
	expect(effectLocked === 1, 'BoardBlock 效果应封锁 1 格，实际 ' + effectLocked);

	// 13c. 封锁到期自动恢复：计时随敌人行动递减，到期格恢复为常规方块且约束仍成立
	const expireBoard = new Board();
	const expireCombat = new Combat(expireBoard);
	expect(expireCombat.applySpecs([boardBlockSpec]) === 1, '封锁效果应经执行器下发到棋盘');
	expect(expireBoard.lockedCount() === 1, '封锁后棋盘应有 1 个封锁格，实际 ' + expireBoard.lockedCount());
	let expireFlat = -1;
	for (let row = 0; row < expireBoard.rows && expireFlat < 0; row++) {
		for (let col = 0; col < expireBoard.columns; col++) {
			const index = expireBoard.cellIndex(col, row);
			if (index >= 0 && !BlockDefs.isPlaceable(index)) {
				expireFlat = expireBoard.flatIndex(col, row);
				break;
			}
		}
	}
	expect(expireFlat >= 0, '应在棋盘上定位封锁格');
	expect(expireBoard.lockTurnsAt(expireFlat) === Config.LockDurationActions, '封锁格应记录 ' + Config.LockDurationActions + ' 次敌人行动计时，实际 ' + expireBoard.lockTurnsAt(expireFlat));
	expireCombat.enemyAct();
	expect(expireBoard.lockedCount() === 1, '第 1 次敌人行动后封锁不应到期，实际剩余 ' + expireBoard.lockedCount());
	expect(expireCombat.lastExpiredLocks === 0, '未到期时 lastExpiredLocks 应为 0，实际 ' + expireCombat.lastExpiredLocks);
	expireCombat.enemyAct();
	expect(expireBoard.lockedCount() === 0, '第 ' + Config.LockDurationActions + ' 次敌人行动后封锁应自动恢复，实际剩余 ' + expireBoard.lockedCount());
	expect(expireCombat.lastExpiredLocks === 1, '到期恢复数应为 1，实际 ' + expireCombat.lastExpiredLocks);
	expect(BlockDefs.isPlaceable(expireBoard.cellIndex(expireFlat % expireBoard.columns, Math.floor(expireFlat / expireBoard.columns))), '恢复后的格子应为可放置方块');
	expect(expireBoard.isFull(), '封锁恢复后棋盘应仍满格');
	expect(expireBoard.isPlayable(), '封锁恢复后棋盘应仍可执行');
	expect(expireBoard.satisfiesGroupLimit(Config.GroupSizeRelaxLimit), '封锁恢复后棋盘应满足连通块上限');

	// 13d. M6 排版：极端宽高比下的安全区 + HUD/棋盘越界审计
	// zoom = min(w/960, h/1080) 保证任何宽高比下至少 960×1080 设计单位可见，
	// 因此 HUD/棋盘必须全部落在 x∈[-480,480]、y∈[-540,540] 内。
	const viewSizes: number[][] = [
		[5120, 1440], [3440, 1440], [2560, 1080], [1920, 1080], [1280, 960],
		[1024, 768], [960, 1080], [900, 1200], [800, 1280], [720, 1600], [600, 1040], [0, 0],
	];
	let minHalfWidth = 999999;
	let minHalfHeight = 999999;
	for (const viewSize of viewSizes) {
		const extent = visibleHalfExtent(viewSize[0], viewSize[1]);
		const halfWidth = extent.width * 0.5;
		const halfHeight = extent.height * 0.5;
		if (halfWidth < minHalfWidth) {
			minHalfWidth = halfWidth;
		}
		if (halfHeight < minHalfHeight) {
			minHalfHeight = halfHeight;
		}
		expect(halfWidth >= SafeBox.HalfWidth - 0.01, '窗口 ' + viewSize[0] + '×' + viewSize[1] + ' 可见半宽 ' + Math.floor(halfWidth) + ' 应 ≥ 安全区 ' + SafeBox.HalfWidth);
		expect(halfHeight >= SafeBox.HalfHeight - 0.01, '窗口 ' + viewSize[0] + '×' + viewSize[1] + ' 可见半高 ' + Math.floor(halfHeight) + ' 应 ≥ 安全区 ' + SafeBox.HalfHeight);
	}
	const layoutRects = hudLayoutRects();
	for (const rect of layoutRects) {
		expect(insideSafeBox(rect), 'HUD 元素「' + rect.name + '」（x ' + Math.floor(rect.x) + '±' + Math.floor(rect.width / 2) + '，y ' + Math.floor(rect.y) + '±' + Math.floor(rect.height / 2) + '）越出安全区');
	}
	const layoutBoard = boardLayoutRect();
	expect(insideSafeBox(layoutBoard), '棋盘应完整落在安全区内');
	const boardBottom = layoutBoard.y - layoutBoard.height * 0.5;
	const hintTop = HudLayout.HintY + HudLayout.FontLabel * 0.75;
	expect(hintTop <= boardBottom, '底部操作提示（顶边 ' + Math.floor(hintTop) + '）不应与棋盘（底边 ' + Math.floor(boardBottom) + '）重叠');
	const skillBottom = HudLayout.SkillButtonY - HudLayout.SkillButtonHeight * 0.5;
	const laneTop = Config.NoticeEnemyY + HudLayout.NoticeRise + HudLayout.FontNotice * 0.75;
	expect(laneTop <= skillBottom, '对敌飘字道（上浮终点 ' + Math.floor(laneTop) + '）不应升进技能按钮区（下沿 ' + Math.floor(skillBottom) + '）');
	const laneBottom = Config.NoticePlayerY - HudLayout.FontNotice * 0.75;
	expect(laneBottom >= hintTop + 0.01 + HudLayout.FontLabel * 1.5, '我方飘字道（下沿 ' + Math.floor(laneBottom) + '）不应压到底部提示行');

	const head = failures.length === 0 ? 'passed' : 'failed';
	const lines: string[] = [head];
	lines.push('检查项 ' + checks + ' 项，失败 ' + failures.length + ' 项');
	lines.push('链长下限 ' + Config.MinChainLength + '；链长2 物伤 ' + damageValue + '、魔力 ' + manaValue + '；无解重排惩罚 ' + Config.BoardResetPenalty + ' 生命；波次/失败切换与设置/实时模式已校验');
	const sizes: string[] = [];
	for (const size of workBoard.maxGroupSizes()) {
		sizes.push('' + size);
	}
	lines.push('200 次随机操作后：生效 ' + applied + ' 次，各类型最大连通块 ' + sizes.join(',') + '，严格上限越界 ' + strictViolations + ' 次，放宽上限告警 ' + workBoard.limitWarningCount + ' 次，无解告警 ' + workBoard.deadlockWarningCount + ' 次，强制修复 ' + workBoard.forcedRepairs + ' 次');
	lines.push('M5 封锁/蓄力：blockCells ' + lockPlaced + ' 格，精英蓄力→重击 ' + heavyDamage + ' 伤害并封锁 ' + eliteLocked + ' 格；封锁经 ' + Config.LockDurationActions + ' 次敌人行动后自动恢复');
	lines.push('M6 排版：' + viewSizes.length + ' 种窗口（含 0×0 未就绪）下最小可见区 ' + Math.floor(minHalfWidth * 2) + '×' + Math.floor(minHalfHeight * 2) + ' ≥ 安全区 ' + Config.DesignSceneWidth + '×' + Config.DesignSceneHeight + '，HUD/面板 ' + layoutRects.length + ' 个元素与棋盘均在安全区内；棋盘底边 ' + Math.floor(boardBottom) + '，提示行上沿 ' + Math.floor(hintTop) + '，对敌飘字上浮终点 ' + Math.floor(laneTop) + '（技能按钮下沿 ' + Math.floor(skillBottom) + '）');
	for (const failure of failures) {
		lines.push(' - ' + failure);
	}
	return lines.join('\n');
}

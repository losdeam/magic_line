// 战斗状态（纯逻辑，可单独测试）：玩家/敌人属性、魔力与技能释放、波次与关卡推进、棋盘可执行性兜底。
// 模式时间源（回合制/实时）在 M4 接入；HUD 只读本类的状态。

import { Board } from 'game/Board';
import { Config } from 'game/Config';
import { ActorState, EffectContext, EffectSpec, applyDamage, executeEffects, makeActor } from 'game/Effects';
import { EnemySkillDef, LevelDef, Levels, WaveDef } from 'game/Levels';
import { SkillDef, Skills } from 'game/Skills';

export interface SkillResult {
	ok: boolean;
	message: string;
}

/** 敌人一次行动的类别：普通出手 / 预告（本次不出手，下次释放该技能）/ 释放（技能真正结算）。 */
export const enum EnemyAction {
	Attack = 'attack',
	Prepare = 'prepare',
	Release = 'release',
}

export class Combat {
	readonly player: ActorState;
	readonly enemy: ActorState;
	private readonly board: Board;
	private readonly enemies: ActorState[];
	private resetCount = 0;
	private waveIndex = 0;
	private stage = 1;
	private difficultyScale = 1;
	private realtime = false;
	private realtimeTimer = 0;
	/** 当前关卡定义（来自 game/Levels.ts 的纯数据注册表）。 */
	private readonly level: LevelDef;
	/** 已预告、下次行动应被释放的技能下标（-1 表示当前无预告）。 */
	private prepared = -1;
	/** 与当前波技能等长的冷却计时；> 0 时该技能不会被选中。 */
	private cooldowns: number[] = [];
	/** 技能轮转起点：保证波次里的每个技能都有机会被选中。 */
	private skillCursor = 0;
	/** 最近一次敌人行动的类别（HUD 据此分道播报）。 */
	private lastAction = EnemyAction.Attack;
	/** 最近一次敌人行动使用/预告的技能名（HUD 播报用）。 */
	private lastSkill = '普通攻击';
	/** 最近一次敌人行动经执行器新封锁的棋盘格数。 */
	private newLocks = 0;
	/** 最近一次敌人行动时自动恢复（封锁到期）的格子数。 */
	private expiredLockCount = 0;

	constructor(board: Board, level?: LevelDef) {
		this.board = board;
		this.level = level === undefined ? Levels.Default : level;
		this.player = makeActor(Config.PlayerMaxHp, 0, Config.MaxMana);
		const wave = Levels.waveOf(this.level, 0);
		this.enemy = makeActor(wave.hp, wave.armor, 0);
		this.enemies = [this.enemy];
		this.loadWave();
	}

	/** 棋盘因不可执行而被动重排的次数。 */
	get boardResetCount(): number {
		return this.resetCount;
	}

	/** 玩家是否已被击败。 */
	get defeated(): boolean {
		return this.player.hp <= 0;
	}

	/** 当前关卡序号（从 1 开始）。 */
	get stageNumber(): number {
		return this.stage;
	}

	/** 当前波次序号（从 1 开始）。 */
	get waveNumber(): number {
		return this.waveIndex + 1;
	}

	/** 每关波数。 */
	get waveCount(): number {
		return this.level.waves.length;
	}

	/** 当前关卡定义（HUD/关卡界面只读）。 */
	get levelDef(): LevelDef {
		return this.level;
	}

	currentWave(): WaveDef {
		return Levels.waveOf(this.level, this.waveIndex);
	}

	/** 当前波次的敌人行动间隔（回合制：回合数）。 */
	get enemyInterval(): number {
		return this.currentWave().actionTurns;
	}

	/** 是否实时模式（敌人按秒倒计时行动）。 */
	get isRealtime(): boolean {
		return this.realtime;
	}

	/** 当前波次的敌人行动间隔（实时模式：秒）。 */
	get enemyIntervalSeconds(): number {
		return this.currentWave().actionSeconds;
	}

	/** 实时模式剩余秒数（HUD 显示用）。 */
	get secondsLeft(): number {
		return this.realtimeTimer;
	}

	/** 切换时间源：回合计数 / 秒级倒计时，并重置倒计时。 */
	setRealtime(on: boolean): void {
		this.realtime = on;
		this.resetTimer();
	}

	resetTimer(): void {
		this.realtimeTimer = this.enemyIntervalSeconds;
	}

	/**
	 * 推进实时倒计时；返回 true 表示敌人应当出手（调用方随后执行 enemyAct）。
	 * 回合制下始终返回 false（由回合计数驱动）。
	 */
	advanceTime(dt: number): boolean {
		if (!this.realtime) {
			return false;
		}
		this.realtimeTimer -= dt;
		if (this.realtimeTimer > 0) {
			return false;
		}
		this.resetTimer();
		return true;
	}

	setDifficultyScale(scale: number): void {
		this.difficultyScale = scale;
	}

	/** 载入当前波次的敌人属性（按关卡与难度缩放）。 */
	loadWave(): void {
		const wave = this.currentWave();
		const scale = this.difficultyScale * Config.stageEnemyScale(this.stage);
		this.enemy.maxHp = Math.round(wave.hp * scale);
		this.enemy.hp = this.enemy.maxHp;
		this.enemy.shield = 0;
		this.enemy.armor = wave.armor;
		this.enemy.debuffStacks = 0;
		// 换波/换关时清除预告与全部技能冷却
		this.prepared = -1;
		this.lastAction = EnemyAction.Attack;
		this.skillCursor = 0;
		this.cooldowns = [];
		for (let i = 0; i < wave.skills.length; i++) {
			this.cooldowns.push(0);
		}
		this.newLocks = 0;
		this.resetTimer();
	}

	/** 敌人是否已预告技能、下次行动将释放它。 */
	get isPreparing(): boolean {
		return this.prepared >= 0;
	}

	/** 最近一次敌人行动使用/预告的技能名。 */
	get lastSkillName(): string {
		return this.lastSkill;
	}

	/** 最近一次敌人行动经执行器新封锁的棋盘格数。 */
	get lastNewLocks(): number {
		return this.newLocks;
	}

	/** 最近一次敌人行动的类别（在 enemyAct() 之后读取）。 */
	get lastEnemyAction(): EnemyAction {
		return this.lastAction;
	}

	/** 最近一次敌人行动后自动解除的封锁格数（0 表示没有封锁到期）。 */
	get lastExpiredLocks(): number {
		return this.expiredLockCount;
	}

	/**
	 * 敌人出手：按当前波次的数据化技能表轮转选出一个技能并结算。
	 * - 带 `preparesNext` 的技能首次选中只是预告（0 伤害、不结算效果），下一次行动才真正释放；
	 * - 技能 `effects` 一律交统一效果执行器下发（例如重击封锁棋盘），Combat 不含按技能/按 kind 的分支；
	 * - 技能自带的 `damage` 由本方法统一乘上「难度 × 关卡」缩放后结算。
	 */
	enemyAct(): number {
		// 先推进封锁计时：到期的封锁格自动恢复为常规方块（恢复走棋盘标准补充流程），
		// 因此本次刚下发的封锁不会被立刻扣减。
		this.expiredLockCount = this.board.expireLocks();
		// 推进技能冷却（本次释放的技能会在其分支里被重新设为满冷却）。
		for (let i = 0; i < this.cooldowns.length; i++) {
			if (this.cooldowns[i] > 0) {
				this.cooldowns[i] -= 1;
			}
		}
		const wave = this.currentWave();
		const scale = this.difficultyScale * Config.stageEnemyScale(this.stage);
		const index = this.prepared >= 0 ? this.prepared : this.pickSkill(wave);
		if (index < 0) {
			// 该波所有技能都在冷却中：退回本波自身的普通攻击（纯数据推导，无特例分支）。
			const fallback = Levels.fallbackSkill(wave);
			this.lastAction = EnemyAction.Attack;
			this.lastSkill = fallback.name;
			this.newLocks = 0;
			return applyDamage(this.player, fallback.damage * scale);
		}
		const skill = Levels.skillOf(wave, index);
		if (this.prepared >= 0) {
			// 释放上一次行动预告的技能。
			this.prepared = -1;
			this.cooldowns[index] = skill.cooldownActions;
			this.lastAction = EnemyAction.Release;
		} else if (skill.preparesNext) {
			// 预告：本次不出手、不结算效果与伤害，仅记录待释放的技能下标。
			this.prepared = index;
			this.lastAction = EnemyAction.Prepare;
			this.lastSkill = skill.name;
			this.newLocks = 0;
			return 0;
		} else {
			this.lastAction = EnemyAction.Attack;
			this.cooldowns[index] = skill.cooldownActions;
		}
		this.lastSkill = skill.name;
		const locksBefore = this.board.lockedCount();
		this.applySpecs(skill.effects);
		this.newLocks = this.board.lockedCount() - locksBefore;
		return applyDamage(this.player, skill.damage * scale);
	}

	/** 从当前波次的技能表中轮转选出下一个可用技能下标；全部在冷却中时返回 -1。 */
	private pickSkill(wave: WaveDef): number {
		const count = wave.skills.length;
		if (count === 0) {
			return -1;
		}
		for (let offset = 0; offset < count; offset++) {
			const index = (this.skillCursor + offset) % count;
			if (this.cooldowns[index] <= 0) {
				this.skillCursor = (index + 1) % count;
				return index;
			}
		}
		return -1;
	}

	/** 推进到下一波；返回 true 表示本关波次已清完。 */
	advanceWave(): boolean {
		this.waveIndex++;
		if (this.waveIndex >= this.waveCount) {
			return true;
		}
		this.loadWave();
		return false;
	}

	/** 进入下一关：波次归零、敌人数值增长、玩家回复一定生命。 */
	nextStage(): void {
		this.stage++;
		this.waveIndex = 0;
		this.loadWave();
		this.player.hp += Math.round(this.player.maxHp * Config.StageClearHealRatio);
		if (this.player.hp > this.player.maxHp) {
			this.player.hp = this.player.maxHp;
		}
	}

	/** 重开本关：波次、关卡与双方状态复位。 */
	resetBattle(): void {
		this.waveIndex = 0;
		this.stage = 1;
		this.resetCount = 0;
		this.player.hp = this.player.maxHp;
		this.player.shield = 0;
		this.player.buffStacks = 0;
		this.player.debuffStacks = 0;
		this.player.mana = 0;
		this.loadWave();
	}

	/** 把效果三元组列表交给统一执行器，返回实际执行条数。 */
	applySpecs(specs: EffectSpec[]): number {
		return executeEffects(specs, this.makeContext());
	}

	/** 释放技能：先扣魔力，再执行技能的效果列表。 */
	useSkill(id: string): SkillResult {
		const def = Skills.find(id);
		if (def === undefined) {
			return { ok: false, message: '技能不存在：' + id };
		}
		if (this.player.mana < def.cost) {
			return { ok: false, message: def.name + ' 需要 ' + def.cost + ' 魔力，当前 ' + this.player.mana };
		}
		this.player.mana -= def.cost;
		this.applySpecs(def.effects);
		return { ok: true, message: def.name + '（魔力 −' + def.cost + '）' };
	}

	/** 可释放的技能列表，供 HUD 绘制按钮。 */
	availableSkills(): SkillDef[] {
		return Skills.List;
	}

	/**
	 * 棋盘可执行性兜底：不可执行（所有颜色都不存在 ≥ MinChainLength 的区域）时
	 * 直接重排整盘并惩罚玩家，返回提示文本；返回 undefined 表示无需处理。
	 */
	ensureBoardPlayable(): string | undefined {
		if (this.board.isPlayable()) {
			return undefined;
		}
		this.board.reset();
		this.resetCount++;
		this.player.hp -= Config.BoardResetPenalty;
		if (this.player.hp < 0) {
			this.player.hp = 0;
		}
		return '棋盘无可连线区域，已重排棋盘（生命 −' + Config.BoardResetPenalty + '）';
	}

	private makeContext(): EffectContext {
		return { player: this.player, currentEnemy: this.enemy, allEnemies: this.enemies, board: this.board };
	}
}

// 关卡注册表：纯数据。波次表、敌人技能表与 6 个手工关卡全部写在这里。
// 敌人技能的效果同样交给 game/Effects.ts 的统一执行器，Combat 不写任何按技能/按 kind 的特例分支。
// 敌人伤害不进效果三元组（执行器没有难度与关卡上下文的缩放能力），而是技能自带的 damage 字段，
// 由 Combat 统一乘上「难度 × 关卡」缩放后再结算。

import { Config } from 'game/Config';
import { EffectKind, EffectSpec, EffectTarget } from 'game/Effects';

/**
 * 敌人技能：一次敌人行动的纯数据定义。
 * - damage：结算给玩家的基础伤害（0 表示本次出手不造成伤害，例如蓄力预告）。
 * - effects：经统一执行器下发的效果三元组（例如重击封锁棋盘）。
 * - preparesNext：true = 本次出手只是蓄力预告，下一次行动才真正释放该技能。
 * - cooldownActions：释放后需要经过多少次敌人行动才能再次被选中。
 */
export interface EnemySkillDef {
	id: string;
	name: string;
	damage: number;
	effects: EffectSpec[];
	preparesNext: boolean;
	cooldownActions: number;
}

/** 单波敌人的纯数据定义（不含技能；技能见 EnemySkillDef）。 */
export interface WaveDef {
	name: string;
	isElite: boolean;
	hp: number;
	attack: number;
	armor: number;
	actionTurns: number;
	actionSeconds: number;
	skills: EnemySkillDef[];
}

/** 一个手工关卡的纯数据定义。 */
export interface LevelDef {
	id: number;
	name: string;
	subtitle: string;
	waves: WaveDef[];
}

/** 构造一条敌人技能。 */
function makeSkill(id: string, name: string, damage: number, preparesNext: boolean, cooldownActions: number, effects?: EffectSpec[]): EnemySkillDef {
	return { id, name, damage, effects: effects === undefined ? [] : effects, preparesNext, cooldownActions };
}

/** 构造波次定义（技能列表必须非空：至少要有一条冷却为 0 的普通攻击，保证敌人永远能出手）。 */
function makeWave(name: string, isElite: boolean, hp: number, attack: number, armor: number, actionTurns: number, actionSeconds: number, skills: EnemySkillDef[]): WaveDef {
	return { name, isElite, hp, attack, armor, actionTurns, actionSeconds, skills };
}

/** 封锁棋盘的效果条目（走统一执行器的棋盘效果，等级数据只给格数与时机）。 */
function blockSpec(cells: number): EffectSpec {
	return { kind: EffectKind.BoardBlock, value: cells, target: EffectTarget.Board };
}

/**
 * 默认关卡：数值严格等于 Config.Waves（自检以字面量锁定该等式），
 * 精英技能 = 蓄力重击（伤害 = Config 的重击 24，效果 = 封锁棋盘）在前、普通攻击在后，
 * 因此 `new Combat(new Board())` 保持 M5 已验收的「先蓄力 → 再重击」时序。
 */
function buildDefaultLevel(): LevelDef {
	const waves: WaveDef[] = [];
	for (let i = 0; i < Config.Waves.length; i++) {
		const nums = Config.Waves[i];
		const strike = makeSkill('strike', '普通攻击', nums.attack, false, 0);
		if (nums.isElite) {
			const heavy = makeSkill('heavy', '蓄力重击', nums.heavyAttack, true, 0, [blockSpec(Config.EliteHeavyBlockCells)]);
			waves.push(makeWave(nums.name, nums.isElite, nums.hp, nums.attack, nums.armor, nums.actionTurns, nums.actionSeconds, [heavy, strike]));
		} else {
			waves.push(makeWave(nums.name, nums.isElite, nums.hp, nums.attack, nums.armor, nums.actionTurns, nums.actionSeconds, [strike]));
		}
	}
	return {
		id: 0,
		name: '默认关卡',
		subtitle: '数值与 Config.Waves 一致的兼容关卡（自检基准）',
		waves,
	};
}

/**
 * 6 个手工关卡：逐关引入新机制 ——
 * 1 关仅普通攻击；2 关节奏加快；3 关首次出现棋盘封锁；4 关封锁常态化；
 * 5 关双精英；6 关高频高压（通关后解锁无尽挑战，复用本关波次表并按轮次放大）。
 */
function buildLevels(): LevelDef[] {
	return [
		{
			id: 1,
			name: '试炼场',
			subtitle: '敌人只会普通攻击，先熟悉连线与结算节奏',
			waves: [
				makeWave('游荡者', false, 36, 7, 3, 3, 5, [makeSkill('strike', '普通攻击', 7, false, 0)]),
				makeWave('游荡者', false, 54, 9, 5, 3, 4.5, [makeSkill('strike', '普通攻击', 9, false, 0)]),
				makeWave('看门人', true, 100, 12, 8, 3, 4, [makeSkill('strike', '普通攻击', 12, false, 0)]),
			],
		},
		{
			id: 2,
			name: '锈蚀回廊',
			subtitle: '敌人出手更快，需要压缩每次决策时间',
			waves: [
				makeWave('锈蚀兵', false, 46, 8, 4, 3, 4.5, [makeSkill('strike', '普通攻击', 8, false, 0)]),
				makeWave('锈蚀兵', false, 68, 11, 6, 2, 4, [makeSkill('strike', '普通攻击', 11, false, 0)]),
				makeWave('锈蚀队长', true, 130, 15, 10, 2, 3.5, [makeSkill('heavy', '蓄力重击', 26, true, 0), makeSkill('strike', '普通攻击', 15, false, 0)]),
			],
		},
		{
			id: 3,
			name: '封锁者',
			subtitle: '首次出现棋盘封锁：被锁的格子无法连线',
			waves: [
				makeWave('封锁学徒', false, 50, 9, 4, 3, 4.5, [makeSkill('strike', '普通攻击', 9, false, 0)]),
				makeWave('封锁者', false, 74, 12, 6, 3, 4, [
					makeSkill('lockPunch', '封锁击', 14, true, 0, [blockSpec(1)]),
					makeSkill('strike', '普通攻击', 12, false, 0),
				]),
				makeWave('封锁监工', true, 145, 16, 10, 2, 3.5, [
					makeSkill('heavy', '蓄力封锁', 28, true, 0, [blockSpec(2)]),
					makeSkill('strike', '普通攻击', 16, false, 0),
				]),
			],
		},
		{
			id: 4,
			name: '铁壁工事',
			subtitle: '封锁常态化，场上会长期残留在障碍',
			waves: [
				makeWave('工事兵', false, 58, 10, 5, 3, 4.5, [
					makeSkill('lockPunch', '封锁击', 12, true, 1, [blockSpec(1)]),
					makeSkill('strike', '普通攻击', 10, false, 0),
				]),
				makeWave('工事官', false, 82, 13, 7, 3, 4, [
					makeSkill('lockPunch', '封锁击', 15, true, 1, [blockSpec(2)]),
					makeSkill('strike', '普通攻击', 13, false, 0),
				]),
				makeWave('铁壁统领', true, 165, 18, 12, 2, 3.5, [
					makeSkill('heavy', '蓄力封锁', 32, true, 0, [blockSpec(3)]),
					makeSkill('strike', '普通攻击', 18, false, 0),
				]),
			],
		},
		{
			id: 5,
			name: '双生精英',
			subtitle: '连续两波精英，蓄力重击接踵而至',
			waves: [
				makeWave('双子卫兵', false, 62, 11, 5, 3, 4, [makeSkill('strike', '普通攻击', 11, false, 0)]),
				makeWave('左精英', true, 140, 16, 10, 2, 3.5, [
					makeSkill('heavy', '蓄力重击', 28, true, 0),
					makeSkill('strike', '普通攻击', 16, false, 0),
				]),
				makeWave('右精英', true, 175, 20, 12, 2, 3, [
					makeSkill('heavy', '蓄力封锁', 34, true, 0, [blockSpec(2)]),
					makeSkill('strike', '普通攻击', 20, false, 0),
				]),
			],
		},
		{
			id: 6,
			name: '终局回响',
			subtitle: '高频出手 + 大范围封锁，通关后解锁无尽挑战',
			waves: [
				makeWave('回响残兵', false, 70, 13, 6, 2, 4, [makeSkill('strike', '普通攻击', 13, false, 0)]),
				makeWave('回响官', true, 160, 19, 11, 2, 3.5, [
					makeSkill('lockPunch', '封锁击', 24, true, 1, [blockSpec(2)]),
					makeSkill('strike', '普通攻击', 19, false, 0),
				]),
				makeWave('回响之主', true, 210, 23, 14, 2, 3, [
					makeSkill('heavy', '蓄力封锁', 40, true, 0, [blockSpec(3)]),
					makeSkill('strike', '普通攻击', 23, false, 0),
				]),
			],
		},
	];
}

/** 关卡注册表：查表即可，不含任何按关卡/按技能的分支逻辑。 */
export class Levels {
	/** 兼容关卡：数值与 Config.Waves 完全一致，供未指定关卡的 Combat 使用。 */
	static readonly Default: LevelDef = buildDefaultLevel();
	/** 6 个手工关卡（顺序解锁，id 从 1 开始）。 */
	static readonly List: LevelDef[] = buildLevels();
	/** 无尽挑战的基础关卡：复用最后一关的波次表，轮次由关卡缩放实现。 */
	static readonly EndlessBase: LevelDef = Levels.List[Levels.List.length - 1];

	/** 按 id 取关卡；id 越界时回退到第 1 关。 */
	static get(id: number): LevelDef {
		for (const level of Levels.List) {
			if (level.id === id) {
				return level;
			}
		}
		return Levels.List[0];
	}

	/** 取指定波次；越界时回退到最后一波（与 Config.wave 的容错语义一致）。 */
	static waveOf(level: LevelDef, index: number): WaveDef {
		const list = level.waves;
		if (index < 0 || index >= list.length) {
			return list[list.length - 1];
		}
		return list[index];
	}

	/** 取指定技能；下标越界时回退到本波自身的普通攻击（与 fallbackSkill 语义一致）。 */
	static skillOf(wave: WaveDef, index: number): EnemySkillDef {
		const list = wave.skills;
		if (index < 0 || index >= list.length) {
			return Levels.fallbackSkill(wave);
		}
		return list[index];
	}

	/**
	 * 波次数据兜底：该波没有任何技能（或技能全在冷却）时使用的普通攻击。
	 * 数值取自波次自身的 attack，因此依然是纯数据推导，不引入按 kind 的分支。
	 */
	static fallbackSkill(wave: WaveDef): EnemySkillDef {
		return makeSkill('strike', '普通攻击', wave.attack, false, 0);
	}
}
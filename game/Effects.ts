// 效果模型：一次连线的结算产物是效果列表 [{kind, value, target}]。
// 注意：持续回合等时间性质不进入三元组，统一放在 Config 的持续时间表里。

import { Config } from 'game/Config';

/** 执行效果的种类。新增效果种类 = 注册一条 handler（本直文件只列枚举）。 */
export const enum EffectKind {
	PhysicalDamage = 'physicalDamage',
	MagicDamage = 'magicDamage',
	Heal = 'heal',
	Dispel = 'dispel',
	Shield = 'shield',
	BuffDamage = 'buffDamage',
	DebuffArmor = 'debuffArmor',
	ManaGain = 'manaGain',
	BoardBlock = 'boardBlock',
	BoardShuffle = 'boardShuffle',
	BoardBlast = 'boardBlast',
}

/** 效果作用对象。`Reserved` 为预留未实现的枚举位。 */
export const enum EffectTarget {
	Self = 'self',
	CurrentEnemy = 'currentEnemy',
	AllEnemies = 'allEnemies',
	Board = 'board',
	Reserved = 'reserved',
}

/** 严格三元组：执行效果 / 执行数值 / 执行对象。不带可选字段，A避免 Lua 数组存 undefined。 */
export interface EffectSpec {
	kind: EffectKind;
	value: number;
	target: EffectTarget;
}

/** 纯数据规则：“链长 → 数值”也是数据，不是函数。 */
export interface EffectRule {
	kind: EffectKind;
	target: EffectTarget;
	/** 链长下限时的数值。 */
	base: number;
	/** 每多一块的增量（可为 0）。 */
	perBlock: number;
	/** 生效所需最小链长。 */
	minChain: number;
	/** 取整粒度：0 = 四舍五入；>0 = 向下取整到该粒度。 */
	floorTo: number;
}

/** 构造一条效果规则，避免各处重复写全字段。 */
export function makeRule(kind: EffectKind, target: EffectTarget, base: number, perBlock: number, minChain: number = Config.MinChainLength, floorTo: number = 0): EffectRule {
	return { kind, target, base, perBlock, minChain, floorTo };
}

/** 按取整粒度把原始数值归整。 */
export function roundRuleValue(raw: number, floorTo: number): number {
	if (floorTo > 0) {
		return Math.floor(raw / floorTo) * floorTo;
	}
	return Math.round(raw);
}

/**
 * 把方块的效果规则展开为效果三元组列表。
 * 链长低于规则下限时跳过该条；链长低于全局下限时统一返回空列表。
 */
export function resolveEffects(rules: EffectRule[], chainLength: number): EffectSpec[] {
	const specs: EffectSpec[] = [];
	if (chainLength < Config.MinChainLength) {
		return specs;
	}
	for (const rule of rules) {
		if (chainLength < rule.minChain) {
			continue;
		}
		const raw = rule.base + rule.perBlock * chainLength;
		specs.push({ kind: rule.kind, value: roundRuleValue(raw, rule.floorTo), target: rule.target });
	}
	return specs;
}

/** 效果类型的中文名（用于日志、飘字与自检报告）。 */
export const EffectKindNames: Record<EffectKind, string> = {
	[EffectKind.PhysicalDamage]: '物理伤害',
	[EffectKind.MagicDamage]: '魔法伤害',
	[EffectKind.Heal]: '治疗',
	[EffectKind.Dispel]: '净化',
	[EffectKind.Shield]: '护盾',
	[EffectKind.BuffDamage]: '增伤',
	[EffectKind.DebuffArmor]: '破甲',
	[EffectKind.ManaGain]: '魔力',
	[EffectKind.BoardBlock]: '封锁',
	[EffectKind.BoardShuffle]: '洗牌',
	[EffectKind.BoardBlast]: '引爆',
};

/** 作用对象的中文名。 */
export const EffectTargetNames: Record<EffectTarget, string> = {
	[EffectTarget.Self]: '自身',
	[EffectTarget.CurrentEnemy]: '当前敌人',
	[EffectTarget.AllEnemies]: '全体敌人',
	[EffectTarget.Board]: '棋盘',
	[EffectTarget.Reserved]: '预留',
};

/** 把效果列表格式化为可读文本：[物理伤害 13 → 当前敌人] */
export function formatEffects(specs: EffectSpec[]): string {
	const parts: string[] = [];
	for (const spec of specs) {
		parts.push(EffectKindNames[spec.kind] + ' ' + spec.value + ' → ' + EffectTargetNames[spec.target]);
	}
	return parts.join(' / ');
}

/** 战斗单位状态（玩家与敌人共用）。 */
export interface ActorState {
	hp: number;
	maxHp: number;
	shield: number;
	armor: number;
	buffStacks: number;
	debuffStacks: number;
	mana: number;
	maxMana: number;
}

/** 执行器需要的棋盘能力；由 Board 结构化实现，避免模块循环依赖。 */
export interface BoardOps {
	/** 重排整盘。 */
	shuffle(): void;
	/** 清除场上最大的连通块，返回移除块数。 */
	blastLargestGroup(): number;
	/** 把 count 个格子封锁为固定障碍（不可消除、不可连线的封锁格），返回实际封锁数。 */
	blockCells(count: number): number;
}

/** 执行一次效果列表所需的上下文。 */
export interface EffectContext {
	player: ActorState;
	currentEnemy: ActorState;
	allEnemies: ActorState[];
	board: BoardOps;
}

/** 新建一个战斗单位状态。 */
export function makeActor(hp: number, armor: number, maxMana: number): ActorState {
	return { hp, maxHp: hp, shield: 0, armor, buffStacks: 0, debuffStacks: 0, mana: 0, maxMana };
}

/** 叠加魔力并夹在 [0, maxMana] 内，返回实际增加量。 */
export function addMana(actor: ActorState, amount: number): number {
	const before = actor.mana;
	actor.mana += Math.round(amount);
	if (actor.mana > actor.maxMana) {
		actor.mana = actor.maxMana;
	}
	if (actor.mana < 0) {
		actor.mana = 0;
	}
	return actor.mana - before;
}

/** 扣除魔力；魔力不足时返回 false 且不扣除。 */
export function spendMana(actor: ActorState, amount: number): boolean {
	if (actor.mana < amount) {
		return false;
	}
	actor.mana -= amount;
	return true;
}

/** 破甲减益后的有效护甲。 */
export function effectiveArmor(actor: ActorState): number {
	const armor = actor.armor * (1 - actor.debuffStacks * Config.DebuffArmorPerStack);
	return armor < 0 ? 0 : armor;
}

/** 增伤层数换算的伤害倍率。 */
export function damageMultiplier(actor: ActorState): number {
	return 1 + actor.buffStacks * Config.BuffDamagePerStack;
}

/** 先扣护盾再扣生命，返回实际造成的生命伤害。 */
export function applyDamage(actor: ActorState, amount: number): number {
	let damage = Math.round(amount);
	if (damage < Config.MinDamage) {
		damage = Config.MinDamage;
	}
	if (actor.shield > 0) {
		const absorbed = damage < actor.shield ? damage : actor.shield;
		actor.shield -= absorbed;
		damage -= absorbed;
	}
	if (damage > 0) {
		actor.hp -= damage;
		if (actor.hp < 0) {
			actor.hp = 0;
		}
	}
	return damage;
}

/** 目标解析表：target → 接收者列表。新增目标类型只需在此加一条。 */
const targetResolvers: Record<string, ((context: EffectContext) => ActorState[]) | undefined> = {
	[EffectTarget.Self]: (context) => [context.player],
	[EffectTarget.CurrentEnemy]: (context) => [context.currentEnemy],
	[EffectTarget.AllEnemies]: (context) => context.allEnemies,
};

type EffectHandler = (context: EffectContext, spec: EffectSpec) => void;

/** 按 target 取接收者；未注册或预留的目标返回空列表。 */
export function resolveTargets(context: EffectContext, target: EffectTarget): ActorState[] {
	const resolver = targetResolvers[target];
	if (resolver === undefined) {
		return [];
	}
	return resolver(context);
}

/**
 * 效果执行表：kind → handler。新增效果种类只需在此加一条，
 * 方块效果与技能效果共用本表，执行器核心不含 if (kind === ...) 分支。
 */
const effectHandlers: Record<string, EffectHandler | undefined> = {
	[EffectKind.PhysicalDamage]: (context, spec) => {
		for (const target of resolveTargets(context, spec.target)) {
			applyDamage(target, spec.value * damageMultiplier(context.player) - effectiveArmor(target));
		}
	},
	[EffectKind.MagicDamage]: (context, spec) => {
		for (const target of resolveTargets(context, spec.target)) {
			const bonus = target.shield > 0 ? 1 + Config.MagicShieldBonus : 1;
			applyDamage(target, spec.value * bonus * damageMultiplier(context.player));
		}
	},
	[EffectKind.Heal]: (context, spec) => {
		for (const target of resolveTargets(context, spec.target)) {
			target.hp += Math.round(spec.value);
			if (target.hp > target.maxHp) {
				target.hp = target.maxHp;
			}
		}
	},
	[EffectKind.Dispel]: (context, spec) => {
		for (const target of resolveTargets(context, spec.target)) {
			target.debuffStacks -= Math.round(spec.value);
			if (target.debuffStacks < 0) {
				target.debuffStacks = 0;
			}
		}
	},
	[EffectKind.Shield]: (context, spec) => {
		for (const target of resolveTargets(context, spec.target)) {
			target.shield += Math.round(spec.value);
		}
	},
	[EffectKind.BuffDamage]: (context, spec) => {
		for (const target of resolveTargets(context, spec.target)) {
			target.buffStacks += Math.round(spec.value);
		}
	},
	[EffectKind.DebuffArmor]: (context, spec) => {
		for (const target of resolveTargets(context, spec.target)) {
			target.debuffStacks += Math.round(spec.value);
		}
	},
	[EffectKind.ManaGain]: (context, spec) => {
		for (const target of resolveTargets(context, spec.target)) {
			addMana(target, spec.value);
		}
	},
	[EffectKind.BoardShuffle]: (context, _spec) => {
		context.board.shuffle();
	},
	[EffectKind.BoardBlast]: (context, _spec) => {
		context.board.blastLargestGroup();
	},
	[EffectKind.BoardBlock]: (context, spec) => {
		context.board.blockCells(Math.round(spec.value));
	},
};

/** 尚未注册 handler 的效果次数（供自检与扩展性验收观测）。 */
let unhandledEffects = 0;

export function unhandledEffectCount(): number {
	return unhandledEffects;
}

export function resetUnhandledEffectCount(): void {
	unhandledEffects = 0;
}

/**
 * 统一执行器：只做“查表 → 按 target 取接收者 → 调用 handler”，
 * 返回实际执行的效果条目数；未注册的 kind 计入告警。
 */
export function executeEffects(specs: EffectSpec[], context: EffectContext): number {
	let executed = 0;
	for (const spec of specs) {
		const handler = effectHandlers[spec.kind];
		if (handler === undefined) {
			unhandledEffects++;
			continue;
		}
		handler(context, spec);
		executed++;
	}
	return executed;
}

// 分阶段强化：链长四档（2-3 / 4-5 / 6-7 / 8+），每档带一条数值倍率。
// 纯数据表：改表即生效，不改控件与执行器；倍率必须严格单调递增（由自检锁定）。

import { Config } from 'game/Config';

/** 一个链长档位的数据定义。 */
export interface ChainTierDef {
	id: string;
	/** 展示名（接触 / 连击 / 共鸣 / 超载）。 */
	name: string;
	/** 含下界。 */
	minChain: number;
	/** 含上界；最高档用大数表示“无上限”。 */
	maxChain: number;
	/** 数值倍率（严格单调递增）。 */
	multiplier: number;
}

/** 链长档位注册表：解析器只查表取倍率，不含任何按档位的分支。 */
export class ChainTiers {
	static readonly Contact = 'contact';
	static readonly Combo = 'combo';
	static readonly Resonance = 'resonance';
	static readonly Overload = 'overload';

	/** 最高档用该值表示“无上限”。 */
	static readonly NoLimit = 9999;

	/** 4 档：2-3 ×1.0 / 4-5 ×1.25 / 6-7 ×1.6 / 8+ ×2.1。 */
	static readonly List: ChainTierDef[] = [
		{ id: ChainTiers.Contact, name: '接触', minChain: Config.MinChainLength, maxChain: Config.MinChainLength + 1, multiplier: 1.0 },
		{ id: ChainTiers.Combo, name: '连击', minChain: 4, maxChain: 5, multiplier: 1.25 },
		{ id: ChainTiers.Resonance, name: '共鸣', minChain: 6, maxChain: 7, multiplier: 1.6 },
		{ id: ChainTiers.Overload, name: '超载', minChain: 8, maxChain: ChainTiers.NoLimit, multiplier: 2.1 },
	];

	static count(): number {
		return ChainTiers.List.length;
	}

	/** 取链长所在档位：低于首档下界回退首档，高于末档上界回退末档（永不返回 undefined）。 */
	static tierOf(chainLength: number): ChainTierDef {
		const list = ChainTiers.List;
		for (const tier of list) {
			if (chainLength >= tier.minChain && chainLength <= tier.maxChain) {
				return tier;
			}
		}
		if (chainLength < list[0].minChain) {
			return list[0];
		}
		return list[list.length - 1];
	}

	/** 链长对应的数值倍率（供解析器与自检使用）。 */
	static multiplierOf(chainLength: number): number {
		return ChainTiers.tierOf(chainLength).multiplier;
	}

	/** 链长对应档位的展示名。 */
	static nameOf(chainLength: number): string {
		return ChainTiers.tierOf(chainLength).name;
	}

	/** 倍率严格单调递增，且各档区间连续无空洞（自检锁定表格有效性）。 */
	static isStrictlyIncreasing(): boolean {
		const list = ChainTiers.List;
		if (list.length === 0) {
			return false;
		}
		for (let i = 0; i < list.length; i++) {
			if (list[i].maxChain < list[i].minChain) {
				return false;
			}
			if (i === 0) {
				continue;
			}
			if (list[i].multiplier <= list[i - 1].multiplier) {
				return false;
			}
			if (list[i].minChain !== list[i - 1].maxChain + 1) {
				return false;
			}
		}
		return true;
	}

	/** 全部档位的一行展示文本（供界面与自检报告）。 */
	static describeAll(): string {
		const parts: string[] = [];
		for (const tier of ChainTiers.List) {
			const upper = tier.maxChain >= ChainTiers.NoLimit ? '+' : '-' + tier.maxChain;
			parts.push(tier.minChain + upper + ' ' + tier.name + '×' + tier.multiplier);
		}
		return parts.join(' / ');
	}
}

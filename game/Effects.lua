-- [ts]: Effects.ts
local ____exports = {} -- 1
local ____Config = require("game.Config") -- 4
local Config = ____Config.Config -- 4
--- 构造一条效果规则，避免各处重复写全字段。
function ____exports.makeRule(kind, target, base, perBlock, minChain, floorTo) -- 52
	if minChain == nil then -- 52
		minChain = Config.MinChainLength -- 52
	end -- 52
	if floorTo == nil then -- 52
		floorTo = 0 -- 52
	end -- 52
	return { -- 53
		kind = kind, -- 53
		target = target, -- 53
		base = base, -- 53
		perBlock = perBlock, -- 53
		minChain = minChain, -- 53
		floorTo = floorTo -- 53
	} -- 53
end -- 52
--- 按取整粒度把原始数值归整。
function ____exports.roundRuleValue(raw, floorTo) -- 57
	if floorTo > 0 then -- 57
		return math.floor(raw / floorTo) * floorTo -- 59
	end -- 59
	return math.floor(raw + 0.5) -- 61
end -- 57
--- 把方块的效果规则展开为效果三元组列表。
-- 链长低于规则下限时跳过该条；链长低于全局下限时统一返回空列表。
function ____exports.resolveEffects(rules, chainLength) -- 68
	local specs = {} -- 69
	if chainLength < Config.MinChainLength then -- 69
		return specs -- 71
	end -- 71
	for ____, rule in ipairs(rules) do -- 73
		do -- 73
			if chainLength < rule.minChain then -- 73
				goto __continue7 -- 75
			end -- 75
			local raw = rule.base + rule.perBlock * chainLength -- 77
			specs[#specs + 1] = { -- 78
				kind = rule.kind, -- 78
				value = ____exports.roundRuleValue(raw, rule.floorTo), -- 78
				target = rule.target -- 78
			} -- 78
		end -- 78
		::__continue7:: -- 78
	end -- 78
	return specs -- 80
end -- 68
--- 效果类型的中文名（用于日志、飘字与自检报告）。
____exports.EffectKindNames = { -- 84
	physicalDamage = "物理伤害", -- 85
	magicDamage = "魔法伤害", -- 86
	heal = "治疗", -- 87
	dispel = "净化", -- 88
	shield = "护盾", -- 89
	buffDamage = "增伤", -- 90
	debuffArmor = "破甲", -- 91
	manaGain = "魔力", -- 92
	boardBlock = "封锁", -- 93
	boardShuffle = "洗牌", -- 94
	boardBlast = "引爆" -- 95
} -- 95
--- 作用对象的中文名。
____exports.EffectTargetNames = { -- 99
	self = "自身", -- 100
	currentEnemy = "当前敌人", -- 101
	allEnemies = "全体敌人", -- 102
	board = "棋盘", -- 103
	reserved = "预留" -- 104
} -- 104
--- 把效果列表格式化为可读文本：[物理伤害 13 → 当前敌人]
function ____exports.formatEffects(specs) -- 108
	local parts = {} -- 109
	for ____, spec in ipairs(specs) do -- 110
		parts[#parts + 1] = (((____exports.EffectKindNames[spec.kind] .. " ") .. tostring(spec.value)) .. " → ") .. ____exports.EffectTargetNames[spec.target] -- 111
	end -- 111
	return table.concat(parts, " / ") -- 113
end -- 108
--- 新建一个战斗单位状态。
function ____exports.makeActor(hp, armor, maxMana) -- 147
	return { -- 148
		hp = hp, -- 148
		maxHp = hp, -- 148
		shield = 0, -- 148
		armor = armor, -- 148
		buffStacks = 0, -- 148
		debuffStacks = 0, -- 148
		mana = 0, -- 148
		maxMana = maxMana -- 148
	} -- 148
end -- 147
--- 叠加魔力并夹在 [0, maxMana] 内，返回实际增加量。
function ____exports.addMana(actor, amount) -- 152
	local before = actor.mana -- 153
	actor.mana = actor.mana + math.floor(amount + 0.5) -- 154
	if actor.mana > actor.maxMana then -- 154
		actor.mana = actor.maxMana -- 156
	end -- 156
	if actor.mana < 0 then -- 156
		actor.mana = 0 -- 159
	end -- 159
	return actor.mana - before -- 161
end -- 152
--- 扣除魔力；魔力不足时返回 false 且不扣除。
function ____exports.spendMana(actor, amount) -- 165
	if actor.mana < amount then -- 165
		return false -- 167
	end -- 167
	actor.mana = actor.mana - amount -- 169
	return true -- 170
end -- 165
--- 破甲减益后的有效护甲。
function ____exports.effectiveArmor(actor) -- 174
	local armor = actor.armor * (1 - actor.debuffStacks * Config.DebuffArmorPerStack) -- 175
	return armor < 0 and 0 or armor -- 176
end -- 174
--- 增伤层数换算的伤害倍率。
function ____exports.damageMultiplier(actor) -- 180
	return 1 + actor.buffStacks * Config.BuffDamagePerStack -- 181
end -- 180
--- 先扣护盾再扣生命，返回实际造成的生命伤害。
function ____exports.applyDamage(actor, amount) -- 185
	local damage = math.floor(amount + 0.5) -- 186
	if damage < Config.MinDamage then -- 186
		damage = Config.MinDamage -- 188
	end -- 188
	if actor.shield > 0 then -- 188
		local absorbed = damage < actor.shield and damage or actor.shield -- 191
		actor.shield = actor.shield - absorbed -- 192
		damage = damage - absorbed -- 193
	end -- 193
	if damage > 0 then -- 193
		actor.hp = actor.hp - damage -- 196
		if actor.hp < 0 then -- 196
			actor.hp = 0 -- 198
		end -- 198
	end -- 198
	return damage -- 201
end -- 185
--- 目标解析表：target → 接收者列表。新增目标类型只需在此加一条。
local targetResolvers = { -- 205
	self = function(context) return {context.player} end, -- 206
	currentEnemy = function(context) return {context.currentEnemy} end, -- 207
	allEnemies = function(context) return context.allEnemies end -- 208
} -- 208
--- 按 target 取接收者；未注册或预留的目标返回空列表。
function ____exports.resolveTargets(context, target) -- 214
	local resolver = targetResolvers[target] -- 215
	if resolver == nil then -- 215
		return {} -- 217
	end -- 217
	return resolver(context) -- 219
end -- 214
--- 效果执行表：kind → handler。新增效果种类只需在此加一条，
-- 方块效果与技能效果共用本表，执行器核心不含 if (kind === ...) 分支。
local effectHandlers = { -- 226
	physicalDamage = function(context, spec) -- 227
		for ____, target in ipairs(____exports.resolveTargets(context, spec.target)) do -- 228
			____exports.applyDamage( -- 229
				target, -- 229
				spec.value * ____exports.damageMultiplier(context.player) - ____exports.effectiveArmor(target) -- 229
			) -- 229
		end -- 229
	end, -- 227
	magicDamage = function(context, spec) -- 232
		for ____, target in ipairs(____exports.resolveTargets(context, spec.target)) do -- 233
			local bonus = target.shield > 0 and 1 + Config.MagicShieldBonus or 1 -- 234
			____exports.applyDamage( -- 235
				target, -- 235
				spec.value * bonus * ____exports.damageMultiplier(context.player) -- 235
			) -- 235
		end -- 235
	end, -- 232
	heal = function(context, spec) -- 238
		for ____, target in ipairs(____exports.resolveTargets(context, spec.target)) do -- 239
			target.hp = target.hp + math.floor(spec.value + 0.5) -- 240
			if target.hp > target.maxHp then -- 240
				target.hp = target.maxHp -- 242
			end -- 242
		end -- 242
	end, -- 238
	dispel = function(context, spec) -- 246
		for ____, target in ipairs(____exports.resolveTargets(context, spec.target)) do -- 247
			target.debuffStacks = target.debuffStacks - math.floor(spec.value + 0.5) -- 248
			if target.debuffStacks < 0 then -- 248
				target.debuffStacks = 0 -- 250
			end -- 250
		end -- 250
	end, -- 246
	shield = function(context, spec) -- 254
		for ____, target in ipairs(____exports.resolveTargets(context, spec.target)) do -- 255
			target.shield = target.shield + math.floor(spec.value + 0.5) -- 256
		end -- 256
	end, -- 254
	buffDamage = function(context, spec) -- 259
		for ____, target in ipairs(____exports.resolveTargets(context, spec.target)) do -- 260
			target.buffStacks = target.buffStacks + math.floor(spec.value + 0.5) -- 261
		end -- 261
	end, -- 259
	debuffArmor = function(context, spec) -- 264
		for ____, target in ipairs(____exports.resolveTargets(context, spec.target)) do -- 265
			target.debuffStacks = target.debuffStacks + math.floor(spec.value + 0.5) -- 266
		end -- 266
	end, -- 264
	manaGain = function(context, spec) -- 269
		for ____, target in ipairs(____exports.resolveTargets(context, spec.target)) do -- 270
			____exports.addMana(target, spec.value) -- 271
		end -- 271
	end, -- 269
	boardShuffle = function(context, _spec) -- 274
		context.board:shuffle() -- 275
	end, -- 274
	boardBlast = function(context, _spec) -- 277
		context.board:blastLargestGroup() -- 278
	end, -- 277
	boardBlock = function(context, spec) -- 280
		context.board:blockCells(math.floor(spec.value + 0.5)) -- 281
	end -- 280
} -- 280
--- 尚未注册 handler 的效果次数（供自检与扩展性验收观测）。
local unhandledEffects = 0 -- 286
function ____exports.unhandledEffectCount() -- 288
	return unhandledEffects -- 289
end -- 288
function ____exports.resetUnhandledEffectCount() -- 292
	unhandledEffects = 0 -- 293
end -- 292
--- 统一执行器：只做“查表 → 按 target 取接收者 → 调用 handler”，
-- 返回实际执行的效果条目数；未注册的 kind 计入告警。
function ____exports.executeEffects(specs, context) -- 300
	local executed = 0 -- 301
	for ____, spec in ipairs(specs) do -- 302
		do -- 302
			local handler = effectHandlers[spec.kind] -- 303
			if handler == nil then -- 303
				unhandledEffects = unhandledEffects + 1 -- 305
				goto __continue63 -- 306
			end -- 306
			handler(context, spec) -- 308
			executed = executed + 1 -- 309
		end -- 309
		::__continue63:: -- 309
	end -- 309
	return executed -- 311
end -- 300
return ____exports -- 300
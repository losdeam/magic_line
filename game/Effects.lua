-- [ts]: Effects.ts
local ____exports = {} -- 1
local ____ChainTiers = require("game.ChainTiers") -- 4
local ChainTiers = ____ChainTiers.ChainTiers -- 4
local ____Config = require("game.Config") -- 5
local Config = ____Config.Config -- 5
--- 构造一条效果规则，避免各处重复写全字段。
function ____exports.makeRule(kind, target, base, perBlock, minChain, floorTo, scaled) -- 55
	if minChain == nil then -- 55
		minChain = Config.MinChainLength -- 55
	end -- 55
	if floorTo == nil then -- 55
		floorTo = 0 -- 55
	end -- 55
	if scaled == nil then -- 55
		scaled = true -- 55
	end -- 55
	return { -- 56
		kind = kind, -- 56
		target = target, -- 56
		base = base, -- 56
		perBlock = perBlock, -- 56
		minChain = minChain, -- 56
		floorTo = floorTo, -- 56
		scaled = scaled -- 56
	} -- 56
end -- 55
--- 按取整粒度把原始数值归整。
function ____exports.roundRuleValue(raw, floorTo) -- 60
	if floorTo > 0 then -- 60
		return math.floor(raw / floorTo) * floorTo -- 62
	end -- 62
	return math.floor(raw + 0.5) -- 64
end -- 60
--- 把方块的效果规则展开为效果三元组列表。
-- 链长低于规则下限时跳过该条；链长低于全局下限时统一返回空列表。
function ____exports.resolveEffects(rules, chainLength) -- 71
	local specs = {} -- 72
	if chainLength < Config.MinChainLength then -- 72
		return specs -- 74
	end -- 74
	local tierMultiplier = ChainTiers:multiplierOf(chainLength) -- 77
	for ____, rule in ipairs(rules) do -- 78
		do -- 78
			if chainLength < rule.minChain then -- 78
				goto __continue7 -- 80
			end -- 80
			local raw = rule.base + rule.perBlock * chainLength -- 82
			if rule.scaled then -- 82
				raw = raw * tierMultiplier -- 84
			end -- 84
			specs[#specs + 1] = { -- 86
				kind = rule.kind, -- 86
				value = ____exports.roundRuleValue(raw, rule.floorTo), -- 86
				target = rule.target -- 86
			} -- 86
		end -- 86
		::__continue7:: -- 86
	end -- 86
	return specs -- 88
end -- 71
--- 效果类型的中文名（用于日志、飘字与自检报告）。
____exports.EffectKindNames = { -- 92
	physicalDamage = "物理伤害", -- 93
	magicDamage = "魔法伤害", -- 94
	heal = "治疗", -- 95
	dispel = "净化", -- 96
	shield = "护盾", -- 97
	buffDamage = "增伤", -- 98
	debuffArmor = "破甲", -- 99
	manaGain = "魔力", -- 100
	boardBlock = "封锁", -- 101
	boardShuffle = "洗牌", -- 102
	boardBlast = "引爆" -- 103
} -- 103
--- 作用对象的中文名。
____exports.EffectTargetNames = { -- 107
	self = "自身", -- 108
	currentEnemy = "当前敌人", -- 109
	allEnemies = "全体敌人", -- 110
	board = "棋盘", -- 111
	reserved = "预留" -- 112
} -- 112
--- 把效果列表格式化为可读文本：[物理伤害 13 → 当前敌人]
function ____exports.formatEffects(specs) -- 116
	local parts = {} -- 117
	for ____, spec in ipairs(specs) do -- 118
		parts[#parts + 1] = (((____exports.EffectKindNames[spec.kind] .. " ") .. tostring(spec.value)) .. " → ") .. ____exports.EffectTargetNames[spec.target] -- 119
	end -- 119
	return table.concat(parts, " / ") -- 121
end -- 116
--- 新建一个战斗单位状态。
function ____exports.makeActor(hp, armor, maxMana) -- 155
	return { -- 156
		hp = hp, -- 156
		maxHp = hp, -- 156
		shield = 0, -- 156
		armor = armor, -- 156
		buffStacks = 0, -- 156
		debuffStacks = 0, -- 156
		mana = 0, -- 156
		maxMana = maxMana -- 156
	} -- 156
end -- 155
--- 叠加魔力并夹在 [0, maxMana] 内，返回实际增加量。
function ____exports.addMana(actor, amount) -- 160
	local before = actor.mana -- 161
	actor.mana = actor.mana + math.floor(amount + 0.5) -- 162
	if actor.mana > actor.maxMana then -- 162
		actor.mana = actor.maxMana -- 164
	end -- 164
	if actor.mana < 0 then -- 164
		actor.mana = 0 -- 167
	end -- 167
	return actor.mana - before -- 169
end -- 160
--- 扣除魔力；魔力不足时返回 false 且不扣除。
function ____exports.spendMana(actor, amount) -- 173
	if actor.mana < amount then -- 173
		return false -- 175
	end -- 175
	actor.mana = actor.mana - amount -- 177
	return true -- 178
end -- 173
--- 破甲减益后的有效护甲。
function ____exports.effectiveArmor(actor) -- 182
	local armor = actor.armor * (1 - actor.debuffStacks * Config.DebuffArmorPerStack) -- 183
	return armor < 0 and 0 or armor -- 184
end -- 182
--- 增伤层数换算的伤害倍率。
function ____exports.damageMultiplier(actor) -- 188
	return 1 + actor.buffStacks * Config.BuffDamagePerStack -- 189
end -- 188
--- 先扣护盾再扣生命，返回实际造成的生命伤害。
function ____exports.applyDamage(actor, amount) -- 193
	local damage = math.floor(amount + 0.5) -- 194
	if damage < Config.MinDamage then -- 194
		damage = Config.MinDamage -- 196
	end -- 196
	if actor.shield > 0 then -- 196
		local absorbed = damage < actor.shield and damage or actor.shield -- 199
		actor.shield = actor.shield - absorbed -- 200
		damage = damage - absorbed -- 201
	end -- 201
	if damage > 0 then -- 201
		actor.hp = actor.hp - damage -- 204
		if actor.hp < 0 then -- 204
			actor.hp = 0 -- 206
		end -- 206
	end -- 206
	return damage -- 209
end -- 193
--- 目标解析表：target → 接收者列表。新增目标类型只需在此加一条。
local targetResolvers = { -- 213
	self = function(context) return {context.player} end, -- 214
	currentEnemy = function(context) return {context.currentEnemy} end, -- 215
	allEnemies = function(context) return context.allEnemies end -- 216
} -- 216
--- 按 target 取接收者；未注册或预留的目标返回空列表。
function ____exports.resolveTargets(context, target) -- 222
	local resolver = targetResolvers[target] -- 223
	if resolver == nil then -- 223
		return {} -- 225
	end -- 225
	return resolver(context) -- 227
end -- 222
--- 效果执行表：kind → handler。新增效果种类只需在此加一条，
-- 方块效果与技能效果共用本表，执行器核心不含 if (kind === ...) 分支。
local effectHandlers = { -- 234
	physicalDamage = function(context, spec) -- 235
		for ____, target in ipairs(____exports.resolveTargets(context, spec.target)) do -- 236
			____exports.applyDamage( -- 237
				target, -- 237
				spec.value * ____exports.damageMultiplier(context.player) - ____exports.effectiveArmor(target) -- 237
			) -- 237
		end -- 237
	end, -- 235
	magicDamage = function(context, spec) -- 240
		for ____, target in ipairs(____exports.resolveTargets(context, spec.target)) do -- 241
			local bonus = target.shield > 0 and 1 + Config.MagicShieldBonus or 1 -- 242
			____exports.applyDamage( -- 243
				target, -- 243
				spec.value * bonus * ____exports.damageMultiplier(context.player) -- 243
			) -- 243
		end -- 243
	end, -- 240
	heal = function(context, spec) -- 246
		for ____, target in ipairs(____exports.resolveTargets(context, spec.target)) do -- 247
			target.hp = target.hp + math.floor(spec.value + 0.5) -- 248
			if target.hp > target.maxHp then -- 248
				target.hp = target.maxHp -- 250
			end -- 250
		end -- 250
	end, -- 246
	dispel = function(context, spec) -- 254
		for ____, target in ipairs(____exports.resolveTargets(context, spec.target)) do -- 255
			target.debuffStacks = target.debuffStacks - math.floor(spec.value + 0.5) -- 256
			if target.debuffStacks < 0 then -- 256
				target.debuffStacks = 0 -- 258
			end -- 258
		end -- 258
	end, -- 254
	shield = function(context, spec) -- 262
		for ____, target in ipairs(____exports.resolveTargets(context, spec.target)) do -- 263
			target.shield = target.shield + math.floor(spec.value + 0.5) -- 264
		end -- 264
	end, -- 262
	buffDamage = function(context, spec) -- 267
		for ____, target in ipairs(____exports.resolveTargets(context, spec.target)) do -- 268
			target.buffStacks = target.buffStacks + math.floor(spec.value + 0.5) -- 269
		end -- 269
	end, -- 267
	debuffArmor = function(context, spec) -- 272
		for ____, target in ipairs(____exports.resolveTargets(context, spec.target)) do -- 273
			target.debuffStacks = target.debuffStacks + math.floor(spec.value + 0.5) -- 274
		end -- 274
	end, -- 272
	manaGain = function(context, spec) -- 277
		for ____, target in ipairs(____exports.resolveTargets(context, spec.target)) do -- 278
			____exports.addMana(target, spec.value) -- 279
		end -- 279
	end, -- 277
	boardShuffle = function(context, _spec) -- 282
		context.board:shuffle() -- 283
	end, -- 282
	boardBlast = function(context, _spec) -- 285
		context.board:blastLargestGroup() -- 286
	end, -- 285
	boardBlock = function(context, spec) -- 288
		context.board:blockCells(math.floor(spec.value + 0.5)) -- 289
	end -- 288
} -- 288
--- 尚未注册 handler 的效果次数（供自检与扩展性验收观测）。
local unhandledEffects = 0 -- 294
function ____exports.unhandledEffectCount() -- 296
	return unhandledEffects -- 297
end -- 296
function ____exports.resetUnhandledEffectCount() -- 300
	unhandledEffects = 0 -- 301
end -- 300
--- 统一执行器：只做“查表 → 按 target 取接收者 → 调用 handler”，
-- 返回实际执行的效果条目数；未注册的 kind 计入告警。
function ____exports.executeEffects(specs, context) -- 308
	local executed = 0 -- 309
	for ____, spec in ipairs(specs) do -- 310
		do -- 310
			local handler = effectHandlers[spec.kind] -- 311
			if handler == nil then -- 311
				unhandledEffects = unhandledEffects + 1 -- 313
				goto __continue64 -- 314
			end -- 314
			handler(context, spec) -- 316
			executed = executed + 1 -- 317
		end -- 317
		::__continue64:: -- 317
	end -- 317
	return executed -- 319
end -- 308
return ____exports -- 308
// HUD 与面板：双方血条、魔力条、敌方行动倒计时、技能按钮、关卡/波次、飘字、设置面板与结算面板。
// 全部由 ui/Controls.ts 的控件拼装；自身不注册 schedule，由 Game 的单一循环调用 update(dt)。

import { Color, DrawNode, Label, Node, Vec2 } from 'Dora';
import { Config } from 'game/Config';
import { SkillDef } from 'game/Skills';
import { HudLayout, Palette } from 'game/UiLayout';
import { BarWidget, ButtonWidget, FloatTextWidget, PanelWidget, makeLabel } from 'game/ui/Controls';
import { colorFromHex } from 'game/ui/Widget';

/** 飘字分道：对敌效果 / 我方受伤与治疗 / 系统提示，三条道位置互不重叠。 */
export const enum NoticeLane {
	Enemy = 0,
	Player = 1,
	System = 2,
}

export class Hud {
	readonly root: Node.Type;
	private readonly stageLabel: Label.Type | undefined;
	private readonly enemyName: Label.Type | undefined;
	private readonly enemyBar: BarWidget;
	private readonly timerLabel: Label.Type | undefined;
	private readonly playerBar: BarWidget;
	private readonly manaBar: BarWidget;
	private readonly hintLabel: Label.Type | undefined;
	private readonly skillButtons: ButtonWidget[] = [];
	private readonly skillCosts: number[] = [];
	/** 技能 id 与按钮一一对应，供释放反馈定位按钮。 */
	private readonly skillIds: string[] = [];
	/** 飘字分道：每条道一个控件 + 一个待播队列，保证同屏飘字不叠在同一位置。 */
	private readonly floatLanes: FloatTextWidget[] = [];
	private readonly floatQueue: string[][] = [];
	private readonly floatQueueHex: number[][] = [];
	/** 全屏受击红闪层（z 低于 HUD 其它元素，也不拦截触控）。 */
	private readonly hitLayer: DrawNode.Type;
	private hitTint = 0;
	private readonly playerName: Label.Type | undefined;
	private readonly timerBar: BarWidget;
	private static readonly LaneX: number[] = [Config.NoticeEnemyX, Config.NoticePlayerX, Config.NoticeSystemX];
	private static readonly LaneY: number[] = [Config.NoticeEnemyY, Config.NoticePlayerY, Config.NoticeSystemY];
	private readonly settingsButton: ButtonWidget;
	private readonly settingsPanelParts: Node.Type[] = [];
	private readonly settingsButtons: ButtonWidget[] = [];
	private readonly modeButton: ButtonWidget;
	private readonly difficultyButton: ButtonWidget;
	private readonly hintButton: ButtonWidget;
	private readonly saveLabel: Label.Type | undefined;
	private settingsOpen = false;
	private readonly panelParts: Node.Type[] = [];
	private readonly panelText: Label.Type | undefined;
	private readonly restartButton: ButtonWidget;
	onSkill: (skillId: string) => void = () => {};
	onRestart: () => void = () => {};
	onToggleMode: () => void = () => {};
	onCycleDifficulty: () => void = () => {};
	onToggleHint: () => void = () => {};

	constructor(skills: SkillDef[]) {
		const root = Node();
		this.root = root;

		// 全屏受击红闪：z 低于 HUD 其它元素（不遮挡文字与面板），也不拦截触控
		const hitLayer = DrawNode();
		hitLayer.z = -1;
		hitLayer.addTo(root);
		this.hitLayer = hitLayer;

		this.stageLabel = makeLabel('', HudLayout.FontStage);
		if (this.stageLabel !== undefined) {
			this.stageLabel.position = Vec2(0, HudLayout.StageY);
			this.stageLabel.addTo(root);
		}

		this.enemyName = makeLabel('', HudLayout.FontName);
		if (this.enemyName !== undefined) {
			this.enemyName.position = Vec2(0, HudLayout.EnemyNameY);
			this.enemyName.addTo(root);
		}
		this.enemyBar = new BarWidget(HudLayout.EnemyBarWidth, HudLayout.EnemyBarHeight, Palette.EnemyBar);
		this.enemyBar.setPosition(0, HudLayout.EnemyBarY);
		this.enemyBar.addTo(root);

		this.timerLabel = makeLabel('', HudLayout.FontLabel);
		if (this.timerLabel !== undefined) {
			this.timerLabel.position = Vec2(0, HudLayout.TimerLabelY);
			this.timerLabel.addTo(root);
		}

		this.playerBar = new BarWidget(HudLayout.PlayerBarWidth, HudLayout.PlayerBarHeight, Palette.PlayerBar);
		this.playerBar.setPosition(0, HudLayout.PlayerBarY);
		this.playerBar.addTo(root);
		// 明确标注“这条是玩家自己的生命”，避免与敌方血条混淆
		this.playerName = makeLabel('玩家生命', HudLayout.FontLabel);
		if (this.playerName !== undefined) {
			this.playerName.anchor = Vec2(1, 0.5);
			this.playerName.position = Vec2(HudLayout.PlayerNameX, HudLayout.PlayerBarY);
			this.playerName.addTo(root);
		}

		this.manaBar = new BarWidget(HudLayout.ManaBarWidth, HudLayout.ManaBarHeight, Palette.ManaBar);
		this.manaBar.setPosition(0, HudLayout.ManaBarY);
		this.manaBar.addTo(root);

		// 敌方行动进度条：实时模式按秒推进，回合制按回合推进（均显示剩余比例）
		this.timerBar = new BarWidget(HudLayout.TimerBarWidth, HudLayout.TimerBarHeight, Palette.TimerBar);
		this.timerBar.setPosition(0, HudLayout.TimerBarY);
		this.timerBar.addTo(root);

		// 技能按钮：由技能注册表驱动，一个技能一个按钮
		for (let i = 0; i < skills.length; i++) {
			const def = skills[i];
			const button = new ButtonWidget(def.name + ' ' + def.cost, HudLayout.SkillButtonWidth, HudLayout.SkillButtonHeight, Palette.ButtonPrimary);
			button.setPosition((i - (skills.length - 1) / 2) * HudLayout.SkillButtonSpacing, HudLayout.SkillButtonY);
			button.addTo(root);
			const id = def.id;
			button.onClick = () => this.onSkill(id);
			this.skillButtons.push(button);
			this.skillCosts.push(def.cost);
			this.skillIds.push(def.id);
		}

		for (let lane = 0; lane < 3; lane++) {
			const widget = new FloatTextWidget(HudLayout.FontNotice);
			widget.addTo(root);
			this.floatLanes.push(widget);
			const queue: string[] = [];
			const hexes: number[] = [];
			this.floatQueue.push(queue);
			this.floatQueueHex.push(hexes);
		}

		// 底部操作提示（可由设置关闭）
		this.hintLabel = makeLabel('按住滑过相邻同色方块，松手结算（≥2 连即可消除）', HudLayout.FontLabel);
		if (this.hintLabel !== undefined) {
			this.hintLabel.position = Vec2(0, HudLayout.HintY);
			this.hintLabel.addTo(root);
		}

		// 设置入口
		this.settingsButton = new ButtonWidget('设置', HudLayout.SettingsButtonWidth, HudLayout.SettingsButtonHeight, Palette.ButtonNeutral);
		this.settingsButton.setPosition(HudLayout.SettingsButtonX, HudLayout.SettingsButtonY);
		this.settingsButton.addTo(root);
		this.settingsButton.onClick = () => this.toggleSettings();

		// 设置面板（默认隐藏）
		const settingsPanel = new PanelWidget(HudLayout.SettingsPanelWidth, HudLayout.SettingsPanelHeight, Palette.PanelBackground);
		settingsPanel.setPosition(0, 0);
		settingsPanel.addTo(root);
		this.settingsPanelParts.push(settingsPanel.root);
		const settingsTitle = makeLabel('设置', HudLayout.FontPanelTitle);
		if (settingsTitle !== undefined) {
			settingsTitle.position = Vec2(0, HudLayout.SettingsTitleY);
			settingsTitle.addTo(root);
			this.settingsPanelParts.push(settingsTitle);
		}
		this.modeButton = new ButtonWidget('模式：回合制', HudLayout.SettingsRowWidth, HudLayout.SettingsRowHeight, Palette.ButtonPrimary);
		this.modeButton.setPosition(0, HudLayout.SettingsModeY);
		this.modeButton.addTo(root);
		this.modeButton.onClick = () => this.onToggleMode();
		this.settingsPanelParts.push(this.modeButton.root);
		this.settingsButtons.push(this.modeButton);
		this.difficultyButton = new ButtonWidget('难度：标准', HudLayout.SettingsRowWidth, HudLayout.SettingsRowHeight, Palette.ButtonPrimary);
		this.difficultyButton.setPosition(0, HudLayout.SettingsDifficultyY);
		this.difficultyButton.addTo(root);
		this.difficultyButton.onClick = () => this.onCycleDifficulty();
		this.settingsPanelParts.push(this.difficultyButton.root);
		this.settingsButtons.push(this.difficultyButton);
		this.hintButton = new ButtonWidget('操作提示：开', HudLayout.SettingsRowWidth, HudLayout.SettingsRowHeight, Palette.ButtonPrimary);
		this.hintButton.setPosition(0, HudLayout.SettingsHintY);
		this.hintButton.addTo(root);
		this.hintButton.onClick = () => this.onToggleHint();
		this.settingsPanelParts.push(this.hintButton.root);
		this.settingsButtons.push(this.hintButton);
		const closeButton = new ButtonWidget('关闭设置', HudLayout.SettingsCloseWidth, HudLayout.SettingsCloseHeight, Palette.ButtonNeutral);
		closeButton.setPosition(0, HudLayout.SettingsCloseY);
		closeButton.addTo(root);
		closeButton.onClick = () => this.closeSettings();
		this.settingsPanelParts.push(closeButton.root);
		this.settingsButtons.push(closeButton);
		this.saveLabel = makeLabel('', HudLayout.FontSmall);
		if (this.saveLabel !== undefined) {
			this.saveLabel.position = Vec2(0, HudLayout.SettingsSaveY);
			this.saveLabel.addTo(root);
			this.settingsPanelParts.push(this.saveLabel);
		}

		// 结算面板（默认隐藏）
		const panel = new PanelWidget(HudLayout.DefeatPanelWidth, HudLayout.DefeatPanelHeight, Palette.PanelBackground);
		panel.setPosition(0, 0);
		panel.addTo(root);
		this.panelParts.push(panel.root);
		const title = makeLabel('战斗结束', HudLayout.FontPanelTitleLarge);
		if (title !== undefined) {
			title.position = Vec2(0, HudLayout.DefeatTitleY);
			title.addTo(root);
			this.panelParts.push(title);
		}
		this.panelText = makeLabel('', HudLayout.FontStage);
		if (this.panelText !== undefined) {
			this.panelText.position = Vec2(0, HudLayout.DefeatTextY);
			this.panelText.addTo(root);
			this.panelParts.push(this.panelText);
		}
		const restart = new ButtonWidget('重新开始本关', HudLayout.DefeatButtonWidth, HudLayout.DefeatButtonHeight, Palette.ButtonPrimary);
		restart.setPosition(0, HudLayout.DefeatButtonY);
		restart.addTo(root);
		restart.onClick = () => this.onRestart();
		this.panelParts.push(restart.root);
		this.restartButton = restart;

		this.closeSettings();
		this.hideDefeat();
	}

	get isSettingsOpen(): boolean {
		return this.settingsOpen;
	}

	toggleSettings(): void {
		if (this.settingsOpen) {
			this.closeSettings();
			return;
		}
		this.openSettings();
	}

	openSettings(): void {
		this.settingsOpen = true;
		for (const part of this.settingsPanelParts) {
			part.visible = true;
		}
		for (const button of this.settingsButtons) {
			button.setEnabled(true);
		}
	}

	closeSettings(): void {
		this.settingsOpen = false;
		for (const part of this.settingsPanelParts) {
			part.visible = false;
		}
		// 隐藏时禁用按钮，避免不可见控件截获棋盘触控
		for (const button of this.settingsButtons) {
			button.setEnabled(false);
		}
	}

	/** 同步设置面板文本、底部提示可见性与存档状态。 */
	syncSettings(modeName: string, difficultyName: string, hintOn: boolean, saved: boolean): void {
		this.modeButton.setText('模式：' + modeName);
		this.difficultyButton.setText('难度：' + difficultyName);
		this.hintButton.setText('操作提示：' + (hintOn ? '开' : '关'));
		if (this.hintLabel !== undefined) {
			this.hintLabel.visible = hintOn;
		}
		if (this.saveLabel !== undefined) {
			this.saveLabel.text = saved ? '设置已保存' : '设置未保存（仅内存态生效）';
			this.saveLabel.color = colorFromHex(saved ? Palette.TextOk : Palette.TextWarn, 255);
		}
	}

	update(dt: number): void {
		this.enemyBar.update(dt);
		this.timerBar.update(dt);
		this.playerBar.update(dt);
		this.manaBar.update(dt);
		// 技能按钮的按下与亮光动画也由单一循环驱动
		for (const button of this.skillButtons) {
			button.update(dt);
		}
		// 每条道独立排队：当前飘字播完才播同一条道的下一条，避免同位置叠加
		for (let lane = 0; lane < this.floatLanes.length; lane++) {
			const widget = this.floatLanes[lane];
			widget.update(dt);
			if (widget.active) {
				continue;
			}
			const queue = this.floatQueue[lane];
			if (queue.length === 0) {
				continue;
			}
			const text = queue.shift();
			const hex = this.floatQueueHex[lane].shift();
			if (text !== undefined && hex !== undefined) {
				this.playNotice(lane, text, hex);
			}
		}
		if (this.hitTint > 0) {
			this.hitTint -= dt * 320;
			if (this.hitTint < 0) {
				this.hitTint = 0;
			}
			this.drawHitTint();
		}
	}

	setStageInfo(text: string): void {
		if (this.stageLabel !== undefined) {
			this.stageLabel.text = text;
		}
	}

	setEnemyInfo(name: string, hp: number, maxHp: number): void {
		if (this.enemyName !== undefined) {
			this.enemyName.text = name;
		}
		this.enemyBar.set('敌方生命 ' + hp + '/' + maxHp, hp, maxHp);
	}

	setTimerInfo(text: string, remainingRatio: number = 1): void {
		if (this.timerLabel !== undefined) {
			this.timerLabel.text = text;
		}
		// 进度条不写字，只展示“还剩多少进度就该敌方行动”
		this.timerBar.set('', remainingRatio * 100, 100);
	}

	setPlayerInfo(hp: number, maxHp: number, mana: number, maxMana: number): void {
		this.playerBar.set('生命 ' + hp + '/' + maxHp, hp, maxHp);
		this.manaBar.set('魔力 ' + mana + '/' + maxMana, mana, maxMana);
	}

	/** 技能释放成功：对应按钮亮一下（技能动画的 HUD 侧反馈）。 */
	glowSkill(skillId: string): void {
		for (let i = 0; i < this.skillIds.length; i++) {
			if (this.skillIds[i] === skillId) {
				this.skillButtons[i].glow();
				return;
			}
		}
	}

	/** 根据当前魔力更新技能按钮可用状态。 */
	syncSkills(mana: number): void {
		for (let i = 0; i < this.skillButtons.length; i++) {
			this.skillButtons[i].setEnabled(mana >= this.skillCosts[i]);
		}
	}

	/**
	 * 显示一条飘字。按 lane 分道（对敌 / 我方 / 系统），同一条道内排队播放，
	 * 因此伤害飘字与受伤飘字不会叠在同一位置。
	 */
	showNotice(text: string, lane: number = NoticeLane.System, hex: number = Palette.NoticeDefault): void {
		if (this.floatLanes.length === 0) {
			return;
		}
		let index = lane;
		if (index < 0 || index >= this.floatLanes.length) {
			index = NoticeLane.System;
		}
		if (!this.floatLanes[index].active) {
			this.playNotice(index, text, hex);
			return;
		}
		const queue = this.floatQueue[index];
		if (queue.length >= 3) {
			// 队列过长时丢弃最早的一条，避免提示积压
			queue.shift();
			this.floatQueueHex[index].shift();
		}
		queue.push(text);
		this.floatQueueHex[index].push(hex);
	}

	/** 我方受击：生命条闪红抖动 + 全屏红闪，并在我方道飘出损失的生命值。 */
	hitPlayer(damage: number): void {
		this.playerBar.flash(Palette.HitFlashPlayer, Config.HitFlashDuration);
		this.playerBar.shake(0.3, 6);
		this.hitTint = Config.PlayerHitTintAlpha;
		this.drawHitTint();
		if (damage > 0) {
			this.showNotice('-' + damage, NoticeLane.Player, Palette.NoticeDamage);
		}
	}

	/** 敌人受击：敌方生命条闪白抖动。 */
	hitEnemy(): void {
		this.enemyBar.flash(Palette.HitFlashEnemy, Config.HitFlashDuration);
		this.enemyBar.shake(0.22, 4);
	}

	private playNotice(lane: number, text: string, hex: number): void {
		this.floatLanes[lane].show(text, hex, Hud.LaneX[lane], Hud.LaneY[lane]);
	}

	private drawHitTint(): void {
		this.hitLayer.clear();
		if (this.hitTint <= 0) {
			return;
		}
		this.hitLayer.drawPolygon(
			[Vec2(-1600, -1100), Vec2(1600, -1100), Vec2(1600, 1100), Vec2(-1600, 1100)],
			Color(255, 60, 50, Math.floor(this.hitTint))
		);
	}

	showDefeat(text: string): void {
		if (this.panelText !== undefined) {
			this.panelText.text = text;
		}
		for (const part of this.panelParts) {
			part.visible = true;
		}
		// 仅显示时允许重开按钮接收触控，避免隐藏面板挡住棋盘
		this.restartButton.setEnabled(true);
	}

	hideDefeat(): void {
		for (const part of this.panelParts) {
			part.visible = false;
		}
		this.restartButton.setEnabled(false);
	}
}

// 排版与配色常量（M6）：HUD/棋盘在设计空间中的坐标、字号与颜色的唯一来源。
// 目的：让「排版统一」可审计 —— 所有位置/尺寸集中在此文件，并由 game/Tests.ts
// 的「安全区/极端宽高比」检查断言它们都落在任何宽高比下都保证可见的设计盒内。
// 注意：这里只放 HUD 与面板的排版；方块外观与效果规则见 game/BlockDefs.ts。

import { Config } from 'game/Config';

/**
 * 设计空间安全区：因为 zoom = min(w/基准宽, h/基准高)，
 * 无论窗口宽高比如何，至少 960×1080 设计单位可见（原点为屏幕中心）。
 */
export class SafeBox {
	static readonly HalfWidth = Config.DesignSceneWidth / 2;
	static readonly HalfHeight = Config.DesignSceneHeight / 2;
}

/** 排版审计条目：以屏幕中心为原点的矩形（设计单位）。 */
export interface LayoutRect {
	name: string;
	x: number;
	y: number;
	width: number;
	height: number;
}

/**
 * 由窗口尺寸计算摄像机 zoom（与 init.ts 共用，保证入口与自检用同一套公式）。
 * 窗口未就绪（宽或高 < 1）时按基准尺寸处理，返回 1。
 */
export function zoomFor(viewWidth: number, viewHeight: number): number {
	let width = viewWidth;
	let height = viewHeight;
	if (width < 1) {
		width = Config.DesignSceneWidth;
	}
	if (height < 1) {
		height = Config.DesignSceneHeight;
	}
	const widthScale = width / Config.DesignSceneWidth;
	const heightScale = height / Config.DesignSceneHeight;
	const scale = widthScale < heightScale ? widthScale : heightScale;
	if (scale < 0.05) {
		// 防止窗口未就绪（尺寸为 0）时把 zoom 算成 0，导致画面全黑
		return 0.05;
	}
	return scale;
}

/** 给定窗口尺寸下实际可见的设计空间半宽/半高（用于极端宽高比检查）。 */
export function visibleHalfExtent(viewWidth: number, viewHeight: number): LayoutRect {
	const width = viewWidth < 1 ? Config.DesignSceneWidth : viewWidth;
	const height = viewHeight < 1 ? Config.DesignSceneHeight : viewHeight;
	const zoom = zoomFor(viewWidth, viewHeight);
	return { name: 'visible', x: 0, y: 0, width: width / zoom, height: height / zoom };
}

/** 矩形是否完全落在安全区内（含 0.01 的浮点容差）。 */
export function insideSafeBox(rect: LayoutRect): boolean {
	return Math.abs(rect.x) + rect.width * 0.5 <= SafeBox.HalfWidth + 0.01
		&& Math.abs(rect.y) + rect.height * 0.5 <= SafeBox.HalfHeight + 0.01;
}

/** HUD/面板配色（与方块配色分开；数值与原硬编码保持一致）。 */
export class Palette {
	/** 敌方血条。 */
	static readonly EnemyBar = 0xd0453c;
	/** 玩家血条。 */
	static readonly PlayerBar = 0x46b266;
	/** 魔力条。 */
	static readonly ManaBar = 0x3b7be0;
	/** 敌方行动进度条。 */
	static readonly TimerBar = 0xe0b23c;
	/** 主要按钮（技能/设置面板操作/重新开始）。 */
	static readonly ButtonPrimary = 0x2f6fd0;
	/** 中性按钮（设置入口/关闭设置）。 */
	static readonly ButtonNeutral = 0x39414f;
	/** 面板底板。 */
	static readonly PanelBackground = 0x1b2130;
	/** 系统提示飘字默认色。 */
	static readonly NoticeDefault = 0xffe58a;
	/** 我方受伤飘字。 */
	static readonly NoticeDamage = 0xff8a7a;
	/** 我方受击：血条闪烁色。 */
	static readonly HitFlashPlayer = 0xff5a4a;
	/** 敌方受击：血条闪烁色。 */
	static readonly HitFlashEnemy = 0xffffff;
	/** 存档成功文本。 */
	static readonly TextOk = 0x9fe0a0;
	/** 存档失败/警示文本。 */
	static readonly TextWarn = 0xffb36b;
}

/**
 * HUD 排版常量：坐标以屏幕中心为原点、+X 右、+Y 上（设计单位）。
 * 自上而下依次为 关卡标签 → 敌人名 → 敌方血条 → 行动进度条 → 倒计时 → 玩家血条 → 魔力条 → 技能按钮。
 */
export class HudLayout {
	// 字号阶梯：统一排版用，避免各处出现随意的字号
	static readonly FontStage = 24;
	static readonly FontName = 28;
	static readonly FontLabel = 22;
	static readonly FontNotice = 26;
	static readonly FontSmall = 20;
	static readonly FontPanelTitle = 34;
	static readonly FontPanelTitleLarge = 40;

	// 顶部信息区
	static readonly StageY = 508;
	static readonly EnemyNameY = 480;
	static readonly EnemyBarY = 448;
	static readonly EnemyBarWidth = 520;
	static readonly EnemyBarHeight = 26;
	static readonly TimerBarY = 428;
	static readonly TimerBarWidth = 520;
	static readonly TimerBarHeight = 10;
	static readonly TimerLabelY = 412;
	static readonly PlayerBarY = 372;
	static readonly PlayerBarWidth = 460;
	static readonly PlayerBarHeight = 26;
	/** 玩家生命标签右对齐锚点（向左延伸，不与血条重叠）。 */
	static readonly PlayerNameX = -262;
	static readonly ManaBarY = 340;
	static readonly ManaBarWidth = 460;
	static readonly ManaBarHeight = 20;
	static readonly SkillButtonY = 292;
	static readonly SkillButtonWidth = 220;
	static readonly SkillButtonHeight = 56;
	/** 技能按钮之间的水平间距（按数量居中排列）。 */
	static readonly SkillButtonSpacing = 240;

	// 右上角设置入口
	static readonly SettingsButtonX = 370;
	static readonly SettingsButtonY = 492;
	static readonly SettingsButtonWidth = 140;
	static readonly SettingsButtonHeight = 46;

	// 底部操作提示（由设置开关控制显隐）
	static readonly HintY = -505;

	// 飘字分道：由 game/Config.ts 的 Notice*X/Y 指定，三条道互不重叠
	static readonly LaneCount = 3;

	// 设置面板（居中，模态）
	static readonly SettingsPanelWidth = 560;
	static readonly SettingsPanelHeight = 420;
	static readonly SettingsTitleY = 160;
	static readonly SettingsRowWidth = 320;
	static readonly SettingsRowHeight = 54;
	/** 模式 / 难度 / 操作提示三行的 Y。 */
	static readonly SettingsModeY = 95;
	static readonly SettingsDifficultyY = 25;
	static readonly SettingsHintY = -45;
	static readonly SettingsCloseY = -130;
	static readonly SettingsCloseWidth = 220;
	static readonly SettingsCloseHeight = 50;
	static readonly SettingsSaveY = -185;

	// 结算面板（居中，模态）
	static readonly DefeatPanelWidth = 640;
	static readonly DefeatPanelHeight = 360;
	static readonly DefeatTitleY = 110;
	static readonly DefeatTextY = 20;
	static readonly DefeatButtonY = -110;
	static readonly DefeatButtonWidth = 260;
	static readonly DefeatButtonHeight = 70;

	/** 飘字上浮总高度（FloatTextWidget：46/秒 × 1.2 秒）。 */
	static readonly NoticeRise = 56;
	/** 最长一行提示文本的字数（按中文 1 em 估算，用于安全区审计）。 */
	static readonly HintMaxChars = 25;
	static readonly StageMaxChars = 16;
	static readonly TimerMaxChars = 14;
	static readonly NoticeMaxChars = 18;
	static readonly PlayerNameMaxChars = 4;
	static readonly EnemyNameMaxChars = 6;
}

/** 文字行高估算：字号 × 1.5。 */
function lineHeight(fontSize: number): number {
	return fontSize * 1.5;
}

/**
 * 列出所有 HUD/面板元素的矩形范围（含按最长文本估算的文字宽度），供自检断言
 * 「任何宽高比下都可见、彼此不越界」。新增 HUD 元素时应同步补充此处。
 */
export function hudLayoutRects(): LayoutRect[] {
	const rects: LayoutRect[] = [];
	rects.push({ name: '关卡标签', x: 0, y: HudLayout.StageY, width: HudLayout.StageMaxChars * HudLayout.FontStage, height: lineHeight(HudLayout.FontStage) });
	rects.push({ name: '敌人名', x: 0, y: HudLayout.EnemyNameY, width: HudLayout.EnemyNameMaxChars * HudLayout.FontName, height: lineHeight(HudLayout.FontName) });
	rects.push({ name: '敌方血条', x: 0, y: HudLayout.EnemyBarY, width: HudLayout.EnemyBarWidth, height: HudLayout.EnemyBarHeight });
	rects.push({ name: '行动进度条', x: 0, y: HudLayout.TimerBarY, width: HudLayout.TimerBarWidth, height: HudLayout.TimerBarHeight });
	rects.push({ name: '行动倒计时', x: 0, y: HudLayout.TimerLabelY, width: HudLayout.TimerMaxChars * HudLayout.FontLabel, height: lineHeight(HudLayout.FontLabel) });
	rects.push({ name: '玩家血条', x: 0, y: HudLayout.PlayerBarY, width: HudLayout.PlayerBarWidth, height: HudLayout.PlayerBarHeight });
	rects.push({
		name: '玩家生命标签',
		x: HudLayout.PlayerNameX - (HudLayout.PlayerNameMaxChars * HudLayout.FontLabel) / 2,
		y: HudLayout.PlayerBarY,
		width: HudLayout.PlayerNameMaxChars * HudLayout.FontLabel,
		height: lineHeight(HudLayout.FontLabel),
	});
	rects.push({ name: '魔力条', x: 0, y: HudLayout.ManaBarY, width: HudLayout.ManaBarWidth, height: HudLayout.ManaBarHeight });
	rects.push({ name: '技能按钮1', x: -HudLayout.SkillButtonSpacing / 2, y: HudLayout.SkillButtonY, width: HudLayout.SkillButtonWidth, height: HudLayout.SkillButtonHeight });
	rects.push({ name: '技能按钮2', x: HudLayout.SkillButtonSpacing / 2, y: HudLayout.SkillButtonY, width: HudLayout.SkillButtonWidth, height: HudLayout.SkillButtonHeight });
	rects.push({ name: '设置按钮', x: HudLayout.SettingsButtonX, y: HudLayout.SettingsButtonY, width: HudLayout.SettingsButtonWidth, height: HudLayout.SettingsButtonHeight });
	rects.push({ name: '操作提示', x: 0, y: HudLayout.HintY, width: HudLayout.HintMaxChars * HudLayout.FontLabel, height: lineHeight(HudLayout.FontLabel) });
	// 飘字分道：取上浮终点（更高的一侧）作为范围，确保不会穿过上方 HUD 元素
	const noticeWidth = HudLayout.NoticeMaxChars * HudLayout.FontNotice;
	rects.push({ name: '对敌飘字道', x: Config.NoticeEnemyX, y: Config.NoticeEnemyY + HudLayout.NoticeRise / 2, width: noticeWidth, height: HudLayout.NoticeRise + lineHeight(HudLayout.FontNotice) });
	rects.push({ name: '我方飘字道', x: Config.NoticePlayerX, y: Config.NoticePlayerY + HudLayout.NoticeRise / 2, width: noticeWidth, height: HudLayout.NoticeRise + lineHeight(HudLayout.FontNotice) });
	rects.push({ name: '系统飘字道', x: Config.NoticeSystemX, y: Config.NoticeSystemY + HudLayout.NoticeRise / 2, width: noticeWidth, height: HudLayout.NoticeRise + lineHeight(HudLayout.FontNotice) });
	// 面板（居中模态）
	rects.push({ name: '设置面板', x: 0, y: 0, width: HudLayout.SettingsPanelWidth, height: HudLayout.SettingsPanelHeight });
	rects.push({ name: '结算面板', x: 0, y: 0, width: HudLayout.DefeatPanelWidth, height: HudLayout.DefeatPanelHeight });
	return rects;
}

/** 棋盘在设计空间中的矩形范围（容器尺寸 7×格宽，中心位于 Config.BoardCenterY）。 */
export function boardLayoutRect(): LayoutRect {
	const span = Config.Columns * Config.CellSize;
	return { name: '棋盘', x: 0, y: Config.BoardCenterY, width: span, height: span };
}
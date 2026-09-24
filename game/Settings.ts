// 设置模型与持久化：模式（回合制/实时）、难度、是否显示操作提示。
// 存档使用极简 “key=value” 行文本（避免引入 JSON 依赖）；读取/写入失败时回退默认值并标记“设置未保存”。

import { Content } from 'Dora';
import { Config, Difficulty, GameMode } from 'game/Config';

/** 默认存档文件名（可传入其它文件名以便自检）。 */
export const SettingsFile = 'settings.txt';

interface KeyValue {
	key: string;
	value: string;
}

function parseLine(line: string): KeyValue {
	const trimmed = line.replace('\r', '').trim();
	const at = trimmed.indexOf('=');
	if (at < 0) {
		return { key: '', value: '' };
	}
	return { key: trimmed.substring(0, at), value: trimmed.substring(at + 1) };
}

export class Settings {
	mode: GameMode = GameMode.TurnBased;
	difficulty: Difficulty = Difficulty.Standard;
	showHint = true;
	/** 上次保存是否成功；false 表示只能内存态生效。 */
	saved = true;

	/** 从存档读取；失败或不存在时返回默认设置。 */
	static load(fileName: string = SettingsFile): Settings {
		const settings = new Settings();
		// 必须用同步 API：Content.loadAsync/saveAsync 要求协程上下文，直接调用会 assert 失败
		const text: string | undefined = Content.load(fileName);
		// 注意：Lua 中空字符串为真值，因此必须显式比较，不能用 if (!text)
		if (text === undefined || text === '') {
			return settings;
		}
		for (const line of text.split('\n')) {
			const pair = parseLine(line);
			if (pair.key === 'mode') {
				settings.mode = pair.value === GameMode.Realtime ? GameMode.Realtime : GameMode.TurnBased;
			} else if (pair.key === 'difficulty') {
				if (pair.value === Difficulty.Casual) {
					settings.difficulty = Difficulty.Casual;
				} else if (pair.value === Difficulty.Hard) {
					settings.difficulty = Difficulty.Hard;
				} else {
					settings.difficulty = Difficulty.Standard;
				}
			} else if (pair.key === 'hint') {
				settings.showHint = pair.value !== '0';
			}
		}
		return settings;
	}

	/** 写入存档；返回是否成功（失败时仍以内存态生效）。 */
	save(fileName: string = SettingsFile): boolean {
		const text = 'mode=' + this.mode + '\ndifficulty=' + this.difficulty + '\nhint=' + (this.showHint ? '1' : '0') + '\n';
		this.saved = Content.save(fileName, text);
		return this.saved;
	}

	toggleMode(): GameMode {
		this.mode = this.mode === GameMode.TurnBased ? GameMode.Realtime : GameMode.TurnBased;
		return this.mode;
	}

	cycleDifficulty(): Difficulty {
		if (this.difficulty === Difficulty.Casual) {
			this.difficulty = Difficulty.Standard;
		} else if (this.difficulty === Difficulty.Standard) {
			this.difficulty = Difficulty.Hard;
		} else {
			this.difficulty = Difficulty.Casual;
		}
		return this.difficulty;
	}

	toggleHint(): boolean {
		this.showHint = !this.showHint;
		return this.showHint;
	}

	modeName(): string {
		return this.mode === GameMode.Realtime ? '实时战斗' : '回合制';
	}

	difficultyName(): string {
		if (this.difficulty === Difficulty.Casual) {
			return '休闲';
		}
		if (this.difficulty === Difficulty.Hard) {
			return '困难';
		}
		return '标准';
	}

	difficultyScale(): number {
		return Config.difficultyScale(this.difficulty);
	}
}

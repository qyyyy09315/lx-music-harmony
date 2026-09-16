import window from '@ohos.window';
import common from '@ohos.app.ability.common';
import { LyricParser, LyricLine } from '../common/LyricParser';
import { AudioPlayerService } from './AudioPlayerService';
import { MusicItem } from '../model/MusicModel';

/**
 * 桌面与全局悬浮歌词服务 (单例)
 */
export class FloatLyricService {
  private static instance: FloatLyricService;
  private floatWindow: window.Window | null = null;
  private isShowing: boolean = false;
  private context: common.UIAbilityContext | null = null;
  private lyricParser: LyricParser = new LyricParser();
  private currentLyricText: string = '洛雪音乐 - 听你所想';
  private lyricUpdateCallbacks: ((text: string) => void)[] = [];

  private constructor() {
    this.bindPlayerEvents();
  }

  public static getInstance(): FloatLyricService {
    if (!FloatLyricService.instance) {
      FloatLyricService.instance = new FloatLyricService();
    }
    return FloatLyricService.instance;
  }

  public init(context: common.UIAbilityContext): void {
    this.context = context;
  }

  private bindPlayerEvents(): void {
    const player = AudioPlayerService.getInstance();
    player.onMusicChange((music: MusicItem | null) => {
      if (music && music.lrc) {
        this.lyricParser.parse(music.lrc);
        this.updateLyricText(`${music.name} - ${music.singer}`);
      } else {
        this.lyricParser.parse('');
        this.updateLyricText(music ? `${music.name} - ${music.singer}` : '洛雪音乐 - 听你所想');
      }
    });

    player.onTimeUpdate((currentTimeMs: number) => {
      if (this.lyricParser.getLines().length > 0) {
        const line = this.lyricParser.getLineAtTime(currentTimeMs);
        if (line && line.text.trim().length > 0) {
          this.updateLyricText(line.text);
        }
      }
    });
  }

  private updateLyricText(text: string): void {
    this.currentLyricText = text;
    this.lyricUpdateCallbacks.forEach(cb => cb(text));
  }

  public getCurrentLyric(): string {
    return this.currentLyricText;
  }

  public onLyricChange(callback: (text: string) => void): void {
    this.lyricUpdateCallbacks.push(callback);
  }

  /**
   * 开启或关闭悬浮歌词
   */
  public async toggleFloatLyric(enable: boolean): Promise<boolean> {
    this.isShowing = enable;
    if (enable) {
      return await this.showFloatWindow();
    } else {
      return await this.hideFloatWindow();
    }
  }

  public isFloatLyricEnabled(): boolean {
    return this.isShowing;
  }

  private async showFloatWindow(): Promise<boolean> {
    if (!this.context) {
      console.warn('FloatLyricService context not initialized');
      return false;
    }
    try {
      const config: window.Configuration = {
        name: 'lx_float_lyric_window',
        windowType: window.WindowType.TYPE_FLOAT,
        ctx: this.context
      };
      this.floatWindow = await window.createWindow(config);
      await this.floatWindow.resize(700, 120);
      await this.floatWindow.moveWindowTo(100, 200);
      await this.floatWindow.showWindow();
      return true;
    } catch (e) {
      console.error('Failed to create float window: ' + JSON.stringify(e));
      return false;
    }
  }

  private async hideFloatWindow(): Promise<boolean> {
    if (this.floatWindow) {
      try {
        await this.floatWindow.destroyWindow();
        this.floatWindow = null;
        return true;
      } catch (e) {
        console.error('Failed to destroy float window: ' + JSON.stringify(e));
        return false;
      }
    }
    return true;
  }
}

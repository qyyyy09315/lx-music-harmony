import media from '@ohos.multimedia.media';
import { MusicItem, PlayState } from '../model/MusicModel';

/**
 * 鸿蒙原生音频播放核心服务 (基于 AVPlayer)
 */
export class AudioPlayerService {
  private static instance: AudioPlayerService;
  private avPlayer: media.AVPlayer | null = null;
  private currentMusic: MusicItem | null = null;
  private state: PlayState = PlayState.IDLE;
  private stateChangeCallbacks: ((state: PlayState) => void)[] = [];
  private timeUpdateCallbacks: ((currentTime: number, duration: number) => void)[] = [];

  private constructor() {}

  public static getInstance(): AudioPlayerService {
    if (!AudioPlayerService.instance) {
      AudioPlayerService.instance = new AudioPlayerService();
    }
    return AudioPlayerService.instance;
  }

  /**
   * 初始化 AVPlayer
   */
  public async init(): Promise<void> {
    if (this.avPlayer) {
      return;
    }
    try {
      this.avPlayer = await media.createAVPlayer();
      this.bindEvents();
    } catch (err) {
      console.error('Failed to create AVPlayer: ' + JSON.stringify(err));
    }
  }

  private bindEvents(): void {
    if (!this.avPlayer) return;

    this.avPlayer.on('stateChange', async (state: string) => {
      switch (state) {
        case 'idle':
          this.state = PlayState.IDLE;
          break;
        case 'initialized':
          await this.avPlayer?.prepare();
          break;
        case 'prepared':
          this.state = PlayState.PAUSED;
          await this.avPlayer?.play();
          break;
        case 'playing':
          this.state = PlayState.PLAYING;
          break;
        case 'paused':
          this.state = PlayState.PAUSED;
          break;
        case 'completed':
          this.state = PlayState.STOPPED;
          break;
        case 'stopped':
          this.state = PlayState.STOPPED;
          break;
        case 'error':
          this.state = PlayState.ERROR;
          break;
      }
      this.notifyState();
    });

    this.avPlayer.on('timeUpdate', (time: number) => {
      const duration = this.avPlayer?.duration || 0;
      this.timeUpdateCallbacks.forEach(cb => cb(time, duration));
    });
  }

  public async playMusic(music: MusicItem): Promise<void> {
    if (!this.avPlayer) {
      await this.init();
    }
    if (!this.avPlayer || !music.url) {
      return;
    }

    this.currentMusic = music;
    if (this.avPlayer.state === 'playing' || this.avPlayer.state === 'paused') {
      await this.avPlayer.reset();
    }
    this.avPlayer.url = music.url;
  }

  public async togglePlay(): Promise<void> {
    if (!this.avPlayer) return;
    if (this.state === PlayState.PLAYING) {
      await this.avPlayer.pause();
    } else if (this.state === PlayState.PAUSED) {
      await this.avPlayer.play();
    }
  }

  public async seek(timeMs: number): Promise<void> {
    if (this.avPlayer) {
      await this.avPlayer.seek(timeMs);
    }
  }

  public onStateChange(callback: (state: PlayState) => void): void {
    this.stateChangeCallbacks.push(callback);
  }

  public onTimeUpdate(callback: (currentTime: number, duration: number) => void): void {
    this.timeUpdateCallbacks.push(callback);
  }

  private notifyState(): void {
    this.stateChangeCallbacks.forEach(cb => cb(this.state));
  }

  public getCurrentMusic(): MusicItem | null {
    return this.currentMusic;
  }

  public getState(): PlayState {
    return this.state;
  }
}

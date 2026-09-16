import media from '@ohos.multimedia.media';
import { MusicItem, PlayMode, PlayState } from '../model/MusicModel';
import { AVSessionService } from './AVSessionService';

/**
 * 鸿蒙原生音频播放核心服务 (基于 AVPlayer + 智能兜底)
 */
export class AudioPlayerService {
  private static instance: AudioPlayerService;
  private avPlayer: media.AVPlayer | null = null;
  private playList: MusicItem[] = [];
  private currentIndex: number = -1;
  private currentMusic: MusicItem | null = null;
  private playMode: PlayMode = PlayMode.LIST_LOOP;
  private state: PlayState = PlayState.IDLE;
  private isAutoPlayNext: boolean = true;
  private mockTimer: number = -1;
  private currentMockTime: number = 0;

  // 监听器队列
  private stateChangeCallbacks: ((state: PlayState) => void)[] = [];
  private timeUpdateCallbacks: ((currentTime: number, duration: number) => void)[] = [];
  private musicChangeCallbacks: ((music: MusicItem | null) => void)[] = [];
  private playlistChangeCallbacks: ((list: MusicItem[]) => void)[] = [];

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
    if (this.avPlayer) return;
    try {
      this.avPlayer = await media.createAVPlayer();
      this.bindEvents();
    } catch (err) {
      console.warn('AudioPlayerService init warning: ' + JSON.stringify(err));
    }
  }

  private bindEvents(): void {
    if (!this.avPlayer) return;

    this.avPlayer.on('stateChange', async (state: string) => {
      console.info(`AVPlayer state changed: ${state}`);
      switch (state) {
        case 'idle':
          this.state = PlayState.IDLE;
          break;
        case 'initialized':
          this.state = PlayState.PREPARING;
          try {
            await this.avPlayer?.prepare();
          } catch (e) {
            console.warn('Prepare error: ' + JSON.stringify(e));
          }
          break;
        case 'prepared':
          this.state = PlayState.PLAYING;
          try {
            await this.avPlayer?.play();
          } catch (e) {
            console.warn('Play error: ' + JSON.stringify(e));
          }
          break;
        case 'playing':
          this.state = PlayState.PLAYING;
          this.stopMockTimer();
          if (this.currentMusic) {
            AVSessionService.getInstance().updateMetadata(this.currentMusic);
          }
          break;
        case 'paused':
          this.state = PlayState.PAUSED;
          this.stopMockTimer();
          break;
        case 'completed':
          this.state = PlayState.STOPPED;
          this.stopMockTimer();
          if (this.isAutoPlayNext) {
            this.handlePlaybackCompleted();
          }
          break;
        case 'stopped':
          this.state = PlayState.STOPPED;
          this.stopMockTimer();
          break;
        case 'error':
          console.warn('AVPlayer error state, fallback to simulated timeline');
          this.state = PlayState.PLAYING;
          this.startMockTimer();
          break;
      }
      this.notifyState();
    });

    this.avPlayer.on('timeUpdate', (time: number) => {
      const duration = this.avPlayer?.duration || this.currentMusic?.duration || 240000;
      this.timeUpdateCallbacks.forEach(cb => cb(time, duration));
    });

    this.avPlayer.on('error', (err) => {
      console.warn('AVPlayer error event, fallback to smooth timer: ' + JSON.stringify(err));
      this.state = PlayState.PLAYING;
      this.startMockTimer();
      this.notifyState();
    });
  }

  private startMockTimer(): void {
    this.stopMockTimer();
    const duration = this.currentMusic?.duration || 240000;
    this.mockTimer = setInterval(() => {
      if (this.state === PlayState.PLAYING) {
        this.currentMockTime += 1000;
        if (this.currentMockTime >= duration) {
          this.currentMockTime = 0;
          this.handlePlaybackCompleted();
        } else {
          this.timeUpdateCallbacks.forEach(cb => cb(this.currentMockTime, duration));
        }
      }
    }, 1000);
  }

  private stopMockTimer(): void {
    if (this.mockTimer !== -1) {
      clearInterval(this.mockTimer);
      this.mockTimer = -1;
    }
  }

  /**
   * 播放单曲
   */
  public async playMusic(music: MusicItem): Promise<void> {
    if (!this.avPlayer) {
      await this.init();
    }

    // 检查是否已经在播放列表中
    const idx = this.playList.findIndex(m => m.id === music.id);
    if (idx >= 0) {
      this.currentIndex = idx;
    } else {
      this.playList.push(music);
      this.currentIndex = this.playList.length - 1;
      this.notifyPlaylist();
    }

    this.currentMusic = music;
    this.currentMockTime = 0;
    this.state = PlayState.PLAYING; // 即刻响应式进入播放态
    this.notifyMusicChange();
    this.notifyState();

    if (this.avPlayer && music.url) {
      try {
        if (this.avPlayer.state !== 'idle') {
          await this.avPlayer.reset();
        }
        this.avPlayer.url = music.url;
      } catch (e) {
        console.warn('Failed to set avPlayer url, start timer: ' + JSON.stringify(e));
        this.startMockTimer();
      }
    } else {
      this.startMockTimer();
    }
  }

  /**
   * 设置播放列表并播放指定索引
   */
  public async setPlayList(list: MusicItem[], startIndex: number = 0): Promise<void> {
    this.playList = [...list];
    this.notifyPlaylist();
    if (list.length > 0 && startIndex >= 0 && startIndex < list.length) {
      await this.playMusic(list[startIndex]);
    }
  }

  /**
   * 切换播放/暂停
   */
  public async togglePlay(): Promise<void> {
    if (this.state === PlayState.PLAYING) {
      this.state = PlayState.PAUSED;
      this.stopMockTimer();
      if (this.avPlayer && this.avPlayer.state === 'playing') {
        try {
          await this.avPlayer.pause();
        } catch (e) {
          console.warn('Pause error: ' + JSON.stringify(e));
        }
      }
    } else if (this.state === PlayState.PAUSED) {
      this.state = PlayState.PLAYING;
      if (this.avPlayer && this.avPlayer.state === 'paused') {
        try {
          await this.avPlayer.play();
        } catch (e) {
          console.warn('Play error: ' + JSON.stringify(e));
          this.startMockTimer();
        }
      } else {
        this.startMockTimer();
      }
    } else if (this.currentMusic) {
      await this.playMusic(this.currentMusic);
    }
    this.notifyState();
  }

  /**
   * 播放下一首
   */
  public async playNext(): Promise<void> {
    if (this.playList.length === 0) return;

    if (this.playMode === PlayMode.RANDOM) {
      const nextIdx = Math.floor(Math.random() * this.playList.length);
      await this.playMusic(this.playList[nextIdx]);
      return;
    }

    let nextIdx = this.currentIndex + 1;
    if (nextIdx >= this.playList.length) {
      nextIdx = 0;
    }
    await this.playMusic(this.playList[nextIdx]);
  }

  /**
   * 播放上一首
   */
  public async playPrevious(): Promise<void> {
    if (this.playList.length === 0) return;

    if (this.playMode === PlayMode.RANDOM) {
      const prevIdx = Math.floor(Math.random() * this.playList.length);
      await this.playMusic(this.playList[prevIdx]);
      return;
    }

    let prevIdx = this.currentIndex - 1;
    if (prevIdx < 0) {
      prevIdx = this.playList.length - 1;
    }
    await this.playMusic(this.playList[prevIdx]);
  }

  private handlePlaybackCompleted(): void {
    if (this.playMode === PlayMode.SINGLE_LOOP && this.currentMusic) {
      this.playMusic(this.currentMusic);
    } else {
      this.playNext();
    }
  }

  /**
   * 移除播放列表中的某首歌曲
   */
  public async removeMusicFromPlaylist(index: number): Promise<void> {
    if (index < 0 || index >= this.playList.length) return;
    const isCurrent = this.currentIndex === index;
    this.playList.splice(index, 1);
    
    if (this.playList.length === 0) {
      this.currentIndex = -1;
      this.currentMusic = null;
      this.stopMockTimer();
      if (this.avPlayer && this.avPlayer.state !== 'idle') {
        try {
          await this.avPlayer.reset();
        } catch (e) {
          console.warn('Reset error: ' + JSON.stringify(e));
        }
      }
      this.state = PlayState.IDLE;
      this.notifyState();
      this.notifyMusicChange();
    } else if (isCurrent) {
      if (this.currentIndex >= this.playList.length) {
        this.currentIndex = 0;
      }
      await this.playMusic(this.playList[this.currentIndex]);
    } else if (this.currentIndex > index) {
      this.currentIndex--;
    }
    this.notifyPlaylist();
  }

  /**
   * 清空播放列表
   */
  public async clearPlaylist(): Promise<void> {
    this.playList = [];
    this.currentIndex = -1;
    this.currentMusic = null;
    this.stopMockTimer();
    if (this.avPlayer && this.avPlayer.state !== 'idle') {
      try {
        await this.avPlayer.reset();
      } catch (e) {
        console.warn('Reset error: ' + JSON.stringify(e));
      }
    }
    this.state = PlayState.IDLE;
    this.notifyState();
    this.notifyMusicChange();
    this.notifyPlaylist();
  }

  /**
   * 播放指定列表索引的歌曲
   */
  public async playIndex(index: number): Promise<void> {
    if (index >= 0 && index < this.playList.length) {
      this.currentIndex = index;
      await this.playMusic(this.playList[index]);
    }
  }

  /**
   * 进度跳转 (ms)
   */
  public async seek(timeMs: number): Promise<void> {
    this.currentMockTime = timeMs;
    if (this.avPlayer && (this.state === PlayState.PLAYING || this.state === PlayState.PAUSED)) {
      try {
        await this.avPlayer.seek(timeMs);
      } catch (e) {
        console.warn('Seek error: ' + JSON.stringify(e));
      }
    }
  }

  public togglePlayMode(): PlayMode {
    switch (this.playMode) {
      case PlayMode.LIST_LOOP:
        this.playMode = PlayMode.SINGLE_LOOP;
        break;
      case PlayMode.SINGLE_LOOP:
        this.playMode = PlayMode.RANDOM;
        break;
      case PlayMode.RANDOM:
        this.playMode = PlayMode.LIST_LOOP;
        break;
    }
    return this.playMode;
  }

  public getPlayMode(): PlayMode {
    return this.playMode;
  }

  public getCurrentMusic(): MusicItem | null {
    return this.currentMusic;
  }

  public getPlayList(): MusicItem[] {
    return this.playList;
  }

  public getState(): PlayState {
    return this.state;
  }

  public onStateChange(callback: (state: PlayState) => void): void {
    this.stateChangeCallbacks.push(callback);
  }

  public onTimeUpdate(callback: (currentTime: number, duration: number) => void): void {
    this.timeUpdateCallbacks.push(callback);
  }

  public onMusicChange(callback: (music: MusicItem | null) => void): void {
    this.musicChangeCallbacks.push(callback);
  }

  public onPlaylistChange(callback: (list: MusicItem[]) => void): void {
    this.playlistChangeCallbacks.push(callback);
  }

  private notifyState(): void {
    this.stateChangeCallbacks.forEach(cb => cb(this.state));
  }

  private notifyMusicChange(): void {
    this.musicChangeCallbacks.forEach(cb => cb(this.currentMusic));
  }

  private notifyPlaylist(): void {
    this.playlistChangeCallbacks.forEach(cb => cb(this.playList));
  }
}

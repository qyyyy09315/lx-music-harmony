import { MusicItem } from '../model/MusicModel';

/**
 * 本地音乐扫描与管理服务 (单例)
 */
export class LocalMusicService {
  private static instance: LocalMusicService;
  private localMusicList: MusicItem[] = [];
  private isScanning: boolean = false;
  private listeners: ((list: MusicItem[]) => void)[] = [];

  private constructor() {
    this.initPresetLocalMusic();
  }

  public static getInstance(): LocalMusicService {
    if (!LocalMusicService.instance) {
      LocalMusicService.instance = new LocalMusicService();
    }
    return LocalMusicService.instance;
  }

  /**
   * 初始化预置演示本地音乐
   */
  private initPresetLocalMusic(): void {
    this.localMusicList = [
      {
        id: 'local_song_1',
        name: '夜的第七章 (本地离线)',
        singer: '周杰伦',
        album: '依然范特西',
        duration: 228000,
        source: 'local',
        pic: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=500&auto=format&fit=crop&q=60',
        url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
        lrc: '[00:00.00]夜的第七章 - 周杰伦\n[00:04.00]1983年小巷12月晴朗\n[00:10.00]夜的第七章 打字机继续推向\n[00:16.00]接近事实的那下一行'
      },
      {
        id: 'local_song_2',
        name: '稻香 (本地高保真)',
        singer: '周杰伦',
        album: '魔杰座',
        duration: 223000,
        source: 'local',
        pic: 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=500&auto=format&fit=crop&q=60',
        url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
        lrc: '[00:00.00]稻香 - 周杰伦\n[00:05.00]对这个世界如果你有太多的抱怨\n[00:10.00]跌倒了 就不敢继续往前走\n[00:15.00]为什么 人要这么的脆弱 堕落'
      }
    ];
  }

  public getLocalMusicList(): MusicItem[] {
    return [...this.localMusicList];
  }

  public isScanInProgress(): boolean {
    return this.isScanning;
  }

  /**
   * 触发设备本地曲库扫描
   */
  public async scanLocalAudio(): Promise<MusicItem[]> {
    this.isScanning = true;
    
    // 模拟文件系统遍历与媒体库索引构建
    await new Promise<void>((resolve) => setTimeout(resolve, 1000));

    // 新增扫描发现的歌曲（去重）
    const scannedSong: MusicItem = {
      id: `local_scanned_${Date.now()}`,
      name: '兰亭序 (扫描入库)',
      singer: '周杰伦',
      album: '魔杰座',
      duration: 254000,
      source: 'local',
      pic: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=500&auto=format&fit=crop&q=60',
      url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
      lrc: '[00:00.00]兰亭序 - 周杰伦\n[00:05.00]兰亭临帖 行书如行云流水\n[00:12.00]月下门推 心细如你脚步碎'
    };

    if (!this.localMusicList.some(m => m.name === scannedSong.name)) {
      this.localMusicList.push(scannedSong);
    }

    this.isScanning = false;
    this.notifyListChange();
    return this.getLocalMusicList();
  }

  /**
   * 移除单首本地音乐
   */
  public removeLocalMusic(id: string): void {
    this.localMusicList = this.localMusicList.filter(m => m.id !== id);
    this.notifyListChange();
  }

  public onListChange(listener: (list: MusicItem[]) => void): void {
    this.listeners.push(listener);
  }

  private notifyListChange(): void {
    const list = this.getLocalMusicList();
    this.listeners.forEach(cb => cb(list));
  }
}

import avSession from '@ohos.multimedia.avsession';
import { MusicItem } from '../model/MusicModel';
import { AudioPlayerService } from './AudioPlayerService';

/**
 * 鸿蒙 AVSession 系统播控对接服务 (通知栏、锁屏、超级终端控制器)
 */
export class AVSessionService {
  private static instance: AVSessionService;
  private session: avSession.AVSession | null = null;

  private constructor() {}

  public static getInstance(): AVSessionService {
    if (!AVSessionService.instance) {
      AVSessionService.instance = new AVSessionService();
    }
    return AVSessionService.instance;
  }

  public async initSession(context: Context): Promise<void> {
    try {
      this.session = await avSession.createAVSession(context, 'LXMusicHarmonySession', 'audio');
      await this.session.activate();
      this.registerSessionCallbacks();
    } catch (err) {
      console.error('Failed to create AVSession: ' + JSON.stringify(err));
    }
  }

  private registerSessionCallbacks(): void {
    if (!this.session) return;

    this.session.on('play', () => {
      AudioPlayerService.getInstance().togglePlay();
    });

    this.session.on('pause', () => {
      AudioPlayerService.getInstance().togglePlay();
    });

    this.session.on('seek', (position: number) => {
      AudioPlayerService.getInstance().seek(position);
    });
  }

  public async updateMetadata(music: MusicItem): Promise<void> {
    if (!this.session) return;
    const metadata: avSession.AVMetadata = {
      assetId: music.id,
      title: music.name,
      artist: music.singer,
      album: music.album || '未知专辑',
      mediaImage: music.pic || '',
      duration: music.duration || 0
    };
    await this.session.setAVMetadata(metadata);
  }

  public async destroy(): Promise<void> {
    if (this.session) {
      await this.session.destroy();
      this.session = null;
    }
  }
}

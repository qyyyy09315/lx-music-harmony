import { MusicItem } from '../model/MusicModel';

export interface CustomPlaylist {
  id: string;
  name: string;
  desc?: string;
  cover?: string;
  list: MusicItem[];
  createTime: number;
  updateTime: number;
}

/**
 * 自定义歌单管理服务 (单例)
 */
export class PlaylistManagerService {
  private static instance: PlaylistManagerService;
  private playlists: Map<string, CustomPlaylist> = new Map();
  private listeners: ((playlists: CustomPlaylist[]) => void)[] = [];

  private constructor() {
    this.initDefaultPlaylists();
  }

  public static getInstance(): PlaylistManagerService {
    if (!PlaylistManagerService.instance) {
      PlaylistManagerService.instance = new PlaylistManagerService();
    }
    return PlaylistManagerService.instance;
  }

  private initDefaultPlaylists(): void {
    const defaultList: CustomPlaylist = {
      id: 'pl_favorites_classic',
      name: '华语经典金曲',
      desc: '穿越时光的旋律，永不过期的经典',
      cover: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=500&auto=format&fit=crop&q=60',
      list: [
        {
          id: 'pl_song_1',
          name: '晴天',
          singer: '周杰伦',
          album: '叶惠美',
          duration: 269000,
          url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
          pic: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=500&auto=format&fit=crop&q=60'
        },
        {
          id: 'pl_song_2',
          name: '七里香',
          singer: '周杰伦',
          album: '七里香',
          duration: 299000,
          url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
          pic: 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=500&auto=format&fit=crop&q=60'
        }
      ],
      createTime: Date.now(),
      updateTime: Date.now()
    };
    this.playlists.set(defaultList.id, defaultList);
  }

  public getAllPlaylists(): CustomPlaylist[] {
    const list: CustomPlaylist[] = [];
    this.playlists.forEach(p => list.push(p));
    return list.sort((a, b) => b.updateTime - a.updateTime);
  }

  public getPlaylistById(id: string): CustomPlaylist | undefined {
    return this.playlists.get(id);
  }

  /**
   * 创建新歌单
   */
  public createPlaylist(name: string, desc: string = '', cover: string = ''): CustomPlaylist {
    const id = `pl_${Date.now()}_${Math.floor(Math.random() * 1000)}`;
    const playlist: CustomPlaylist = {
      id: id,
      name: name.trim() || '我的新建歌单',
      desc: desc.trim(),
      cover: cover || 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=500&auto=format&fit=crop&q=60',
      list: [],
      createTime: Date.now(),
      updateTime: Date.now()
    };
    this.playlists.set(id, playlist);
    this.notifyChange();
    return playlist;
  }

  /**
   * 删除指定歌单
   */
  public deletePlaylist(id: string): boolean {
    const removed = this.playlists.delete(id);
    if (removed) {
      this.notifyChange();
    }
    return removed;
  }

  /**
   * 重命名或更新歌单信息
   */
  public updatePlaylistInfo(id: string, name: string, desc?: string, cover?: string): boolean {
    const target = this.playlists.get(id);
    if (!target) return false;

    target.name = name.trim();
    if (desc !== undefined) target.desc = desc.trim();
    if (cover !== undefined) target.cover = cover;
    target.updateTime = Date.now();

    this.notifyChange();
    return true;
  }

  /**
   * 添加歌曲到指定歌单 (自动去重)
   */
  public addMusicToPlaylist(playlistId: string, music: MusicItem): boolean {
    const target = this.playlists.get(playlistId);
    if (!target) return false;

    if (!target.list.some(m => m.id === music.id)) {
      target.list.push(music);
      target.updateTime = Date.now();
      this.notifyChange();
      return true;
    }
    return false;
  }

  /**
   * 从歌单中移除歌曲
   */
  public removeMusicFromPlaylist(playlistId: string, musicId: string): boolean {
    const target = this.playlists.get(playlistId);
    if (!target) return false;

    const initialLen = target.list.length;
    target.list = target.list.filter(m => m.id !== musicId);
    if (target.list.length !== initialLen) {
      target.updateTime = Date.now();
      this.notifyChange();
      return true;
    }
    return false;
  }

  /**
   * 导出歌单为 JSON 字符串
   */
  public exportPlaylistToJson(playlistId: string): string {
    const target = this.playlists.get(playlistId);
    if (!target) return '';
    return JSON.stringify(target, null, 2);
  }

  /**
   * 从 JSON 字符串导入歌单
   */
  public importPlaylistFromJson(jsonStr: string): CustomPlaylist | null {
    try {
      const parsed = JSON.parse(jsonStr) as CustomPlaylist;
      if (parsed && parsed.name && Array.isArray(parsed.list)) {
        const id = `pl_imp_${Date.now()}`;
        const playlist: CustomPlaylist = {
          id: id,
          name: parsed.name + ' (已导入)',
          desc: parsed.desc || '外部导入歌单',
          cover: parsed.cover || 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=500&auto=format&fit=crop&q=60',
          list: parsed.list,
          createTime: Date.now(),
          updateTime: Date.now()
        };
        this.playlists.set(id, playlist);
        this.notifyChange();
        return playlist;
      }
    } catch (e) {
      console.error('Failed to parse playlist JSON: ' + JSON.stringify(e));
    }
    return null;
  }

  public onPlaylistsChange(listener: (playlists: CustomPlaylist[]) => void): void {
    this.listeners.push(listener);
  }

  private notifyChange(): void {
    const list = this.getAllPlaylists();
    this.listeners.forEach(cb => cb(list));
  }
}

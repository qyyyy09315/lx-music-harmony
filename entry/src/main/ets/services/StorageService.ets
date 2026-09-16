import preferences from '@ohos.data.preferences';
import { MusicItem } from '../model/MusicModel';

/**
 * 鸿蒙数据持久化首选项服务
 */
export class StorageService {
  private static instance: StorageService;
  private pref: preferences.Preferences | null = null;
  private static readonly PREF_NAME = 'lx_music_harmony_pref';

  // 键名定义
  private static readonly KEY_COLLECTION_LIST = 'collection_list';
  private static readonly KEY_HISTORY_LIST = 'history_list';
  private static readonly KEY_PLAY_QUALITY = 'play_quality';
  private static readonly KEY_THEME_COLOR = 'theme_color';
  private static readonly KEY_USER_SOURCE = 'user_source_script';

  private constructor() {}

  public static getInstance(): StorageService {
    if (!StorageService.instance) {
      StorageService.instance = new StorageService();
    }
    return StorageService.instance;
  }

  public async init(context: Context): Promise<void> {
    if (this.pref) return;
    try {
      this.pref = await preferences.getPreferences(context, StorageService.PREF_NAME);
    } catch (e) {
      console.error('StorageService getPreferences error: ' + JSON.stringify(e));
    }
  }

  /**
   * 获取收藏歌单
   */
  public async getCollectionList(): Promise<MusicItem[]> {
    if (!this.pref) return [];
    try {
      const dataStr = (await this.pref.get(StorageService.KEY_COLLECTION_LIST, '[]')) as string;
      return JSON.parse(dataStr);
    } catch (e) {
      console.error('getCollectionList parse error: ' + JSON.stringify(e));
      return [];
    }
  }

  /**
   * 保存收藏歌曲
   */
  public async addCollection(music: MusicItem): Promise<void> {
    if (!this.pref) return;
    const list = await this.getCollectionList();
    if (!list.some(item => item.id === music.id)) {
      list.unshift(music);
      await this.pref.put(StorageService.KEY_COLLECTION_LIST, JSON.stringify(list));
      await this.pref.flush();
    }
  }

  /**
   * 移除收藏
   */
  public async removeCollection(musicId: string): Promise<void> {
    if (!this.pref) return;
    let list = await this.getCollectionList();
    list = list.filter(item => item.id !== musicId);
    await this.pref.put(StorageService.KEY_COLLECTION_LIST, JSON.stringify(list));
    await this.pref.flush();
  }

  /**
   * 获取播放历史
   */
  public async getHistoryList(): Promise<MusicItem[]> {
    if (!this.pref) return [];
    try {
      const dataStr = (await this.pref.get(StorageService.KEY_HISTORY_LIST, '[]')) as string;
      return JSON.parse(dataStr);
    } catch (e) {
      return [];
    }
  }

  /**
   * 添加播放历史 (去重并限制最近100首)
   */
  public async addHistory(music: MusicItem): Promise<void> {
    if (!this.pref) return;
    let list = await this.getHistoryList();
    list = list.filter(item => item.id !== music.id);
    list.unshift(music);
    if (list.length > 100) {
      list = list.slice(0, 100);
    }
    await this.pref.put(StorageService.KEY_HISTORY_LIST, JSON.stringify(list));
    await this.pref.flush();
  }

  /**
   * 保存设置参数
   */
  public async setSetting(key: string, value: string): Promise<void> {
    if (!this.pref) return;
    await this.pref.put(key, value);
    await this.pref.flush();
  }

  /**
   * 读取设置参数
   */
  public async getSetting(key: string, defaultValue: string = ''): Promise<string> {
    if (!this.pref) return defaultValue;
    return (await this.pref.get(key, defaultValue)) as string;
  }
}

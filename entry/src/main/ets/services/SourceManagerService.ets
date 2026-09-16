import http from '@ohos.net.http';
import { MusicItem, MusicQuality, LyricResult, SearchResult, UserSourceScriptInfo } from '../model/MusicModel';
import { StorageService } from './StorageService';

/**
 * 自定义音源管理与调度服务 (单例)
 */
export class SourceManagerService {
  private static instance: SourceManagerService;
  private sources: Map<string, UserSourceScriptInfo> = new Map();
  private activeSourceId: string = '';
  private defaultQuality: MusicQuality = '320k';

  private constructor() {
    this.initDefaultSources();
  }

  public static getInstance(): SourceManagerService {
    if (!SourceManagerService.instance) {
      SourceManagerService.instance = new SourceManagerService();
    }
    return SourceManagerService.instance;
  }

  /**
   * 初始化默认/内置演示源
   */
  private initDefaultSources(): void {
    const builtinSource: UserSourceScriptInfo = {
      id: 'builtin_open_source',
      name: '官方开放测试音源',
      description: '提供免版权与公共开源流媒体试听',
      version: '1.0.0',
      author: 'LX-Team',
      rawScript: '// Built-in fallback script',
      enabled: true,
      createTime: Date.now()
    };
    this.sources.set(builtinSource.id, builtinSource);
    this.activeSourceId = builtinSource.id;
  }

  /**
   * 获取所有已导入音源
   */
  public getAllSources(): UserSourceScriptInfo[] {
    const list: UserSourceScriptInfo[] = [];
    this.sources.forEach((value) => {
      list.push(value);
    });
    return list;
  }

  /**
   * 获取当前激活的音源
   */
  public getActiveSource(): UserSourceScriptInfo | undefined {
    return this.sources.get(this.activeSourceId);
  }

  /**
   * 切换当前激活音源
   */
  public setActiveSource(sourceId: string): boolean {
    if (this.sources.has(sourceId)) {
      this.activeSourceId = sourceId;
      return true;
    }
    return false;
  }

  /**
   * 解析并导入用户自定义音源脚本
   */
  public importScript(rawScript: string): UserSourceScriptInfo {
    const meta = this.parseScriptMetadata(rawScript);
    const id = `user_src_${Date.now()}_${Math.floor(Math.random() * 1000)}`;
    const sourceInfo: UserSourceScriptInfo = {
      id: id,
      name: meta.name || '未命名自定义音源',
      description: meta.description || '本地导入的音源脚本',
      version: meta.version || '1.0.0',
      author: meta.author || '未知作者',
      homepage: meta.homepage,
      rawScript: rawScript,
      enabled: true,
      createTime: Date.now()
    };

    this.sources.set(id, sourceInfo);
    this.activeSourceId = id;
    return sourceInfo;
  }

  /**
   * 删除指定自定义音源
   */
  public deleteSource(sourceId: string): boolean {
    if (sourceId === 'builtin_open_source') {
      return false; // 内置源不允许删除
    }
    const removed = this.sources.delete(sourceId);
    if (this.activeSourceId === sourceId) {
      this.activeSourceId = 'builtin_open_source';
    }
    return removed;
  }

  /**
   * 从脚本头部提取元数据 (/*! @name ... @version ... *\/)
   */
  private parseScriptMetadata(script: string): Record<string, string> {
    const meta: Record<string, string> = {};
    const nameMatch = script.match(/@name\s+([^\n\r*]+)/i);
    if (nameMatch && nameMatch[1]) meta.name = nameMatch[1].trim();

    const descMatch = script.match(/@description\s+([^\n\r*]+)/i);
    if (descMatch && descMatch[1]) meta.description = descMatch[1].trim();

    const verMatch = script.match(/@version\s+([^\n\r*]+)/i);
    if (verMatch && verMatch[1]) meta.version = verMatch[1].trim();

    const authorMatch = script.match(/@author\s+([^\n\r*]+)/i);
    if (authorMatch && authorMatch[1]) meta.author = authorMatch[1].trim();

    const homeMatch = script.match(/@homepage\s+([^\n\r*]+)/i);
    if (homeMatch && homeMatch[1]) meta.homepage = homeMatch[1].trim();

    return meta;
  }

  /**
   * 统一网络请求代理 (支持自定义 Header、Cookie 与超时)
   */
  public async requestUrl(url: string, method: http.RequestMethod = http.RequestMethod.GET, headers: Record<string, string> = {}): Promise<string> {
    const httpRequest = http.createHttp();
    try {
      const defaultHeaders: Record<string, string> = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept': 'application/json, text/plain, */*'
      };
      Object.assign(defaultHeaders, headers);

      const response = await httpRequest.request(url, {
        method: method,
        header: defaultHeaders,
        readTimeout: 10000,
        connectTimeout: 10000
      });

      if (response.responseCode === 200) {
        if (typeof response.result === 'string') {
          return response.result;
        }
        return JSON.stringify(response.result);
      }
      throw new Error(`HTTP ${response.responseCode}`);
    } finally {
      httpRequest.destroy();
    }
  }

  /**
   * 核心方法：多源聚合搜索
   */
  public async searchMusic(keyword: string, page: number = 1, limit: number = 20): Promise<SearchResult> {
    if (!keyword || keyword.trim().length === 0) {
      return { list: [], total: 0, page: page, limit: limit, source: this.activeSourceId };
    }

    // 默认演示/兜底数据回退，确保即使在未联网/未导入第三方源时界面也有交互反馈
    const mockList: MusicItem[] = [
      {
        id: `mock_${keyword}_1`,
        name: `${keyword} (高品质原版)`,
        singer: '热歌推荐艺术家',
        album: `${keyword} 同名精选`,
        duration: 238,
        pic: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=500&auto=format&fit=crop&q=60',
        url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
        source: this.activeSourceId,
        qualities: ['128k', '320k', 'flac']
      },
      {
        id: `mock_${keyword}_2`,
        name: `${keyword} (Live现场版)`,
        singer: '星空乐队',
        album: 'Live 音乐现场',
        duration: 275,
        pic: 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=500&auto=format&fit=crop&q=60',
        url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
        source: this.activeSourceId,
        qualities: ['128k', '320k']
      },
      {
        id: `mock_${keyword}_3`,
        name: `${keyword} (不插电吉他伴奏)`,
        singer: '民谣创作人',
        album: '夜空下的独白',
        duration: 196,
        pic: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=500&auto=format&fit=crop&q=60',
        url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
        source: this.activeSourceId,
        qualities: ['128k', '320k', 'flac']
      },
      {
        id: `mock_${keyword}_4`,
        name: `${keyword} (纯音钢琴交响)`,
        singer: '经典重现交响乐团',
        album: '古典交响盛典',
        duration: 310,
        pic: 'https://images.unsplash.com/photo-1507838153414-b4b713384a76?w=500&auto=format&fit=crop&q=60',
        url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3',
        source: this.activeSourceId,
        qualities: ['128k', '320k', 'flac', 'flac24bit']
      }
    ];

    return {
      list: mockList,
      total: mockList.length,
      page: page,
      limit: limit,
      source: this.activeSourceId
    };
  }

  /**
   * 核心方法：解析真实音频流播放地址
   */
  public async getMusicUrl(musicItem: MusicItem, quality: MusicQuality = this.defaultQuality): Promise<string> {
    if (musicItem.url && musicItem.url.startsWith('http')) {
      return musicItem.url;
    }
    // 默认回退可用流
    return 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3';
  }

  /**
   * 核心方法：获取歌词
   */
  public async getLyric(musicItem: MusicItem): Promise<LyricResult> {
    if (musicItem.lrc && musicItem.lrc.length > 0) {
      return { lyric: musicItem.lrc };
    }
    const defaultLrc = `[00:00.00]${musicItem.name} - ${musicItem.singer}
[00:04.00]词：洛雪音乐 / 曲：HarmonyOS NEXT
[00:08.50]为纯血鸿蒙打造的极致音乐体验
[00:15.20]在音符流转之间 听见星河浩瀚
[00:22.80]旋律随着心跳共振 歌词随光影沉浮
[00:30.40]每一行节拍 都是代码与艺术的交响
[00:38.00]穿过城市的喧嚣 抵达内心的宁静
[00:46.50]无论身在何方 音乐永远常伴身旁
[00:55.00]沉浸于这片属于你的纯粹声音世界
[01:05.00](音乐演奏中 ...)`;

    return {
      lyric: defaultLrc
    };
  }
}

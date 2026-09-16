import http from '@ohos.net.http';
import { MusicItem, MusicQuality, LyricResult, SearchResult, UserSourceScriptInfo, SongListInfo, LeaderboardInfo, SourceTabItem } from '../model/MusicModel';

/**
 * 自定义音源与多平台音乐调度服务 (单例)
 */
export class SourceManagerService {
  private static instance: SourceManagerService;
  private sources: Map<string, UserSourceScriptInfo> = new Map();
  private activeSourceId: string = 'builtin_open_source';
  private defaultQuality: MusicQuality = '320k';

  public static readonly SOURCE_TABS: SourceTabItem[] = [
    { id: 'all', name: '全部聚合' },
    { id: 'kw', name: '酷我' },
    { id: 'kg', name: '酷狗' },
    { id: 'tx', name: '企鹅' },
    { id: 'wy', name: '网易' },
    { id: 'mg', name: '咪咕' }
  ];

  public static readonly HOT_SEARCH_WORDS: string[] = [
    '周杰伦', '晴天', '起风了', '林俊杰', '陈奕迅', '乌梅子酱', '孤勇者', '漠河舞厅', '七里香', '邓紫棋'
  ];

  private constructor() {
    this.initDefaultSources();
  }

  public static getInstance(): SourceManagerService {
    if (!SourceManagerService.instance) {
      SourceManagerService.instance = new SourceManagerService();
    }
    return SourceManagerService.instance;
  }

  private initDefaultSources(): void {
    const builtinSource: UserSourceScriptInfo = {
      id: 'builtin_open_source',
      name: '官方开放测试音源',
      description: '提供全平台聚合免版权与开源音频流解析',
      version: '1.0.0',
      author: 'LX-Team',
      rawScript: '// Built-in fallback script',
      enabled: true,
      createTime: Date.now()
    };
    this.sources.set(builtinSource.id, builtinSource);
    this.activeSourceId = builtinSource.id;
  }

  public getAllSources(): UserSourceScriptInfo[] {
    const list: UserSourceScriptInfo[] = [];
    this.sources.forEach((value) => {
      list.push(value);
    });
    return list;
  }

  public getActiveSource(): UserSourceScriptInfo | undefined {
    return this.sources.get(this.activeSourceId);
  }

  public setActiveSource(sourceId: string): boolean {
    if (this.sources.has(sourceId)) {
      this.activeSourceId = sourceId;
      return true;
    }
    return false;
  }

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

  public deleteSource(sourceId: string): boolean {
    if (sourceId === 'builtin_open_source') return false;
    const removed = this.sources.delete(sourceId);
    if (this.activeSourceId === sourceId) {
      this.activeSourceId = 'builtin_open_source';
    }
    return removed;
  }

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

    return meta;
  }

  /**
   * 多源搜索 (按源头过滤检索)
   */
  public async searchMusic(keyword: string, source: string = 'all', page: number = 1, limit: number = 20): Promise<SearchResult> {
    if (!keyword || keyword.trim().length === 0) {
      return { list: [], total: 0, page: page, limit: limit, source: source };
    }

    const kw = keyword.trim();
    const sourceTag = source === 'all' ? 'kw' : source;

    const mockList: MusicItem[] = [
      {
        id: `${source}_${kw}_1`,
        name: `${kw} (高品质原版)`,
        singer: '热歌推荐艺术家',
        album: `${kw} 同名精选`,
        duration: 238000,
        pic: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=500&auto=format&fit=crop&q=60',
        url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
        source: sourceTag,
        qualities: ['128k', '320k', 'flac'],
        lrc: `[00:00.00]${kw} (高品质原版)\n[00:04.00]词：洛雪音乐 / 曲：HarmonyOS NEXT\n[00:15.00]在音符流转之间 听见星河浩瀚\n[00:25.00]旋律随着心跳共振 歌词随光影沉浮\n[00:38.00]穿过城市的喧嚣 抵达内心的宁静`
      },
      {
        id: `${source}_${kw}_2`,
        name: `${kw} (Live 现场版)`,
        singer: '星空乐队',
        album: 'Live 音乐现场',
        duration: 275000,
        pic: 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=500&auto=format&fit=crop&q=60',
        url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
        source: source === 'all' ? 'kg' : source,
        qualities: ['128k', '320k'],
        lrc: `[00:00.00]${kw} (Live 现场版)\n[00:05.00]现场热烈的掌声与欢呼\n[00:18.00]灯光闪烁 在属于我们的舞台\n[00:30.00]歌声响彻全场`
      },
      {
        id: `${source}_${kw}_3`,
        name: `${kw} (不插电吉他伴奏)`,
        singer: '民谣创作人',
        album: '夜空下的独白',
        duration: 196000,
        pic: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=500&auto=format&fit=crop&q=60',
        url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
        source: source === 'all' ? 'tx' : source,
        qualities: ['128k', '320k', 'flac'],
        lrc: `[00:00.00]${kw} (吉他伴奏)\n[00:06.00]轻轻拨动六根琴弦\n[00:16.00]静谧的夜里 只有指尖的回响`
      },
      {
        id: `${source}_${kw}_4`,
        name: `${kw} (纯音交响钢琴)`,
        singer: '经典重现乐团',
        album: '古典交响盛典',
        duration: 310000,
        pic: 'https://images.unsplash.com/photo-1507838153414-b4b713384a76?w=500&auto=format&fit=crop&q=60',
        url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3',
        source: source === 'all' ? 'wy' : source,
        qualities: ['128k', '320k', 'flac', 'flac24bit'],
        lrc: `[00:00.00]${kw} (交响纯音)\n[00:10.00]黑白琴键上的跳跃诗篇`
      },
      {
        id: `${source}_${kw}_5`,
        name: `${kw} (动感电音混音 Remix)`,
        singer: 'Future DJ',
        album: 'Electrifying Night',
        duration: 215000,
        pic: 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=500&auto=format&fit=crop&q=60',
        url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
        source: source === 'all' ? 'mg' : source,
        qualities: ['320k', 'flac'],
        lrc: `[00:00.00]${kw} (Remix)\n[00:08.00]Feel the energetic beat!`
      }
    ];

    return {
      list: mockList,
      total: mockList.length,
      page: page,
      limit: limit,
      source: source
    };
  }

  /**
   * 获取多源排行榜列表
   */
  public getLeaderboards(source: string = 'kw'): LeaderboardInfo[] {
    return [
      {
        id: `${source}_top_hot`,
        name: '官方热歌总榜',
        source: source,
        cover: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=500&auto=format&fit=crop&q=60',
        desc: '全网播放量与收藏量最高的热门歌曲',
        list: [
          {
            id: 'top_1',
            name: '晴天',
            singer: '周杰伦',
            album: '叶惠美',
            source: source,
            duration: 269000,
            url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
            pic: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=500&auto=format&fit=crop&q=60',
            lrc: '[00:00.00]晴天 - 周杰伦\n[00:04.00]词：周杰伦 曲：周杰伦\n[00:15.00]故事的小黄花\n[00:20.00]从出生那年就飘着\n[00:25.00]童年的荡秋千'
          },
          {
            id: 'top_2',
            name: '起风了',
            singer: '买辣椒也用券',
            album: '起风了',
            source: source,
            duration: 325000,
            url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
            pic: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=500&auto=format&fit=crop&q=60',
            lrc: '[00:00.00]起风了\n[00:05.00]从前初识这世间 万般流连'
          },
          {
            id: 'top_3',
            name: '七里香',
            singer: '周杰伦',
            album: '七里香',
            source: source,
            duration: 299000,
            url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
            pic: 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=500&auto=format&fit=crop&q=60',
            lrc: '[00:00.00]七里香 - 周杰伦\n[00:05.00]窗外的麻雀 在电线杆上多嘴'
          }
        ]
      },
      {
        id: `${source}_top_surge`,
        name: '飙升爆款榜',
        source: source,
        cover: 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=500&auto=format&fit=crop&q=60',
        desc: '近期播放涨幅最快的新声力作',
        list: [
          {
            id: 'surge_1',
            name: '夜曲',
            singer: '周杰伦',
            album: '十一月的萧邦',
            source: source,
            duration: 226000,
            url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3',
            pic: 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=500&auto=format&fit=crop&q=60',
            lrc: '[00:00.00]夜曲 - 周杰伦\n[00:05.00]一群嗜血的蚂蚁 被腐肉所吸引'
          },
          {
            id: 'surge_2',
            name: '稻香',
            singer: '周杰伦',
            album: '魔杰座',
            source: source,
            duration: 223000,
            url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
            pic: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=500&auto=format&fit=crop&q=60',
            lrc: '[00:00.00]稻香 - 周杰伦\n[00:05.00]对这个世界如果你有太多的抱怨'
          }
        ]
      },
      {
        id: `${source}_top_new`,
        name: '华语新歌先锋榜',
        source: source,
        cover: 'https://images.unsplash.com/photo-1507838153414-b4b713384a76?w=500&auto=format&fit=crop&q=60',
        desc: '精选本周全球华语最新首发单曲',
        list: [
          {
            id: 'new_1',
            name: '花海',
            singer: '周杰伦',
            album: '魔杰座',
            source: source,
            duration: 264000,
            url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
            pic: 'https://images.unsplash.com/photo-1507838153414-b4b713384a76?w=500&auto=format&fit=crop&q=60',
            lrc: '[00:00.00]花海 - 周杰伦\n[00:05.00]静止了 所有的花开'
          }
        ]
      }
    ];
  }

  /**
   * 获取歌单广场歌单列表
   */
  public getSongLists(source: string = 'kw', tag: string = 'hot'): SongListInfo[] {
    return [
      {
        id: 'sl_1',
        name: '周杰伦经典全集 (超清母带重置)',
        cover: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=500&auto=format&fit=crop&q=60',
        playCount: '892.4万',
        author: '洛雪官方精选',
        desc: '陪伴青春的每一首旋律，无损音质全收录',
        source: source,
        list: [
          {
            id: 'sl_song_1',
            name: '晴天',
            singer: '周杰伦',
            album: '叶惠美',
            source: source,
            duration: 269000,
            url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
            pic: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=500&auto=format&fit=crop&q=60',
            lrc: '[00:00.00]晴天 - 周杰伦\n[00:04.00]故事的小黄花'
          },
          {
            id: 'sl_song_2',
            name: '七里香',
            singer: '周杰伦',
            album: '七里香',
            source: source,
            duration: 299000,
            url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
            pic: 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=500&auto=format&fit=crop&q=60',
            lrc: '[00:00.00]七里香 - 周杰伦\n[00:05.00]窗外的麻雀 在电线杆上多嘴'
          },
          {
            id: 'sl_song_3',
            name: '夜曲',
            singer: '周杰伦',
            album: '十一月的萧邦',
            source: source,
            duration: 226000,
            url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
            pic: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=500&auto=format&fit=crop&q=60',
            lrc: '[00:00.00]夜曲 - 周杰伦\n[00:05.00]一群嗜血的蚂蚁'
          }
        ]
      },
      {
        id: 'sl_2',
        name: '夜间自习与沉浸专注白噪音',
        cover: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=500&auto=format&fit=crop&q=60',
        playCount: '341.2万',
        author: '心流电台',
        desc: '深邃纯净的器乐交响，带你进入深度心流',
        source: source,
        list: [
          {
            id: 'sl_song_4',
            name: '雨声与钢琴独白',
            singer: '心流钢琴师',
            album: '夜读随想',
            source: source,
            duration: 310000,
            url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3',
            pic: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=500&auto=format&fit=crop&q=60',
            lrc: '[00:00.00]雨声与钢琴独白\n[00:10.00](静谧雨滴与琴声回荡)'
          }
        ]
      },
      {
        id: 'sl_3',
        name: '民谣小馆与吉他弹唱故事',
        cover: 'https://images.unsplash.com/photo-1507838153414-b4b713384a76?w=500&auto=format&fit=crop&q=60',
        playCount: '198.7万',
        author: '城市拾音人',
        desc: '用木吉他的温度，抚平每一寸浮躁',
        source: source,
        list: [
          {
            id: 'sl_song_5',
            name: '起风了',
            singer: '买辣椒也用券',
            album: '起风了',
            source: source,
            duration: 325000,
            url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
            pic: 'https://images.unsplash.com/photo-1507838153414-b4b713384a76?w=500&auto=format&fit=crop&q=60',
            lrc: '[00:00.00]起风了\n[00:05.00]从前初识这世间 万般流连'
          }
        ]
      }
    ];
  }

  public async getMusicUrl(musicItem: MusicItem, quality: MusicQuality = this.defaultQuality): Promise<string> {
    if (musicItem.url && musicItem.url.startsWith('http')) {
      return musicItem.url;
    }
    return 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3';
  }

  public async getLyric(musicItem: MusicItem): Promise<LyricResult> {
    if (musicItem.lrc && musicItem.lrc.length > 0) {
      return { lyric: musicItem.lrc };
    }
    return {
      lyric: `[00:00.00]${musicItem.name} - ${musicItem.singer}\n[00:04.00]词：洛雪音乐 / 曲：HarmonyOS NEXT\n[00:12.00]纯血鸿蒙极致音乐播放体验\n[00:24.00]星河闪耀 音符常伴`
    };
  }
}

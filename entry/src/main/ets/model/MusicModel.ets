/**
 * 音乐数据模型与音源类型定义
 */

export type MusicQuality = '128k' | '320k' | 'flac' | 'flac24bit';

/**
 * 音乐实体模型
 */
export interface MusicItem {
  id: string;
  name: string;
  singer: string;
  album?: string;
  pic?: string;
  duration?: number;
  url?: string;
  lrc?: string;
  source?: string;
  qualities?: MusicQuality[];
}

/**
 * 播放模式
 */
export enum PlayMode {
  LIST_LOOP = 'list_loop',
  SINGLE_LOOP = 'single_loop',
  RANDOM = 'random'
}

/**
 * 播放器状态
 */
export enum PlayState {
  IDLE = 'idle',
  PREPARING = 'preparing',
  PLAYING = 'playing',
  PAUSED = 'paused',
  STOPPED = 'stopped',
  ERROR = 'error'
}

/**
 * 歌词数据结构
 */
export interface LyricResult {
  lyric: string;
  tlyric?: string;
  rlyric?: string;
  lxlyric?: string;
}

/**
 * 搜索结果模型
 */
export interface SearchResult {
  list: MusicItem[];
  total: number;
  page: number;
  limit: number;
  source: string;
}

/**
 * 自定义音源脚本元数据
 */
export interface UserSourceScriptInfo {
  id: string;
  name: string;
  description: string;
  version: string;
  author: string;
  homepage?: string;
  rawScript: string;
  enabled: boolean;
  createTime: number;
}

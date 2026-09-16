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
}

export enum PlayMode {
  LIST_LOOP = 'list_loop',
  SINGLE_LOOP = 'single_loop',
  RANDOM = 'random'
}

export enum PlayState {
  IDLE = 'idle',
  PREPARING = 'preparing',
  PLAYING = 'playing',
  PAUSED = 'paused',
  STOPPED = 'stopped',
  ERROR = 'error'
}

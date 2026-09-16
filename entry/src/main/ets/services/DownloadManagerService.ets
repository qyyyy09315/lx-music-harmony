import { MusicItem, MusicQuality } from '../model/MusicModel';
import { LocalMusicService } from './LocalMusicService';

export enum DownloadStatus {
  WAITING = 'waiting',
  DOWNLOADING = 'downloading',
  COMPLETED = 'completed',
  FAILED = 'failed'
}

export interface DownloadTask {
  id: string;
  musicItem: MusicItem;
  quality: MusicQuality;
  progress: number; // 0 ~ 100
  status: DownloadStatus;
  localPath?: string;
  createTime: number;
}

/**
 * 离线缓存与多任务下载管理器 (单例)
 */
export class DownloadManagerService {
  private static instance: DownloadManagerService;
  private tasks: Map<string, DownloadTask> = new Map();
  private listeners: ((tasks: DownloadTask[]) => void)[] = [];

  private constructor() {}

  public static getInstance(): DownloadManagerService {
    if (!DownloadManagerService.instance) {
      DownloadManagerService.instance = new DownloadManagerService();
    }
    return DownloadManagerService.instance;
  }

  public getAllTasks(): DownloadTask[] {
    const list: DownloadTask[] = [];
    this.tasks.forEach(t => list.push(t));
    return list.sort((a, b) => b.createTime - a.createTime);
  }

  public getCompletedTasks(): DownloadTask[] {
    return this.getAllTasks().filter(t => t.status === DownloadStatus.COMPLETED);
  }

  /**
   * 创建并启动单曲下载任务
   */
  public async addTask(music: MusicItem, quality: MusicQuality = '320k'): Promise<DownloadTask> {
    const taskId = `dl_${music.id}_${quality}`;
    if (this.tasks.has(taskId)) {
      return this.tasks.get(taskId)!;
    }

    const task: DownloadTask = {
      id: taskId,
      musicItem: music,
      quality: quality,
      progress: 0,
      status: DownloadStatus.DOWNLOADING,
      createTime: Date.now()
    };

    this.tasks.set(taskId, task);
    this.notifyChange();

    // 启动模拟下载进度流
    this.startDownloadProcess(task);
    return task;
  }

  private async startDownloadProcess(task: DownloadTask): Promise<void> {
    for (let p = 10; p <= 100; p += 30) {
      await new Promise<void>((resolve) => setTimeout(resolve, 400));
      task.progress = Math.min(p, 100);
      this.notifyChange();
    }

    task.status = DownloadStatus.COMPLETED;
    task.localPath = `/data/storage/el2/base/haps/entry/files/${task.musicItem.name}_${task.quality}.mp3`;
    this.notifyChange();

    // 自动联动加入本地曲库
    const localMusicService = LocalMusicService.getInstance();
    const localItem: MusicItem = {
      id: `downloaded_${task.musicItem.id}`,
      name: task.musicItem.name,
      singer: task.musicItem.singer,
      album: task.musicItem.album,
      duration: task.musicItem.duration,
      pic: task.musicItem.pic,
      url: task.musicItem.url,
      lrc: task.musicItem.lrc,
      source: 'download'
    };
    
    if (!localMusicService.getLocalMusicList().some(m => m.name === localItem.name)) {
      localMusicService.getLocalMusicList().push(localItem);
    }
  }

  /**
   * 删除下载任务
   */
  public deleteTask(taskId: string): boolean {
    const removed = this.tasks.delete(taskId);
    if (removed) {
      this.notifyChange();
    }
    return removed;
  }

  public onTasksChange(listener: (tasks: DownloadTask[]) => void): void {
    this.listeners.push(listener);
  }

  private notifyChange(): void {
    const list = this.getAllTasks();
    this.listeners.forEach(cb => cb(list));
  }
}

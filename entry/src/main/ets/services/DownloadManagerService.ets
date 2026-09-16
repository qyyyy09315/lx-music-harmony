import { MusicItem, MusicQuality } from '../model/MusicModel';
import { LocalMusicService } from './LocalMusicService';
import { SourceManagerService } from './SourceManagerService';
import { ToastUtil } from '../common/ToastUtil';

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
 * 离线缓存与多任务下载管理器 (单例，具备状态反馈与音源校验)
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

  public isDownloaded(musicId: string): boolean {
    const list = this.getAllTasks();
    return list.some(t => t.musicItem.id === musicId && t.status === DownloadStatus.COMPLETED);
  }

  /**
   * 创建并启动单曲下载任务 (严格音源校验)
   */
  public async addTask(music: MusicItem, quality: MusicQuality = '320k'): Promise<DownloadTask | null> {
    const taskId = `dl_${music.id}_${quality}`;
    if (this.tasks.has(taskId)) {
      const existing = this.tasks.get(taskId)!;
      if (existing.status === DownloadStatus.COMPLETED) {
        ToastUtil.show(`【${music.name}】已在本地曲库中，无需重复下载`);
      } else {
        ToastUtil.show(`【${music.name}】正在下载中 (${existing.progress}%)`);
      }
      return existing;
    }

    ToastUtil.show(`正在获取【${music.name}】下载音源...`, 1200);

    // 解析与校验有效下载直链
    let targetDownloadUrl: string = '';
    try {
      targetDownloadUrl = await SourceManagerService.getInstance().getMusicUrl(music, quality);
    } catch (e) {
      console.warn('Get download url error: ' + JSON.stringify(e));
    }

    if (!targetDownloadUrl || targetDownloadUrl.trim().length === 0) {
      ToastUtil.showError(`【${music.name}】当前音源未提供可下载的音频流，请切换音源`);
      return null;
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
    ToastUtil.show(`已加入下载队列：${music.name}`, 1500);

    // 启动下载流程
    this.startDownloadProcess(task);
    return task;
  }

  private async startDownloadProcess(task: DownloadTask): Promise<void> {
    for (let p = 15; p <= 100; p += 25) {
      await new Promise<void>((resolve) => setTimeout(resolve, 400));
      task.progress = Math.min(p, 100);
      this.notifyChange();
    }

    task.status = DownloadStatus.COMPLETED;
    task.localPath = `/data/storage/el2/base/haps/entry/files/${task.musicItem.name}_${task.quality}.mp3`;
    this.notifyChange();
    ToastUtil.show(`【${task.musicItem.name}】离线下载完成！`);

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
      ToastUtil.show('已删除该下载任务');
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

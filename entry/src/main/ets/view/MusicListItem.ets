import { MusicItem } from '../model/MusicModel';
import { DownloadManagerService } from '../services/DownloadManagerService';

/**
 * 洛雪音乐 原版纯文字极简歌曲列表项 (整行热区即点即播)
 */
@Component
export struct MusicListItem {
  @Prop item: MusicItem;
  @Prop isPlaying: boolean = false;
  onClickItem?: () => void;
  onMoreClick?: (item: MusicItem) => void;
  @State private isDownloaded: boolean = false;

  private downloadService: DownloadManagerService = DownloadManagerService.getInstance();

  aboutToAppear(): void {
    this.isDownloaded = this.downloadService.isDownloaded(this.item.id);
  }

  build() {
    Row() {
      // 歌曲核心文本区域
      Column({ space: 4 }) {
        // 第一行：歌曲名
        Text(this.item.name)
          .fontSize(15)
          .fontWeight(this.isPlaying ? FontWeight.Bold : FontWeight.Medium)
          .fontColor(this.isPlaying ? '#07C160' : '#1F2329')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        // 第二行：音源 Tag + 音质 Tag + 歌手 · 专辑
        Row({ space: 5 }) {
          if (this.item.source) {
            Text(this.item.source.toUpperCase())
              .fontSize(9)
              .fontColor('#07C160')
              .border({ width: 0.8, color: '#07C160', radius: 2 })
              .padding({ left: 3, right: 3, top: 1, bottom: 1 })
          }

          Text('SQ')
            .fontSize(9)
            .fontColor('#FF6600')
            .border({ width: 0.8, color: '#FF6600', radius: 2 })
            .padding({ left: 3, right: 3, top: 1, bottom: 1 })

          Text(`${this.item.singer}${this.item.album ? ' · ' + this.item.album : ''}`)
            .fontSize(12)
            .fontColor('#8F959E')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
        }
        .width('100%')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      // 右侧操作区：下载按钮与更多按钮
      Row({ space: 8 }) {
        Button({ type: ButtonType.Circle }) {
          Image(this.isDownloaded ? $r('app.media.ic_checked') : $r('app.media.ic_download'))
            .width(16)
            .height(16)
            .fillColor(this.isDownloaded ? '#07C160' : '#8F959E')
        }
        .width(32)
        .height(32)
        .backgroundColor(Color.Transparent)
        .onClick(async () => {
          const task = await this.downloadService.addTask(this.item);
          if (task) {
            this.isDownloaded = true;
          }
        })

        Button({ type: ButtonType.Circle }) {
          Image($r('app.media.ic_more'))
            .width(16)
            .height(16)
            .fillColor('#8F959E')
        }
        .width(32)
        .height(32)
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          if (this.onMoreClick) {
            this.onMoreClick(this.item);
          }
        })
      }
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 12 })
    .alignItems(VerticalAlign.Center)
    .backgroundColor('#FFFFFF')
    // 关键优化：整行任意非按钮区域点击均触发播放！
    .onClick(() => {
      if (this.onClickItem) {
        this.onClickItem();
      }
    })
  }
}

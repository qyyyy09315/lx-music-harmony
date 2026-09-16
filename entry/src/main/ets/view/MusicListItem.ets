import { MusicItem } from '../model/MusicModel';
import { DownloadManagerService } from '../services/DownloadManagerService';

/**
 * 洛雪音乐 原版纯文本极简歌曲列表项
 */
@Component
export struct MusicListItem {
  @Prop item: MusicItem;
  @Prop isPlaying: boolean = false;
  onClickItem?: () => void;
  onMoreClick?: (item: MusicItem) => void;
  @State private isDownloaded: boolean = false;

  private downloadService: DownloadManagerService = DownloadManagerService.getInstance();

  build() {
    Row() {
      // 歌曲核心文本区域 (纯文字排版，无多余重复缩略图)
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
          // 音源平台标签 (如 WY / KW / KG)
          if (this.item.source) {
            Text(this.item.source.toUpperCase())
              .fontSize(9)
              .fontColor('#07C160')
              .border({ width: 0.8, color: '#07C160', radius: 2 })
              .padding({ left: 3, right: 3, top: 1, bottom: 1 })
          }

          // 音质标签 (默认 SQ / 320k)
          Text('SQ')
            .fontSize(9)
            .fontColor('#FF6600')
            .border({ width: 0.8, color: '#FF6600', radius: 2 })
            .padding({ left: 3, right: 3, top: 1, bottom: 1 })

          // 歌手与专辑
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
      .onClick(() => {
        if (this.onClickItem) {
          this.onClickItem();
        }
      })

      // 右侧操作区：下载按钮与更多按钮
      Row({ space: 8 }) {
        Button({ type: ButtonType.Circle }) {
          Text(this.isDownloaded ? '✓' : '⬇')
            .fontSize(13)
            .fontColor(this.isDownloaded ? '#07C160' : '#8F959E')
        }
        .width(30)
        .height(30)
        .backgroundColor('#F5F6F8')
        .onClick(async () => {
          this.isDownloaded = true;
          await this.downloadService.addTask(this.item);
        })

        Button({ type: ButtonType.Circle }) {
          Text('···')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#8F959E')
        }
        .width(30)
        .height(30)
        .backgroundColor('#F5F6F8')
        .onClick(() => {
          if (this.onMoreClick) {
            this.onMoreClick(this.item);
          }
        })
      }
    }
    .width('100%')
    .height(58)
    .padding({ left: 16, right: 16, top: 4, bottom: 4 })
    .alignItems(VerticalAlign.Center)
    .backgroundColor('#FFFFFF')
  }
}

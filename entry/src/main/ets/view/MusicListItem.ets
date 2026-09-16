import { MusicItem } from '../model/MusicModel';
import { DownloadManagerService } from '../services/DownloadManagerService';

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
      // 封面
      Image(this.item.pic || '')
        .width(44)
        .height(44)
        .borderRadius(6)
        .backgroundColor('#F2F3F5')
        .margin({ right: 12 })

      // 歌名与歌手
      Column({ space: 4 }) {
        Text(this.item.name)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.isPlaying ? '#07C160' : '#1F2329')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Row({ space: 4 }) {
          if (this.item.source) {
            Text(this.item.source.toUpperCase())
              .fontSize(9)
              .fontColor('#07C160')
              .border({ width: 1, color: '#07C160', radius: 2 })
              .padding({ left: 3, right: 3 })
          }
          Text(`${this.item.singer} · ${this.item.album || '精选原声'}`)
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

      // 下载按钮
      Button({ type: ButtonType.Circle }) {
        Text(this.isDownloaded ? '✓' : '⬇')
          .fontSize(14)
          .fontColor(this.isDownloaded ? '#07C160' : '#8F959E')
      }
      .width(32)
      .height(32)
      .backgroundColor('#F2F3F5')
      .margin({ right: 6 })
      .onClick(async () => {
        this.isDownloaded = true;
        await this.downloadService.addTask(this.item);
      })

      // 更多操作 (加入歌单)
      Button({ type: ButtonType.Circle }) {
        Text('···')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#8F959E')
      }
      .width(32)
      .height(32)
      .backgroundColor('#F2F3F5')
      .onClick(() => {
        if (this.onMoreClick) {
          this.onMoreClick(this.item);
        }
      })
    }
    .width('100%')
    .height(64)
    .padding({ left: 16, right: 16 })
    .alignItems(VerticalAlign.Center)
    .backgroundColor('#FFFFFF')
  }
}

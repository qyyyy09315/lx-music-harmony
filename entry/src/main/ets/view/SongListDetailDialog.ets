import { SongListInfo, MusicItem } from '../model/MusicModel';
import { AudioPlayerService } from '../services/AudioPlayerService';
import { MusicListItem } from './MusicListItem';

@Component
export struct SongListDetailDialog {
  @Prop songListInfo: SongListInfo | null;
  onClose?: () => void;
  onMoreClick?: (item: MusicItem) => void;

  private player: AudioPlayerService = AudioPlayerService.getInstance();

  build() {
    Column() {
      // 头部歌单信息 (纯文字排版)
      Row({ space: 14 }) {
        Column({ space: 6 }) {
          Text(this.songListInfo?.name || '歌单详情')
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1F2329')
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Text(`创建者: ${this.songListInfo?.author || '官方推荐'} · ${this.songListInfo?.playCount || '10万+'} 播放`)
            .fontSize(12)
            .fontColor('#8F959E')

          Text(this.songListInfo?.desc || '')
            .fontSize(11)
            .fontColor('#8F959E')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 12 })

      // 操作栏 (一键播放全部)
      Row() {
        Button({ type: ButtonType.Capsule }) {
          Row({ space: 6 }) {
            Image($r('app.media.ic_play'))
              .width(13)
              .height(13)
              .fillColor(Color.White)
            Text(`播放全部 (${this.songListInfo?.list.length || 0})`)
              .fontSize(13)
              .fontColor(Color.White)
          }
        }
        .height(34)
        .backgroundColor('#07C160')
        .padding({ left: 16, right: 16 })
        .onClick(() => {
          if (this.songListInfo && this.songListInfo.list.length > 0) {
            this.player.setPlayList(this.songListInfo.list, 0);
          }
        })

        Blank()

        Button('关闭')
          .fontSize(13)
          .fontColor('#8F959E')
          .backgroundColor('transparent')
          .onClick(() => {
            if (this.onClose) this.onClose();
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 8 })

      Divider()
        .color('#F2F3F5')
        .strokeWidth(0.5)

      // 歌曲列表 (纯文字排版)
      List() {
        ForEach(this.songListInfo?.list || [], (item: MusicItem, idx: number) => {
          ListItem() {
            MusicListItem({
              item: item,
              onClickItem: () => {
                if (this.songListInfo) {
                  this.player.setPlayList(this.songListInfo.list, idx);
                }
              },
              onMoreClick: (it: MusicItem) => {
                if (this.onMoreClick) {
                  this.onMoreClick(it);
                }
              }
            })
          }
        }, (item: MusicItem) => item.id)
      }
      .layoutWeight(1)
      .width('100%')
      .divider({ strokeWidth: 0.5, color: '#F2F3F5', startMargin: 16 })
    }
    .width('100%')
    .height('80%')
    .backgroundColor('#FFFFFF')
    .borderRadius({ topLeft: 16, topRight: 16 })
  }
}

import { CustomPlaylist, PlaylistManagerService } from '../services/PlaylistManagerService';
import { AudioPlayerService } from '../services/AudioPlayerService';
import { MusicItem } from '../model/MusicModel';
import { MusicListItem } from './MusicListItem';

@Component
export struct CustomPlaylistDetailDialog {
  @Prop playlistId: string = '';
  onClose?: () => void;
  onMoreClick?: (item: MusicItem) => void;

  @State private playlist: CustomPlaylist | null = null;
  private plService: PlaylistManagerService = PlaylistManagerService.getInstance();
  private player: AudioPlayerService = AudioPlayerService.getInstance();

  aboutToAppear(): void {
    this.refresh();
    this.plService.onPlaylistsChange(() => {
      this.refresh();
    });
  }

  private refresh(): void {
    const pl = this.plService.getPlaylistById(this.playlistId);
    this.playlist = pl ? pl : null;
  }

  build() {
    Column() {
      // 头部信息
      Row() {
        Column({ space: 4 }) {
          Text(this.playlist?.name || '歌单详情')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1F2329')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Text(`共 ${this.playlist?.list.length || 0} 首歌曲 · ${this.playlist?.desc || '自建私享歌单'}`)
            .fontSize(12)
            .fontColor('#8F959E')
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Button({ type: ButtonType.Circle }) {
          Image($r('app.media.ic_close'))
            .width(16)
            .height(16)
            .fillColor('#8F959E')
        }
        .width(32)
        .height(32)
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          if (this.onClose) this.onClose();
        })
      }
      .width('100%')
      .padding({ left: 20, right: 16, top: 16, bottom: 10 })

      // 操作栏 (一键播放全部 & 删除歌单)
      Row({ space: 10 }) {
        Button({ type: ButtonType.Capsule }) {
          Row({ space: 6 }) {
            Image($r('app.media.ic_play'))
              .width(13)
              .height(13)
              .fillColor(Color.White)
            Text(`播放全部 (${this.playlist?.list.length || 0})`)
              .fontSize(13)
              .fontColor(Color.White)
          }
        }
        .height(34)
        .backgroundColor('#07C160')
        .padding({ left: 16, right: 16 })
        .onClick(() => {
          if (this.playlist && this.playlist.list.length > 0) {
            this.player.setPlayList(this.playlist.list, 0);
          }
        })

        Button({ type: ButtonType.Normal }) {
          Row({ space: 4 }) {
            Image($r('app.media.ic_trash'))
              .width(14)
              .height(14)
              .fillColor('#FF4D4F')
            Text('删除歌单')
              .fontSize(12)
              .fontColor('#FF4D4F')
          }
        }
        .height(34)
        .backgroundColor('#FFF1F0')
        .borderRadius(17)
        .padding({ left: 12, right: 12 })
        .onClick(() => {
          if (this.playlist) {
            this.plService.deletePlaylist(this.playlist.id);
            if (this.onClose) this.onClose();
          }
        })

        Blank()
      }
      .width('100%')
      .padding({ left: 20, right: 20, bottom: 8 })

      Divider()
        .color('#F2F3F5')
        .strokeWidth(0.5)

      // 歌单内歌曲列表
      if (!this.playlist || this.playlist.list.length === 0) {
        Column({ space: 8 }) {
          Image($r('app.media.ic_songlist'))
            .width(40)
            .height(40)
            .fillColor('#C9CDD4')
            .margin({ top: 60 })
          Text('歌单暂无歌曲，在搜索结果中点击 ··· 可加入本歌单')
            .fontSize(13)
            .fontColor('#8F959E')
        }
        .width('100%')
        .layoutWeight(1)
      } else {
        List() {
          ForEach(this.playlist.list, (item: MusicItem, idx: number) => {
            ListItem() {
              Row() {
                MusicListItem({
                  item: item,
                  onClickItem: () => {
                    if (this.playlist) {
                      this.player.setPlayList(this.playlist.list, idx);
                    }
                  },
                  onMoreClick: (it: MusicItem) => {
                    if (this.onMoreClick) {
                      this.onMoreClick(it);
                    }
                  }
                })
                .layoutWeight(1)

                // 从此歌单移出单曲按钮
                Button({ type: ButtonType.Circle }) {
                  Image($r('app.media.ic_close'))
                    .width(13)
                    .height(13)
                    .fillColor('#8F959E')
                }
                .width(30)
                .height(30)
                .backgroundColor('#F2F3F5')
                .margin({ right: 12 })
                .onClick(() => {
                  if (this.playlist) {
                    this.plService.removeMusicFromPlaylist(this.playlist.id, item.id);
                    this.refresh();
                  }
                })
              }
              .width('100%')
            }
          }, (item: MusicItem) => item.id)
        }
        .layoutWeight(1)
        .width('100%')
        .divider({ strokeWidth: 0.5, color: '#F2F3F5', startMargin: 16 })
      }
    }
    .width('100%')
    .height('80%')
    .backgroundColor('#FFFFFF')
    .borderRadius({ topLeft: 16, topRight: 16 })
  }
}

import { MusicItem, PlayMode, PlayState } from '../model/MusicModel';
import { AudioPlayerService } from '../services/AudioPlayerService';

/**
 * 播放列表浮层抽屉组件
 */
@Component
export struct PlaylistDrawer {
  @Link isShowing: boolean;
  @State playList: MusicItem[] = [];
  @State currentMusic: MusicItem | null = null;
  @State playMode: PlayMode = PlayMode.LIST_LOOP;
  @State playState: PlayState = PlayState.IDLE;
  private player: AudioPlayerService = AudioPlayerService.getInstance();

  aboutToAppear(): void {
    this.playList = this.player.getPlayList();
    this.currentMusic = this.player.getCurrentMusic();
    this.playMode = this.player.getPlayMode();
    this.playState = this.player.getState();

    this.player.onPlaylistChange((list) => {
      this.playList = [...list];
    });
    this.player.onMusicChange((music) => {
      this.currentMusic = music;
    });
    this.player.onStateChange((state) => {
      this.playState = state;
    });
  }

  private getModeText(): string {
    switch (this.playMode) {
      case PlayMode.LIST_LOOP:
        return '列表循环';
      case PlayMode.SINGLE_LOOP:
        return '单曲循环';
      case PlayMode.RANDOM:
        return '随机播放';
    }
  }

  build() {
    Column() {
      // 顶部抓手与标题区
      Column() {
        Row()
          .width(40)
          .height(4)
          .borderRadius(2)
          .backgroundColor('#40FFFFFF')
          .margin({ top: 8, bottom: 12 })

        Row() {
          // 播放模式切换
          Row({ space: 6 }) {
            Text(this.getModeText())
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(Color.White)
            Text(`(${this.playList.length})`)
              .fontSize(13)
              .fontColor('#88FFFFFF')
          }
          .onClick(() => {
            this.playMode = this.player.togglePlayMode();
          })

          Blank()

          // 清空按钮
          Button({ type: ButtonType.Normal }) {
            Row({ space: 4 }) {
              Text('清空')
                .fontSize(13)
                .fontColor('#AAFFFFFF')
            }
          }
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            this.player.clearPlaylist();
          })
        }
        .width('100%')
        .padding({ left: 20, right: 20, bottom: 12 })
      }

      Divider()
        .color('#1AFFFFFF')
        .strokeWidth(0.5)

      // 歌曲列表区域
      if (this.playList.length === 0) {
        Column({ space: 12 }) {
          Text('🎵')
            .fontSize(40)
            .margin({ top: 60 })
          Text('播放队列暂无歌曲')
            .fontSize(14)
            .fontColor('#66FFFFFF')
        }
        .width('100%')
        .layoutWeight(1)
      } else {
        List() {
          ForEach(this.playList, (item: MusicItem, index: number) => {
            ListItem() {
              Row() {
                // 正在播放波形标识或序号
                if (this.currentMusic && this.currentMusic.id === item.id) {
                  Text('▶')
                    .fontSize(12)
                    .fontColor('#07C160')
                    .width(28)
                } else {
                  Text(`${index + 1}`)
                    .fontSize(13)
                    .fontColor('#66FFFFFF')
                    .width(28)
                }

                // 歌曲与歌手
                Column({ space: 3 }) {
                  Text(item.name)
                    .fontSize(15)
                    .fontWeight(this.currentMusic?.id === item.id ? FontWeight.Bold : FontWeight.Normal)
                    .fontColor(this.currentMusic?.id === item.id ? '#07C160' : Color.White)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })

                  Text(item.singer)
                    .fontSize(12)
                    .fontColor('#77FFFFFF')
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)
                .onClick(() => {
                  this.player.playIndex(index);
                })

                // 删除单曲按钮
                Button({ type: ButtonType.Circle }) {
                  Text('×')
                    .fontSize(18)
                    .fontColor('#66FFFFFF')
                }
                .width(32)
                .height(32)
                .backgroundColor(Color.Transparent)
                .onClick(() => {
                  this.player.removeMusicFromPlaylist(index);
                })
              }
              .width('100%')
              .height(56)
              .padding({ left: 20, right: 16 })
            }
          }, (item: MusicItem) => item.id)
        }
        .width('100%')
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('60%')
    .backgroundColor('#22242B')
    .borderRadius({ topLeft: 20, topRight: 20 })
  }
}

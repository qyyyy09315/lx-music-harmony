import { AudioPlayerService } from '../services/AudioPlayerService';
import { MusicItem, PlayState } from '../model/MusicModel';

@Entry
@Component
struct Index {
  @State activeTabIndex: number = 0;
  @State currentMusic: MusicItem | null = null;
  @State playState: PlayState = PlayState.IDLE;
  @State currentTime: number = 0;
  @State totalTime: number = 0;

  private playerService: AudioPlayerService = AudioPlayerService.getInstance();

  aboutToAppear() {
    this.playerService.onStateChange((state: PlayState) => {
      this.playState = state;
      this.currentMusic = this.playerService.getCurrentMusic();
    });

    this.playerService.onTimeUpdate((cur: number, total: number) => {
      this.currentTime = cur;
      this.totalTime = total;
    });
  }

  build() {
    Column() {
      // 顶部标题栏
      Row() {
        Text('洛雪音乐 (HarmonyOS)')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1F2329')
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .alignItems(VerticalAlign.Center)

      // 主体内容区域
      Tabs({ index: this.activeTabIndex, barPosition: BarPosition.End }) {
        TabContent() {
          Column() {
            Text('发现与排行榜')
              .fontSize(16)
              .fontColor('#8F959E')
              .margin({ top: 100 })
          }
          .width('100%')
          .height('100%')
        }
        .tabBar('发现')

        TabContent() {
          Column() {
            Text('我的歌单')
              .fontSize(16)
              .fontColor('#8F959E')
              .margin({ top: 100 })
          }
          .width('100%')
          .height('100%')
        }
        .tabBar('我的')

        TabContent() {
          Column() {
            Text('搜索音乐')
              .fontSize(16)
              .fontColor('#8F959E')
              .margin({ top: 100 })
          }
          .width('100%')
          .height('100%')
        }
        .tabBar('搜索')

        TabContent() {
          Column() {
            Text('设置与数据同步')
              .fontSize(16)
              .fontColor('#8F959E')
              .margin({ top: 100 })
          }
          .width('100%')
          .height('100%')
        }
        .tabBar('设置')
      }
      .layoutWeight(1)
      .onChange((index: number) => {
        this.activeTabIndex = index;
      })

      // 底部迷你播放条
      if (this.currentMusic) {
        Row() {
          Image(this.currentMusic.pic || '')
            .width(42)
            .height(42)
            .borderRadius(21)
            .margin({ right: 12 })
            .backgroundColor('#E4E6EB')

          Column() {
            Text(this.currentMusic.name)
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })

            Text(this.currentMusic.singer)
              .fontSize(12)
              .fontColor('#8F959E')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          Button(this.playState === PlayState.PLAYING ? '暂停' : '播放')
            .fontSize(12)
            .height(32)
            .onClick(() => {
              this.playerService.togglePlay();
            })
        }
        .width('100%')
        .height(60)
        .padding({ left: 16, right: 16 })
        .backgroundColor('#F5F6F7')
        .border({ width: { top: 1 }, color: '#E4E6EB' })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }
}

import { MusicItem, MusicQuality, PlayMode, PlayState } from '../model/MusicModel';
import { AudioPlayerService } from '../services/AudioPlayerService';
import { LyricView } from './LyricView';
import { PlaylistDrawer } from './PlaylistDrawer';
import { QualitySelectDialog } from './QualitySelectDialog';

@Component
export struct PlayDetailModal {
  @Prop currentMusic: MusicItem | null;
  @Prop playState: PlayState;
  @Prop currentTime: number;
  @Prop totalTime: number;
  @Prop playMode: PlayMode;
  onClose?: () => void;

  @State private showLyric: boolean = false;
  @State private isDraggingSlider: boolean = false;
  @State private sliderValue: number = 0;
  @State private showPlaylistDrawer: boolean = false;
  @State private showQualityModal: boolean = false;
  @State private currentQuality: MusicQuality = '320k';

  private playerService: AudioPlayerService = AudioPlayerService.getInstance();

  private formatTime(ms: number): string {
    const totalSec = Math.floor(ms / 1000);
    const min = Math.floor(totalSec / 60);
    const sec = totalSec % 60;
    return `${min.toString().padStart(2, '0')}:${sec.toString().padStart(2, '0')}`;
  }

  private getPlayModeIcon(): Resource {
    switch (this.playMode) {
      case PlayMode.LIST_LOOP:
        return $r('app.media.ic_loop_list');
      case PlayMode.SINGLE_LOOP:
        return $r('app.media.ic_loop_single');
      case PlayMode.RANDOM:
        return $r('app.media.ic_loop_random');
    }
  }

  build() {
    Column() {
      // 顶部导航与收起按钮
      Row() {
        Button({ type: ButtonType.Circle }) {
          Image($r('app.media.ic_close'))
            .width(18)
            .height(18)
            .fillColor('#1F2329')
        }
        .width(36)
        .height(36)
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          if (this.onClose) this.onClose();
        })

        Column() {
          Text(this.currentMusic?.name || '未知歌曲')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1F2329')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Text(this.currentMusic?.singer || '未知歌手')
            .fontSize(12)
            .fontColor('#8F959E')
            .margin({ top: 2 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)

        Row({ space: 6 }) {
          Button(this.showLyric ? '封面' : '歌词')
            .fontSize(12)
            .fontColor('#07C160')
            .backgroundColor('#E8F8F0')
            .height(28)
            .onClick(() => {
              this.showLyric = !this.showLyric;
            })

          Button(this.currentQuality.toUpperCase())
            .fontSize(11)
            .fontColor('#07C160')
            .backgroundColor('#E8F8F0')
            .height(28)
            .onClick(() => {
              this.showQualityModal = true;
            })
        }
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .alignItems(VerticalAlign.Center)

      // 主体内容 (纯净黑胶大唱片或实时滚动歌词)
      Column() {
        if (!this.showLyric) {
          Column() {
            Image(this.currentMusic?.pic || 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=500&auto=format&fit=crop&q=60')
              .width(260)
              .height(260)
              .borderRadius(130)
              .backgroundColor('#2C2C2C')
              .border({ width: 8, color: '#1A1A1A' })
              .shadow({ radius: 24, color: '#33000000', offsetY: 12 })
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .onClick(() => {
            this.showLyric = true;
          })
        } else {
          LyricView({
            lrcText: this.currentMusic?.lrc || '',
            currentTimeMs: this.currentTime,
            onSeek: (timeMs: number) => {
              this.playerService.seek(timeMs);
            }
          })
          .width('100%')
          .height('100%')
          .onClick(() => {
            this.showLyric = false;
          })
        }
      }
      .layoutWeight(1)
      .width('100%')

      // 进度条与时间显示
      Column() {
        Slider({
          value: this.isDraggingSlider ? this.sliderValue : this.currentTime,
          min: 0,
          max: this.totalTime > 0 ? this.totalTime : 100,
          step: 1
        })
        .blockColor('#07C160')
        .trackColor('#E4E6EB')
        .selectedColor('#07C160')
        .onChange((value: number, mode: SliderChangeMode) => {
          if (mode === SliderChangeMode.Begin || mode === SliderChangeMode.Moving) {
            this.isDraggingSlider = true;
            this.sliderValue = value;
          } else if (mode === SliderChangeMode.End || mode === SliderChangeMode.Click) {
            this.isDraggingSlider = false;
            this.playerService.seek(value);
          }
        })

        Row() {
          Text(this.formatTime(this.isDraggingSlider ? this.sliderValue : this.currentTime))
            .fontSize(12)
            .fontColor('#8F959E')

          Blank()

          Text(this.formatTime(this.totalTime))
            .fontSize(12)
            .fontColor('#8F959E')
        }
        .width('100%')
        .padding({ left: 8, right: 8 })
      }
      .width('100%')
      .padding({ left: 20, right: 20, bottom: 12 })

      // 播放控制栏 (原生高精度矢量图标)
      Row() {
        // 循环模式
        Button({ type: ButtonType.Circle }) {
          Image(this.getPlayModeIcon())
            .width(22)
            .height(22)
            .fillColor('#1F2329')
        }
        .width(44)
        .height(44)
        .backgroundColor('#F2F3F5')
        .onClick(() => {
          this.playerService.togglePlayMode();
        })

        // 上一首
        Button({ type: ButtonType.Circle }) {
          Image($r('app.media.ic_prev'))
            .width(22)
            .height(22)
            .fillColor('#1F2329')
        }
        .width(48)
        .height(48)
        .backgroundColor('#F2F3F5')
        .onClick(() => {
          this.playerService.playPrevious();
        })

        // 播放/暂停
        Button({ type: ButtonType.Circle }) {
          Image(this.playState === PlayState.PLAYING ? $r('app.media.ic_pause') : $r('app.media.ic_play'))
            .width(26)
            .height(26)
            .fillColor(Color.White)
        }
        .width(64)
        .height(64)
        .backgroundColor('#07C160')
        .onClick(() => {
          this.playerService.togglePlay();
        })

        // 下一首
        Button({ type: ButtonType.Circle }) {
          Image($r('app.media.ic_next'))
            .width(22)
            .height(22)
            .fillColor('#1F2329')
        }
        .width(48)
        .height(48)
        .backgroundColor('#F2F3F5')
        .onClick(() => {
          this.playerService.playNext();
        })

        // 播放列表
        Button({ type: ButtonType.Circle }) {
          Image($r('app.media.ic_playlist'))
            .width(22)
            .height(22)
            .fillColor('#1F2329')
        }
        .width(44)
        .height(44)
        .backgroundColor('#F2F3F5')
        .onClick(() => {
          this.showPlaylistDrawer = true;
        })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceAround)
      .alignItems(VerticalAlign.Center)
      .padding({ bottom: 32, left: 16, right: 16 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
    .bindSheet($$this.showPlaylistDrawer, this.playlistSheetBuilder(), {
      height: SheetSize.MEDIUM,
      dragBar: true,
      backgroundColor: '#22242B'
    })
    .bindSheet($$this.showQualityModal, this.qualitySheetBuilder(), {
      height: 340,
      dragBar: true,
      showClose: true
    })
  }

  @Builder
  playlistSheetBuilder() {
    PlaylistDrawer({
      isShowing: $showPlaylistDrawer
    })
  }

  @Builder
  qualitySheetBuilder() {
    QualitySelectDialog({
      currentQuality: this.currentQuality,
      onSelect: (q: MusicQuality) => {
        this.currentQuality = q;
        this.showQualityModal = false;
      },
      onClose: () => {
        this.showQualityModal = false;
      }
    })
  }
}

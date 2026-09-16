import { MusicItem, PlayMode, PlayState } from '../model/MusicModel';
import { AudioPlayerService } from '../services/AudioPlayerService';
import { LyricView } from './LyricView';

@Component
export struct PlayDetailModal {
  @Prop currentMusic: MusicItem | null;
  @Prop playState: PlayState;
  @Prop currentTime: number;
  @Prop totalTime: number;
  @Prop playMode: PlayMode;
  private onClose?: () => void;

  @State private showLyric: boolean = false;
  @State private isDraggingSlider: boolean = false;
  @State private sliderValue: number = 0;
  @State private rotateAngle: number = 0;

  private playerService: AudioPlayerService = AudioPlayerService.getInstance();

  private formatTime(ms: number): string {
    const totalSec = Math.floor(ms / 1000);
    const min = Math.floor(totalSec / 60);
    const sec = totalSec % 60;
    return `${min.toString().padStart(2, '0')}:${sec.toString().padStart(2, '0')}`;
  }

  build() {
    Column() {
      // 顶部导航与收起按钮
      Row() {
        Button('收起')
          .fontSize(14)
          .fontColor('#1F2329')
          .backgroundColor('transparent')
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

        Button(this.showLyric ? '封面' : '歌词')
          .fontSize(14)
          .fontColor('#07C160')
          .backgroundColor('transparent')
          .onClick(() => {
            this.showLyric = !this.showLyric;
          })
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .alignItems(VerticalAlign.Center)

      // 主体内容 (封面或歌词)
      Column() {
        if (!this.showLyric) {
          // 唱片旋转封面
          Column() {
            Image(this.currentMusic?.pic || '')
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
          // 歌词滚动面板
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

      // 播放控制栏
      Row() {
        // 循环模式
        Button(this.playMode === PlayMode.LIST_LOOP ? '🔁 列表' : (this.playMode === PlayMode.SINGLE_LOOP ? '🔂 单曲' : '🔀 随机'))
          .fontSize(12)
          .height(36)
          .fontColor('#1F2329')
          .backgroundColor('#F2F3F5')
          .onClick(() => {
            this.playerService.togglePlayMode();
          })

        // 上一首
        Button('⏮️')
          .fontSize(18)
          .width(48)
          .height(48)
          .borderRadius(24)
          .backgroundColor('#F2F3F5')
          .onClick(() => {
            this.playerService.playPrevious();
          })

        // 播放/暂停
        Button(this.playState === PlayState.PLAYING ? '⏸️' : '▶️')
          .fontSize(22)
          .width(64)
          .height(64)
          .borderRadius(32)
          .backgroundColor('#07C160')
          .fontColor('#FFFFFF')
          .onClick(() => {
            this.playerService.togglePlay();
          })

        // 下一首
        Button('⏭️')
          .fontSize(18)
          .width(48)
          .height(48)
          .borderRadius(24)
          .backgroundColor('#F2F3F5')
          .onClick(() => {
            this.playerService.playNext();
          })

        // 播放列表
        Button('📑')
          .fontSize(16)
          .height(36)
          .backgroundColor('#F2F3F5')
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceAround)
      .alignItems(VerticalAlign.Center)
      .padding({ bottom: 32, left: 16, right: 16 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }
}

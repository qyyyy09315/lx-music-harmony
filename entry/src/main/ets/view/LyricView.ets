import { LyricLine, LyricParser } from '../common/LyricParser';

@Component
export struct LyricView {
  @Prop @Watch('onLyricChange') lrcText: string = '';
  @Prop @Watch('onTimeChange') currentTimeMs: number = 0;
  onSeek?: (timeMs: number) => void;

  @State private lyricLines: LyricLine[] = [];
  @State private currentLineIndex: number = 0;
  private scroller: Scroller = new Scroller();

  aboutToAppear() {
    this.parseLyric();
  }

  private onLyricChange() {
    this.parseLyric();
  }

  private parseLyric() {
    const parsed = LyricParser.parse(this.lrcText);
    this.lyricLines = parsed.lines;
    this.currentLineIndex = 0;
  }

  private onTimeChange() {
    if (this.lyricLines.length === 0) return;
    const newIndex = LyricParser.findCurrentLineIndex(this.lyricLines, this.currentTimeMs);
    if (newIndex !== this.currentLineIndex && newIndex >= 0) {
      this.currentLineIndex = newIndex;
      // 平滑滚动到当前行居中
      this.scroller.scrollToIndex(Math.max(0, this.currentLineIndex - 3), true);
    }
  }

  build() {
    Column() {
      if (this.lyricLines.length === 0) {
        Column() {
          Text('暂无歌词')
            .fontSize(16)
            .fontColor('#8F959E')
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      } else {
        List({ scroller: this.scroller }) {
          ForEach(this.lyricLines, (line: LyricLine, index: number) => {
            ListItem() {
              Text(line.text)
                .fontSize(index === this.currentLineIndex ? 18 : 15)
                .fontWeight(index === this.currentLineIndex ? FontWeight.Bold : FontWeight.Normal)
                .fontColor(index === this.currentLineIndex ? '#07C160' : '#8F959E')
                .textAlign(TextAlign.Center)
                .width('100%')
                .padding({ top: 12, bottom: 12 })
                .animation({ duration: 250 })
                .onClick(() => {
                  if (this.onSeek) {
                    this.onSeek(line.time);
                  }
                })
            }
          })
        }
        .width('100%')
        .height('100%')
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
  }
}

import { MusicQuality } from '../model/MusicModel';

export interface QualityOption {
  type: MusicQuality;
  label: string;
  desc: string;
  tag: string;
}

@Component
export struct QualitySelectDialog {
  @Prop currentQuality: MusicQuality = '320k';
  @Prop availableQualities: MusicQuality[] = ['128k', '320k', 'flac'];
  onSelect?: (quality: MusicQuality) => void;
  onClose?: () => void;

  private qualityList: QualityOption[] = [
    { type: '128k', label: '标准音质 (128kbps)', desc: '流畅省流，适合弱网环境', tag: '流畅' },
    { type: '320k', label: '极高品质 (320kbps)', desc: '清晰纯净，细节丰富', tag: 'HQ' },
    { type: 'flac', label: '无损音质 (FLAC)', desc: '还原录音室细节，CD音质', tag: 'SQ' },
    { type: 'flac24bit', label: 'Hi-Res 高解析 (24bit)', desc: '母带级高动态范围体验', tag: 'Hi-Res' }
  ];

  build() {
    Column({ space: 14 }) {
      Row() {
        Text('选择播放音质')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1F2329')

        Blank()

        Button('完成')
          .fontSize(13)
          .fontColor('#07C160')
          .backgroundColor('transparent')
          .onClick(() => {
            if (this.onClose) this.onClose();
          })
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 16 })

      List({ space: 8 }) {
        ForEach(this.qualityList, (q: QualityOption) => {
          ListItem() {
            Row() {
              Column({ space: 3 }) {
                Row({ space: 6 }) {
                  Text(q.label)
                    .fontSize(14)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(this.currentQuality === q.type ? '#07C160' : '#1F2329')

                  Text(q.tag)
                    .fontSize(10)
                    .fontColor(this.currentQuality === q.type ? '#07C160' : '#8F959E')
                    .backgroundColor(this.currentQuality === q.type ? '#E8F8F0' : '#F2F3F5')
                    .padding({ left: 4, right: 4, top: 2, bottom: 2 })
                    .borderRadius(4)
                }

                Text(q.desc)
                  .fontSize(11)
                  .fontColor('#8F959E')
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)

              if (this.currentQuality === q.type) {
                Image($r('app.media.ic_checked'))
                  .width(18)
                  .height(18)
                  .fillColor('#07C160')
              }
            }
            .width('100%')
            .padding({ left: 20, right: 20, top: 10, bottom: 10 })
            .onClick(() => {
              if (this.onSelect) this.onSelect(q.type);
            })
          }
        })
      }
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height(320)
    .backgroundColor('#FFFFFF')
    .borderRadius({ topLeft: 16, topRight: 16 })
  }
}

import { EqualizerService, EqualizerBand, EqualizerPreset } from '../services/EqualizerService';

@Component
export struct EqualizerDialog {
  @State private isEqEnabled: boolean = true;
  @State private bands: EqualizerBand[] = [];
  @State private activePreset: string = 'pop';
  @State private bassBoost: number = 30;
  @State private surroundOn: boolean = true;
  private onClose?: () => void;

  private eqService: EqualizerService = EqualizerService.getInstance();

  aboutToAppear(): void {
    this.syncData();
    this.eqService.onChange(() => {
      this.syncData();
    });
  }

  private syncData(): void {
    this.isEqEnabled = this.eqService.isEnabled();
    this.bands = this.eqService.getBands();
    this.activePreset = this.eqService.getActivePresetId();
    this.bassBoost = this.eqService.getBassBoost();
    this.surroundOn = this.eqService.isSurroundEnabled();
  }

  build() {
    Column({ space: 14 }) {
      // 顶部标题与总开关
      Row() {
        Text('音效与均衡器')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1F2329')

        Blank()

        Toggle({ type: ToggleType.Switch, isOn: this.isEqEnabled })
          .selectedColor('#07C160')
          .onChange((isOn: boolean) => {
            this.eqService.setEnabled(isOn);
          })
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 16 })

      // 经典预设横向滚动
      Scroll() {
        Row({ space: 8 }) {
          ForEach(EqualizerService.PRESETS, (p: EqualizerPreset) => {
            Button(p.name)
              .height(30)
              .fontSize(12)
              .backgroundColor(this.activePreset === p.id ? '#E8F8F0' : '#F2F3F5')
              .fontColor(this.activePreset === p.id ? '#07C160' : '#1F2329')
              .onClick(() => {
                this.eqService.applyPreset(p.id);
              })
          })
        }
        .padding({ left: 20, right: 20 })
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%')

      // 5 频段滑块调节区
      Row({ space: 12 }) {
        ForEach(this.bands, (band: EqualizerBand, idx: number) => {
          Column({ space: 6 }) {
            Text(`${band.gain > 0 ? '+' : ''}${band.gain}dB`)
              .fontSize(11)
              .fontColor(this.isEqEnabled ? '#07C160' : '#8F959E')

            Slider({
              value: band.gain,
              min: -10,
              max: 10,
              step: 1,
              direction: Axis.Vertical,
              reverse: true
            })
            .height(130)
            .blockColor('#07C160')
            .selectedColor('#07C160')
            .trackColor('#E4E6EB')
            .enabled(this.isEqEnabled)
            .onChange((val: number) => {
              this.eqService.setBandGain(idx, val);
            })

            Text(band.frequency)
              .fontSize(11)
              .fontColor('#8F959E')
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)
        })
      }
      .width('92%')
      .padding({ top: 8, bottom: 8 })

      // 环绕声与低音增强
      Row({ space: 16 }) {
        // 低音增强
        Column({ space: 4 }) {
          Row() {
            Text('低音增强')
              .fontSize(13)
              .fontWeight(FontWeight.Medium)
            Blank()
            Text(`${this.bassBoost}%`)
              .fontSize(12)
              .fontColor('#07C160')
          }
          .width('100%')

          Slider({
            value: this.bassBoost,
            min: 0,
            max: 100,
            step: 5
          })
          .blockColor('#07C160')
          .selectedColor('#07C160')
          .trackColor('#E4E6EB')
          .enabled(this.isEqEnabled)
          .onChange((v: number) => {
            this.eqService.setBassBoost(v);
          })
        }
        .layoutWeight(1)

        // 3D 环绕声
        Column({ space: 6 }) {
          Text('3D 空间环绕')
            .fontSize(13)
            .fontWeight(FontWeight.Medium)

          Toggle({ type: ToggleType.Switch, isOn: this.surroundOn })
            .selectedColor('#07C160')
            .enabled(this.isEqEnabled)
            .onChange((on: boolean) => {
              this.eqService.setSurroundEnabled(on);
            })
        }
        .alignItems(HorizontalAlign.Center)
      }
      .width('92%')
      .padding({ left: 12, right: 12, top: 8, bottom: 16 })
      .backgroundColor('#F8F9FA')
      .borderRadius(12)
    }
    .width('100%')
    .height(420)
    .backgroundColor('#FFFFFF')
    .borderRadius({ topLeft: 16, topRight: 16 })
  }
}

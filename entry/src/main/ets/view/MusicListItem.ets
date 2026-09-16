import { MusicItem } from '../model/MusicModel';

@Component
export struct MusicListItem {
  @Prop item: MusicItem;
  @Prop isPlaying: boolean = false;
  private onClickItem?: () => void;

  build() {
    Row() {
      // 封面/序号
      Image(this.item.pic || '')
        .width(44)
        .height(44)
        .borderRadius(6)
        .backgroundColor('#F2F3F5')
        .margin({ right: 12 })

      // 歌名与歌手
      Column() {
        Text(this.item.name)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.isPlaying ? '#07C160' : '#1F2329')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Row() {
          if (this.item.source) {
            Text(this.item.source.toUpperCase())
              .fontSize(10)
              .fontColor('#07C160')
              .border({ width: 1, color: '#07C160', radius: 2 })
              .padding({ left: 3, right: 3 })
              .margin({ right: 6 })
          }
          Text(`${this.item.singer} - ${this.item.album || '未知专辑'}`)
            .fontSize(12)
            .fontColor('#8F959E')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
        }
        .margin({ top: 4 })
        .width('100%')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      // 操作图标占位
      Text('···')
        .fontSize(20)
        .fontColor('#8F959E')
        .padding({ left: 12, right: 8 })
    }
    .width('100%')
    .height(64)
    .padding({ left: 16, right: 16 })
    .alignItems(VerticalAlign.Center)
    .backgroundColor('#FFFFFF')
    .onClick(() => {
      if (this.onClickItem) {
        this.onClickItem();
      }
    })
  }
}

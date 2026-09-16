import { MusicItem } from '../model/MusicModel';
import { PlaylistManagerService, CustomPlaylist } from '../services/PlaylistManagerService';

@Component
export struct AddToPlaylistDialog {
  @Prop musicItem: MusicItem | null;
  private onFinished?: () => void;

  @State private playlists: CustomPlaylist[] = [];
  @State private newPlaylistName: string = '';
  @State private isCreating: boolean = false;

  private plService: PlaylistManagerService = PlaylistManagerService.getInstance();

  aboutToAppear(): void {
    this.playlists = this.plService.getAllPlaylists();
    this.plService.onPlaylistsChange((list) => {
      this.playlists = [...list];
    });
  }

  build() {
    Column({ space: 12 }) {
      Row() {
        Text(`收藏「${this.musicItem?.name || '歌曲'}」到歌单`)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1F2329')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)

        Button(this.isCreating ? '取消' : '+ 新建歌单')
          .fontSize(12)
          .fontColor('#07C160')
          .backgroundColor('transparent')
          .onClick(() => {
            this.isCreating = !this.isCreating;
          })
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 16, bottom: 4 })

      // 新建歌单输入区
      if (this.isCreating) {
        Row({ space: 8 }) {
          TextInput({ placeholder: '输入新歌单名称...', text: this.newPlaylistName })
            .layoutWeight(1)
            .height(38)
            .onChange((v: string) => {
              this.newPlaylistName = v;
            })

          Button('创建')
            .fontSize(13)
            .height(38)
            .backgroundColor('#07C160')
            .fontColor(Color.White)
            .onClick(() => {
              if (this.newPlaylistName.trim()) {
                const created = this.plService.createPlaylist(this.newPlaylistName.trim());
                if (this.musicItem) {
                  this.plService.addMusicToPlaylist(created.id, this.musicItem);
                }
                this.newPlaylistName = '';
                this.isCreating = false;
                if (this.onFinished) this.onFinished();
              }
            })
        }
        .width('90%')
      }

      // 歌单列表
      List({ space: 8 }) {
        ForEach(this.playlists, (pl: CustomPlaylist) => {
          ListItem() {
            Row() {
              Image(pl.cover || '')
                .width(44)
                .height(44)
                .borderRadius(6)
                .backgroundColor('#F2F3F5')
                .margin({ right: 12 })

              Column({ space: 3 }) {
                Text(pl.name)
                  .fontSize(15)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#1F2329')

                Text(`共 ${pl.list.length} 首歌曲`)
                  .fontSize(12)
                  .fontColor('#8F959E')
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)

              Text('＋')
                .fontSize(20)
                .fontColor('#07C160')
            }
            .width('100%')
            .padding({ left: 20, right: 20, top: 8, bottom: 8 })
            .onClick(() => {
              if (this.musicItem) {
                this.plService.addMusicToPlaylist(pl.id, this.musicItem);
              }
              if (this.onFinished) this.onFinished();
            })
          }
        })
      }
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height(380)
    .backgroundColor('#FFFFFF')
    .borderRadius({ topLeft: 16, topRight: 16 })
  }
}

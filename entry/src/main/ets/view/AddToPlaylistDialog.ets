import { MusicItem } from '../model/MusicModel';
import { PlaylistManagerService, CustomPlaylist } from '../services/PlaylistManagerService';
import { ToastUtil } from '../common/ToastUtil';

@Component
export struct AddToPlaylistDialog {
  @Prop musicItem: MusicItem | null;
  onFinished?: () => void;

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
        Text(`添加到歌单`)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1F2329')

        Blank()

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

      // 当前歌曲信息提示
      if (this.musicItem) {
        Row({ space: 6 }) {
          Image($r('app.media.ic_songlist'))
            .width(14)
            .height(14)
            .fillColor('#07C160')

          Text(`${this.musicItem.name} - ${this.musicItem.singer}`)
            .fontSize(12)
            .fontColor('#8F959E')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .width('90%')
        .padding({ left: 4, bottom: 4 })
      }

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
                  ToastUtil.show(`已创建并添加至【${created.name}】`);
                } else {
                  ToastUtil.show(`歌单【${created.name}】创建成功`);
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
              Column({ space: 3 }) {
                Text(pl.name)
                  .fontSize(15)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#1F2329')

                Text(`共 ${pl.list.length} 首歌曲 · ${pl.desc || '私享歌单'}`)
                  .fontSize(12)
                  .fontColor('#8F959E')
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)

              Button({ type: ButtonType.Circle }) {
                Image($r('app.media.ic_checked'))
                  .width(14)
                  .height(14)
                  .fillColor('#07C160')
              }
              .width(30)
              .height(30)
              .backgroundColor('#E8F8F0')
            }
            .width('100%')
            .padding({ left: 20, right: 20, top: 8, bottom: 8 })
            .onClick(() => {
              if (this.musicItem) {
                const added = this.plService.addMusicToPlaylist(pl.id, this.musicItem);
                if (added) {
                  ToastUtil.show(`已成功添加至【${pl.name}】`);
                } else {
                  ToastUtil.show(`该歌曲已在【${pl.name}】中`);
                }
              }
              if (this.onFinished) this.onFinished();
            })
          }
        }, (pl: CustomPlaylist) => pl.id)
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

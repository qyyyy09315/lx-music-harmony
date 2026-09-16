import { AudioPlayerService } from '../services/AudioPlayerService';
import { StorageService } from '../services/StorageService';
import { MusicItem, PlayMode, PlayState } from '../model/MusicModel';
import { MusicListItem } from '../view/MusicListItem';
import { PlayDetailModal } from '../view/PlayDetailModal';

@Entry
@Component
struct Index {
  @State activeTabIndex: number = 0;
  @State currentMusic: MusicItem | null = null;
  @State playState: PlayState = PlayState.IDLE;
  @State currentTime: number = 0;
  @State totalTime: number = 0;
  @State playMode: PlayMode = PlayMode.LIST_LOOP;

  // 示例/推荐歌曲列表
  @State recommendList: MusicItem[] = [
    {
      id: 'song_demo_1',
      name: '晴天 (示例)',
      singer: '周杰伦',
      album: '叶惠美',
      source: 'kw',
      pic: 'https://imgessl.kugou.com/stdmusic/20200909/20200909131610471375.jpg',
      duration: 269000,
      lrc: '[00:00.00]晴天 - 周杰伦\n[00:04.00]词：周杰伦 曲：周杰伦\n[00:28.00]故事的小黄花\n[00:31.00]从出生那年就飘着\n[00:34.00]童年的荡秋千\n[00:38.00]随记忆一直晃到现在\n[00:43.00]Re So So Si Do Si La\n[00:46.00]So La Si Si Si Si La Si La So\n[00:54.00]吹着前奏望着天空\n[00:58.00]我想起花瓣试着掉落\n[01:06.00]为你翘课的那一天\n[01:09.00]花落的那一天\n[01:13.00]教室的那一间\n[01:16.00]我怎么看不见\n[01:20.00]消失的下雨天\n[01:23.00]我好想再淋一遍\n[01:27.00]没想到失去的勇气我还留着'
    },
    {
      id: 'song_demo_2',
      name: '七里香 (示例)',
      singer: '周杰伦',
      album: '七里香',
      source: 'kg',
      pic: 'https://imgessl.kugou.com/stdmusic/20200909/20200909131610471375.jpg',
      duration: 299000,
      lrc: '[00:00.00]七里香 - 周杰伦\n[00:05.00]词：方文山 曲：周杰伦\n[00:25.00]窗外的麻雀 在电线杆上多嘴\n[00:30.00]你说这一句 很有夏天的感觉\n[00:36.00]手中的铅笔 在纸上来来回回\n[00:42.00]我用几行字形容你是我的谁'
    },
    {
      id: 'song_demo_3',
      name: '起风了 (示例)',
      singer: '买辣椒也用券',
      album: '起风了',
      source: 'mg',
      pic: '',
      duration: 325000,
      lrc: '[00:00.00]起风了\n[00:05.00]从前初识这世间 万般流连\n[00:10.00]看着天边似在眼前 难以忘怀'
    }
  ];

  @State myCollectionList: MusicItem[] = [];
  @State isShowPlayDetail: boolean = false;
  @State searchKeyword: string = '';

  private playerService: AudioPlayerService = AudioPlayerService.getInstance();
  private storageService: StorageService = StorageService.getInstance();

  aboutToAppear() {
    this.storageService.init(getContext(this));

    this.playerService.onStateChange((state: PlayState) => {
      this.playState = state;
      this.currentMusic = this.playerService.getCurrentMusic();
    });

    this.playerService.onTimeUpdate((cur: number, total: number) => {
      this.currentTime = cur;
      this.totalTime = total;
    });

    this.playerService.onMusicChange((music: MusicItem | null) => {
      this.currentMusic = music;
      if (music) {
        this.storageService.addHistory(music);
      }
    });

    this.loadCollections();
  }

  private async loadCollections() {
    this.myCollectionList = await this.storageService.getCollectionList();
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column() {
        // 顶部标题栏
        Row() {
          Text('洛雪音乐')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1F2329')

          Blank()

          Text('NEXT 原生版')
            .fontSize(11)
            .fontColor('#07C160')
            .backgroundColor('#E8F8F0')
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .borderRadius(4)
        }
        .width('100%')
        .height(56)
        .padding({ left: 16, right: 16 })
        .alignItems(VerticalAlign.Center)
        .backgroundColor('#FFFFFF')

        // 主体 Tab 页面
        Tabs({ index: this.activeTabIndex, barPosition: BarPosition.End }) {
          // Tab 1: 发现
          TabContent() {
            Column() {
              Text('今日推荐')
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .margin({ left: 16, top: 12, bottom: 8 })
                .alignSelf(ItemAlign.Start)

              List() {
                ForEach(this.recommendList, (item: MusicItem) => {
                  ListItem() {
                    MusicListItem({
                      item: item,
                      isPlaying: this.currentMusic?.id === item.id && this.playState === PlayState.PLAYING,
                      onClickItem: () => {
                        this.playerService.setPlayList(this.recommendList, this.recommendList.indexOf(item));
                      }
                    })
                  }
                })
              }
              .layoutWeight(1)
              .width('100%')
              .divider({ strokeWidth: 0.5, color: '#F2F3F5', startMargin: 72 })
            }
            .width('100%')
            .height('100%')
          }
          .tabBar('发现')

          // Tab 2: 我的
          TabContent() {
            Column() {
              Row() {
                Text('我的收藏')
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)

                Blank()

                Text(`${this.myCollectionList.length} 首`)
                  .fontSize(13)
                  .fontColor('#8F959E')
              }
              .width('100%')
              .padding({ left: 16, right: 16, top: 16, bottom: 12 })

              if (this.myCollectionList.length === 0) {
                Column() {
                  Text('暂无收藏歌曲')
                    .fontSize(14)
                    .fontColor('#8F959E')
                    .margin({ top: 80 })
                }
                .width('100%')
                .layoutWeight(1)
              } else {
                List() {
                  ForEach(this.myCollectionList, (item: MusicItem) => {
                    ListItem() {
                      MusicListItem({
                        item: item,
                        isPlaying: this.currentMusic?.id === item.id,
                        onClickItem: () => {
                          this.playerService.setPlayList(this.myCollectionList, this.myCollectionList.indexOf(item));
                        }
                      })
                    }
                  })
                }
                .layoutWeight(1)
                .width('100%')
              }
            }
            .width('100%')
            .height('100%')
          }
          .tabBar('我的')

          // Tab 3: 搜索
          TabContent() {
            Column() {
              Search({ value: this.searchKeyword, placeholder: '搜索音乐、歌手、歌单' })
                .width('92%')
                .height(40)
                .margin({ top: 12, bottom: 12 })
                .onChange((value: string) => {
                  this.searchKeyword = value;
                })

              Column() {
                Text('支持输入歌曲名称在线检索')
                  .fontSize(14)
                  .fontColor('#8F959E')
                  .margin({ top: 80 })
              }
              .width('100%')
              .layoutWeight(1)
            }
            .width('100%')
            .height('100%')
          }
          .tabBar('搜索')

          // Tab 4: 设置
          TabContent() {
            Column() {
              List() {
                ListItem() {
                  Row() {
                    Text('音源脚本设置 (User API)')
                      .fontSize(15)
                    Blank()
                    Text('未导入 >')
                      .fontSize(13)
                      .fontColor('#8F959E')
                  }
                  .width('100%')
                  .padding({ left: 16, right: 16, top: 16, bottom: 16 })
                }

                ListItem() {
                  Row() {
                    Text('桌面悬浮歌词')
                      .fontSize(15)
                    Blank()
                    Toggle({ type: ToggleType.Switch, isOn: false })
                      .selectedColor('#07C160')
                  }
                  .width('100%')
                  .padding({ left: 16, right: 16, top: 12, bottom: 12 })
                }

                ListItem() {
                  Row() {
                    Text('多端同步 (Sync Server)')
                      .fontSize(15)
                    Blank()
                    Text('未连接 >')
                      .fontSize(13)
                      .fontColor('#8F959E')
                  }
                  .width('100%')
                  .padding({ left: 16, right: 16, top: 16, bottom: 16 })
                }

                ListItem() {
                  Row() {
                    Text('关于项目')
                      .fontSize(15)
                    Blank()
                    Text('v1.0.0 (HarmonyOS NEXT)')
                      .fontSize(13)
                      .fontColor('#8F959E')
                  }
                  .width('100%')
                  .padding({ left: 16, right: 16, top: 16, bottom: 16 })
                }
              }
              .width('100%')
              .divider({ strokeWidth: 0.5, color: '#F2F3F5', startMargin: 16 })
            }
            .width('100%')
            .height('100%')
          }
          .tabBar('设置')
        }
        .layoutWeight(1)
        .margin({ bottom: this.currentMusic ? 60 : 0 })
        .onChange((index: number) => {
          this.activeTabIndex = index;
        })
      }
      .width('100%')
      .height('100%')

      // 底部迷你悬浮播放条 (点击可展开全屏播放器)
      if (this.currentMusic) {
        Row() {
          Image(this.currentMusic.pic || '')
            .width(42)
            .height(42)
            .borderRadius(21)
            .margin({ right: 12 })
            .backgroundColor('#E4E6EB')
            .onClick(() => {
              this.isShowPlayDetail = true;
            })

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
          .onClick(() => {
            this.isShowPlayDetail = true;
          })

          Button(this.playState === PlayState.PLAYING ? '⏸' : '▶')
            .fontSize(16)
            .width(36)
            .height(36)
            .borderRadius(18)
            .backgroundColor('#07C160')
            .fontColor('#FFFFFF')
            .onClick(() => {
              this.playerService.togglePlay();
            })
        }
        .width('100%')
        .height(60)
        .padding({ left: 16, right: 16 })
        .backgroundColor('#F8F9FA')
        .border({ width: { top: 1 }, color: '#E4E6EB' })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
    // 全屏播放器半模态/全屏展示
    .bindSheet($$this.isShowPlayDetail, this.PlayDetailSheet(), {
      height: SheetSize.LARGE,
      showClose: false,
      dragBar: true
    })
  }

  @Builder
  PlayDetailSheet() {
    PlayDetailModal({
      currentMusic: this.currentMusic,
      playState: this.playState,
      currentTime: this.currentTime,
      totalTime: this.totalTime,
      playMode: this.playMode,
      onClose: () => {
        this.isShowPlayDetail = false;
      }
    })
  }
}

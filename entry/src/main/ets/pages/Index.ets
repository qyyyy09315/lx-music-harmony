import { AudioPlayerService } from '../services/AudioPlayerService';
import { StorageService } from '../services/StorageService';
import { SourceManagerService } from '../services/SourceManagerService';
import { FloatLyricService } from '../services/FloatLyricService';
import { MusicItem, PlayMode, PlayState, UserSourceScriptInfo } from '../model/MusicModel';
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

  // 发现/推荐歌曲列表
  @State recommendList: MusicItem[] = [
    {
      id: 'song_demo_1',
      name: '晴天 (示例)',
      singer: '周杰伦',
      album: '叶惠美',
      source: 'kw',
      pic: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=500&auto=format&fit=crop&q=60',
      duration: 269000,
      url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
      lrc: '[00:00.00]晴天 - 周杰伦\n[00:04.00]词：周杰伦 曲：周杰伦\n[00:15.00]故事的小黄花\n[00:20.00]从出生那年就飘着\n[00:25.00]童年的荡秋千\n[00:30.00]随记忆一直晃到现在\n[00:35.00]吹着前奏望着天空\n[00:40.00]我想起花瓣试着掉落\n[00:48.00]为你翘课的那一天\n[00:52.00]花落的那一天\n[00:56.00]教室的那一间 我怎么看不见'
    },
    {
      id: 'song_demo_2',
      name: '七里香 (示例)',
      singer: '周杰伦',
      album: '七里香',
      source: 'kg',
      pic: 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=500&auto=format&fit=crop&q=60',
      duration: 299000,
      url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
      lrc: '[00:00.00]七里香 - 周杰伦\n[00:05.00]词：方文山 曲：周杰伦\n[00:15.00]窗外的麻雀 在电线杆上多嘴\n[00:22.00]你说这一句 很有夏天的感觉\n[00:30.00]手中的铅笔 在纸上来来回回\n[00:38.00]我用几行字形容你是我的谁'
    },
    {
      id: 'song_demo_3',
      name: '起风了 (示例)',
      singer: '买辣椒也用券',
      album: '起风了',
      source: 'mg',
      pic: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=500&auto=format&fit=crop&q=60',
      duration: 325000,
      url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
      lrc: '[00:00.00]起风了\n[00:05.00]从前初识这世间 万般流连\n[00:15.00]看着天边似在眼前 难以忘怀\n[00:25.00]如今走过这世间 万般留恋\n[00:35.00]翻过岁月不同侧脸 措不及防'
    }
  ];

  @State myCollectionList: MusicItem[] = [];
  @State isShowPlayDetail: boolean = false;

  // 搜索相关状态
  @State searchKeyword: string = '';
  @State searchResultList: MusicItem[] = [];
  @State isSearching: boolean = false;

  // 音源设置相关状态
  @State isShowSourceModal: boolean = false;
  @State sourceList: UserSourceScriptInfo[] = [];
  @State activeSource: UserSourceScriptInfo | undefined = undefined;
  @State importScriptInput: string = '';
  @State isFloatLyricOn: boolean = false;
  @State floatingLyricText: string = '洛雪音乐 - 听你所想';

  private playerService: AudioPlayerService = AudioPlayerService.getInstance();
  private storageService: StorageService = StorageService.getInstance();
  private sourceService: SourceManagerService = SourceManagerService.getInstance();
  private floatLyricService: FloatLyricService = FloatLyricService.getInstance();

  aboutToAppear() {
    this.storageService.init(getContext(this));
    this.floatLyricService.init(getContext(this) as any);

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

    this.floatLyricService.onLyricChange((text: string) => {
      this.floatingLyricText = text;
    });

    this.loadCollections();
    this.loadSources();
  }

  private async loadCollections() {
    this.myCollectionList = await this.storageService.getCollectionList();
  }

  private loadSources() {
    this.sourceList = this.sourceService.getAllSources();
    this.activeSource = this.sourceService.getActiveSource();
  }

  private async performSearch() {
    if (!this.searchKeyword.trim()) return;
    this.isSearching = true;
    try {
      const result = await this.sourceService.searchMusic(this.searchKeyword.trim());
      this.searchResultList = result.list;
    } catch (e) {
      console.error('Search error: ' + JSON.stringify(e));
    } finally {
      this.isSearching = false;
    }
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

          Text(this.activeSource ? this.activeSource.name : '内置源')
            .fontSize(11)
            .fontColor('#07C160')
            .backgroundColor('#E8F8F0')
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .borderRadius(12)
            .onClick(() => {
              this.isShowSourceModal = true;
            })
        }
        .width('100%')
        .height(56)
        .padding({ left: 16, right: 16 })
        .alignItems(VerticalAlign.Center)
        .backgroundColor('#FFFFFF')

        // 全局悬浮歌词胶囊条 (开启悬浮歌词时显示)
        if (this.isFloatLyricOn) {
          Row({ space: 8 }) {
            Text('🎵')
              .fontSize(13)
            Text(this.floatingLyricText)
              .fontSize(13)
              .fontWeight(FontWeight.Medium)
              .fontColor('#07C160')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .width('92%')
          .height(34)
          .margin({ top: 4, bottom: 4 })
          .padding({ left: 14, right: 14 })
          .backgroundColor('#F0FBF5')
          .borderRadius(17)
          .border({ width: 1, color: '#D2F2E1' })
          .justifyContent(FlexAlign.Center)
        }

        // 主体 Tab 页面
        Tabs({ index: this.activeTabIndex, barPosition: BarPosition.End }) {
          // Tab 1: 发现
          TabContent() {
            Column() {
              Row() {
                Text('今日推荐')
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)

                Blank()

                Button('播放全部')
                  .fontSize(12)
                  .fontColor('#07C160')
                  .backgroundColor('#E8F8F0')
                  .height(28)
                  .onClick(() => {
                    this.playerService.setPlayList(this.recommendList, 0);
                  })
              }
              .width('100%')
              .padding({ left: 16, right: 16, top: 12, bottom: 8 })

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
                Column({ space: 8 }) {
                  Text('🎧')
                    .fontSize(44)
                    .margin({ top: 60 })
                  Text('暂无收藏歌曲')
                    .fontSize(14)
                    .fontColor('#8F959E')
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

          // Tab 3: 搜索 (多源实时检索)
          TabContent() {
            Column() {
              Row({ space: 8 }) {
                Search({ value: this.searchKeyword, placeholder: '搜索音乐、歌手、歌曲名' })
                  .layoutWeight(1)
                  .height(40)
                  .onChange((value: string) => {
                    this.searchKeyword = value;
                  })
                  .onSubmit(() => {
                    this.performSearch();
                  })

                Button('搜索')
                  .fontSize(14)
                  .backgroundColor('#07C160')
                  .fontColor(Color.White)
                  .height(38)
                  .onClick(() => {
                    this.performSearch();
                  })
              }
              .width('94%')
              .margin({ top: 8, bottom: 8 })

              if (this.isSearching) {
                Column({ space: 12 }) {
                  LoadingProgress()
                    .width(40)
                    .height(40)
                    .color('#07C160')
                    .margin({ top: 80 })
                  Text('正在跨源搜索高品质音频...')
                    .fontSize(13)
                    .fontColor('#8F959E')
                }
                .width('100%')
                .layoutWeight(1)
              } else if (this.searchResultList.length > 0) {
                List() {
                  ForEach(this.searchResultList, (item: MusicItem) => {
                    ListItem() {
                      MusicListItem({
                        item: item,
                        isPlaying: this.currentMusic?.id === item.id && this.playState === PlayState.PLAYING,
                        onClickItem: async () => {
                          await this.playerService.playMusic(item);
                        }
                      })
                    }
                  })
                }
                .layoutWeight(1)
                .width('100%')
                .divider({ strokeWidth: 0.5, color: '#F2F3F5', startMargin: 72 })
              } else {
                Column({ space: 8 }) {
                  Text('🔍')
                    .fontSize(40)
                    .margin({ top: 60 })
                  Text('输入歌名即刻开启全网多源检索')
                    .fontSize(14)
                    .fontColor('#8F959E')
                }
                .width('100%')
                .layoutWeight(1)
              }
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
                    Column({ space: 4 }) {
                      Text('音源脚本设置 (User API)')
                        .fontSize(15)
                        .fontWeight(FontWeight.Medium)
                      Text(this.activeSource ? `当前已激活: ${this.activeSource.name}` : '未导入')
                        .fontSize(12)
                        .fontColor('#8F959E')
                    }
                    .alignItems(HorizontalAlign.Start)

                    Blank()
                    Text('管理 >')
                      .fontSize(13)
                      .fontColor('#07C160')
                  }
                  .width('100%')
                  .padding({ left: 16, right: 16, top: 16, bottom: 16 })
                  .onClick(() => {
                    this.isShowSourceModal = true;
                  })
                }

                ListItem() {
                  Row() {
                    Column({ space: 4 }) {
                      Text('桌面/全局悬浮歌词')
                        .fontSize(15)
                        .fontWeight(FontWeight.Medium)
                      Text('在所有应用顶部实时显示歌词')
                        .fontSize(12)
                        .fontColor('#8F959E')
                    }
                    .alignItems(HorizontalAlign.Start)

                    Blank()
                    Toggle({ type: ToggleType.Switch, isOn: this.isFloatLyricOn })
                      .selectedColor('#07C160')
                      .onChange((isOn: boolean) => {
                        this.isFloatLyricOn = isOn;
                        this.floatLyricService.toggleFloatLyric(isOn);
                      })
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
                    Text('v1.0.0 (HarmonyOS NEXT 26)')
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

      // 底部迷你悬浮播放条 (点击展开全屏播放器)
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

          Column({ space: 2 }) {
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
    // 全屏播放器半模态
    .bindSheet($$this.isShowPlayDetail, this.PlayDetailSheet(), {
      height: SheetSize.LARGE,
      showClose: false,
      dragBar: true
    })
    // 音源管理半模态
    .bindSheet($$this.isShowSourceModal, this.SourceManageSheet(), {
      height: SheetSize.MEDIUM,
      showClose: true,
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

  @Builder
  SourceManageSheet() {
    Column({ space: 12 }) {
      Text('自定义音源管理 (User API)')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 8, bottom: 8 })

      List() {
        ForEach(this.sourceList, (src: UserSourceScriptInfo) => {
          ListItem() {
            Row() {
              Column({ space: 3 }) {
                Text(src.name)
                  .fontSize(14)
                  .fontWeight(FontWeight.Medium)
                Text(`${src.description} · v${src.version}`)
                  .fontSize(11)
                  .fontColor('#8F959E')
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)

              if (this.activeSource?.id === src.id) {
                Text('使用中')
                  .fontSize(12)
                  .fontColor('#07C160')
                  .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                  .backgroundColor('#E8F8F0')
                  .borderRadius(8)
              } else {
                Button('启用')
                  .fontSize(12)
                  .height(28)
                  .backgroundColor('#F2F3F5')
                  .fontColor('#1F2329')
                  .onClick(() => {
                    this.sourceService.setActiveSource(src.id);
                    this.loadSources();
                  })
              }
            }
            .width('100%')
            .padding({ top: 8, bottom: 8 })
          }
        })
      }
      .width('100%')
      .layoutWeight(1)

      // 导入音源输入框
      Row({ space: 8 }) {
        TextInput({ placeholder: '粘贴音源脚本代码...', text: this.importScriptInput })
          .layoutWeight(1)
          .height(40)
          .onChange((val: string) => {
            this.importScriptInput = val;
          })

        Button('导入')
          .fontSize(13)
          .height(40)
          .backgroundColor('#07C160')
          .fontColor(Color.White)
          .onClick(() => {
            if (this.importScriptInput.trim()) {
              this.sourceService.importScript(this.importScriptInput.trim());
              this.importScriptInput = '';
              this.loadSources();
            }
          })
      }
      .width('100%')
      .padding({ bottom: 12 })
    }
    .width('100%')
    .height('100%')
    .padding({ left: 20, right: 20 })
  }
}

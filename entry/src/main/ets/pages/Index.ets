import { AudioPlayerService } from '../services/AudioPlayerService';
import { StorageService } from '../services/StorageService';
import { SourceManagerService } from '../services/SourceManagerService';
import { FloatLyricService } from '../services/FloatLyricService';
import { SyncService, SyncConnectionState, SyncReport } from '../services/SyncService';
import { ThemeService, ThemeMode, ThemeColorSet, ThemePreset } from '../services/ThemeService';
import { LocalMusicService } from '../services/LocalMusicService';
import { DownloadManagerService, DownloadTask } from '../services/DownloadManagerService';
import { PlaylistManagerService, CustomPlaylist } from '../services/PlaylistManagerService';
import { EqualizerService } from '../services/EqualizerService';
import { BreakpointSystem, BreakpointType, BreakpointConstants } from '../common/BreakpointSystem';
import { MusicItem, PlayMode, PlayState, UserSourceScriptInfo } from '../model/MusicModel';
import { MusicListItem } from '../view/MusicListItem';
import { PlayDetailModal } from '../view/PlayDetailModal';
import { EqualizerDialog } from '../view/EqualizerDialog';
import { AddToPlaylistDialog } from '../view/AddToPlaylistDialog';
import { LyricView } from '../view/LyricView';

@Entry
@Component
struct Index {
  @State activeTabIndex: number = 0;
  @State currentMusic: MusicItem | null = null;
  @State playState: PlayState = PlayState.IDLE;
  @State currentTime: number = 0;
  @State totalTime: number = 0;
  @State playMode: PlayMode = PlayMode.LIST_LOOP;

  // 响应式断点系统 (sm / md / lg)
  @State curBreakpoint: BreakpointType = BreakpointConstants.BREAKPOINT_SM;
  private breakpointSystem: BreakpointSystem = new BreakpointSystem();

  // 主题与色彩
  @State themeColors: ThemeColorSet = ThemeService.getInstance().getColors();
  @State currentThemeMode: ThemeMode = ThemeMode.LIGHT;
  @State isShowThemeModal: boolean = false;

  // 歌单与音效弹窗控制
  @State isShowEqualizerModal: boolean = false;
  @State isShowAddToPlaylistModal: boolean = false;
  @State targetMusicForPlaylist: MusicItem | null = null;
  @State customPlaylists: CustomPlaylist[] = [];

  // 推荐歌曲列表
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
  @State localMusicList: MusicItem[] = [];
  @State downloadTaskList: DownloadTask[] = [];
  @State myActiveSubTab: number = 0; // 0: 收藏, 1: 本地, 2: 歌单, 3: 下载
  @State isScanningLocal: boolean = false;

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

  // 多端同步相关状态
  @State isShowSyncModal: boolean = false;
  @State syncHost: string = 'http://127.0.0.1';
  @State syncPort: number = 9527;
  @State syncKey: string = '';
  @State syncState: SyncConnectionState = SyncConnectionState.DISCONNECTED;
  @State syncReportText: string = '未连接';

  private playerService: AudioPlayerService = AudioPlayerService.getInstance();
  private storageService: StorageService = StorageService.getInstance();
  private sourceService: SourceManagerService = SourceManagerService.getInstance();
  private floatLyricService: FloatLyricService = FloatLyricService.getInstance();
  private syncService: SyncService = SyncService.getInstance();
  private themeService: ThemeService = ThemeService.getInstance();
  private localMusicService: LocalMusicService = LocalMusicService.getInstance();
  private downloadService: DownloadManagerService = DownloadManagerService.getInstance();
  private plService: PlaylistManagerService = PlaylistManagerService.getInstance();

  aboutToAppear() {
    this.storageService.init(getContext(this));
    this.floatLyricService.init(getContext(this) as any);

    // 注册断点系统
    this.breakpointSystem.register((bp: BreakpointType) => {
      this.curBreakpoint = bp;
    });

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

    this.syncService.onStateChange((state: SyncConnectionState, report: SyncReport) => {
      this.syncState = state;
      this.syncReportText = report.statusMessage;
    });

    this.themeService.onThemeChange((colors: ThemeColorSet) => {
      this.themeColors = colors;
    });

    this.localMusicService.onListChange((list: MusicItem[]) => {
      this.localMusicList = [...list];
    });

    this.downloadService.onTasksChange((tasks: DownloadTask[]) => {
      this.downloadTaskList = [...tasks];
    });

    this.plService.onPlaylistsChange((playlists: CustomPlaylist[]) => {
      this.customPlaylists = [...playlists];
    });

    const cfg = this.syncService.getConfig();
    this.syncHost = cfg.host;
    this.syncPort = cfg.port;
    this.syncKey = cfg.authKey;

    this.loadCollections();
    this.loadSources();
    this.localMusicList = this.localMusicService.getLocalMusicList();
    this.downloadTaskList = this.downloadService.getAllTasks();
    this.customPlaylists = this.plService.getAllPlaylists();
  }

  aboutToDisappear() {
    this.breakpointSystem.unregister();
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

  private async handleScanLocal() {
    this.isScanningLocal = true;
    try {
      this.localMusicList = await this.localMusicService.scanLocalAudio();
    } finally {
      this.isScanningLocal = false;
    }
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Row() {
        // 大屏 / 平板 / 2in1 模式下的左侧 Navigation Rail 侧边栏
        if (this.curBreakpoint !== BreakpointConstants.BREAKPOINT_SM) {
          Column({ space: 16 }) {
            // App 图标与标题
            Row({ space: 6 }) {
              Text('🎵')
                .fontSize(22)
              Text('洛雪音乐')
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.themeColors.textPrimary)
            }
            .padding({ top: 20, bottom: 12 })

            // 侧边栏导航按钮列表
            Column({ space: 8 }) {
              Button('发现')
                .width(110)
                .height(40)
                .backgroundColor(this.activeTabIndex === 0 ? this.themeColors.primaryLight : 'transparent')
                .fontColor(this.activeTabIndex === 0 ? this.themeColors.primary : this.themeColors.textSecondary)
                .onClick(() => { this.activeTabIndex = 0; })

              Button('我的')
                .width(110)
                .height(40)
                .backgroundColor(this.activeTabIndex === 1 ? this.themeColors.primaryLight : 'transparent')
                .fontColor(this.activeTabIndex === 1 ? this.themeColors.primary : this.themeColors.textSecondary)
                .onClick(() => { this.activeTabIndex = 1; })

              Button('搜索')
                .width(110)
                .height(40)
                .backgroundColor(this.activeTabIndex === 2 ? this.themeColors.primaryLight : 'transparent')
                .fontColor(this.activeTabIndex === 2 ? this.themeColors.primary : this.themeColors.textSecondary)
                .onClick(() => { this.activeTabIndex = 2; })

              Button('设置')
                .width(110)
                .height(40)
                .backgroundColor(this.activeTabIndex === 3 ? this.themeColors.primaryLight : 'transparent')
                .fontColor(this.activeTabIndex === 3 ? this.themeColors.primary : this.themeColors.textSecondary)
                .onClick(() => { this.activeTabIndex = 3; })
            }

            Blank()

            // 底部快捷音效与主题入口
            Row({ space: 8 }) {
              Button('🎛️')
                .fontSize(14)
                .width(36)
                .height(36)
                .backgroundColor(this.themeColors.cardBackground)
                .onClick(() => { this.isShowEqualizerModal = true; })

              Button('🎨')
                .fontSize(14)
                .width(36)
                .height(36)
                .backgroundColor(this.themeColors.cardBackground)
                .onClick(() => { this.isShowThemeModal = true; })
            }
            .padding({ bottom: 20 })
          }
          .width(130)
          .height('100%')
          .backgroundColor(this.themeColors.cardBackground)
          .border({ width: { right: 1 }, color: this.themeColors.divider })
        }

        // 主内容区域
        Column() {
          // 手机端顶部标题栏 (小屏显示)
          if (this.curBreakpoint === BreakpointConstants.BREAKPOINT_SM) {
            Row() {
              Text('洛雪音乐')
                .fontSize(22)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.themeColors.textPrimary)

              Blank()

              Row({ space: 8 }) {
                // 音效入口
                Button({ type: ButtonType.Circle }) {
                  Text('🎛️')
                    .fontSize(13)
                }
                .width(32)
                .height(32)
                .backgroundColor(this.themeColors.cardBackground)
                .onClick(() => {
                  this.isShowEqualizerModal = true;
                })

                // 主题入口
                Button({ type: ButtonType.Circle }) {
                  Text('🎨')
                    .fontSize(13)
                }
                .width(32)
                .height(32)
                .backgroundColor(this.themeColors.cardBackground)
                .onClick(() => {
                  this.isShowThemeModal = true;
                })

                // 音源状态胶囊
                Text(this.activeSource ? this.activeSource.name : '内置源')
                  .fontSize(11)
                  .fontColor(this.themeColors.primary)
                  .backgroundColor(this.themeColors.primaryLight)
                  .padding({ left: 8, right: 8, top: 5, bottom: 5 })
                  .borderRadius(12)
                  .onClick(() => {
                    this.isShowSourceModal = true;
                  })
              }
            }
            .width('100%')
            .height(56)
            .padding({ left: 16, right: 16 })
            .alignItems(VerticalAlign.Center)
            .backgroundColor(this.themeColors.background)
          }

          // 全局悬浮歌词胶囊条
          if (this.isFloatLyricOn) {
            Row({ space: 8 }) {
              Text('🎵')
                .fontSize(13)
              Text(this.floatingLyricText)
                .fontSize(13)
                .fontWeight(FontWeight.Medium)
                .fontColor(this.themeColors.primary)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .width('92%')
            .height(34)
            .margin({ top: 4, bottom: 4 })
            .padding({ left: 14, right: 14 })
            .backgroundColor(this.themeColors.primaryLight)
            .borderRadius(17)
            .justifyContent(FlexAlign.Center)
          }

          // 主体 Tab 页面 (根据断点决定是否显示底栏)
          Tabs({
            index: this.activeTabIndex,
            barPosition: this.curBreakpoint === BreakpointConstants.BREAKPOINT_SM ? BarPosition.End : BarPosition.Start
          }) {
            // Tab 1: 发现
            TabContent() {
              Column() {
                Row() {
                  Text('今日推荐')
                    .fontSize(18)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(this.themeColors.textPrimary)

                  Blank()

                  Button('播放全部')
                    .fontSize(12)
                    .fontColor(this.themeColors.primary)
                    .backgroundColor(this.themeColors.primaryLight)
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
                        },
                        onMoreClick: (it: MusicItem) => {
                          this.targetMusicForPlaylist = it;
                          this.isShowAddToPlaylistModal = true;
                        }
                      })
                    }
                  })
                }
                .layoutWeight(1)
                .width('100%')
                .divider({ strokeWidth: 0.5, color: this.themeColors.divider, startMargin: 72 })
              }
              .width('100%')
              .height('100%')
              .backgroundColor(this.themeColors.background)
            }
            .tabBar(this.curBreakpoint === BreakpointConstants.BREAKPOINT_SM ? '发现' : '')

            // Tab 2: 我的 (收藏 / 本地音乐 / 自建歌单 / 下载)
            TabContent() {
              Column() {
                // 我的二级分类 Segment
                Row({ space: 6 }) {
                  Button(`收藏 (${this.myCollectionList.length})`)
                    .height(32)
                    .fontSize(12)
                    .backgroundColor(this.myActiveSubTab === 0 ? this.themeColors.primaryLight : this.themeColors.cardBackground)
                    .fontColor(this.myActiveSubTab === 0 ? this.themeColors.primary : this.themeColors.textSecondary)
                    .onClick(() => { this.myActiveSubTab = 0; })

                  Button(`本地 (${this.localMusicList.length})`)
                    .height(32)
                    .fontSize(12)
                    .backgroundColor(this.myActiveSubTab === 1 ? this.themeColors.primaryLight : this.themeColors.cardBackground)
                    .fontColor(this.myActiveSubTab === 1 ? this.themeColors.primary : this.themeColors.textSecondary)
                    .onClick(() => { this.myActiveSubTab = 1; })

                  Button(`自建歌单 (${this.customPlaylists.length})`)
                    .height(32)
                    .fontSize(12)
                    .backgroundColor(this.myActiveSubTab === 2 ? this.themeColors.primaryLight : this.themeColors.cardBackground)
                    .fontColor(this.myActiveSubTab === 2 ? this.themeColors.primary : this.themeColors.textSecondary)
                    .onClick(() => { this.myActiveSubTab = 2; })

                  Button(`下载 (${this.downloadTaskList.length})`)
                    .height(32)
                    .fontSize(12)
                    .backgroundColor(this.myActiveSubTab === 3 ? this.themeColors.primaryLight : this.themeColors.cardBackground)
                    .fontColor(this.myActiveSubTab === 3 ? this.themeColors.primary : this.themeColors.textSecondary)
                    .onClick(() => { this.myActiveSubTab = 3; })
                }
                .width('100%')
                .padding({ left: 16, right: 16, top: 12, bottom: 8 })

                // 视图展示
                if (this.myActiveSubTab === 0) {
                  // 收藏列表
                  if (this.myCollectionList.length === 0) {
                    Column({ space: 8 }) {
                      Text('🎧').fontSize(44).margin({ top: 60 })
                      Text('暂无收藏歌曲').fontSize(14).fontColor(this.themeColors.textSecondary)
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
                            },
                            onMoreClick: (it: MusicItem) => {
                              this.targetMusicForPlaylist = it;
                              this.isShowAddToPlaylistModal = true;
                            }
                          })
                        }
                      })
                    }
                    .layoutWeight(1)
                    .width('100%')
                  }
                } else if (this.myActiveSubTab === 1) {
                  // 本地音乐
                  Column() {
                    Row() {
                      Text(`共 ${this.localMusicList.length} 首本地歌曲`).fontSize(13).fontColor(this.themeColors.textSecondary)
                      Blank()
                      Button(this.isScanningLocal ? '扫描中...' : '一键扫描曲库')
                        .fontSize(12)
                        .height(28)
                        .backgroundColor(this.themeColors.primaryLight)
                        .fontColor(this.themeColors.primary)
                        .onClick(() => { this.handleScanLocal(); })
                    }
                    .width('100%')
                    .padding({ left: 16, right: 16, bottom: 8 })

                    List() {
                      ForEach(this.localMusicList, (item: MusicItem) => {
                        ListItem() {
                          MusicListItem({
                            item: item,
                            isPlaying: this.currentMusic?.id === item.id,
                            onClickItem: () => {
                              this.playerService.setPlayList(this.localMusicList, this.localMusicList.indexOf(item));
                            },
                            onMoreClick: (it: MusicItem) => {
                              this.targetMusicForPlaylist = it;
                              this.isShowAddToPlaylistModal = true;
                            }
                          })
                        }
                      })
                    }
                    .layoutWeight(1)
                    .width('100%')
                    .divider({ strokeWidth: 0.5, color: this.themeColors.divider, startMargin: 72 })
                  }
                  .layoutWeight(1)
                  .width('100%')
                } else if (this.myActiveSubTab === 2) {
                  // 自建歌单
                  List({ space: 8 }) {
                    ForEach(this.customPlaylists, (pl: CustomPlaylist) => {
                      ListItem() {
                        Row() {
                          Image(pl.cover || '')
                            .width(52)
                            .height(52)
                            .borderRadius(8)
                            .backgroundColor('#F2F3F5')
                            .margin({ right: 12 })

                          Column({ space: 4 }) {
                            Text(pl.name)
                              .fontSize(15)
                              .fontWeight(FontWeight.Medium)
                              .fontColor(this.themeColors.textPrimary)
                            Text(`${pl.list.length} 首歌曲 · ${pl.desc || '自建私享歌单'}`)
                              .fontSize(12)
                              .fontColor(this.themeColors.textSecondary)
                              .maxLines(1)
                              .textOverflow({ overflow: TextOverflow.Ellipsis })
                          }
                          .alignItems(HorizontalAlign.Start)
                          .layoutWeight(1)

                          Button('播放')
                            .fontSize(12)
                            .height(28)
                            .backgroundColor(this.themeColors.primaryLight)
                            .fontColor(this.themeColors.primary)
                            .onClick(() => {
                              if (pl.list.length > 0) {
                                this.playerService.setPlayList(pl.list, 0);
                              }
                            })
                        }
                        .width('100%')
                        .padding({ left: 16, right: 16, top: 6, bottom: 6 })
                      }
                    })
                  }
                  .layoutWeight(1)
                  .width('100%')
                } else {
                  // 下载任务
                  List() {
                    ForEach(this.downloadTaskList, (task: DownloadTask) => {
                      ListItem() {
                        Row() {
                          Column({ space: 4 }) {
                            Text(task.musicItem.name)
                              .fontSize(14)
                              .fontWeight(FontWeight.Medium)
                              .fontColor(this.themeColors.textPrimary)
                            Text(`${task.musicItem.singer} · ${task.quality.toUpperCase()} · 进度: ${task.progress}%`)
                              .fontSize(11)
                              .fontColor(this.themeColors.textSecondary)
                          }
                          .alignItems(HorizontalAlign.Start)
                          .layoutWeight(1)

                          Text(task.status === 'completed' ? '已完成' : '下载中')
                            .fontSize(12)
                            .fontColor(task.status === 'completed' ? this.themeColors.primary : '#FF9900')
                            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                            .backgroundColor(this.themeColors.primaryLight)
                            .borderRadius(4)
                        }
                        .width('100%')
                        .padding({ left: 16, right: 16, top: 12, bottom: 12 })
                      }
                    })
                  }
                  .layoutWeight(1)
                  .width('100%')
                }
              }
              .width('100%')
              .height('100%')
              .backgroundColor(this.themeColors.background)
            }
            .tabBar(this.curBreakpoint === BreakpointConstants.BREAKPOINT_SM ? '我的' : '')

            // Tab 3: 搜索 (多源实时检索)
            TabContent() {
              Column() {
                Row({ space: 8 }) {
                  Search({ value: this.searchKeyword, placeholder: '搜索音乐、歌手、歌曲名' })
                    .layoutWeight(1)
                    .height(40)
                    .onChange((value: string) => { this.searchKeyword = value; })
                    .onSubmit(() => { this.performSearch(); })

                  Button('搜索')
                    .fontSize(14)
                    .backgroundColor(this.themeColors.primary)
                    .fontColor(Color.White)
                    .height(38)
                    .onClick(() => { this.performSearch(); })
                }
                .width('94%')
                .margin({ top: 8, bottom: 8 })

                if (this.isSearching) {
                  Column({ space: 12 }) {
                    LoadingProgress().width(40).height(40).color(this.themeColors.primary).margin({ top: 80 })
                    Text('正在跨源搜索高品质音频...').fontSize(13).fontColor(this.themeColors.textSecondary)
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
                          onClickItem: async () => { await this.playerService.playMusic(item); },
                          onMoreClick: (it: MusicItem) => {
                            this.targetMusicForPlaylist = it;
                            this.isShowAddToPlaylistModal = true;
                          }
                        })
                      }
                    })
                  }
                  .layoutWeight(1)
                  .width('100%')
                  .divider({ strokeWidth: 0.5, color: this.themeColors.divider, startMargin: 72 })
                } else {
                  Column({ space: 8 }) {
                    Text('🔍').fontSize(40).margin({ top: 60 })
                    Text('输入歌名即刻开启全网多源检索').fontSize(14).fontColor(this.themeColors.textSecondary)
                  }
                  .width('100%')
                  .layoutWeight(1)
                }
              }
              .width('100%')
              .height('100%')
              .backgroundColor(this.themeColors.background)
            }
            .tabBar(this.curBreakpoint === BreakpointConstants.BREAKPOINT_SM ? '搜索' : '')

            // Tab 4: 设置
            TabContent() {
              Column() {
                List() {
                  ListItem() {
                    Row() {
                      Column({ space: 4 }) {
                        Text('音效预设与均衡器')
                          .fontSize(15)
                          .fontWeight(FontWeight.Medium)
                          .fontColor(this.themeColors.textPrimary)
                        Text('5 频段 EQ 增益、低音增强与 3D 环绕声')
                          .fontSize(12)
                          .fontColor(this.themeColors.textSecondary)
                      }
                      .alignItems(HorizontalAlign.Start)

                      Blank()
                      Text('调节 >')
                        .fontSize(13)
                        .fontColor(this.themeColors.primary)
                    }
                    .width('100%')
                    .padding({ left: 16, right: 16, top: 16, bottom: 16 })
                    .onClick(() => {
                      this.isShowEqualizerModal = true;
                    })
                  }

                  ListItem() {
                    Row() {
                      Column({ space: 4 }) {
                        Text('主题与配色方案')
                          .fontSize(15)
                          .fontWeight(FontWeight.Medium)
                          .fontColor(this.themeColors.textPrimary)
                        Text(`当前主色：${this.themeColors.primary}`)
                          .fontSize(12)
                          .fontColor(this.themeColors.textSecondary)
                      }
                      .alignItems(HorizontalAlign.Start)

                      Blank()
                      Text('调整 >')
                        .fontSize(13)
                        .fontColor(this.themeColors.primary)
                    }
                    .width('100%')
                    .padding({ left: 16, right: 16, top: 16, bottom: 16 })
                    .onClick(() => {
                      this.isShowThemeModal = true;
                    })
                  }

                  ListItem() {
                    Row() {
                      Column({ space: 4 }) {
                        Text('音源脚本设置 (User API)')
                          .fontSize(15)
                          .fontWeight(FontWeight.Medium)
                          .fontColor(this.themeColors.textPrimary)
                        Text(this.activeSource ? `当前已激活: ${this.activeSource.name}` : '未导入')
                          .fontSize(12)
                          .fontColor(this.themeColors.textSecondary)
                      }
                      .alignItems(HorizontalAlign.Start)

                      Blank()
                      Text('管理 >')
                        .fontSize(13)
                        .fontColor(this.themeColors.primary)
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
                          .fontColor(this.themeColors.textPrimary)
                        Text('在所有应用顶部实时显示歌词')
                          .fontSize(12)
                          .fontColor(this.themeColors.textSecondary)
                      }
                      .alignItems(HorizontalAlign.Start)

                      Blank()
                      Toggle({ type: ToggleType.Switch, isOn: this.isFloatLyricOn })
                        .selectedColor(this.themeColors.primary)
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
                      Column({ space: 4 }) {
                        Text('多端数据同步 (Sync Server)')
                          .fontSize(15)
                          .fontWeight(FontWeight.Medium)
                          .fontColor(this.themeColors.textPrimary)
                        Text(`状态: ${this.syncReportText}`)
                          .fontSize(12)
                          .fontColor(this.syncState === SyncConnectionState.CONNECTED ? this.themeColors.primary : this.themeColors.textSecondary)
                      }
                      .alignItems(HorizontalAlign.Start)

                      Blank()
                      Text('配置 >')
                        .fontSize(13)
                        .fontColor(this.themeColors.primary)
                    }
                    .width('100%')
                    .padding({ left: 16, right: 16, top: 16, bottom: 16 })
                    .onClick(() => {
                      this.isShowSyncModal = true;
                    })
                  }

                  ListItem() {
                    Row() {
                      Text('关于项目')
                        .fontSize(15)
                        .fontColor(this.themeColors.textPrimary)
                      Blank()
                      Text('v1.0.0 (HarmonyOS NEXT 26)')
                        .fontSize(13)
                        .fontColor(this.themeColors.textSecondary)
                    }
                    .width('100%')
                    .padding({ left: 16, right: 16, top: 16, bottom: 16 })
                  }
                }
                .width('100%')
                .divider({ strokeWidth: 0.5, color: this.themeColors.divider, startMargin: 16 })
              }
              .width('100%')
              .height('100%')
              .backgroundColor(this.themeColors.background)
            }
            .tabBar(this.curBreakpoint === BreakpointConstants.BREAKPOINT_SM ? '设置' : '')
          }
          .layoutWeight(1)
          .margin({ bottom: this.currentMusic ? 60 : 0 })
          .onChange((index: number) => {
            this.activeTabIndex = index;
          })
        }
        .layoutWeight(1)
        .height('100%')

        // 宽屏/大屏 (lg 断点) 下的右侧常驻沉浸式双栏播放器
        if (this.curBreakpoint === BreakpointConstants.BREAKPOINT_LG) {
          Column({ space: 14 }) {
            Text('正在播放')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.themeColors.textPrimary)
              .margin({ top: 16 })

            // 黑胶旋转唱片
            Image(this.currentMusic?.pic || 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=500&auto=format&fit=crop&q=60')
              .width(180)
              .height(180)
              .borderRadius(90)
              .border({ width: 6, color: '#1A1A1A' })
              .shadow({ radius: 16, color: '#26000000', offsetY: 8 })

            Column({ space: 2 }) {
              Text(this.currentMusic?.name || '静候天籁')
                .fontSize(15)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.themeColors.textPrimary)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })

              Text(this.currentMusic?.singer || '挑选一首歌曲开始聆听')
                .fontSize(12)
                .fontColor(this.themeColors.textSecondary)
            }

            // 常驻滚动歌词
            LyricView({
              lrcText: this.currentMusic?.lrc || '',
              currentTimeMs: this.currentTime,
              onSeek: (timeMs: number) => {
                this.playerService.seek(timeMs);
              }
            })
            .layoutWeight(1)
            .width('100%')
          }
          .width(320)
          .height('100%')
          .backgroundColor(this.themeColors.cardBackground)
          .border({ width: { left: 1 }, color: this.themeColors.divider })
          .padding({ left: 16, right: 16, bottom: 60 })
        }
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
              .fontColor(this.themeColors.textPrimary)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })

            Text(this.currentMusic.singer)
              .fontSize(12)
              .fontColor(this.themeColors.textSecondary)
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
            .backgroundColor(this.themeColors.primary)
            .fontColor('#FFFFFF')
            .onClick(() => {
              this.playerService.togglePlay();
            })
        }
        .width('100%')
        .height(60)
        .padding({ left: 16, right: 16 })
        .backgroundColor(this.themeColors.cardBackground)
        .border({ width: { top: 1 }, color: this.themeColors.divider })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.themeColors.background)
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
    // 多端同步配置半模态
    .bindSheet($$this.isShowSyncModal, this.SyncManageSheet(), {
      height: 420,
      showClose: true,
      dragBar: true
    })
    // 主题色彩设置半模态
    .bindSheet($$this.isShowThemeModal, this.ThemeManageSheet(), {
      height: 360,
      showClose: true,
      dragBar: true
    })
    // 音效与均衡器设置半模态
    .bindSheet($$this.isShowEqualizerModal, this.EqualizerSheet(), {
      height: 440,
      showClose: true,
      dragBar: true
    })
    // 添加到歌单半模态
    .bindSheet($$this.isShowAddToPlaylistModal, this.AddToPlaylistSheet(), {
      height: 400,
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
  EqualizerSheet() {
    EqualizerDialog({
      onClose: () => {
        this.isShowEqualizerModal = false;
      }
    })
  }

  @Builder
  AddToPlaylistSheet() {
    AddToPlaylistDialog({
      musicItem: this.targetMusicForPlaylist,
      onFinished: () => {
        this.isShowAddToPlaylistModal = false;
      }
    })
  }

  @Builder
  SourceManageSheet() {
    Column({ space: 12 }) {
      Text('自定义音源管理 (User API)')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.themeColors.textPrimary)
        .margin({ top: 8, bottom: 8 })

      List() {
        ForEach(this.sourceList, (src: UserSourceScriptInfo) => {
          ListItem() {
            Row() {
              Column({ space: 3 }) {
                Text(src.name)
                  .fontSize(14)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(this.themeColors.textPrimary)
                Text(`${src.description} · v${src.version}`)
                  .fontSize(11)
                  .fontColor(this.themeColors.textSecondary)
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)

              if (this.activeSource?.id === src.id) {
                Text('使用中')
                  .fontSize(12)
                  .fontColor(this.themeColors.primary)
                  .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                  .backgroundColor(this.themeColors.primaryLight)
                  .borderRadius(8)
              } else {
                Button('启用')
                  .fontSize(12)
                  .height(28)
                  .backgroundColor(this.themeColors.cardBackground)
                  .fontColor(this.themeColors.textPrimary)
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
          .backgroundColor(this.themeColors.primary)
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
    .backgroundColor(this.themeColors.background)
  }

  @Builder
  SyncManageSheet() {
    Column({ space: 14 }) {
      Text('多端数据同步配置 (Sync Server)')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.themeColors.textPrimary)
        .margin({ top: 12, bottom: 4 })

      // 服务器地址
      Column({ space: 4 }) {
        Text('服务器地址与端口')
          .fontSize(12)
          .fontColor(this.themeColors.textSecondary)
          .alignSelf(ItemAlign.Start)

        Row({ space: 8 }) {
          TextInput({ placeholder: 'http://192.168.1.100', text: this.syncHost })
            .layoutWeight(3)
            .height(40)
            .onChange((v: string) => {
              this.syncHost = v;
            })

          TextInput({ placeholder: '9527', text: this.syncPort.toString() })
            .layoutWeight(1)
            .height(40)
            .type(InputType.Number)
            .onChange((v: string) => {
              this.syncPort = parseInt(v) || 9527;
            })
        }
      }
      .width('100%')

      // 连接秘钥
      Column({ space: 4 }) {
        Text('连接密钥 (Auth Key)')
          .fontSize(12)
          .fontColor(this.themeColors.textSecondary)
          .alignSelf(ItemAlign.Start)

        TextInput({ placeholder: '请输入同步认证密钥', text: this.syncKey })
          .width('100%')
          .height(40)
          .type(InputType.Password)
          .onChange((v: string) => {
            this.syncKey = v;
          })
      }
      .width('100%')

      // 同步操作按钮
      Row({ space: 12 }) {
        Button('测试连接')
          .layoutWeight(1)
          .height(40)
          .backgroundColor(this.themeColors.cardBackground)
          .fontColor(this.themeColors.textPrimary)
          .onClick(async () => {
            await this.syncService.connectServer(this.syncHost, this.syncPort, this.syncKey);
          })

        Button('立即双向同步')
          .layoutWeight(1)
          .height(40)
          .backgroundColor(this.themeColors.primary)
          .fontColor(Color.White)
          .onClick(async () => {
            await this.syncService.syncData();
            await this.loadCollections();
          })
      }
      .width('100%')
      .margin({ top: 8 })

      Text(`当前状态：${this.syncReportText}`)
        .fontSize(12)
        .fontColor(this.themeColors.textSecondary)
        .margin({ bottom: 12 })
    }
    .width('100%')
    .height('100%')
    .padding({ left: 20, right: 20 })
    .backgroundColor(this.themeColors.background)
  }

  @Builder
  ThemeManageSheet() {
    Column({ space: 16 }) {
      Text('个性化主题与配色')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.themeColors.textPrimary)
        .margin({ top: 12 })

      // 明暗模式切换
      Row({ space: 12 }) {
        Button('浅色模式')
          .layoutWeight(1)
          .height(36)
          .backgroundColor(this.currentThemeMode === ThemeMode.LIGHT ? this.themeColors.primaryLight : this.themeColors.cardBackground)
          .fontColor(this.currentThemeMode === ThemeMode.LIGHT ? this.themeColors.primary : this.themeColors.textPrimary)
          .onClick(() => {
            this.currentThemeMode = ThemeMode.LIGHT;
            this.themeService.setMode(ThemeMode.LIGHT);
          })

        Button('深色模式')
          .layoutWeight(1)
          .height(36)
          .backgroundColor(this.currentThemeMode === ThemeMode.DARK ? this.themeColors.primaryLight : this.themeColors.cardBackground)
          .fontColor(this.currentThemeMode === ThemeMode.DARK ? this.themeColors.primary : this.themeColors.textPrimary)
          .onClick(() => {
            this.currentThemeMode = ThemeMode.DARK;
            this.themeService.setMode(ThemeMode.DARK);
          })
      }
      .width('100%')

      // 主题色彩条
      Column({ space: 8 }) {
        Text('选择主色调')
          .fontSize(13)
          .fontColor(this.themeColors.textSecondary)
          .alignSelf(ItemAlign.Start)

        Row({ space: 12 }) {
          ForEach(ThemeService.PRESETS, (p: ThemePreset) => {
            Column({ space: 4 }) {
              Circle({ width: 36, height: 36 })
                .fill(p.color)
                .stroke(this.themeColors.primary === p.color ? '#1F2329' : 'transparent')
                .strokeWidth(2)
                .onClick(() => {
                  this.themeService.setPrimaryColor(p.color);
                })

              Text(p.name)
                .fontSize(11)
                .fontColor(this.themeColors.textSecondary)
            }
          })
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .padding({ top: 6, bottom: 6 })
      }
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .padding({ left: 20, right: 20 })
    .backgroundColor(this.themeColors.background)
  }
}

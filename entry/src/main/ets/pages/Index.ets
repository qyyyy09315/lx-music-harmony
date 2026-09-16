import common from '@ohos.app.ability.common';
import { ToastUtil } from '../common/ToastUtil';
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
import { MusicItem, PlayMode, PlayState, UserSourceScriptInfo, SourceTabItem } from '../model/MusicModel';
import { MusicListItem } from '../view/MusicListItem';
import { PlayDetailModal } from '../view/PlayDetailModal';
import { EqualizerDialog } from '../view/EqualizerDialog';
import { AddToPlaylistDialog } from '../view/AddToPlaylistDialog';
import { CustomPlaylistDetailDialog } from '../view/CustomPlaylistDetailDialog';
import { LyricView } from '../view/LyricView';

export type ModalType = 'none' | 'player' | 'playlist_detail' | 'source' | 'sync' | 'theme' | 'equalizer' | 'add_to_playlist' | 'about';

@Entry
@Component
struct Index {
  @State activeTabIndex: number = 0; // 0: 搜索, 1: 我的, 2: 设置
  @State currentMusic: MusicItem | null = null;
  @State playState: PlayState = PlayState.IDLE;
  @State currentTime: number = 0;
  @State totalTime: number = 0;
  @State playMode: PlayMode = PlayMode.LIST_LOOP;

  // 统一绝对可靠的弹窗浮层管理
  @State activeModal: ModalType = 'none';

  // 响应式断点系统 (sm / md / lg)
  @State curBreakpoint: BreakpointType = BreakpointConstants.BREAKPOINT_SM;
  private breakpointSystem: BreakpointSystem = new BreakpointSystem();

  // 主题与色彩
  @State themeColors: ThemeColorSet = ThemeService.getInstance().getColors();
  @State currentThemeMode: ThemeMode = ThemeMode.LIGHT;

  // 搜索相关状态 (默认空白搜索首页)
  @State searchKeyword: string = '';
  @State searchSourceTab: string = 'all';
  @State searchResultList: MusicItem[] = [];
  @State searchHistoryList: string[] = ['周杰伦', '晴天', '起风了'];
  @State isSearching: boolean = false;

  // 我的与自建歌单状态
  @State myActiveSubTab: number = 0; // 0: 收藏, 1: 歌单, 2: 本地, 3: 下载
  @State myCollectionList: MusicItem[] = [];
  @State localMusicList: MusicItem[] = [];
  @State downloadTaskList: DownloadTask[] = [];
  @State customPlaylists: CustomPlaylist[] = [];
  @State selectedPlaylistId: string = '';
  @State isScanningLocal: boolean = false;
  @State newPlaylistNameInput: string = '';
  @State isShowCreatePlaylistInput: boolean = false;

  @State targetMusicForPlaylist: MusicItem | null = null;

  // 音源与同步
  @State sourceList: UserSourceScriptInfo[] = [];
  @State activeSource: UserSourceScriptInfo | undefined = undefined;
  @State importScriptInput: string = '';
  @State isShowPasteScript: boolean = false;
  @State rawPasteScriptInput: string = '';
  @State isFloatLyricOn: boolean = false;
  @State floatingLyricText: string = '洛雪音乐 - 听你所想';
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
    this.storageService.init(getContext(this) as common.UIAbilityContext);
    this.floatLyricService.init(getContext(this) as common.UIAbilityContext);

    // 断点注册
    this.breakpointSystem.register((bp: BreakpointType) => {
      this.curBreakpoint = bp;
    });

    // 播放事件监听
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
    if (!this.searchKeyword.trim()) {
      this.searchResultList = [];
      ToastUtil.show('请输入歌曲名或歌手名');
      return;
    }

    const kw = this.searchKeyword.trim();
    if (!this.searchHistoryList.includes(kw)) {
      this.searchHistoryList.unshift(kw);
      if (this.searchHistoryList.length > 10) {
        this.searchHistoryList.pop();
      }
    }

    this.isSearching = true;
    try {
      const result = await this.sourceService.searchMusic(kw, this.searchSourceTab);
      this.searchResultList = result.list;
      if (this.searchResultList.length === 0) {
        ToastUtil.show('未检索到相关曲目，请尝试其他关键词或音源');
      }
    } catch (e) {
      console.error('Search error: ' + JSON.stringify(e));
      ToastUtil.showError('搜索请求失败，请检查网络设置');
    } finally {
      this.isSearching = false;
    }
  }

  private async handleScanLocal() {
    this.isScanningLocal = true;
    ToastUtil.show('正在扫描设备存储音频...', 1200);
    try {
      this.localMusicList = await this.localMusicService.scanLocalAudio();
      ToastUtil.show(`本地曲库扫描完成，共 ${this.localMusicList.length} 首`);
    } finally {
      this.isScanningLocal = false;
    }
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Row() {
        // 大屏 / 平板 / 2in1 模式下的左侧 Navigation Rail 侧边栏
        if (this.curBreakpoint !== BreakpointConstants.BREAKPOINT_SM) {
          Column({ space: 14 }) {
            Row({ space: 8 }) {
              Image($r('app.media.ic_songlist'))
                .width(22)
                .height(22)
                .fillColor(this.themeColors.primary)
              Text('洛雪音乐').fontSize(16).fontWeight(FontWeight.Bold).fontColor(this.themeColors.textPrimary)
            }
            .padding({ top: 20, bottom: 12 })

            Column({ space: 6 }) {
              Button({ type: ButtonType.Normal }) {
                Row({ space: 8 }) {
                  Image($r('app.media.ic_search')).width(16).height(16).fillColor(this.activeTabIndex === 0 ? this.themeColors.primary : this.themeColors.textSecondary)
                  Text('搜索').fontSize(14).fontColor(this.activeTabIndex === 0 ? this.themeColors.primary : this.themeColors.textSecondary)
                }
              }
              .width(110).height(40).borderRadius(8)
              .backgroundColor(this.activeTabIndex === 0 ? this.themeColors.primaryLight : 'transparent')
              .onClick(() => { this.activeTabIndex = 0; })

              Button({ type: ButtonType.Normal }) {
                Row({ space: 8 }) {
                  Image($r('app.media.ic_mine')).width(16).height(16).fillColor(this.activeTabIndex === 1 ? this.themeColors.primary : this.themeColors.textSecondary)
                  Text('我的').fontSize(14).fontColor(this.activeTabIndex === 1 ? this.themeColors.primary : this.themeColors.textSecondary)
                }
              }
              .width(110).height(40).borderRadius(8)
              .backgroundColor(this.activeTabIndex === 1 ? this.themeColors.primaryLight : 'transparent')
              .onClick(() => { this.activeTabIndex = 1; })

              Button({ type: ButtonType.Normal }) {
                Row({ space: 8 }) {
                  Image($r('app.media.ic_setting')).width(16).height(16).fillColor(this.activeTabIndex === 2 ? this.themeColors.primary : this.themeColors.textSecondary)
                  Text('设置').fontSize(14).fontColor(this.activeTabIndex === 2 ? this.themeColors.primary : this.themeColors.textSecondary)
                }
              }
              .width(110).height(40).borderRadius(8)
              .backgroundColor(this.activeTabIndex === 2 ? this.themeColors.primaryLight : 'transparent')
              .onClick(() => { this.activeTabIndex = 2; })
            }

            Blank()

            Row({ space: 8 }) {
              Button({ type: ButtonType.Circle }) {
                Image($r('app.media.ic_equalizer')).width(16).height(16).fillColor(this.themeColors.textPrimary)
              }
              .width(36).height(36).backgroundColor(this.themeColors.cardBackground)
              .onClick(() => { this.activeModal = 'equalizer'; })

              Button({ type: ButtonType.Circle }) {
                Image($r('app.media.ic_theme')).width(16).height(16).fillColor(this.themeColors.textPrimary)
              }
              .width(36).height(36).backgroundColor(this.themeColors.cardBackground)
              .onClick(() => { this.activeModal = 'theme'; })
            }
            .padding({ bottom: 20 })
          }
          .width(130)
          .height('100%')
          .backgroundColor(this.themeColors.cardBackground)
          .border({ width: { right: 1 }, color: this.themeColors.divider })
        }

        // 主内容区
        Column() {
          // 手机端顶部标题栏
          if (this.curBreakpoint === BreakpointConstants.BREAKPOINT_SM) {
            Row() {
              Text('洛雪音乐')
                .fontSize(22)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.themeColors.textPrimary)

              Blank()

              Row({ space: 8 }) {
                Button({ type: ButtonType.Circle }) {
                  Image($r('app.media.ic_equalizer'))
                    .width(16)
                    .height(16)
                    .fillColor(this.themeColors.textPrimary)
                }
                .width(32).height(32).backgroundColor(this.themeColors.cardBackground)
                .onClick(() => { this.activeModal = 'equalizer'; })

                Button({ type: ButtonType.Circle }) {
                  Image($r('app.media.ic_theme'))
                    .width(16)
                    .height(16)
                    .fillColor(this.themeColors.textPrimary)
                }
                .width(32).height(32).backgroundColor(this.themeColors.cardBackground)
                .onClick(() => { this.activeModal = 'theme'; })

                Text(this.activeSource ? this.activeSource.name : '内置源')
                  .fontSize(11)
                  .fontColor(this.themeColors.primary)
                  .backgroundColor(this.themeColors.primaryLight)
                  .padding({ left: 8, right: 8, top: 5, bottom: 5 })
                  .borderRadius(12)
                  .onClick(() => { this.activeModal = 'source'; })
              }
            }
            .width('100%')
            .height(54)
            .padding({ left: 16, right: 16 })
            .alignItems(VerticalAlign.Center)
            .backgroundColor(this.themeColors.background)
          }

          // 全局悬浮歌词条
          if (this.isFloatLyricOn) {
            Row({ space: 8 }) {
              Image($r('app.media.ic_songlist'))
                .width(14)
                .height(14)
                .fillColor(this.themeColors.primary)

              Text(this.floatingLyricText)
                .fontSize(13)
                .fontWeight(FontWeight.Medium)
                .fontColor(this.themeColors.primary)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .width('92%')
            .height(34)
            .margin({ top: 2, bottom: 2 })
            .padding({ left: 14, right: 14 })
            .backgroundColor(this.themeColors.primaryLight)
            .borderRadius(17)
            .justifyContent(FlexAlign.Center)
          }

          // 核心 3 大主功能 Tab 视图
          Tabs({
            index: this.activeTabIndex,
            barPosition: this.curBreakpoint === BreakpointConstants.BREAKPOINT_SM ? BarPosition.End : BarPosition.Start
          }) {
            // Tab 1: 搜索
            TabContent() {
              Column() {
                Row({ space: 8 }) {
                  Search({ value: this.searchKeyword, placeholder: '搜索音乐、歌手、专辑' })
                    .layoutWeight(1)
                    .height(40)
                    .onChange((val: string) => {
                      this.searchKeyword = val;
                      if (!val.trim()) {
                        this.searchResultList = [];
                      }
                    })
                    .onSubmit(() => { this.performSearch(); })

                  Button('搜索')
                    .fontSize(14)
                    .backgroundColor(this.themeColors.primary)
                    .fontColor(Color.White)
                    .height(38)
                    .onClick(() => { this.performSearch(); })
                }
                .width('94%')
                .margin({ top: 6, bottom: 6 })

                // 多源选择 Tab 胶囊栏
                Scroll() {
                  Row({ space: 8 }) {
                    ForEach(SourceManagerService.SOURCE_TABS, (st: SourceTabItem) => {
                      Button(st.name)
                        .height(30)
                        .fontSize(12)
                        .backgroundColor(this.searchSourceTab === st.id ? this.themeColors.primaryLight : this.themeColors.cardBackground)
                        .fontColor(this.searchSourceTab === st.id ? this.themeColors.primary : this.themeColors.textSecondary)
                        .onClick(() => {
                          this.searchSourceTab = st.id;
                          if (this.searchKeyword.trim()) {
                            this.performSearch();
                          }
                        })
                    }, (st: SourceTabItem) => st.id)
                  }
                  .padding({ left: 16, right: 16, top: 2, bottom: 6 })
                }
                .scrollable(ScrollDirection.Horizontal)
                .scrollBar(BarState.Off)
                .width('100%')

                if (this.isSearching) {
                  Row({ space: 8 }) {
                    LoadingProgress().width(20).height(20).color(this.themeColors.primary)
                    Text('正在跨多平台检索高保真音频...').fontSize(12).fontColor(this.themeColors.textSecondary)
                  }
                  .height(32)
                }

                if (this.searchResultList.length > 0) {
                  List() {
                    ForEach(this.searchResultList, (item: MusicItem) => {
                      ListItem() {
                        MusicListItem({
                          item: item,
                          isPlaying: this.currentMusic?.id === item.id && this.playState === PlayState.PLAYING,
                          onClickItem: async () => {
                            await this.playerService.playMusic(item);
                          },
                          onMoreClick: (it: MusicItem) => {
                            this.targetMusicForPlaylist = it;
                            this.activeModal = 'add_to_playlist';
                          }
                        })
                      }
                    }, (item: MusicItem) => item.id)
                  }
                  .layoutWeight(1)
                  .width('100%')
                  .divider({ strokeWidth: 0.5, color: this.themeColors.divider, startMargin: 16 })
                } else {
                  // BlankView
                  Scroll() {
                    Column({ space: 16 }) {
                      Column({ space: 8 }) {
                        Text('热门搜索')
                          .fontSize(13)
                          .fontWeight(FontWeight.Medium)
                          .fontColor(this.themeColors.textSecondary)
                          .alignSelf(ItemAlign.Start)

                        Flex({ wrap: FlexWrap.Wrap }) {
                          ForEach(SourceManagerService.HOT_SEARCH_WORDS, (word: string) => {
                            Text(word)
                              .fontSize(12)
                              .fontColor(this.themeColors.textPrimary)
                              .backgroundColor(this.themeColors.cardBackground)
                              .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                              .borderRadius(14)
                              .margin({ right: 8, bottom: 8 })
                              .onClick(() => {
                                this.searchKeyword = word;
                                this.performSearch();
                              })
                          }, (w: string) => w)
                        }
                      }
                      .width('100%')

                      if (this.searchHistoryList.length > 0) {
                        Column({ space: 8 }) {
                          Row() {
                            Text('历史搜索')
                              .fontSize(13)
                              .fontWeight(FontWeight.Medium)
                              .fontColor(this.themeColors.textSecondary)

                            Blank()

                            Button({ type: ButtonType.Normal }) {
                              Row({ space: 4 }) {
                                Image($r('app.media.ic_trash'))
                                  .width(13)
                                  .height(13)
                                  .fillColor(this.themeColors.textSecondary)
                                Text('清空').fontSize(11).fontColor(this.themeColors.textSecondary)
                              }
                            }
                            .backgroundColor(Color.Transparent)
                            .onClick(() => {
                              this.searchHistoryList = [];
                            })
                          }
                          .width('100%')

                          Flex({ wrap: FlexWrap.Wrap }) {
                            ForEach(this.searchHistoryList, (hWord: string) => {
                              Text(hWord)
                                .fontSize(12)
                                .fontColor(this.themeColors.textPrimary)
                                .backgroundColor(this.themeColors.cardBackground)
                                .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                                .borderRadius(14)
                                .margin({ right: 8, bottom: 8 })
                                .onClick(() => {
                                  this.searchKeyword = hWord;
                                  this.performSearch();
                                })
                            }, (hw: string) => hw)
                          }
                        }
                        .width('100%')
                      }

                      Column({ space: 6 }) {
                        Image($r('app.media.ic_search'))
                          .width(44)
                          .height(44)
                          .fillColor(this.themeColors.primaryLight)
                          .margin({ top: 40 })

                        Text('海量音乐 即搜即听')
                          .fontSize(14)
                          .fontColor(this.themeColors.textSecondary)
                      }
                      .width('100%')
                      .alignItems(HorizontalAlign.Center)
                    }
                    .width('100%')
                    .padding({ left: 20, right: 20, top: 12, bottom: 20 })
                  }
                  .layoutWeight(1)
                  .width('100%')
                }
              }
              .width('100%')
              .height('100%')
              .backgroundColor(this.themeColors.background)
            }
            .tabBar(this.curBreakpoint === BreakpointConstants.BREAKPOINT_SM ? '搜索' : '')

            // Tab 2: 我的
            TabContent() {
              Column() {
                Row({ space: 6 }) {
                  Button(`收藏 (${this.myCollectionList.length})`)
                    .height(32).fontSize(12)
                    .backgroundColor(this.myActiveSubTab === 0 ? this.themeColors.primaryLight : this.themeColors.cardBackground)
                    .fontColor(this.myActiveSubTab === 0 ? this.themeColors.primary : this.themeColors.textSecondary)
                    .onClick(() => { this.myActiveSubTab = 0; })

                  Button(`自建歌单 (${this.customPlaylists.length})`)
                    .height(32).fontSize(12)
                    .backgroundColor(this.myActiveSubTab === 1 ? this.themeColors.primaryLight : this.themeColors.cardBackground)
                    .fontColor(this.myActiveSubTab === 1 ? this.themeColors.primary : this.themeColors.textSecondary)
                    .onClick(() => { this.myActiveSubTab = 1; })

                  Button(`本地 (${this.localMusicList.length})`)
                    .height(32).fontSize(12)
                    .backgroundColor(this.myActiveSubTab === 2 ? this.themeColors.primaryLight : this.themeColors.cardBackground)
                    .fontColor(this.myActiveSubTab === 2 ? this.themeColors.primary : this.themeColors.textSecondary)
                    .onClick(() => { this.myActiveSubTab = 2; })

                  Button(`下载 (${this.downloadTaskList.length})`)
                    .height(32).fontSize(12)
                    .backgroundColor(this.myActiveSubTab === 3 ? this.themeColors.primaryLight : this.themeColors.cardBackground)
                    .fontColor(this.myActiveSubTab === 3 ? this.themeColors.primary : this.themeColors.textSecondary)
                    .onClick(() => { this.myActiveSubTab = 3; })
                }
                .width('100%')
                .padding({ left: 16, right: 16, top: 12, bottom: 8 })

                if (this.myActiveSubTab === 0) {
                  if (this.myCollectionList.length === 0) {
                    Column({ space: 8 }) {
                      Image($r('app.media.ic_mine'))
                        .width(40).height(40)
                        .fillColor(this.themeColors.textSecondary)
                        .margin({ top: 60 })
                      Text('暂无收藏歌曲，搜索歌曲点击 ··· 即可收藏').fontSize(13).fontColor(this.themeColors.textSecondary)
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
                              this.activeModal = 'add_to_playlist';
                            }
                          })
                        }
                      }, (item: MusicItem) => item.id)
                    }
                    .layoutWeight(1)
                    .width('100%')
                    .divider({ strokeWidth: 0.5, color: this.themeColors.divider, startMargin: 16 })
                  }
                } else if (this.myActiveSubTab === 1) {
                  // 自建歌单
                  Column() {
                    Row() {
                      Text(`全部歌单 (${this.customPlaylists.length})`).fontSize(13).fontColor(this.themeColors.textSecondary)
                      Blank()
                      Button(this.isShowCreatePlaylistInput ? '取消' : '+ 新建歌单')
                        .fontSize(12)
                        .height(28)
                        .backgroundColor(this.themeColors.primaryLight)
                        .fontColor(this.themeColors.primary)
                        .onClick(() => {
                          this.isShowCreatePlaylistInput = !this.isShowCreatePlaylistInput;
                        })
                    }
                    .width('100%')
                    .padding({ left: 16, right: 16, bottom: 6 })

                    if (this.isShowCreatePlaylistInput) {
                      Row({ space: 8 }) {
                        TextInput({ placeholder: '输入新歌单名称...', text: this.newPlaylistNameInput })
                          .layoutWeight(1)
                          .height(38)
                          .onChange((v: string) => { this.newPlaylistNameInput = v; })

                        Button('确定')
                          .fontSize(12)
                          .height(38)
                          .backgroundColor(this.themeColors.primary)
                          .fontColor(Color.White)
                          .onClick(() => {
                            if (this.newPlaylistNameInput.trim()) {
                              const created = this.plService.createPlaylist(this.newPlaylistNameInput.trim());
                              this.newPlaylistNameInput = '';
                              this.isShowCreatePlaylistInput = false;
                              ToastUtil.show(`歌单【${created.name}】创建成功！`);
                            } else {
                              ToastUtil.show('请输入歌单名称');
                            }
                          })
                      }
                      .width('92%')
                      .padding({ bottom: 8 })
                    }

                    List({ space: 8 }) {
                      ForEach(this.customPlaylists, (pl: CustomPlaylist) => {
                        ListItem() {
                          Row() {
                            Column({ space: 4 }) {
                              Text(pl.name).fontSize(15).fontWeight(FontWeight.Medium).fontColor(this.themeColors.textPrimary)
                              Text(`${pl.list.length} 首歌曲 · ${pl.desc || '自建私享歌单'}`)
                                .fontSize(12).fontColor(this.themeColors.textSecondary).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
                            }
                            .alignItems(HorizontalAlign.Start)
                            .layoutWeight(1)

                            Button({ type: ButtonType.Circle }) {
                              Image($r('app.media.ic_play'))
                                .width(13).height(13).fillColor(this.themeColors.primary)
                            }
                            .width(32).height(32)
                            .backgroundColor(this.themeColors.primaryLight)
                            .onClick(() => {
                              if (pl.list.length > 0) {
                                this.playerService.setPlayList(pl.list, 0);
                              }
                            })
                          }
                          .width('100%')
                          .padding({ left: 16, right: 16, top: 8, bottom: 8 })
                          .onClick(() => {
                            // 点击歌单，直接打开歌单详情弹窗！
                            this.selectedPlaylistId = pl.id;
                            this.activeModal = 'playlist_detail';
                          })
                        }
                      }, (pl: CustomPlaylist) => pl.id)
                    }
                    .layoutWeight(1)
                    .width('100%')
                    .divider({ strokeWidth: 0.5, color: this.themeColors.divider, startMargin: 16 })
                  }
                  .layoutWeight(1)
                  .width('100%')
                } else if (this.myActiveSubTab === 2) {
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
                              this.activeModal = 'add_to_playlist';
                            }
                          })
                        }
                      }, (item: MusicItem) => item.id)
                    }
                    .layoutWeight(1)
                    .width('100%')
                    .divider({ strokeWidth: 0.5, color: this.themeColors.divider, startMargin: 16 })
                  }
                  .layoutWeight(1)
                  .width('100%')
                } else {
                  List() {
                    ForEach(this.downloadTaskList, (task: DownloadTask) => {
                      ListItem() {
                        Row() {
                          Column({ space: 4 }) {
                            Text(task.musicItem.name).fontSize(14).fontWeight(FontWeight.Medium).fontColor(this.themeColors.textPrimary)
                            Text(`${task.musicItem.singer} · ${task.quality.toUpperCase()} · 进度: ${task.progress}%`)
                              .fontSize(11).fontColor(this.themeColors.textSecondary)
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
                    }, (task: DownloadTask) => task.id)
                  }
                  .layoutWeight(1)
                  .width('100%')
                  .divider({ strokeWidth: 0.5, color: this.themeColors.divider, startMargin: 16 })
                }
              }
              .width('100%')
              .height('100%')
              .backgroundColor(this.themeColors.background)
            }
            .tabBar(this.curBreakpoint === BreakpointConstants.BREAKPOINT_SM ? '我的' : '')

            // Tab 3: 设置 (每一项点击即刻打开弹窗)
            TabContent() {
              Column() {
                List() {
                  ListItem() {
                    Row() {
                      Column({ space: 4 }) {
                        Text('音效预设与均衡器').fontSize(15).fontWeight(FontWeight.Medium).fontColor(this.themeColors.textPrimary)
                        Text('5 频段 EQ 增益、低音增强与 3D 环绕声').fontSize(12).fontColor(this.themeColors.textSecondary)
                      }
                      .alignItems(HorizontalAlign.Start)
                      Blank()
                      Text('调节 >').fontSize(13).fontColor(this.themeColors.primary)
                    }
                    .width('100%')
                    .padding({ left: 16, right: 16, top: 16, bottom: 16 })
                    .onClick(() => {
                      this.activeModal = 'equalizer';
                    })
                  }

                  ListItem() {
                    Row() {
                      Column({ space: 4 }) {
                        Text('主题与配色方案').fontSize(15).fontWeight(FontWeight.Medium).fontColor(this.themeColors.textPrimary)
                        Text(`当前主色：${this.themeColors.primary}`).fontSize(12).fontColor(this.themeColors.textSecondary)
                      }
                      .alignItems(HorizontalAlign.Start)
                      Blank()
                      Text('调整 >').fontSize(13).fontColor(this.themeColors.primary)
                    }
                    .width('100%')
                    .padding({ left: 16, right: 16, top: 16, bottom: 16 })
                    .onClick(() => {
                      this.activeModal = 'theme';
                    })
                  }

                  ListItem() {
                    Row() {
                      Column({ space: 4 }) {
                        Text('音源脚本设置 (User API)').fontSize(15).fontWeight(FontWeight.Medium).fontColor(this.themeColors.textPrimary)
                        Text(this.activeSource ? `当前已激活: ${this.activeSource.name}` : '未导入').fontSize(12).fontColor(this.themeColors.textSecondary)
                      }
                      .alignItems(HorizontalAlign.Start)
                      Blank()
                      Text('管理 >').fontSize(13).fontColor(this.themeColors.primary)
                    }
                    .width('100%')
                    .padding({ left: 16, right: 16, top: 16, bottom: 16 })
                    .onClick(() => {
                      this.activeModal = 'source';
                    })
                  }

                  ListItem() {
                    Row() {
                      Column({ space: 4 }) {
                        Text('桌面/全局悬浮歌词').fontSize(15).fontWeight(FontWeight.Medium).fontColor(this.themeColors.textPrimary)
                        Text('在所有应用顶部实时显示歌词').fontSize(12).fontColor(this.themeColors.textSecondary)
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
                        Text('多端数据同步 (Sync Server)').fontSize(15).fontWeight(FontWeight.Medium).fontColor(this.themeColors.textPrimary)
                        Text(`状态: ${this.syncReportText}`)
                          .fontSize(12)
                          .fontColor(this.syncState === SyncConnectionState.CONNECTED ? this.themeColors.primary : this.themeColors.textSecondary)
                      }
                      .alignItems(HorizontalAlign.Start)
                      Blank()
                      Text('配置 >').fontSize(13).fontColor(this.themeColors.primary)
                    }
                    .width('100%')
                    .padding({ left: 16, right: 16, top: 16, bottom: 16 })
                    .onClick(() => {
                      this.activeModal = 'sync';
                    })
                  }

                  ListItem() {
                    Row() {
                      Column({ space: 4 }) {
                        Text('关于项目').fontSize(15).fontWeight(FontWeight.Medium).fontColor(this.themeColors.textPrimary)
                        Text('v1.0.0 (HarmonyOS NEXT 26 纯血鸿蒙)').fontSize(12).fontColor(this.themeColors.textSecondary)
                      }
                      .alignItems(HorizontalAlign.Start)
                      Blank()
                      Text('查看 >').fontSize(13).fontColor(this.themeColors.primary)
                    }
                    .width('100%')
                    .padding({ left: 16, right: 16, top: 16, bottom: 16 })
                    .onClick(() => {
                      this.activeModal = 'about';
                    })
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

        // 宽屏/大屏 (lg 断点) 下的右侧常驻双栏沉浸式播放器
        if (this.curBreakpoint === BreakpointConstants.BREAKPOINT_LG) {
          Column({ space: 14 }) {
            Text('正在播放')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.themeColors.textPrimary)
              .margin({ top: 16 })

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
          Button({ type: ButtonType.Circle }) {
            Image($r('app.media.ic_songlist'))
              .width(18)
              .height(18)
              .fillColor(this.themeColors.primary)
          }
          .width(38)
          .height(38)
          .backgroundColor(this.themeColors.primaryLight)
          .margin({ right: 12 })
          .onClick(() => {
            this.activeModal = 'player';
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
            this.activeModal = 'player';
          })

          Button({ type: ButtonType.Circle }) {
            Image(this.playState === PlayState.PLAYING ? $r('app.media.ic_pause') : $r('app.media.ic_play'))
              .width(18)
              .height(18)
              .fillColor(Color.White)
          }
          .width(36)
          .height(36)
          .backgroundColor(this.themeColors.primary)
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

      // ==========================================
      // 全局绝对可信赖的半模态浮层系统 (彻底解决模拟器弹窗失效)
      // ==========================================
      if (this.activeModal !== 'none') {
        Column() {
          // 顶部半透明遮罩 (点击可直接关闭)
          Blank()
            .width('100%')
            .layoutWeight(1)
            .onClick(() => {
              this.activeModal = 'none';
            })

          // 浮层内容面板
          Column() {
            if (this.activeModal === 'player') {
              PlayDetailModal({
                currentMusic: this.currentMusic,
                playState: this.playState,
                currentTime: this.currentTime,
                totalTime: this.totalTime,
                playMode: this.playMode,
                onClose: () => {
                  this.activeModal = 'none';
                }
              })
            } else if (this.activeModal === 'playlist_detail') {
              CustomPlaylistDetailDialog({
                playlistId: this.selectedPlaylistId,
                onClose: () => {
                  this.activeModal = 'none';
                },
                onMoreClick: (it: MusicItem) => {
                  this.targetMusicForPlaylist = it;
                  this.activeModal = 'add_to_playlist';
                }
              })
            } else if (this.activeModal === 'source') {
              this.SourceManageContent()
            } else if (this.activeModal === 'sync') {
              this.SyncManageContent()
            } else if (this.activeModal === 'theme') {
              this.ThemeManageContent()
            } else if (this.activeModal === 'equalizer') {
              EqualizerDialog({
                onClose: () => {
                  this.activeModal = 'none';
                }
              })
            } else if (this.activeModal === 'add_to_playlist') {
              AddToPlaylistDialog({
                musicItem: this.targetMusicForPlaylist,
                onFinished: () => {
                  this.activeModal = 'none';
                }
              })
            } else if (this.activeModal === 'about') {
              this.AboutContent()
            }
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .borderRadius({ topLeft: 16, topRight: 16 })
          .shadow({ radius: 30, color: '#4D000000', offsetY: -4 })
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#66000000') // 暗色遮罩
        .animation({ duration: 250 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.themeColors.background)
  }

  @Builder
  SourceManageContent() {
    Column({ space: 12 }) {
      Row() {
        Text('自定义音源管理 (User API)')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1F2329')

        Blank()

        Button({ type: ButtonType.Circle }) {
          Image($r('app.media.ic_close'))
            .width(16).height(16).fillColor('#8F959E')
        }
        .width(32).height(32).backgroundColor(Color.Transparent)
        .onClick(() => { this.activeModal = 'none'; })
      }
      .width('100%')
      .padding({ left: 20, right: 16, top: 16, bottom: 4 })

      // 外链输入与下载导入区
      Column({ space: 8 }) {
        Text('通过网络外链导入音源脚本 (.js)')
          .fontSize(12)
          .fontColor('#8F959E')
          .alignSelf(ItemAlign.Start)

        Row({ space: 8 }) {
          TextInput({ placeholder: '输入音源脚本外链 URL (http/https)...', text: this.importScriptInput })
            .layoutWeight(1)
            .height(40)
            .onChange((val: string) => {
              this.importScriptInput = val;
            })

          Button('下载导入')
            .fontSize(13)
            .height(40)
            .backgroundColor('#07C160')
            .fontColor(Color.White)
            .onClick(async () => {
              if (this.importScriptInput.trim()) {
                ToastUtil.show('正在下载并解析音源脚本...', 1500);
                try {
                  const info = await this.sourceService.importScriptFromUrl(this.importScriptInput.trim());
                  this.importScriptInput = '';
                  this.loadSources();
                  ToastUtil.show(`音源【${info.name}】导入并激活成功！`);
                } catch (e) {
                  console.error('Download source error: ' + JSON.stringify(e));
                  ToastUtil.showError(e.message || '音源脚本下载失败，请检查外链或网络');
                }
              } else {
                ToastUtil.show('请输入音源脚本外链 URL');
              }
            })
        }
        .width('100%')

        // 备用粘贴导入入口
        Row() {
          Text(this.isShowPasteScript ? '收起直接粘贴模式' : '外链打不开？点击直接粘贴代码导入')
            .fontSize(11)
            .fontColor('#07C160')
            .onClick(() => {
              this.isShowPasteScript = !this.isShowPasteScript;
            })
        }
        .width('100%')
        .padding({ top: 2 })

        if (this.isShowPasteScript) {
          Row({ space: 8 }) {
            TextInput({ placeholder: '粘贴音源脚本 JS 完整代码...', text: this.rawPasteScriptInput })
              .layoutWeight(1)
              .height(38)
              .onChange((v: string) => {
                this.rawPasteScriptInput = v;
              })

            Button('导入')
              .fontSize(12)
              .height(38)
              .backgroundColor('#07C160')
              .fontColor(Color.White)
              .onClick(() => {
                if (this.rawPasteScriptInput.trim()) {
                  try {
                    const info = this.sourceService.importScript(this.rawPasteScriptInput.trim());
                    this.rawPasteScriptInput = '';
                    this.isShowPasteScript = false;
                    this.loadSources();
                    ToastUtil.show(`音源【${info.name}】代码导入成功！`);
                  } catch (err) {
                    ToastUtil.showError('脚本解析失败，请确保代码格式正确');
                  }
                } else {
                  ToastUtil.show('请粘贴脚本代码');
                }
              })
          }
          .width('100%')
          .padding({ top: 4 })
        }
      }
      .width('100%')
      .padding({ left: 20, right: 20, bottom: 4 })

      Divider().color('#F2F3F5').strokeWidth(0.5)

      // 已安装音源列表
      List({ space: 8 }) {
        ForEach(this.sourceList, (src: UserSourceScriptInfo) => {
          ListItem() {
            Row() {
              Column({ space: 4 }) {
                Row({ space: 6 }) {
                  Text(src.name)
                    .fontSize(14)
                    .fontWeight(FontWeight.Medium)
                    .fontColor('#1F2329')
                  Text(`v${src.version}`)
                    .fontSize(11)
                    .fontColor('#07C160')
                    .backgroundColor('#E8F8F0')
                    .padding({ left: 4, right: 4, top: 1, bottom: 1 })
                    .borderRadius(4)
                }

                Text(src.description)
                  .fontSize(11)
                  .fontColor('#8F959E')
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })

                if (src.downloadUrl) {
                  Text(src.downloadUrl)
                    .fontSize(10)
                    .fontColor('#8F959E')
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                }
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)

              Row({ space: 6 }) {
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
                      ToastUtil.show(`已切换为音源【${src.name}】`);
                    })
                }

                if (src.id !== 'builtin_open_source') {
                  Button({ type: ButtonType.Circle }) {
                    Image($r('app.media.ic_trash'))
                      .width(13).height(13).fillColor('#FF4D4F')
                  }
                  .width(28).height(28).backgroundColor('#FFF1F0')
                  .onClick(() => {
                    this.sourceService.deleteSource(src.id);
                    this.loadSources();
                    ToastUtil.show(`已删除音源【${src.name}】`);
                  })
                }
              }
            }
            .width('100%')
            .padding({ top: 6, bottom: 6 })
          }
        }, (src: UserSourceScriptInfo) => src.id)
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: 20, right: 20 })
    }
    .width('100%')
    .height(440)
  }

  @Builder
  SyncManageContent() {
    Column({ space: 14 }) {
      Row() {
        Text('多端数据同步配置 (Sync Server)')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1F2329')

        Blank()

        Button({ type: ButtonType.Circle }) {
          Image($r('app.media.ic_close'))
            .width(16).height(16).fillColor('#8F959E')
        }
        .width(32).height(32).backgroundColor(Color.Transparent)
        .onClick(() => { this.activeModal = 'none'; })
      }
      .width('100%')
      .padding({ left: 20, right: 16, top: 16, bottom: 4 })

      Column({ space: 4 }) {
        Text('服务器地址与端口')
          .fontSize(12)
          .fontColor('#8F959E')
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

      Column({ space: 4 }) {
        Text('连接密钥 (Auth Key)')
          .fontSize(12)
          .fontColor('#8F959E')
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

      Row({ space: 12 }) {
        Button('测试连接')
          .layoutWeight(1)
          .height(40)
          .backgroundColor('#F2F3F5')
          .fontColor('#1F2329')
          .onClick(async () => {
            ToastUtil.show('正在测试服务器连接...', 1000);
            await this.syncService.connectServer(this.syncHost, this.syncPort, this.syncKey);
            ToastUtil.show(this.syncReportText);
          })

        Button('立即双向同步')
          .layoutWeight(1)
          .height(40)
          .backgroundColor('#07C160')
          .fontColor(Color.White)
          .onClick(async () => {
            ToastUtil.show('正在执行双向加密同步...', 1000);
            await this.syncService.syncData();
            await this.loadCollections();
            ToastUtil.show(this.syncReportText);
          })
      }
      .width('100%')
      .margin({ top: 4 })

      Text(`当前状态：${this.syncReportText}`)
        .fontSize(12)
        .fontColor('#8F959E')
        .margin({ bottom: 16 })
    }
    .width('100%')
    .height(400)
    .padding({ left: 20, right: 20 })
  }

  @Builder
  ThemeManageContent() {
    Column({ space: 16 }) {
      Row() {
        Text('个性化主题与配色')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1F2329')

        Blank()

        Button({ type: ButtonType.Circle }) {
          Image($r('app.media.ic_close'))
            .width(16).height(16).fillColor('#8F959E')
        }
        .width(32).height(32).backgroundColor(Color.Transparent)
        .onClick(() => { this.activeModal = 'none'; })
      }
      .width('100%')
      .padding({ left: 20, right: 16, top: 16, bottom: 4 })

      Row({ space: 12 }) {
        Button('浅色模式')
          .layoutWeight(1)
          .height(36)
          .backgroundColor(this.currentThemeMode === ThemeMode.LIGHT ? '#E8F8F0' : '#F2F3F5')
          .fontColor(this.currentThemeMode === ThemeMode.LIGHT ? '#07C160' : '#1F2329')
          .onClick(() => {
            this.currentThemeMode = ThemeMode.LIGHT;
            this.themeService.setMode(ThemeMode.LIGHT);
          })

        Button('深色模式')
          .layoutWeight(1)
          .height(36)
          .backgroundColor(this.currentThemeMode === ThemeMode.DARK ? '#E8F8F0' : '#F2F3F5')
          .fontColor(this.currentThemeMode === ThemeMode.DARK ? '#07C160' : '#1F2329')
          .onClick(() => {
            this.currentThemeMode = ThemeMode.DARK;
            this.themeService.setMode(ThemeMode.DARK);
          })
      }
      .width('100%')

      Column({ space: 8 }) {
        Text('选择主色调')
          .fontSize(13)
          .fontColor('#8F959E')
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
                .fontColor('#8F959E')
            }
          }, (p: ThemePreset) => p.id)
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .padding({ top: 6, bottom: 16 })
      }
      .width('100%')
    }
    .width('100%')
    .height(320)
    .padding({ left: 20, right: 20 })
  }

  @Builder
  AboutContent() {
    Column({ space: 12 }) {
      Row() {
        Text('关于 洛雪音乐')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1F2329')

        Blank()

        Button({ type: ButtonType.Circle }) {
          Image($r('app.media.ic_close'))
            .width(16).height(16).fillColor('#8F959E')
        }
        .width(32).height(32).backgroundColor(Color.Transparent)
        .onClick(() => { this.activeModal = 'none'; })
      }
      .width('100%')
      .padding({ left: 20, right: 16, top: 16, bottom: 4 })

      Text('基于 lyswhut/lx-music-mobile 深度重构的原生纯血鸿蒙音乐客户端。')
        .fontSize(13)
        .fontColor('#8F959E')
        .textAlign(TextAlign.Center)
        .width('90%')
        .margin({ top: 12 })

      Text('特别致谢原作者 @lyswhut 提供的优秀架构设计理念。\n本软件不内置任何音频，完全遵循开源社区 Apache-2.0 协议。')
        .fontSize(12)
        .fontColor('#8F959E')
        .textAlign(TextAlign.Center)
        .width('90%')

      Blank()

      Text('v1.0.0 · HarmonyOS NEXT 26 Release')
        .fontSize(11)
        .fontColor('#07C160')
        .padding({ bottom: 20 })
    }
    .width('100%')
    .height(280)
    .padding({ left: 20, right: 20 })
    .alignItems(HorizontalAlign.Center)
  }
}

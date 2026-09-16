import mediaquery from '@ohos.mediaquery';

export type BreakpointType = 'sm' | 'md' | 'lg';

export class BreakpointConstants {
  public static readonly BREAKPOINT_SM: BreakpointType = 'sm';
  public static readonly BREAKPOINT_MD: BreakpointType = 'md';
  public static readonly BREAKPOINT_LG: BreakpointType = 'lg';
  public static readonly RANGE_SM: string = '(width < 600vp)';
  public static readonly RANGE_MD: string = '(600vp <= width < 840vp)';
  public static readonly RANGE_LG: string = '(840vp <= width)';
}

/**
 * 响应式断点监听系统
 */
export class BreakpointSystem {
  private smListener: mediaquery.MediaQueryListener = mediaquery.matchMediaSync(BreakpointConstants.RANGE_SM);
  private mdListener: mediaquery.MediaQueryListener = mediaquery.matchMediaSync(BreakpointConstants.RANGE_MD);
  private lgListener: mediaquery.MediaQueryListener = mediaquery.matchMediaSync(BreakpointConstants.RANGE_LG);

  private currentBreakpoint: BreakpointType = BreakpointConstants.BREAKPOINT_SM;
  private listeners: ((bp: BreakpointType) => void)[] = [];

  constructor() {
    this.initListeners();
  }

  private initListeners(): void {
    this.smListener.on('change', (result: mediaquery.MediaQueryResult) => {
      if (result.matches) {
        this.updateCurrent(BreakpointConstants.BREAKPOINT_SM);
      }
    });

    this.mdListener.on('change', (result: mediaquery.MediaQueryResult) => {
      if (result.matches) {
        this.updateCurrent(BreakpointConstants.BREAKPOINT_MD);
      }
    });

    this.lgListener.on('change', (result: mediaquery.MediaQueryResult) => {
      if (result.matches) {
        this.updateCurrent(BreakpointConstants.BREAKPOINT_LG);
      }
    });
  }

  private updateCurrent(bp: BreakpointType): void {
    this.currentBreakpoint = bp;
    this.listeners.forEach(cb => cb(bp));
  }

  public getCurrent(): BreakpointType {
    return this.currentBreakpoint;
  }

  public register(callback: (bp: BreakpointType) => void): void {
    this.listeners.push(callback);
    callback(this.currentBreakpoint);
  }

  public unregister(): void {
    this.smListener.off('change');
    this.mdListener.off('change');
    this.lgListener.off('change');
    this.listeners = [];
  }
}

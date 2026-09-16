/**
 * 主题配置与调色板定义
 */
export enum ThemeMode {
  SYSTEM = 'system',
  LIGHT = 'light',
  DARK = 'dark'
}

export interface ThemeColorSet {
  primary: string;
  primaryLight: string;
  background: string;
  cardBackground: string;
  textPrimary: string;
  textSecondary: string;
  divider: string;
}

export interface ThemePreset {
  id: string;
  name: string;
  color: string;
}

/**
 * 全局主题管理服务 (单例)
 */
export class ThemeService {
  private static instance: ThemeService;
  private mode: ThemeMode = ThemeMode.LIGHT;
  private currentPrimaryColor: string = '#07C160';

  public static readonly PRESETS: ThemePreset[] = [
    { id: 'green', name: '经典翡翠', color: '#07C160' },
    { id: 'blue', name: '极光天蓝', color: '#3377FF' },
    { id: 'purple', name: '魅影流光', color: '#7B61FF' },
    { id: 'red', name: '珊瑚落樱', color: '#FF4D4F' },
    { id: 'black', name: '深邃曜石', color: '#1F2329' }
  ];

  private listeners: ((theme: ThemeColorSet) => void)[] = [];

  private constructor() {}

  public static getInstance(): ThemeService {
    if (!ThemeService.instance) {
      ThemeService.instance = new ThemeService();
    }
    return ThemeService.instance;
  }

  public getMode(): ThemeMode {
    return this.mode;
  }

  public setMode(mode: ThemeMode): void {
    this.mode = mode;
    this.notifyThemeChange();
  }

  public getPrimaryColor(): string {
    return this.currentPrimaryColor;
  }

  public setPrimaryColor(color: string): void {
    this.currentPrimaryColor = color;
    this.notifyThemeChange();
  }

  public getColors(): ThemeColorSet {
    const isDark = this.mode === ThemeMode.DARK;
    return {
      primary: this.currentPrimaryColor,
      primaryLight: `${this.currentPrimaryColor}20`,
      background: isDark ? '#121316' : '#FFFFFF',
      cardBackground: isDark ? '#1E2024' : '#F8F9FA',
      textPrimary: isDark ? '#F5F5F5' : '#1F2329',
      textSecondary: isDark ? '#8A8D93' : '#8F959E',
      divider: isDark ? '#2B2D33' : '#F2F3F5'
    };
  }

  public onThemeChange(listener: (theme: ThemeColorSet) => void): void {
    this.listeners.push(listener);
  }

  private notifyThemeChange(): void {
    const colors = this.getColors();
    this.listeners.forEach(cb => cb(colors));
  }
}

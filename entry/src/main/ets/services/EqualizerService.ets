export interface EqualizerBand {
  frequency: string;
  gain: number; // -10 ~ +10 dB
}

export interface EqualizerPreset {
  id: string;
  name: string;
  gains: number[]; // 5 频段增益: 60Hz, 230Hz, 910Hz, 3.6kHz, 14kHz
}

/**
 * 音效预设与 5 频段均衡器服务 (单例)
 */
export class EqualizerService {
  private static instance: EqualizerService;
  private enabled: boolean = true;
  private activePresetId: string = 'pop';
  private bands: EqualizerBand[] = [
    { frequency: '60Hz', gain: 4 },
    { frequency: '230Hz', gain: 2 },
    { frequency: '910Hz', gain: 0 },
    { frequency: '3.6kHz', gain: 3 },
    { frequency: '14kHz', gain: 5 }
  ];
  private bassBoost: number = 30; // 0 ~ 100%
  private surroundEnabled: boolean = true;
  private listeners: (() => void)[] = [];

  public static readonly PRESETS: EqualizerPreset[] = [
    { id: 'flat', name: '原声音质 (Flat)', gains: [0, 0, 0, 0, 0] },
    { id: 'pop', name: '流行热曲 (Pop)', gains: [4, 2, 0, 3, 5] },
    { id: 'rock', name: '重金属摇滚 (Rock)', gains: [6, 4, -1, 4, 7] },
    { id: 'vocal', name: '清澈纯净人声 (Vocal)', gains: [-2, 1, 5, 4, 2] },
    { id: 'classical', name: '交响古典 (Classical)', gains: [5, 3, -2, 4, 6] },
    { id: 'jazz', name: '温暖醇厚爵士 (Jazz)', gains: [3, 2, 1, 2, 2] }
  ];

  private constructor() {}

  public static getInstance(): EqualizerService {
    if (!EqualizerService.instance) {
      EqualizerService.instance = new EqualizerService();
    }
    return EqualizerService.instance;
  }

  public isEnabled(): boolean {
    return this.enabled;
  }

  public setEnabled(enable: boolean): void {
    this.enabled = enable;
    this.notifyChange();
  }

  public getBands(): EqualizerBand[] {
    const list: EqualizerBand[] = [];
    for (let i = 0; i < this.bands.length; i++) {
      list.push({
        frequency: this.bands[i].frequency,
        gain: this.bands[i].gain
      });
    }
    return list;
  }

  public setBandGain(index: number, gain: number): void {
    if (index >= 0 && index < this.bands.length) {
      this.bands[index].gain = Math.max(-10, Math.min(10, gain));
      this.activePresetId = 'custom';
      this.notifyChange();
    }
  }

  public getActivePresetId(): string {
    return this.activePresetId;
  }

  public applyPreset(presetId: string): void {
    const preset = EqualizerService.PRESETS.find(p => p.id === presetId);
    if (preset) {
      this.activePresetId = presetId;
      for (let i = 0; i < this.bands.length && i < preset.gains.length; i++) {
        this.bands[i].gain = preset.gains[i];
      }
      this.notifyChange();
    }
  }

  public getBassBoost(): number {
    return this.bassBoost;
  }

  public setBassBoost(value: number): void {
    this.bassBoost = Math.max(0, Math.min(100, value));
    this.notifyChange();
  }

  public isSurroundEnabled(): boolean {
    return this.surroundEnabled;
  }

  public setSurroundEnabled(enable: boolean): void {
    this.surroundEnabled = enable;
    this.notifyChange();
  }

  public onChange(listener: () => void): void {
    this.listeners.push(listener);
  }

  private notifyChange(): void {
    this.listeners.forEach(cb => cb());
  }
}

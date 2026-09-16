/**
 * 单行歌词数据结构
 */
export interface LyricLine {
  time: number; // 毫秒
  text: string;
}

export interface ParsedLyric {
  title?: string;
  artist?: string;
  album?: string;
  offset?: number;
  lines: LyricLine[];
}

/**
 * LRC 歌词解析器与时间轴索引定位
 */
export class LyricParser {
  private static timeRegex = /\[(\d{2}):(\d{2})(?:\.(\d{2,3}))?\]/g;

  /**
   * 解析 LRC 文本
   */
  public static parse(lrcText: string): ParsedLyric {
    const result: ParsedLyric = {
      lines: []
    };

    if (!lrcText || typeof lrcText !== 'string') {
      return result;
    }

    const lines = lrcText.split(/\r?\n/);
    for (const rawLine of lines) {
      const line = rawLine.trim();
      if (!line) continue;

      // 解析元数据标签
      if (line.startsWith('[ti:')) {
        result.title = line.substring(4, line.length - 1).trim();
        continue;
      }
      if (line.startsWith('[ar:')) {
        result.artist = line.substring(4, line.length - 1).trim();
        continue;
      }
      if (line.startsWith('[al:')) {
        result.album = line.substring(4, line.length - 1).trim();
        continue;
      }
      if (line.startsWith('[offset:')) {
        const offset = parseInt(line.substring(8, line.length - 1).trim(), 10);
        result.offset = isNaN(offset) ? 0 : offset;
        continue;
      }

      // 解析时间标签
      const matches: RegExpExecArray[] = [];
      let match: RegExpExecArray | null = null;
      LyricParser.timeRegex.lastIndex = 0;
      while ((match = LyricParser.timeRegex.exec(line)) !== null) {
        matches.push(match);
      }

      if (matches.length > 0) {
        const text = line.replace(LyricParser.timeRegex, '').trim();
        for (const m of matches) {
          const minute = parseInt(m[1], 10);
          const second = parseInt(m[2], 10);
          const millisecond = m[3] ? (m[3].length === 2 ? parseInt(m[3], 10) * 10 : parseInt(m[3], 10)) : 0;
          const time = minute * 60 * 1000 + second * 1000 + millisecond + (result.offset || 0);
          result.lines.push({
            time: Math.max(0, time),
            text: text
          });
        }
      }
    }

    // 按时间顺序升序排列
    result.lines.sort((a, b) => a.time - b.time);
    return result;
  }

  /**
   * 根据当前播放时间获取当前行索引
   */
  public static findCurrentLineIndex(lines: LyricLine[], currentTimeMs: number): number {
    if (!lines || lines.length === 0) {
      return -1;
    }
    if (currentTimeMs < lines[0].time) {
      return 0;
    }

    let left = 0;
    let right = lines.length - 1;
    let target = 0;

    while (left <= right) {
      const mid = Math.floor((left + right) / 2);
      if (lines[mid].time <= currentTimeMs) {
        target = mid;
        left = mid + 1;
      } else {
        right = mid - 1;
      }
    }

    return target;
  }
}

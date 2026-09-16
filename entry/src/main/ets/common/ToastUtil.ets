import promptAction from '@ohos.promptAction';

/**
 * 鸿蒙全局交互提示工具类
 */
export class ToastUtil {
  /**
   * 显示短消息提示 (Toast)
   */
  public static show(message: string, duration: number = 2000): void {
    if (!message || message.trim().length === 0) return;
    try {
      promptAction.showToast({
        message: message,
        duration: duration,
        bottom: 80
      });
    } catch (e) {
      console.warn('Toast show warning: ' + JSON.stringify(e));
    }
  }

  public static showWarning(message: string): void {
    ToastUtil.show(message, 2500);
  }

  public static showError(message: string): void {
    ToastUtil.show(message, 3000);
  }
}

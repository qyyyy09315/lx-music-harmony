import UIAbility from '@ohos.app.ability.UIAbility';
import window from '@ohos.window';
import { AudioPlayerService } from '../services/AudioPlayerService';
import { AVSessionService } from '../services/AVSessionService';

export default class EntryAbility extends UIAbility {
  onCreate(): void {
    console.info('LX Music Harmony Ability onCreate');
    AudioPlayerService.getInstance().init();
    AVSessionService.getInstance().initSession(this.context);
  }

  onDestroy(): void {
    console.info('LX Music Harmony Ability onDestroy');
    AVSessionService.getInstance().destroy();
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    console.info('LX Music Harmony Ability onWindowStageCreate');
    windowStage.loadContent('pages/Index', (err, data) => {
      if (err.code) {
        console.error('Failed to load the content. Cause: ' + JSON.stringify(err));
        return;
      }
      console.info('Succeeded in loading the content. Data: ' + JSON.stringify(data));
    });
  }

  onWindowStageDestroy(): void {
    console.info('LX Music Harmony Ability onWindowStageDestroy');
  }

  onForeground(): void {
    console.info('LX Music Harmony Ability onForeground');
  }

  onBackground(): void {
    console.info('LX Music Harmony Ability onBackground');
  }
}

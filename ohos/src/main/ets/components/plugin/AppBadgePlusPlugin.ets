import {
  FlutterPlugin,
  FlutterPluginBinding,
  MethodCall,
  MethodCallHandler,
  MethodChannel,
  MethodResult,
} from '@ohos/flutter_ohos';
import { AbilityAware, AbilityPluginBinding } from '@ohos/flutter_ohos';
import { notificationManager } from '@kit.NotificationKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
const TAG: string = '[PublishOperation]';
const DOMAIN_NUMBER: number = 0xFF00;
/** AppBadgePlusPlugin **/
export default class AppBadgePlusPlugin implements FlutterPlugin, MethodCallHandler,AbilityAware  {
  private channel: MethodChannel | null = null;
  private static _context: common.UIAbilityContext | null = null;

  constructor() {
  }

  static get context(): common.Context | null {
    return AppBadgePlusPlugin._context;
  }

  get context(): common.UIAbilityContext | null {
    return AppBadgePlusPlugin._context;
  }


  getUniqueClassName(): string {
    return "AppBadgePlusPlugin"
  }

  onAttachedToAbility(binding: AbilityPluginBinding): void {
    AppBadgePlusPlugin._context = binding.getAbility().context;
    // Called when the plugin is attached to an Ability.
  }
  onDetachedFromAbility(): void {
    // this._uiContext = null;
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {

    this.channel = new MethodChannel(binding.getBinaryMessenger(), "app_badge_plus");
    this.channel.setMethodCallHandler(this)
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    if (this.channel != null) {
      this.channel.setMethodCallHandler(null)
    }
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {

    if (call.method == "updateBadge") {


      if (AppBadgePlusPlugin._context) { // Add null check here
        try {
          notificationManager.isNotificationEnabled().then((data: boolean) => {
            hilog.info(DOMAIN_NUMBER, TAG, "isNotificationEnabled success, data: " + JSON.stringify(data));

            try {
              // 获取参数
              const countArg: string = call.argument("count");

              if (countArg === null || countArg === undefined) {
                console.error('Badge count argument is missing.');
                result.error("MISSING_ARGUMENT", "Badge count argument is required.", null);
                return;
              }

              // 确保 countArg 是数字类型
              let badgeNumber: number = Number(countArg);

              if (isNaN(badgeNumber)) {
                console.error('Invalid badge number received:', countArg);
                result.error("INVALID_ARGUMENT", "Badge count must be a number.", null);
                return;
              }

              notificationManager.setBadgeNumber(badgeNumber).then(() => {
                console.info(`Succeeded in setting badge number to ${badgeNumber}.`);
                result.success(null);
              }).catch((err: BusinessError) => {
                console.error(`Failed to set badge number. Code is ${err.code}, message is ${err.message}`);
                result.error(err.code.toString(), err.message, null);
              });
            } catch (e) {
              const error = e as Error;
              console.error(`Error processing updateBadge: ${error.message}`);
              result.error("UNKNOWN_ERROR", error.message, null);
            }

            if (!data) {
              notificationManager.requestEnableNotification(AppBadgePlusPlugin._context).then(() => {
                hilog.info(DOMAIN_NUMBER, TAG, `[ANS] requestEnableNotification success`);
              }).catch((err: BusinessError) => {
                if (1600004 == err.code) {
                  hilog.error(DOMAIN_NUMBER, TAG,
                    `[ANS] requestEnableNotification refused, code is ${err.code}, message is ${err.message}`);
                } else {
                  hilog.error(DOMAIN_NUMBER, TAG,
                    `[ANS] requestEnableNotification failed, code is ${err.code}, message is ${err.message}`);
                }
              });
            }
          }).catch((err: BusinessError) => {
            hilog.error(DOMAIN_NUMBER, TAG,
              `isNotificationEnabled fail, code is ${err.code}, message is ${err.message}`);
          });
        } catch (err) {
          // 捕获同步的参数错误
          let code = (err as BusinessError).code;
          let message = (err as BusinessError).message;
          console.error(`terminateSelf failed, code is ${code}, message is ${message}`);
          result.error("TERMINATE_ERROR", `terminateSelf error: ${message}`, null);
        }
      } else {
        console.error("UIContext is null, cannot terminate self.");
        result.error("CONTEXT_NULL", "UIContext is null", null); // Inform Flutter about the error
      }

    } else if (call.method == "isSupported") {
      // 鸿蒙平台默认支持角标
      result.success(true);
    } else {
      result.notImplemented();
    }
  }

}
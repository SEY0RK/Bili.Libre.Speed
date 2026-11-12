import 'package:PiliBro/utils/storage.dart';
import 'package:PiliBro/utils/storage_key.dart';

/// 我的页快捷按钮。键同时是设置箱里的显示开关，映射顺序即默认顺序。
abstract final class MineAction {
  static const labels = <String, String>{
    SettingBoxKey.mineBtnOneKeyListen: '一键听歌',
    SettingBoxKey.mineBtnSpeed: '倍速设置',
    SettingBoxKey.mineBtnHistory: '观看记录',
    SettingBoxKey.mineBtnSub: '我的订阅',
    SettingBoxKey.mineBtnLater: '稍后再看',
    SettingBoxKey.mineBtnAvSettings: '音画设置',
    SettingBoxKey.mineBtnNetworkPolicy: '智能网优',
    SettingBoxKey.mineBtnOrientation: '屏幕旋转',
    SettingBoxKey.mineBtnCreator: '创作中心',
    SettingBoxKey.mineBtnDownload: '离线缓存',
    SettingBoxKey.mineBtnGateway: '网关管理',
    SettingBoxKey.mineBtnAudioSettings: '特色播放',
    SettingBoxKey.mineBtnPlaybackStats: '播放统计',
  };

  static bool shown(String key) =>
      GStorage.setting.get(key, defaultValue: true) as bool;

  /// 用户排过的顺序；没排过或新加的按钮按默认顺序补在末尾。
  static List<String> get order {
    final stored =
        (GStorage.setting.get(SettingBoxKey.mineBtnOrder) as List?)
            ?.whereType<String>()
            .where(labels.containsKey)
            .toList() ??
        const <String>[];
    return [
      ...stored,
      for (final key in labels.keys)
        if (!stored.contains(key)) key,
    ];
  }

  /// [order] 是全部按钮的新顺序，[shown] 是要显示的按钮。
  static Future<void> save(List<String> order, {required Set<String> shown}) =>
      GStorage.setting.putAll({
        for (final key in labels.keys) key: shown.contains(key),
        SettingBoxKey.mineBtnOrder: order,
      });
}

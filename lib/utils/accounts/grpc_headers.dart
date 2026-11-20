import 'dart:convert';

import 'package:PiliBro/grpc/bilibili/metadata.pb.dart';
import 'package:PiliBro/grpc/bilibili/metadata/device.pb.dart';
import 'package:PiliBro/grpc/bilibili/metadata/locale.pb.dart';
import 'package:PiliBro/grpc/bilibili/metadata/network.pb.dart' as network;
import 'package:PiliBro/grpc/bilibili/metadata/fawkes.pb.dart';
import 'package:PiliBro/utils/bili_device.dart';
import 'package:PiliBro/utils/id_utils.dart';
import 'package:PiliBro/utils/storage_pref.dart';

/// gRPC 公共请求头；trace-id 与 ticket 由拦截器每次请求补上
abstract final class GrpcHeaders {
  /// 完全照搬 PiliPlus 的评论接口请求头（固定 HD 2.0.1 / 2001100 / master 渠道，
  /// 不带 x-bili-mid、x-bili-aurora-eid、ticket）。B站对这套身份返回完整楼中楼，
  /// 不会像对登录态 HD 2.3.1 那样折叠回复。
  static Map<String, String> piliPlusHeaders(String? accessKey) {
    final buvid = BiliDevice.buvid;
    return {
      'grpc-encoding': 'gzip',
      'gzip-accept-encoding': 'gzip,identity',
      'user-agent':
          'Mozilla/5.0 BiliDroid/2.0.1 (bbcallen@gmail.com) os/android '
          'model/android_hd mobi_app/android_hd build/2001100 channel/master '
          'innerVer/2001100 osVer/15 network/2',
      'x-bili-gaia-vtoken': '',
      'x-bili-aurora-zone': '',
      'x-bili-trace-id': '11111111111111111111111111111111:1111111111111111:0:0',
      'bili-http-engine': 'cronet',
      'x-bili-network-bin': base64Encode(
        network.Network(type: network.NetworkType.WIFI).writeToBuffer(),
      ),
      'x-bili-locale-bin': base64Encode(
        Locale(
          cLocale: LocaleIds(language: 'zh', region: 'CN', script: 'Hans'),
          sLocale: LocaleIds(language: 'zh', region: 'CN', script: 'Hans'),
          timezone: 'Asia/Shanghai',
        ).writeToBuffer(),
      ),
      'x-bili-exps-bin': '',
      if (accessKey != null && accessKey.isNotEmpty)
        'authorization': 'identify_v1 $accessKey',
      'buvid': buvid,
      'x-bili-fawkes-req-bin': fawkes(BiliApp.hd),
      'x-bili-device-bin': base64Encode(
        Device(
          appId: 5,
          build: 2001100,
          buvid: buvid,
          mobiApp: 'android_hd',
          platform: 'android',
          channel: 'master',
          brand: 'android',
          model: 'android',
          osver: '15',
          versionName: '2.0.1',
        ).writeToBuffer(),
      ),
      'x-bili-metadata-bin': base64Encode(
        Metadata(
          accessKey: accessKey,
          mobiApp: 'android_hd',
          device: 'android',
          build: 2001100,
          channel: 'master',
          buvid: buvid,
          platform: 'android',
        ).writeToBuffer(),
      ),
    };
  }

  static String fawkes(BiliApp app) => base64Encode(
    FawkesReq(
      appkey: app.keyName,
      env: 'prod',
      sessionId: BiliDevice.sessionId,
    ).writeToBuffer(),
  );

  // 新版本客户端拿到的楼中楼正文不再带「回复 @某人 :」，靠客户端自己拼。
  // 评论接口照 PiliPlus 自报 HD 2.0.1，让服务器把前缀写回正文
  static bool replyLegacy = Pref.replyLegacyIdentity;
  static const _replyBuild = 2001100;
  static const _replyVersion = '2.0.1';

  /// 盖在 [newHeaders] 上，只用于评论列表的 gRPC。票要跟身份一套：有 HD token 就用它，
  /// 拿粉版 token 自报 HD 时服务器当成未登录，IP 属地之类只给登录用户的字段就没了
  static Map<String, String> replyHeaders(String? accessKey) => {
    if (accessKey != null) 'authorization': 'identify_v1 $accessKey',
    'x-bili-device-bin': BiliDevice.deviceBin(
      BiliApp.hd,
      build: _replyBuild,
      version: _replyVersion,
    ),
    'x-bili-metadata-bin': base64Encode(
      Metadata(
        accessKey: accessKey,
        mobiApp: BiliApp.hd.mobiApp,
        build: _replyBuild,
        channel: BiliDevice.channel,
        buvid: BiliDevice.buvid,
        platform: 'android',
      ).writeToBuffer(),
    ),
  };

  static Map<String, String> newHeaders(
    BiliApp app,
    int mid, [
    String? accessKey,
  ]) => {
    'grpc-encoding': 'gzip',
    'gzip-accept-encoding': 'gzip,identity',
    'user-agent': app.grpcUserAgent,
    'x-bili-gaia-vtoken': '',
    'x-bili-aurora-zone': '',
    'x-bili-aurora-eid': mid > 0 ? IdUtils.genAuroraEid(mid) : '',
    'x-bili-mid': mid > 0 ? '$mid' : '',
    'buvid': BiliDevice.buvid,
    'env': 'prod',
    'app-key': app.keyName,
    'bili-http-engine': 'ignet',
    // 'te': 'trailers', // dio not supported
    'x-bili-device-bin': BiliDevice.deviceBin(app),
    'x-bili-network-bin': BiliDevice.networkBin,
    'x-bili-locale-bin': BiliDevice.localeBin,
    'x-bili-exps-bin': '',
    'x-bili-restriction-bin': '',
    if (accessKey != null) 'authorization': 'identify_v1 $accessKey',
    'x-bili-fawkes-req-bin': fawkes(app),
    'x-bili-metadata-bin': base64Encode(
      Metadata(
        accessKey: accessKey,
        mobiApp: app.mobiApp,
        build: app.build,
        channel: BiliDevice.channel,
        buvid: BiliDevice.buvid,
        platform: 'android',
      ).writeToBuffer(),
    ),
  };
}

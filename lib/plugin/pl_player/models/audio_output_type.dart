import 'package:PiliBro/models/common/enum_with_label.dart';

enum AudioOutput implements EnumWithLabel {
  // AAudio 在部分 Android 16 设备上 seek 后不再推进（audio-pts 冻住），
  // 以音频为时钟的 mpv 随之停摆；OpenSL ES 没有该问题，故排在前面。
  opensles('OpenSL ES'),
  aaudio('AAudio'),
  audiotrack('AudioTrack'),
  ;

  static final defaultValue = values.map((e) => e.name).join(',');

  @override
  final String label;
  const AudioOutput(this.label);
}

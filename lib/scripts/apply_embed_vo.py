#!/usr/bin/env python3
"""Build-time patch: switch Android video output to MediaCodec direct output.

vo=gpu feeds frames through AImageReader; on some devices that path stops
delivering frames after a seek, freezing the playback clock. mediacodec_embed
bypasses it. Idempotent: skips when already applied.
"""
import pathlib
import sys

P = pathlib.Path("lib/plugin/pl_player/controller.dart")


def rep(t, old, new, label):
    n = t.count(old)
    if n != 1:
        raise SystemExit(f"patch anchor {label}: expected 1, got {n}")
    return t.replace(old, new)


t = P.read_text(encoding="utf-8")
if "useEmbed" in t:
    print("embed vo already applied, skip")
    sys.exit(0)

t = rep(
    t,
    "    final bool baseline = _mpvVerbose && Platform.isAndroid;\n    final opt = {",
    "    final bool baseline = _mpvVerbose && Platform.isAndroid;\n"
    "    // Android: MediaCodec direct output, bypass vo/gpu AImageReader.\n"
    "    final bool useEmbed = Platform.isAndroid;\n"
    "    final String? effectiveVo = useEmbed ? 'mediacodec_embed' : null;\n"
    "    final String? effectiveHwdec = useEmbed ? 'mediacodec' : hwdec;\n"
    "    final opt = {",
    "vars",
)

t = rep(
    t,
    "    final player = await Player.create(",
    "    debugPrint('[VO] vo=${effectiveVo ?? 'gpu'} hwdec=${effectiveHwdec ?? 'no'}');\n"
    "    final player = await Player.create(",
    "log",
)

t = rep(
    t,
    "        enableHardwareAcceleration: hwdec != null,\n"
    "        androidAttachSurfaceAfterVideoParameters: false,\n"
    "        hwdec: hwdec,",
    "        enableHardwareAcceleration: effectiveHwdec != null,\n"
    "        androidAttachSurfaceAfterVideoParameters: false,\n"
    "        vo: effectiveVo,\n"
    "        hwdec: effectiveHwdec,",
    "config",
)

old_conf = (
    '        "[CONF] baseline=$baseline hwdec=${hwdec ?? \'no\'} "\n'
    '        "videoSync=${opt[\'video-sync\']} autosync=${opt[\'autosync\'] ?? \'0\'}",'
)
new_conf = (
    '        "[CONF] baseline=$baseline vo=${effectiveVo ?? \'gpu\'} "\n'
    '        "hwdec=${effectiveHwdec ?? \'no\'} "\n'
    '        "videoSync=${opt[\'video-sync\']} autosync=${opt[\'autosync\'] ?? \'0\'}",'
)
t = rep(t, old_conf, new_conf, "conf")

P.write_text(t, encoding="utf-8")
print("embed vo patch applied")

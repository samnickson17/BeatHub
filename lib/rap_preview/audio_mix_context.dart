import 'package:audioplayers/audioplayers.dart';

/// Audio context that allows two streams (beat + voice) to play
/// simultaneously on both Android and iOS without stealing audio focus.
AudioContext get mixingAudioContext => AudioContext(
  android: const AudioContextAndroid(
    // Do not request audio focus so beat and vocal players can run in parallel
    // without forcing focus-loss callbacks on each other.
    audioFocus: AndroidAudioFocus.none,
    contentType: AndroidContentType.music,
    usageType: AndroidUsageType.media,
    isSpeakerphoneOn: false,
    stayAwake: false,
  ),
  iOS: AudioContextIOS(
    category: AVAudioSessionCategory.playAndRecord,
    options: {
      AVAudioSessionOptions.mixWithOthers,
      AVAudioSessionOptions.defaultToSpeaker,
      AVAudioSessionOptions.allowBluetooth,
    },
  ),
);

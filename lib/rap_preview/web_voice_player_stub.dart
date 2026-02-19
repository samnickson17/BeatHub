// Stub for non-web platforms — no-ops, never called at runtime on native.
class WebVoicePlayer {
  void play(String src, {required void Function() onEnded}) {}
  void pause() {}
  void dispose() {}
}

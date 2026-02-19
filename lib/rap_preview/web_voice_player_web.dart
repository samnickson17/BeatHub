// Web implementation — uses dart:html AudioElement for truly parallel playback.
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class WebVoicePlayer {
  html.AudioElement? _el;

  void play(String src, {required void Function() onEnded}) {
    _el?.pause();
    final el = html.AudioElement();
    el.src = src;
    el.volume = 1.0;
    el.onEnded.listen((_) => onEnded());
    _el = el;
    el.play();
  }

  void pause() {
    _el?.pause();
    _el = null;
  }

  // alias used by dispose
  void dispose() => pause();
}

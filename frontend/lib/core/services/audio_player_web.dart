import 'package:web/web.dart' as web;

void playWebSound(String soundResourceName) {
  try {
    final audio = web.HTMLAudioElement();
    audio.src = 'sounds/$soundResourceName.wav';
    audio.play();
  } catch (e) {
    // Autoplay restrictions or web error fallback
  }
}

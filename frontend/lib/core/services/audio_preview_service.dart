import 'package:flutter/foundation.dart';
import '../../features/settings/domain/reminder_sound_model.dart';
import 'audio_player_stub.dart' if (dart.library.js_interop) 'audio_player_web.dart';

class AudioPreviewService {
  static void playPreview(ReminderSound sound) {
    if (sound.resourceName != null) {
      playWebSound(sound.resourceName!);
    }
  }
}

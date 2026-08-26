import 'package:flutter/services.dart';

const MethodChannel _channel = MethodChannel('com.example.frontend/system_settings');

void playWebSound(String soundResourceName) {
  try {
    print('Calling native playSoundPreview MethodChannel for: $soundResourceName');
    _channel.invokeMethod('playSoundPreview', {'soundName': soundResourceName});
  } catch (e) {
    print('Native playSoundPreview error: $e');
  }
}

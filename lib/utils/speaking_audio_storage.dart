import 'dart:typed_data';

import 'speaking_audio_storage_io.dart'
    if (dart.library.html) 'speaking_audio_storage_web.dart' as impl;

class SpeakingAudioUpload {
  final Uint8List bytes;
  final String filename;
  final String mimeType;

  const SpeakingAudioUpload({
    required this.bytes,
    required this.filename,
    required this.mimeType,
  });
}

Future<String> createSpeakingRecordingPath() {
  return impl.createSpeakingRecordingPath();
}

Future<SpeakingAudioUpload> readSpeakingRecording(String path) {
  return impl.readSpeakingRecording(path);
}

Future<void> cleanupSpeakingRecording(String path) {
  return impl.cleanupSpeakingRecording(path);
}

import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'speaking_audio_storage.dart';

Future<String> createSpeakingRecordingPath() async {
  return 'speaking.webm';
}

Future<SpeakingAudioUpload> readSpeakingRecording(String path) async {
  final response = await web.window.fetch(path.toJS).toDart;
  final blob = await response.blob().toDart;
  final buffer = await blob.arrayBuffer().toDart;
  final bytes = Uint8List.view(buffer.toDart);
  final mimeType = blob.type.isNotEmpty ? blob.type : 'audio/webm';

  return SpeakingAudioUpload(
    bytes: bytes,
    filename: 'speaking.webm',
    mimeType: mimeType,
  );
}

Future<void> cleanupSpeakingRecording(String path) async {
  if (path.startsWith('blob:')) {
    web.URL.revokeObjectURL(path);
  }
}

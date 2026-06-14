import 'dart:io';

import 'speaking_audio_storage.dart';

Future<String> createSpeakingRecordingPath() async {
  final dir = await Directory.systemTemp.createTemp('oyu_speaking_');
  return '${dir.path}/speaking_${DateTime.now().millisecondsSinceEpoch}.m4a';
}

Future<SpeakingAudioUpload> readSpeakingRecording(String path) async {
  final file = File(path);
  final bytes = await file.readAsBytes();

  return SpeakingAudioUpload(
    bytes: bytes,
    filename: 'speaking.m4a',
    mimeType: 'audio/mp4',
  );
}

Future<void> cleanupSpeakingRecording(String path) async {
  final file = File(path);
  if (await file.exists()) {
    await file.delete();
  }

  final parent = file.parent;
  if (await parent.exists()) {
    await parent.delete(recursive: true);
  }
}

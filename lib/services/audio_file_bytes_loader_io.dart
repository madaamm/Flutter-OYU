import 'dart:io';
import 'dart:typed_data';

Future<Uint8List> loadRecordedAudioBytes(String source) async {
  final file = File(source);

  if (!await file.exists()) {
    throw Exception('Recorded audio file not found: $source');
  }

  return file.readAsBytes();
}
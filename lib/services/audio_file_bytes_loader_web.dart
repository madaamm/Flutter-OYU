import 'dart:html' as html;
import 'dart:typed_data';

Future<Uint8List> loadRecordedAudioBytes(String source) async {
  final request = await html.HttpRequest.request(
    source,
    method: 'GET',
    responseType: 'arraybuffer',
  );

  final response = request.response;
  if (response == null) {
    throw Exception('Recorded audio bytes are empty');
  }

  if (response is ByteBuffer) {
    return Uint8List.view(response);
  }

  throw Exception('Unsupported web audio response type');
}
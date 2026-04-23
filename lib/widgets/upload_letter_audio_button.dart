import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kazakh_learning_app/services/alphabet_service.dart';

class UploadLetterAudioButton extends StatefulWidget {
  final int letterId;
  final String token;
  final VoidCallback? onUploaded;

  const UploadLetterAudioButton({
    super.key,
    required this.letterId,
    required this.token,
    this.onUploaded,
  });

  @override
  State<UploadLetterAudioButton> createState() =>
      _UploadLetterAudioButtonState();
}

class _UploadLetterAudioButtonState extends State<UploadLetterAudioButton> {
  final AlphabetService _service = AlphabetService();

  bool _loading = false;

  Future<void> _pickAndUpload() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['mp3', 'wav', 'ogg'],
        withData: kIsWeb,
      );

      if (result == null || result.files.isEmpty) return;

      final picked = result.files.single;

      setState(() => _loading = true);

      if (kIsWeb) {
        final bytes = picked.bytes;
        if (bytes == null || bytes.isEmpty) {
          throw Exception('Web-та файл bytes табылмады');
        }

        await _service.uploadAudio(
          id: widget.letterId,
          fileName: picked.name,
          fileBytes: bytes,
        );
      } else {
        final path = picked.path;
        if (path == null || path.isEmpty) {
          throw Exception('Файл path табылмады');
        }

        await _service.uploadAudio(
          id: widget.letterId,
          fileName: picked.name,
          filePath: path,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Audio сәтті жүктелді'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      widget.onUploaded?.call();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload error: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _loading ? null : _pickAndUpload,
      icon: _loading
          ? const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      )
          : const Icon(Icons.audio_file_rounded),
      label: Text(_loading ? 'Жүктелуде...' : 'Аудио қосу'),
    );
  }
}
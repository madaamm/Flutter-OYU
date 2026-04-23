import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class LetterRecorderButton extends StatefulWidget {
  final double size;
  final BorderRadius? borderRadius;
  final ValueChanged<String>? onRecorded;

  const LetterRecorderButton({
    super.key,
    this.size = 58,
    this.borderRadius,
    this.onRecorded,
  });

  @override
  State<LetterRecorderButton> createState() => _LetterRecorderButtonState();
}

class _LetterRecorderButtonState extends State<LetterRecorderButton> {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  bool _isRecording = false;
  bool _isPlaying = false;
  bool _busy = false;
  String? _recordedPath;

  @override
  void initState() {
    super.initState();

    _player.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() {
        _isPlaying = state == PlayerState.playing;
      });
    });

    _player.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() {
        _isPlaying = false;
      });
    });
  }

  @override
  void dispose() {
    _player.dispose();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    if (_busy) return;

    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    try {
      setState(() => _busy = true);

      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        throw Exception('Микрофонға рұқсат берілмеген');
      }

      await _player.stop();

      if (kIsWeb) {
        const config = RecordConfig(
          encoder: AudioEncoder.wav,
          numChannels: 1,
          sampleRate: 44100,
          bitRate: 128000,
        );

        await _recorder.start(
          config,
          path: 'letter_record_${DateTime.now().millisecondsSinceEpoch}.wav',
        );
      } else {
        final dir = await getTemporaryDirectory();
        final path =
            '${dir.path}/letter_record_${DateTime.now().millisecondsSinceEpoch}.m4a';

        const config = RecordConfig(
          encoder: AudioEncoder.aacLc,
          numChannels: 1,
          sampleRate: 44100,
          bitRate: 128000,
        );

        await _recorder.start(
          config,
          path: path,
        );
      }

      if (!mounted) return;

      setState(() {
        _isRecording = true;
        _busy = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Жазу басталды. Әріпті айтып, қайта басып тоқтат.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _busy = false;
        _isRecording = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Recording start error: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _stopRecording() async {
    try {
      setState(() => _busy = true);

      final path = await _recorder.stop();

      if (path == null || path.isEmpty) {
        throw Exception('Жазылған файл табылмады');
      }

      widget.onRecorded?.call(path);

      if (!mounted) return;

      setState(() {
        _recordedPath = path;
        _isRecording = false;
        _busy = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Жазу аяқталды. Енді өз даусың ойнатылады.'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      await _playRecordedVoice();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _busy = false;
        _isRecording = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Recording stop error: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _playRecordedVoice() async {
    final path = _recordedPath;
    if (path == null || path.isEmpty) return;

    try {
      await _player.stop();

      if (kIsWeb ||
          path.startsWith('blob:') ||
          path.startsWith('http://') ||
          path.startsWith('https://') ||
          path.startsWith('data:')) {
        await _player.play(UrlSource(path));
      } else {
        await _player.play(DeviceFileSource(path));
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Recorded audio play error: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(14);

    return Material(
      color: const Color(0xFF4B007D),
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: _busy ? null : _toggleRecording,
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: Center(
            child: _busy
                ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
                : Icon(
              _isRecording
                  ? Icons.stop_rounded
                  : (_isPlaying ? Icons.graphic_eq_rounded : Icons.mic),
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
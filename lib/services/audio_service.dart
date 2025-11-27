import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';

class AudioService {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  bool _isRecording = false;
  String? _currentRecordingPath;
  DateTime? _recordingStartTime;
  double _playbackSpeed = 1.0;

  bool get isRecording => _isRecording;
  Duration? get recordingDuration => _recordingStartTime != null 
      ? DateTime.now().difference(_recordingStartTime!) 
      : null;

  Future<bool> requestPermission() async {
    try {
      final status = await Permission.microphone.request();
      return status.isGranted;
    } catch (e) {
      return false;
    }
  }

  Future<bool> startRecording() async {
    try {
      if (_isRecording) {
        return false;
      }

      final hasPermission = await requestPermission();
      if (!hasPermission) {
        return false;
      }

      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentRecordingPath = '${directory.path}/axia_audio_$timestamp.m4a';

      if (await _recorder.hasPermission()) {
        await _recorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: _currentRecordingPath!,
        );
        _isRecording = true;
        _recordingStartTime = DateTime.now();
        return true;
      }
      return false;
    } catch (e) {
      _isRecording = false;
      return false;
    }
  }

  Future<String?> stopRecordingAndGetBase64() async {
    try {
      if (!_isRecording) {
        return null;
      }

      final path = await _recorder.stop();
      _isRecording = false;
      _recordingStartTime = null;

      if (path == null) {
        return null;
      }

      final file = File(path);
      if (!await file.exists()) {
        return null;
      }

      final bytes = await file.readAsBytes();
      final base64Audio = base64Encode(bytes);

      try {
        await file.delete();
      } catch (e) {
        // Ignore deletion errors
      }

      return base64Audio;
    } catch (e) {
      _isRecording = false;
      _recordingStartTime = null;
      return null;
    }
  }

  Future<void> cancelRecording() async {
    try {
      if (_isRecording) {
        await _recorder.stop();
        _isRecording = false;
        _recordingStartTime = null;
        
        if (_currentRecordingPath != null) {
          final file = File(_currentRecordingPath!);
          if (await file.exists()) {
            await file.delete();
          }
        }
      }
    } catch (e) {
      // Ignore errors
    }
  }

  Future<void> setPlaybackSpeed(double speed) async {
    _playbackSpeed = speed;
    await _player.setSpeed(speed);
  }

  double get playbackSpeed => _playbackSpeed;

  Future<void> playAudioFromBase64(String audioBase64) async {
    try {
      final bytes = base64Decode(audioBase64);
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final tempPath = '${directory.path}/axia_playback_$timestamp.m4a';
      
      final file = File(tempPath);
      await file.writeAsBytes(bytes);

      await _player.setFilePath(tempPath);
      await _player.setSpeed(_playbackSpeed);
      await _player.play();

      _player.playerStateStream.listen((state) async {
        if (state.processingState == ProcessingState.completed) {
          try {
            await file.delete();
          } catch (e) {
            // Ignore deletion errors
          }
        }
      });
    } catch (e) {
      // Ignore playback errors
    }
  }

  Future<void> playAudioFromUrl(String url) async {
    try {
      await _player.setUrl(url);
      await _player.setSpeed(_playbackSpeed);
      await _player.play();
    } catch (e) {
      // Ignore playback errors
    }
  }

  Future<void> pausePlayback() async {
    try {
      await _player.pause();
    } catch (e) {
      // Ignore errors
    }
  }

  Future<void> resumePlayback() async {
    try {
      await _player.play();
    } catch (e) {
      // Ignore errors
    }
  }

  Future<void> stopPlayback() async {
    try {
      await _player.stop();
    } catch (e) {
      // Ignore errors
    }
  }

  Future<void> seekTo(Duration position) async {
    try {
      await _player.seek(position);
    } catch (e) {
      // Ignore errors
    }
  }

  bool get isPlaying => _player.playing;

  Stream<Duration> get positionStream => _player.positionStream;

  Duration? get duration => _player.duration;

  Duration? get currentPosition => _player.position;

  Future<void> dispose() async {
    await _recorder.dispose();
    await _player.dispose();
  }
}

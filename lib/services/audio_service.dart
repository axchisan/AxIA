import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';

class AudioService {
  final AudioRecorder _recorder = AudioRecorder();
  final Map<String, AudioPlayer> _players = {};
  bool _isRecording = false;
  String? _currentRecordingPath;
  DateTime? _recordingStartTime;

  bool get isRecording => _isRecording;
  Duration? get recordingDuration => _recordingStartTime != null 
      ? DateTime.now().difference(_recordingStartTime!) 
      : null;

  AudioPlayer getPlayerForMessage(String messageId) {
    if (!_players.containsKey(messageId)) {
      _players[messageId] = AudioPlayer();
    }
    return _players[messageId]!;
  }

  Future<void> stopAllExcept(String messageId) async {
    for (var entry in _players.entries) {
      if (entry.key != messageId && entry.value.playing) {
        await entry.value.pause();
      }
    }
  }

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

      final directory = await getApplicationDocumentsDirectory();
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

  Future<Map<String, dynamic>?> stopRecordingAndGetData() async {
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

      return {
        'base64': base64Audio,
        'localPath': path,
      };
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

  Future<void> setPlaybackSpeed(String messageId, double speed) async {
    final player = getPlayerForMessage(messageId);
    await player.setSpeed(speed);
  }

  double getPlaybackSpeed(String messageId) {
    final player = getPlayerForMessage(messageId);
    return player.speed;
  }

  Future<void> playAudioFromPath(String messageId, String filePath) async {
    try {
      await stopAllExcept(messageId);
      
      final player = getPlayerForMessage(messageId);
      await player.setFilePath(filePath);
      await player.play();
    } catch (e) {
      // Ignore playback errors
    }
  }

  Future<void> playAudioFromBase64(String messageId, String audioBase64) async {
    try {
      await stopAllExcept(messageId);
      
      final player = getPlayerForMessage(messageId);
      final bytes = base64Decode(audioBase64);
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final tempPath = '${directory.path}/axia_playback_${messageId}_$timestamp.m4a';
      
      final file = File(tempPath);
      await file.writeAsBytes(bytes);

      await player.setFilePath(tempPath);
      await player.play();

      player.playerStateStream.listen((state) async {
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

  Future<void> playAudioFromUrl(String messageId, String url) async {
    try {
      await stopAllExcept(messageId);
      
      final player = getPlayerForMessage(messageId);
      await player.setUrl(url);
      await player.play();
    } catch (e) {
      // Ignore playback errors
    }
  }

  Future<void> pausePlayback(String messageId) async {
    try {
      final player = getPlayerForMessage(messageId);
      await player.pause();
    } catch (e) {
      // Ignore errors
    }
  }

  Future<void> resumePlayback(String messageId) async {
    try {
      await stopAllExcept(messageId);
      
      final player = getPlayerForMessage(messageId);
      await player.play();
    } catch (e) {
      // Ignore errors
    }
  }

  Future<void> stopPlayback(String messageId) async {
    try {
      final player = getPlayerForMessage(messageId);
      await player.stop();
    } catch (e) {
      // Ignore errors
    }
  }

  Future<void> seekTo(String messageId, Duration position) async {
    try {
      final player = getPlayerForMessage(messageId);
      await player.seek(position);
    } catch (e) {
      // Ignore errors
    }
  }

  bool isPlaying(String messageId) {
    final player = getPlayerForMessage(messageId);
    return player.playing;
  }

  Stream<Duration> positionStream(String messageId) {
    final player = getPlayerForMessage(messageId);
    return player.positionStream;
  }

  Duration? getDuration(String messageId) {
    final player = getPlayerForMessage(messageId);
    return player.duration;
  }

  Duration? getCurrentPosition(String messageId) {
    final player = getPlayerForMessage(messageId);
    return player.position;
  }

  Future<void> dispose() async {
    await _recorder.dispose();
    for (var player in _players.values) {
      await player.dispose();
    }
    _players.clear();
  }
}

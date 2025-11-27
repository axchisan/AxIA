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

  bool get isRecording => _isRecording;

  Future<bool> requestPermission() async {
    try {
      final status = await Permission.microphone.request();
      return status.isGranted;
    } catch (e) {
      print('[AudioService] Error requesting permission: $e');
      return false;
    }
  }

  Future<bool> startRecording() async {
    try {
      if (_isRecording) {
        print('[AudioService] Already recording');
        return false;
      }

      final hasPermission = await requestPermission();
      if (!hasPermission) {
        print('[AudioService] Microphone permission not granted');
        return false;
      }

      // Get temporary directory for audio file
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentRecordingPath = '${directory.path}/axia_audio_$timestamp.m4a';

      // Check if recorder has permission
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
        print('[AudioService] Recording started: $_currentRecordingPath');
        return true;
      }
      return false;
    } catch (e) {
      print('[AudioService] Error starting recording: $e');
      _isRecording = false;
      return false;
    }
  }

  Future<String?> stopRecordingAndGetBase64() async {
    try {
      if (!_isRecording) {
        print('[AudioService] Not currently recording');
        return null;
      }

      final path = await _recorder.stop();
      _isRecording = false;

      if (path == null) {
        print('[AudioService] Recording path is null');
        return null;
      }

      print('[AudioService] Recording stopped: $path');

      // Read file and convert to base64
      final file = File(path);
      if (!await file.exists()) {
        print('[AudioService] Audio file does not exist');
        return null;
      }

      final bytes = await file.readAsBytes();
      final base64Audio = base64Encode(bytes);

      // Clean up temp file
      try {
        await file.delete();
      } catch (e) {
        print('[AudioService] Error deleting temp file: $e');
      }

      print('[AudioService] Audio converted to base64 (${base64Audio.length} chars)');
      return base64Audio;
    } catch (e) {
      print('[AudioService] Error stopping recording: $e');
      _isRecording = false;
      return null;
    }
  }

  Future<void> cancelRecording() async {
    try {
      if (_isRecording) {
        await _recorder.stop();
        _isRecording = false;
        
        // Delete the temp file if it exists
        if (_currentRecordingPath != null) {
          final file = File(_currentRecordingPath!);
          if (await file.exists()) {
            await file.delete();
          }
        }
        print('[AudioService] Recording cancelled');
      }
    } catch (e) {
      print('[AudioService] Error cancelling recording: $e');
    }
  }

  Future<void> playAudioFromBase64(String audioBase64) async {
    try {
      // Decode base64 to bytes
      final bytes = base64Decode(audioBase64);

      // Save to temporary file
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final tempPath = '${directory.path}/axia_playback_$timestamp.m4a';
      
      final file = File(tempPath);
      await file.writeAsBytes(bytes);

      // Play audio
      await _player.setFilePath(tempPath);
      await _player.play();

      // Clean up after playback
      _player.playerStateStream.listen((state) async {
        if (state.processingState == ProcessingState.completed) {
          try {
            await file.delete();
          } catch (e) {
            print('[AudioService] Error deleting playback file: $e');
          }
        }
      });

      print('[AudioService] Playing audio from base64');
    } catch (e) {
      print('[AudioService] Error playing audio: $e');
    }
  }

  Future<void> playAudioFromUrl(String url) async {
    try {
      await _player.setUrl(url);
      await _player.play();
      print('[AudioService] Playing audio from URL: $url');
    } catch (e) {
      print('[AudioService] Error playing audio from URL: $e');
    }
  }

  Future<void> stopPlayback() async {
    try {
      await _player.stop();
    } catch (e) {
      print('[AudioService] Error stopping playback: $e');
    }
  }

  bool get isPlaying => _player.playing;

  Stream<Duration> get positionStream => _player.positionStream;

  Duration? get duration => _player.duration;

  Future<void> dispose() async {
    await _recorder.dispose();
    await _player.dispose();
  }
}

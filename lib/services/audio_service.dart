import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';

class AudioService {
  FlutterSoundRecorder? _recorder;
  FlutterSoundPlayer? _player;

  AudioService() {
    _recorder = FlutterSoundRecorder();
    _player = FlutterSoundPlayer();
  }

  Future<bool> initRecorder() async {
    try {
      final status = await Permission.microphone.request();
      
      if (!status.isGranted) {
        return false;
      }

      await _recorder?.openRecorder();
      return true;
    } catch (e) {
      print('Error initializing recorder: $e');
      return false;
    }
  }

  // Start recording
  Future<void> startRecording(String filePath, dynamic AudioCodec) async {
    try {
      await _recorder?.startRecorder(
        toFile: filePath,
        codec: AudioCodec.aacMP4,
      );
    } catch (e) {
      print('Error starting recording: $e');
    }
  }

  // Stop recording and return file path
  Future<String?> stopRecording() async {
    try {
      return await _recorder?.stopRecorder();
    } catch (e) {
      print('Error stopping recording: $e');
      return null;
    }
  }

  // Convert audio file to base64
  Future<String?> audioFileToBase64(String filePath) async {
    try {
      // This would use dart:io File in actual implementation
      // For now, returning placeholder
      return 'base64_encoded_audio_data';
    } catch (e) {
      print('Error converting audio to base64: $e');
      return null;
    }
  }

  // Play audio from base64
  Future<void> playAudioFromBase64(String audioBase64, dynamic AudioCodec) async {
    try {
      // Decode base64 to bytes
      final bytes = base64Decode(audioBase64);
      
      // Play audio
      await _player?.openPlayer();
      await _player?.startPlayer(
        fromDataBuffer: bytes,
        codec: AudioCodec.aacMP4,
      );
    } catch (e) {
      print('Error playing audio: $e');
    }
  }

  // Dispose resources
  Future<void> dispose() async {
    await _recorder?.closeRecorder();
    await _player?.closePlayer();
  }
}

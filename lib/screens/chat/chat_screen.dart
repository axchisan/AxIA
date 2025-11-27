import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_typography.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/common/glass_card.dart';
import 'dart:async';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  // ignore: unused_field
  bool _isTyping = false;
  bool _isRecording = false;
  bool _isRecordingLocked = false;
  Timer? _recordingTimer;
  int _recordingSeconds = 0;
  double _slideOffset = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().initializeWebSocket();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _recordingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Consumer<ChatProvider>(
        builder: (context, chatProvider, _) {
          if (chatProvider.error != null) {
            return Column(
              children: [
                Container(
                  color: Colors.red.withOpacity(0.1),
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          chatProvider.error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                      TextButton(
                        onPressed: () => chatProvider.reconnect(),
                        child: const Text('Reconectar'),
                      ),
                    ],
                  ),
                ),
                Expanded(child: _buildChatBody(chatProvider)),
              ],
            );
          }

          return _buildChatBody(chatProvider);
        },
      ),
    );
  }

  Widget _buildChatBody(ChatProvider chatProvider) {
    return Column(
      children: [
        Expanded(
          child: Consumer<ChatProvider>(
            builder: (context, chatProvider, _) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_scrollController.hasClients) {
                  _scrollController.jumpTo(
                    _scrollController.position.maxScrollExtent,
                  );
                }
              });

              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                itemCount: chatProvider.messages.length,
                itemBuilder: (context, index) {
                  final message = chatProvider.messages[index];
                  final isUserMessage = message.sender.name == 'user';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Align(
                      alignment: isUserMessage
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: _buildMessageBubble(message, isUserMessage, chatProvider),
                    ),
                  );
                },
              );
            },
          ),
        ),
        _buildInputArea(chatProvider),
      ],
    );
  }

  Widget _buildInputArea(ChatProvider chatProvider) {
    final bool hasText = _messageController.text.isNotEmpty;
    
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgDarkSecondary,
        border: Border(
          top: BorderSide(
            color: AppColors.neonPurple.withOpacity(0.1),
          ),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              onChanged: (value) {
                setState(() {
                  _isTyping = value.isNotEmpty;
                });
              },
              style: AppTypography.body2.copyWith(
                color: AppColors.textDarkPrimary,
              ),
              maxLines: null,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: 'Escribe tu mensaje...',
                hintStyle: AppTypography.body2.copyWith(
                  color: AppColors.textDarkTertiary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: AppColors.neonPurple.withOpacity(0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(
                    color: AppColors.neonPurple,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          if (hasText)
            GestureDetector(
              onTap: chatProvider.isConnected
                  ? () {
                      final text = _messageController.text.trim();
                      if (text.isNotEmpty) {
                        chatProvider.sendMessage(text);
                        _messageController.clear();
                        setState(() => _isTyping = false);
                      }
                    }
                  : null,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: chatProvider.isConnected
                        ? AppColors.neonGradient
                        : [Colors.grey, Colors.grey],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.send_rounded,
                  color: chatProvider.isConnected ? Colors.white : Colors.grey.shade400,
                  size: 24,
                ),
              ),
            )
          else
            GestureDetector(
              onLongPressStart: (_) => _startVoiceRecording(chatProvider),
              onLongPressEnd: (_) => _stopVoiceRecording(chatProvider),
              onLongPressMoveUpdate: (details) {
                if (_isRecording && !_isRecordingLocked) {
                  setState(() {
                    _slideOffset = details.localOffsetFromOrigin.dy;
                    if (_slideOffset < -100) {
                      _lockRecording();
                    }
                  });
                }
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Recording indicator
                  if (_isRecording && !_isRecordingLocked)
                    Positioned(
                      bottom: 70,
                      child: Column(
                        children: [
                          Icon(
                            Icons.lock_open_rounded,
                            color: Colors.white.withOpacity(0.7),
                            size: 24,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Desliza arriba para fijar',
                            style: AppTypography.caption.copyWith(
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Timer
                  if (_isRecording)
                    Positioned(
                      right: 70,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatRecordingTime(_recordingSeconds),
                              style: AppTypography.body2.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Mic button
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _isRecording 
                            ? [Colors.red, Colors.red.shade700]
                            : AppColors.neonGradient,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: _isRecording
                          ? [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.5),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      _isRecordingLocked 
                          ? Icons.send_rounded
                          : (_isRecording ? Icons.stop_rounded : Icons.mic_rounded),
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _formatRecordingTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _lockRecording() {
    setState(() {
      _isRecordingLocked = true;
    });
    HapticFeedback.mediumImpact();
  }

  Future<void> _startVoiceRecording(ChatProvider chatProvider) async {
    final success = await chatProvider.audioService.startRecording();
    if (success) {
      setState(() {
        _isRecording = true;
        _recordingSeconds = 0;
        _isRecordingLocked = false;
        _slideOffset = 0;
      });
      HapticFeedback.mediumImpact();
      
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _recordingSeconds++;
        });
      });
    } else {
      _showSnackbar('No se pudo acceder al micrófono');
    }
  }

  Future<void> _stopVoiceRecording(ChatProvider chatProvider) async {
    if (!_isRecording) return;
    
    _recordingTimer?.cancel();
    
    if (_isRecordingLocked) {
      // Send the audio
      setState(() => _isRecording = false);
      HapticFeedback.lightImpact();
      
      final audioBase64 = await chatProvider.audioService.stopRecordingAndGetBase64();
      if (audioBase64 != null) {
        await chatProvider.sendAudioMessage(audioBase64);
      } else {
        _showSnackbar('Error al procesar el audio');
      }
      
      setState(() {
        _isRecordingLocked = false;
        _recordingSeconds = 0;
      });
    } else if (_recordingSeconds < 1) {
      // Too short, cancel
      await _cancelVoiceRecording(chatProvider);
    } else {
      // Send the audio
      setState(() => _isRecording = false);
      HapticFeedback.lightImpact();
      
      final audioBase64 = await chatProvider.audioService.stopRecordingAndGetBase64();
      if (audioBase64 != null) {
        await chatProvider.sendAudioMessage(audioBase64);
      } else {
        _showSnackbar('Error al procesar el audio');
      }
      
      setState(() {
        _recordingSeconds = 0;
      });
    }
  }

  Future<void> _cancelVoiceRecording(ChatProvider chatProvider) async {
    if (!_isRecording) return;
    
    _recordingTimer?.cancel();
    setState(() {
      _isRecording = false;
      _isRecordingLocked = false;
      _recordingSeconds = 0;
    });
    await chatProvider.audioService.cancelRecording();
    _showSnackbar('Grabación cancelada');
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.bgDarkCard,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: AppColors.neonGradient,
              ),
            ),
            child: const Icon(Icons.smart_toy_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AxIA',
                style: AppTypography.body1.copyWith(
                  color: AppColors.textDarkPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Consumer<ChatProvider>(
                builder: (context, chatProvider, _) {
                  return Text(
                    chatProvider.isConnected ? 'Activa • En línea' : 'Conectando...',
                    style: AppTypography.caption.copyWith(
                      color: chatProvider.isConnected
                          ? AppColors.statusAvailable
                          : Colors.orange,
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert_rounded),
          onPressed: () => _showChatOptions(),
        ),
      ],
    );
  }

  void _showChatOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgDarkSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildOptionTile(
              icon: Icons.delete_sweep_rounded,
              label: 'Vaciar chat',
              onTap: () {
                Navigator.pop(context);
                _showConfirmClearDialog();
              },
            ),
            _buildOptionTile(
              icon: Icons.refresh_rounded,
              label: 'Reconectar',
              onTap: () {
                Navigator.pop(context);
                context.read<ChatProvider>().reconnect();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showConfirmClearDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgDarkCard,
        title: Text(
          '¿Vaciar chat?',
          style: AppTypography.h5.copyWith(color: AppColors.textDarkPrimary),
        ),
        content: Text(
          'Esta acción eliminará todos los mensajes del historial.',
          style: AppTypography.body2.copyWith(color: AppColors.textDarkSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: TextStyle(color: AppColors.textDarkTertiary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<ChatProvider>().clearMessages();
            },
            child: const Text(
              'Vaciar',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.neonPurple),
      title: Text(
        label,
        style: AppTypography.body2.copyWith(
          color: AppColors.textDarkPrimary,
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildMessageBubble(dynamic message, bool isUserMessage, ChatProvider chatProvider) {
    final timeFormat = DateFormat('h:mm a');
    final timeString = timeFormat.format(message.timestamp);

    return GestureDetector(
      onLongPress: () => _showMessageOptions(message, chatProvider),
      child: GlassCard(
        backgroundColor: isUserMessage
            ? AppColors.primaryViolet
            : AppColors.bgDarkCard,
        borderRadius: BorderRadius.circular(16),
        border: isUserMessage
            ? null
            : Border.all(
                color: AppColors.neonPurple.withOpacity(0.2),
              ),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (message.isVoice) ...[
                _buildAudioPlayer(message, isUserMessage, chatProvider),
                const SizedBox(height: 8),
              ],
              if (isUserMessage)
                Text(
                  message.content,
                  style: AppTypography.body2.copyWith(
                    color: Colors.white,
                  ),
                )
              else
                MarkdownBody(
                  data: message.content,
                  styleSheet: MarkdownStyleSheet(
                    p: AppTypography.body2.copyWith(
                      color: AppColors.textDarkPrimary,
                    ),
                    h1: AppTypography.h3.copyWith(
                      color: AppColors.neonPurple,
                    ),
                    h2: AppTypography.h4.copyWith(
                      color: AppColors.neonPurple,
                    ),
                    h3: AppTypography.h5.copyWith(
                      color: AppColors.neonCyan,
                    ),
                    strong: AppTypography.body2.copyWith(
                      color: AppColors.textDarkPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                    em: AppTypography.body2.copyWith(
                      color: AppColors.textDarkSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                    code: AppTypography.body2.copyWith(
                      color: AppColors.neonPink,
                      fontFamily: 'monospace',
                      backgroundColor: AppColors.bgDarkSecondary,
                    ),
                    listBullet: AppTypography.body2.copyWith(
                      color: AppColors.neonPurple,
                    ),
                  ),
                ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    timeString,
                    style: AppTypography.caption.copyWith(
                      color: isUserMessage
                          ? Colors.white.withOpacity(0.7)
                          : AppColors.textDarkTertiary,
                    ),
                  ),
                  if (isUserMessage) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAudioPlayer(dynamic message, bool isUserMessage, ChatProvider chatProvider) {
    final messageId = message.id;
    
    return StreamBuilder<Duration>(
      stream: chatProvider.audioService.positionStream(messageId),
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        final duration = chatProvider.audioService.getDuration(messageId) ?? Duration.zero;
        final isPlaying = chatProvider.audioService.isPlaying(messageId);

        return Column(
          children: [
            Row(
              children: [
                // Play/Pause button
                GestureDetector(
                  onTap: () async {
                    if (isPlaying) {
                      await chatProvider.audioService.pausePlayback(messageId);
                    } else {
                      if (message.audioBase64 != null) {
                        await chatProvider.audioService.playAudioFromBase64(messageId, message.audioBase64);
                      } else if (message.audioUrl != null) {
                        await chatProvider.audioService.playAudioFromUrl(messageId, message.audioUrl);
                      }
                    }
                    setState(() {});
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isUserMessage 
                          ? Colors.white.withOpacity(0.2)
                          : AppColors.neonPurple.withOpacity(0.2),
                    ),
                    child: Icon(
                      isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: isUserMessage ? Colors.white : AppColors.neonPurple,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Progress bar
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 3,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                          activeTrackColor: isUserMessage ? Colors.white : AppColors.neonPurple,
                          inactiveTrackColor: isUserMessage 
                              ? Colors.white.withOpacity(0.3)
                              : AppColors.neonPurple.withOpacity(0.3),
                          thumbColor: isUserMessage ? Colors.white : AppColors.neonPurple,
                        ),
                        child: Slider(
                          value: duration.inMilliseconds > 0 
                              ? position.inMilliseconds.toDouble().clamp(0.0, duration.inMilliseconds.toDouble())
                              : 0,
                          max: duration.inMilliseconds > 0 ? duration.inMilliseconds.toDouble() : 1.0,
                          onChanged: (value) async {
                            await chatProvider.audioService.seekTo(
                              messageId,
                              Duration(milliseconds: value.toInt()),
                            );
                          },
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(position),
                            style: AppTypography.caption.copyWith(
                              color: isUserMessage 
                                  ? Colors.white.withOpacity(0.7)
                                  : AppColors.textDarkTertiary,
                            ),
                          ),
                          Text(
                            _formatDuration(duration),
                            style: AppTypography.caption.copyWith(
                              color: isUserMessage 
                                  ? Colors.white.withOpacity(0.7)
                                  : AppColors.textDarkTertiary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Speed control
                PopupMenuButton<double>(
                  icon: Icon(
                    Icons.speed_rounded,
                    color: isUserMessage ? Colors.white : AppColors.neonPurple,
                    size: 20,
                  ),
                  color: AppColors.bgDarkCard,
                  onSelected: (speed) async {
                    await chatProvider.audioService.setPlaybackSpeed(messageId, speed);
                    setState(() {});
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 0.5, child: Text('0.5x')),
                    const PopupMenuItem(value: 0.75, child: Text('0.75x')),
                    const PopupMenuItem(value: 1.0, child: Text('1.0x')),
                    const PopupMenuItem(value: 1.25, child: Text('1.25x')),
                    const PopupMenuItem(value: 1.5, child: Text('1.5x')),
                    const PopupMenuItem(value: 2.0, child: Text('2.0x')),
                  ],
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(1, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _showMessageOptions(dynamic message, ChatProvider chatProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgDarkSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildOptionTile(
              icon: Icons.copy_rounded,
              label: 'Copiar',
              onTap: () {
                Clipboard.setData(ClipboardData(text: message.content));
                Navigator.pop(context);
                _showSnackbar('Mensaje copiado');
              },
            ),
            _buildOptionTile(
              icon: Icons.delete_outline_rounded,
              label: 'Eliminar',
              onTap: () {
                Navigator.pop(context);
                chatProvider.deleteMessage(message.id);
                _showSnackbar('Mensaje eliminado');
              },
            ),
          ],
        ),
      ),
    );
  }
}

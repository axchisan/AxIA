import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_typography.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/common/glass_card.dart';

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
  late List<AnimationController> _dotAnimations;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().initializeWebSocket();
    });

    _dotAnimations = List.generate(3, (index) {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      );
      controller.repeat(
        min: 0.0,
        max: 1.0,
        period: const Duration(milliseconds: 1200),
      );
      return controller;
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    for (var controller in _dotAnimations) {
      controller.dispose();
    }
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
                  _scrollController.animateTo(
                    _scrollController.position.maxScrollExtent,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
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
                      child: _buildMessageBubble(message, isUserMessage),
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
              onLongPressCancel: () => _cancelVoiceRecording(chatProvider),
              child: AnimatedContainer(
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
                  _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _startVoiceRecording(ChatProvider chatProvider) async {
    final success = await chatProvider.audioService.startRecording();
    if (success) {
      setState(() => _isRecording = true);
      HapticFeedback.mediumImpact();
    } else {
      _showSnackbar('No se pudo acceder al micrófono');
    }
  }

  Future<void> _stopVoiceRecording(ChatProvider chatProvider) async {
    if (!_isRecording) return;
    
    setState(() => _isRecording = false);
    HapticFeedback.lightImpact();
    
    final audioBase64 = await chatProvider.audioService.stopRecordingAndGetBase64();
    if (audioBase64 != null) {
      await chatProvider.sendAudioMessage(audioBase64);
    } else {
      _showSnackbar('Error al procesar el audio');
    }
  }

  Future<void> _cancelVoiceRecording(ChatProvider chatProvider) async {
    if (!_isRecording) return;
    
    setState(() => _isRecording = false);
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
              label: 'Limpiar chat',
              onTap: () {
                Navigator.pop(context);
                context.read<ChatProvider>().clearMessages();
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

  Widget _buildMessageBubble(dynamic message, bool isUserMessage) {
    return GestureDetector(
      onLongPress: () => _showMessageOptions(message),
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
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.mic_rounded,
                      size: 20,
                      color: isUserMessage ? Colors.white : AppColors.neonPurple,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: isUserMessage
                              ? Colors.white.withOpacity(0.3)
                              : AppColors.neonPurple.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ],
                ),
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
                    '${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}',
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

  void _showMessageOptions(dynamic message) {
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
          ],
        ),
      ),
    );
  }
}

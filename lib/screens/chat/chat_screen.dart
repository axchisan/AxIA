import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  bool _isTyping = false;
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
                      Icon(Icons.error_outline, color: Colors.red),
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
                itemCount: chatProvider.messages.length + (_isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == chatProvider.messages.length && _isTyping) {
                    return _buildTypingIndicator();
                  }

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

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: GlassCard(
        backgroundColor: AppColors.bgDarkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.neonPurple.withOpacity(0.2),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDot(0),
            const SizedBox(width: 4),
            _buildDot(1),
            const SizedBox(width: 4),
            _buildDot(2),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedBuilder(
      animation: _dotAnimations[index],
      builder: (context, child) {
        final value = _dotAnimations[index].value;
        return Transform.translate(
          offset: Offset(0, -(value * 8)),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.neonPurple,
            ),
          ),
        );
      },
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
          GestureDetector(
            onTap: () => _showInputOptions(),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bgDarkCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.neonPurple.withOpacity(0.2),
                ),
              ),
              child: Icon(
                Icons.add_rounded,
                color: AppColors.neonPurple,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _messageController,
              onChanged: (value) {
                setState(() => _isTyping = value.isNotEmpty);
              },
              style: AppTypography.body2.copyWith(
                color: AppColors.textDarkPrimary,
              ),
              maxLines: null,
              decoration: InputDecoration(
                hintText: 'Escribe tu mensaje...',
                hintStyle: AppTypography.body2.copyWith(
                  color: AppColors.textDarkTertiary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.neonPurple.withOpacity(0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.neonPurple,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
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
                      chatProvider.sendMessage(_messageController.text);
                      _messageController.clear();
                      setState(() => _isTyping = false);
                    }
                  : null,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: chatProvider.isConnected
                        ? AppColors.neonGradient
                        : [Colors.grey, Colors.grey],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.send_rounded,
                  color: chatProvider.isConnected ? Colors.white : Colors.grey,
                  size: 24,
                ),
              ),
            )
          else
            GestureDetector(
              onTap: () => _sendVoiceMessage(),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: AppColors.neonGradient,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.mic_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showInputOptions() {
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
              icon: Icons.mic_rounded,
              label: 'Mensaje de Voz',
              onTap: () {
                Navigator.pop(context);
                _sendVoiceMessage();
              },
            ),
            _buildOptionTile(
              icon: Icons.image_rounded,
              label: 'Imagen',
              onTap: () {
                Navigator.pop(context);
              },
            ),
            _buildOptionTile(
              icon: Icons.schedule_rounded,
              label: 'Agendar',
              onTap: () {
                Navigator.pop(context);
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

  void _sendVoiceMessage() {
    // TODO: Implement actual voice recording
    context.read<ChatProvider>().sendMessage('🎤 Mensaje de voz (próximamente)');
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
              onTap: () => Navigator.pop(context),
            ),
            _buildOptionTile(
              icon: Icons.delete_rounded,
              label: 'Eliminar',
              onTap: () => Navigator.pop(context),
            ),
            _buildOptionTile(
              icon: Icons.star_rounded,
              label: 'Marcar',
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
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
          icon: const Icon(Icons.call_rounded),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.more_vert_rounded),
          onPressed: () {},
        ),
      ],
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
                    Container(
                      width: 120,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isUserMessage
                            ? Colors.white.withOpacity(0.3)
                            : AppColors.neonPurple.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              Text(
                message.content,
                style: AppTypography.body2.copyWith(
                  color: isUserMessage
                      ? Colors.white
                      : AppColors.textDarkPrimary,
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
}

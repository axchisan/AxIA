import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_typography.dart';
import '../../../providers/chat_provider.dart';

class RecentChats extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, _) {
        final lastMessages = chatProvider.messages.length > 3
            ? chatProvider.messages.sublist(chatProvider.messages.length - 3)
            : chatProvider.messages;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Últimos Mensajes',
                  style: AppTypography.body1.copyWith(
                    color: AppColors.textDarkPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                GestureDetector(
                  onTap: () {},
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: AppColors.neonPurple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: lastMessages.length,
              itemBuilder: (context, index) {
                final message = lastMessages[index];
                final isUserMessage = message.sender.name == 'user';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Align(
                    alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.7,
                      ),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isUserMessage ? AppColors.primaryViolet : AppColors.bgDarkCard,
                        borderRadius: BorderRadius.circular(12),
                        border: isUserMessage
                            ? null
                            : Border.all(
                                color: AppColors.neonPurple.withOpacity(0.2),
                              ),
                      ),
                      child: Text(
                        message.content,
                        style: AppTypography.body2.copyWith(
                          color: isUserMessage ? Colors.white : AppColors.textDarkPrimary,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

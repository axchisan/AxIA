// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_typography.dart';
import '../../providers/presence_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/routine_provider.dart';
import '../../providers/theme_provider.dart';
import 'widgets/greeting_card.dart';
import 'widgets/presence_widget.dart';
import 'widgets/quick_routines.dart';
import 'widgets/recent_chats.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat();
    
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final presenceProvider = context.read<PresenceProvider>();
    final routineProvider = context.read<RoutineProvider>();
    final chatProvider = context.read<ChatProvider>();
    
    await Future.wait([
      presenceProvider.loadPresence(),
      routineProvider.loadRoutines(),
      chatProvider.initializeWebSocket(),
    ]);
  }

  Future<void> _refreshData() async {
    await _loadInitialData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          SafeArea(
            child: RefreshIndicator(
              onRefresh: _refreshData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 24),
                      const GreetingCard(),
                      const SizedBox(height: 24),
                      PresenceWidget(),
                      const SizedBox(height: 24),
                      QuickRoutines(),
                      const SizedBox(height: 24),
                      RecentChats(),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.bgDarkPrimary,
            AppColors.bgDarkSecondary.withOpacity(0.8),
          ],
        ),
      ),
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return CustomPaint(
            painter: _BackgroundPainter(
              animationValue: _animationController.value,
            ),
            child: Container(),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AxIA',
              style: AppTypography.h2.copyWith(
                color: AppColors.neonPurple,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Control Center',
              style: AppTypography.caption.copyWith(
                color: AppColors.textDarkSecondary,
              ),
            ),
          ],
        ),
        Consumer<ThemeProvider>(
          builder: (context, themeProvider, _) {
            return Container(
              decoration: BoxDecoration(
                color: AppColors.bgDarkSecondary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.neonPurple.withOpacity(0.3),
                ),
              ),
              child: IconButton(
                icon: Icon(
                  themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  color: AppColors.neonPurple,
                ),
                onPressed: () => themeProvider.toggleTheme(),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  final double animationValue;

  _BackgroundPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.neonPurple.withOpacity(0.08),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(
          size.width * 0.8 + (animationValue * 20),
          size.height * 0.2 + (animationValue * 20),
        ),
        radius: 150,
      ));

    canvas.drawCircle(
      Offset(
        size.width * 0.8 + (animationValue * 20),
        size.height * 0.2 + (animationValue * 20),
      ),
      150,
      paint,
    );
  }

  @override
  bool shouldRepaint(_BackgroundPainter oldDelegate) {
    return animationValue != oldDelegate.animationValue;
  }
}

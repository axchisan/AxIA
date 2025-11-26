import 'package:flutter/material.dart';
import '../config/theme/app_colors.dart';
import '../config/theme/app_typography.dart';
import 'dashboard/dashboard_screen.dart';
import 'chat/chat_screen.dart';
import 'presence/presence_screen.dart';
import 'routines/routines_screen.dart';
import 'notes/notes_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({Key? key}) : super(key: key);

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const ChatScreen(),
    const PresenceScreen(),
    const RoutinesScreen(),
    const NotesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgDarkSecondary,
        border: Border(
          top: BorderSide(
            color: AppColors.neonPurple.withOpacity(0.2),
          ),
        ),
      ),
      child: BottomNavigationBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: AppColors.neonPurple,
        unselectedItemColor: AppColors.textDarkTertiary,
        selectedLabelStyle: AppTypography.caption.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTypography.caption,
        onTap: (index) {
          setState(() => _selectedIndex = index);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_rounded),
            label: 'AxIA',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.radio_button_checked_rounded),
            label: 'Presencia',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.checklist_rounded),
            label: 'Rutinas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.note_rounded),
            label: 'Notas',
          ),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: () => _navigateTo(context),
      backgroundColor: AppColors.primaryViolet,
      elevation: 8,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.mic_rounded),
          const SizedBox(width: 8),
          Text(
            'Hey AxIA',
            style: AppTypography.button.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }

  void _navigateTo(BuildContext context) {
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
            Text(
              'Ir a...',
              style: AppTypography.h3.copyWith(
                color: AppColors.textDarkPrimary,
              ),
            ),
            const SizedBox(height: 20),
            ...List.generate(
              _screens.length,
              (index) => ListTile(
                leading: Icon(
                  [
                    Icons.dashboard_rounded,
                    Icons.chat_rounded,
                    Icons.radio_button_checked_rounded,
                    Icons.checklist_rounded,
                    Icons.note_rounded,
                  ][index],
                  color: AppColors.neonPurple,
                ),
                title: Text(
                  ['Dashboard', 'Chat', 'Presencia', 'Rutinas', 'Notas'][index],
                  style: AppTypography.body2.copyWith(
                    color: AppColors.textDarkPrimary,
                  ),
                ),
                onTap: () {
                  setState(() => _selectedIndex = index);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

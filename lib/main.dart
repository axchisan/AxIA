import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'config/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/presence_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/routine_provider.dart';
import 'providers/notes_provider.dart';
import 'providers/projects_provider.dart';
import 'providers/calendar_provider.dart';
import 'providers/tasks_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/main_navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Hive para almacenamiento local
  await Hive.initFlutter();
  
  runApp(
    MultiProvider(
      providers: [
        // Authentication & Core
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        
        // Main Features
        ChangeNotifierProvider(create: (_) => PresenceProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => RoutineProvider()),
        ChangeNotifierProvider(create: (_) => NotesProvider()),
        ChangeNotifierProvider(create: (_) => ProjectsProvider()),
        
        ChangeNotifierProvider(create: (_) => CalendarProvider()),
        ChangeNotifierProvider(create: (_) => TasksProvider()),
      ],
      child: const AxiaApp(),
    ),
  );
}

class AxiaApp extends StatelessWidget {
  const AxiaApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          title: 'AxIA',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          themeAnimationDuration: const Duration(milliseconds: 300),
          themeAnimationCurve: Curves.easeInOut,
          home: const SplashScreen(),
          routes: {
            '/login': (context) => const LoginScreen(),
            '/home': (context) => const MainNavigation(),
            '/splash': (context) => const SplashScreen(),
          },
        );
      },
    );
  }
}

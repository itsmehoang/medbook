import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/main_shell_screen.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart';
import 'state/auth_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AppScreen());
}

class AppScreen extends StatelessWidget {
  const AppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'MEDBOOK - Đặt Lịch Khám Bệnh',
        theme: const AppTheme().themeData,
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (authProvider.isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppTheme.elevatedShadow,
                ),
                child: const Icon(Icons.local_hospital_rounded, color: Colors.white, size: 38),
              ),
              const SizedBox(height: 16),
              const Text(
                'MEDBOOK',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  letterSpacing: 2,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 20),
              const CircularProgressIndicator(color: AppTheme.primaryColor, strokeWidth: 2),
            ],
          ),
        ),
      );
    }

    if (authProvider.isAuthenticated) {
      return const MainShellScreen();
    } else {
      return const LoginScreen();
    }
  }
}

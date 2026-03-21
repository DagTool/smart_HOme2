import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'providers/auth_provider.dart';
import 'providers/device_provider.dart';
import 'providers/home_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/join_home_screen.dart';

// ⚠️ Thay bằng cấu hình Firebase của bạn
// Chạy: flutterfire configure để tự động tạo file này
// Hoặc tạo thủ công theo hướng dẫn bên dưới
const firebaseOptions = FirebaseOptions(
  apiKey: 'AIzaSyD82KraoFEv1uhaEHVBiS6u5otSSVGJoxk',
  appId: '1:941940225099:web:b34103b02269a8f20ac9ce',
  messagingSenderId: '941940225099',
  projectId: 'henhung-99234',
  databaseURL:
      'https://henhung-99234-default-rtdb.asia-southeast1.firebasedatabase.app/',
  storageBucket: 'henhung-99234.appspot.com',
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: firebaseOptions);
  runApp(const SmartHomeApp());
}

class SmartHomeApp extends StatelessWidget {
  const SmartHomeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppAuthProvider()),
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        ChangeNotifierProvider(create: (_) => DeviceProvider()),
      ],
      child: MaterialApp(
        title: 'Smart Home',
        debugShowCheckedModeBanner: false,
        theme: _buildDarkTheme(),
        initialRoute: '/',
        routes: {
          '/': (_) => const AppRouter(),
          '/login': (_) => const LoginScreen(),
          '/register': (_) => const RegisterScreen(),
          '/dashboard': (_) => const DashboardScreen(),
          '/join': (_) => const JoinHomeScreen(),
        },
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    const bg = Color(0xFF0A0E1A);
    const surface = Color(0xFF111827);
    const card = Color(0xFF1A2235);
    const primary = Color(0xFF3B82F6);
    const accent = Color(0xFF06B6D4);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: accent,
        surface: surface,
        onPrimary: Colors.white,
        onSurface: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      textTheme: GoogleFonts.spaceGroteskTextTheme(
        const TextTheme(
          displayLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          headlineMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          titleMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
          bodyMedium: TextStyle(color: Color(0xFFB0B8CC)),
          bodySmall: TextStyle(color: Color(0xFF6B7280)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
    );
  }
}

/// Router chính: kiểm tra trạng thái auth và điều hướng
class AppRouter extends StatelessWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        if (snapshot.hasData && snapshot.data != null) {
          // Đã đăng nhập → kiểm tra xem có house_id chưa
          return const HomeChecker();
        }

        return const LoginScreen();
      },
    );
  }
}

/// Kiểm tra user có thuộc nhà nào chưa
class HomeChecker extends StatefulWidget {
  const HomeChecker({super.key});

  @override
  State<HomeChecker> createState() => _HomeCheckerState();
}

class _HomeCheckerState extends State<HomeChecker> {
  @override
  void initState() {
    super.initState();
    _checkHome();
  }

  Future<void> _checkHome() async {
    final homeProvider = context.read<HomeProvider>();
    await homeProvider.loadHouseId();

    if (!mounted) return;

    if (homeProvider.houseId != null) {
      // Đã có nhà → load devices và vào Dashboard
      context.read<DeviceProvider>().init(homeProvider.houseId!);
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else {
      // Chưa có nhà → màn hình nhập mã mời hoặc tạo nhà
      Navigator.pushReplacementNamed(context, '/join');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}

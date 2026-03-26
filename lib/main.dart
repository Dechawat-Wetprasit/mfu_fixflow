import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mfu_fixflow/features/auth/login_screen.dart';
import 'package:mfu_fixflow/features/auth/role_selection_screen.dart';
import 'package:mfu_fixflow/supabase_config.dart';
import 'package:mfu_fixflow/services/notification_service.dart';
import 'package:mfu_fixflow/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 0. Load environment variables from .env
  await dotenv.load(fileName: ".env");

  // 1. Initialise Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print("Firebase init error: $e");
  }

  // 2. Initialise Supabase
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  // 3. เริ่มต้นเปิดระบบรับแจ้งเตือน (ขอ Permission + บันทึก Token)
  try {
    await NotificationService().initialize();
  } catch (e) {
    print("Notification Service error: $e");
  }

  // 4. รอฟังสถานะล็อกอิน - ถ้าล็อกอินใหม่ให้อัปเดต Token ทันที
  Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
    final AuthChangeEvent event = data.event;
    if (event == AuthChangeEvent.signedIn || event == AuthChangeEvent.initialSession) {
      try {
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null) {
          await NotificationService().saveTokenToSupabase(token);
        }
      } catch (e) {
        print("Error updating token on login: $e");
      }
    } else if (event == AuthChangeEvent.signedOut) {
      try {
        await FirebaseMessaging.instance.deleteToken();
      } catch (e) {
        print("Error deleting token on logout: $e");
      }
    }
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MFU FIXFLOW',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFFA51C30),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFA51C30),
          primary: const Color(0xFFA51C30),
          secondary: const Color(0xFFD4AF37),
        ),
        useMaterial3: true,
      ),

      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('th'),
        Locale('en'),
      ],

      home: Supabase.instance.client.auth.currentUser == null
          ? const LoginScreen()
          : const RoleSelectionScreen(),
    );
  }
}

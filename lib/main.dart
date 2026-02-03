import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // ✅ Import นี้ถูกต้องแล้ว
// 🔥 Import 2 ไฟล์นี้ เพื่อใช้ระบบตรวจสอบสิทธิ์
import 'package:mfu_fixflow/features/auth/login_screen.dart';
import 'package:mfu_fixflow/features/auth/role_selection_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://vebcqfkgzhkgcryzlrhu.supabase.co',
    anonKey: 'sb_publishable_BWPg6rBqnEcdcIDb7VDotA_Grh2btCw',
  );

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

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // จำเป็นต้องมีสำหรับตอนที่แอปลดพับและมี Push notification เข้าทา
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  Future<void> initialize() async {
    // กำหนด Callback ทำงานเบื้องหลัง (Background)
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // ขออนุญาตรับแจ้งเตือนจากผู้ใช้
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else {
      print('User declined or has not accepted permission');
    }

    // อ่าน FCM Token ปัจจุบันของเครื่อง
    String? token = await _fcm.getToken();
    print("FCM Token: $token");
    if (token != null) {
      await saveTokenToSupabase(token);
    }

    // กรณี Token ฝั่งเซิร์ฟเวอร์ Firebase มีการรีเฟรช (เช่น ลบแอป หรือนานเกินไป)
    _fcm.onTokenRefresh.listen((newToken) {
      saveTokenToSupabase(newToken);
    });

    // กำหนดการทำงานขณะเปิดแอปอยู่แต่อยู่หน้าอื่น (Foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a notification in foreground: ${message.notification?.title}');
      // อนาคตสามารถนำมาต่อกับระบบ Snackbar / Alert Dialog เพื่อโชว์ในแอปตอนกำลังใช้
    });
  }

  // ระบบดึงข้อมูลผู้ใช้ปัจจุบันและอัปโหลด Token ไปที่ Supabase
  Future<void> saveTokenToSupabase(String fcmToken) async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    
    if (user != null) {
      try {
        final existingTokens = await supabase.from('push_tokens').select('id').eq('user_id', user.id);
        if (existingTokens.isNotEmpty) {
          await supabase.from('push_tokens').update({
            'fcm_token': fcmToken,
            'platform': Platform.operatingSystem,
            'updated_at': DateTime.now().toIso8601String(),
          }).eq('user_id', user.id);
        } else {
          await supabase.from('push_tokens').insert({
            'user_id': user.id,
            'fcm_token': fcmToken,
            'platform': Platform.operatingSystem,
            'updated_at': DateTime.now().toIso8601String(),
          });
        }
        print('FCM Token saved to push_tokens successfully.');
      } catch (e) {
        print('Failed to save FCM token: $e');
      }
    } else {
      print('Cannot save token: User not logged in.');
    }
  }

  // ฟังก์ชันสำหรับส่งแจ้งเตือนจากในตัวแอป (API Call)
  Future<void> sendFCMNotification({
    required String targetUserId,
    required String title,
    required String body,
    String? recordId, // ไอดีของงานหรือรายงานที่เกี่ยวข้อง
    String action = 'report_update',
  }) async {
    // ป้องกัน null/empty fields ก่อนส่งไปยัง Edge Function
    if (targetUserId.isEmpty || title.isEmpty || body.isEmpty) {
      debugPrint('[FCM] Skipped: targetUserId, title, or body is empty.');
      return;
    }

    final supabase = Supabase.instance.client;

    // ใช้ http package เรียก Edge Function โดยตรงเพื่อแก้ปัญหา 401
    try {
      debugPrint('[FCM] Sending to user: $targetUserId, title: "$title"');
      
      const supabaseUrl = 'https://vebcqfkgzhkgcryzlrhu.supabase.co';
      const anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZlYmNxZmtnemhrZ2NyeXpscmh1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg3NDA1MDgsImV4cCI6MjA4NDMxNjUwOH0.Za4NWx1wAc00EmKtk6UGwnAxzRPTWzvh0k-cMJHBKNE';

      final res = await http.post(
        Uri.parse('$supabaseUrl/functions/v1/send-notification'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $anonKey',
          'apikey': anonKey,
        },
        body: jsonEncode({
          'target_user_id': targetUserId,
          'title': title,
          'body': body,
          'record_id': recordId ?? '',
          'action': action,
        }),
      );

      debugPrint('[FCM] Response ${res.statusCode}: ${res.body}');
    } catch (error) {
      debugPrint('[FCM] Failed to trigger Push Notification: $error');
    }
  }
}

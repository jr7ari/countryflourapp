import 'dart:async';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../data/models/notification_model.dart';
import '../../presentation/providers/notifications_provider.dart';

// Top-level background message handler — must be a top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialised by the time this is called.
  debugPrint('[FCM] Background message: ${message.messageId}');
  // Background messages are stored when the app comes back to foreground
  // via the getInitialMessage flow in init()
}

class FcmService {
  FcmService._();

  static const _baseUrl = 'https://www.countryflour.in/api/mobileapi';

  static StreamSubscription<String>? _refreshSub;
  static StreamSubscription<RemoteMessage>? _foregroundSub;

  // ── Call once after login / session restore ───────────────────────────────
  static Future<void> init(String jwtToken, {WidgetRef? ref}) async {
    final messaging = FirebaseMessaging.instance;

    // Register background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // iOS foreground notification presentation
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Request permission (Android 13+ and iOS)
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('[FCM] Permission denied');
      return;
    }

    // Get current token and send to server
    final token = await messaging.getToken();
    if (token != null) {
      await _sendToken(token, jwtToken);
    }

    // Cancel any previous subscriptions before re-subscribing
    await _refreshSub?.cancel();
    await _foregroundSub?.cancel();

    // Listen for token refresh
    _refreshSub = messaging.onTokenRefresh.listen((newToken) {
      debugPrint('[FCM] Token refreshed');
      _sendToken(newToken, jwtToken);
    });

    // ── Handle messages and persist to local store ────────────────────────

    // 1. App was terminated — opened via notification tap
    final initial = await messaging.getInitialMessage();
    if (initial != null) _storeMessage(initial);

    // 2. App in foreground
    _foregroundSub = FirebaseMessaging.onMessage.listen((message) {
      debugPrint('[FCM] Foreground message: ${message.notification?.title}');
      _storeMessage(message);
    });

    // 3. App in background — user tapped notification
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('[FCM] Opened from background: ${message.notification?.title}');
      _storeMessage(message);
    });
  }

  // ── Call on logout ────────────────────────────────────────────────────────
  static Future<void> dispose() async {
    await _refreshSub?.cancel();
    await _foregroundSub?.cancel();
    _refreshSub = null;
    _foregroundSub = null;
    await FirebaseMessaging.instance.deleteToken();
  }

  // ── Store received message as AppNotification ─────────────────────────────
  static void _storeMessage(RemoteMessage message) {
    final notification = message.notification;
    final title = notification?.title ?? message.data['title'] ?? '';
    final body = notification?.body ?? message.data['body'] ?? '';
    if (title.isEmpty && body.isEmpty) return;

    final appNotification = AppNotification(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      type: AppNotification.typeFromData(message.data),
      receivedAt: message.sentTime ?? DateTime.now(),
      data: message.data,
    );

    // Use SharedPreferences directly here since we may not have a Riverpod ref
    // The NotificationsNotifier will load from storage on next app start.
    // If we have a live container reference, we update state immediately.
    _container?.read(notificationsProvider.notifier).add(appNotification);
  }

  // ── Riverpod container ref for live state updates ─────────────────────────
  static ProviderContainer? _container;

  static void setContainer(ProviderContainer container) {
    _container = container;
  }

  // ── POST token to backend ─────────────────────────────────────────────────
  static Future<void> _sendToken(String fcmToken, String jwtToken) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/fcm-token'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'fcmToken': fcmToken}),
      );
      debugPrint('[FCM] Token sent — status ${response.statusCode}');
    } catch (e) {
      debugPrint('[FCM] Failed to send token: $e');
    }
  }
}

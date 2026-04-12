import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/notification_model.dart';

const _kNotificationsKey = 'cf_notifications';
const _kMaxStored = 50;

class NotificationsNotifier extends StateNotifier<List<AppNotification>> {
  NotificationsNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kNotificationsKey);
    if (raw == null) return;
    try {
      final list = (jsonDecode(raw) as List)
          .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
          .toList();
      state = list;
    } catch (_) {}
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kNotificationsKey,
      jsonEncode(state.map((n) => n.toJson()).toList()),
    );
  }

  void add(AppNotification notification) {
    // Deduplicate by id
    if (state.any((n) => n.id == notification.id)) return;
    final updated = [notification, ...state];
    // Keep only latest N
    state = updated.length > _kMaxStored
        ? updated.sublist(0, _kMaxStored)
        : updated;
    _save();
  }

  void markRead(String id) {
    state = state
        .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
        .toList();
    _save();
  }

  void markAllRead() {
    state = state.map((n) => n.copyWith(isRead: true)).toList();
    _save();
  }

  void delete(String id) {
    state = state.where((n) => n.id != id).toList();
    _save();
  }

  void clearAll() {
    state = [];
    _save();
  }

  int get unreadCount => state.where((n) => !n.isRead).length;
}

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, List<AppNotification>>(
  (ref) => NotificationsNotifier(),
);

final unreadCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsProvider).where((n) => !n.isRead).length;
});

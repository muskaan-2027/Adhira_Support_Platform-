import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class NotificationProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = false;
  Timer? _pollingTimer;

  List<Map<String, dynamic>> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => n['isRead'] == false).length;
  bool get isLoading => _isLoading;

  void startPolling(AuthService authService) {
    _fetchNotifications(authService);
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _fetchNotifications(authService);
    });
  }

  void stopPolling() {
    _pollingTimer?.cancel();
  }

  Future<void> _fetchNotifications(AuthService authService) async {
    final token = authService.token;
    if (token == null) return;

    if (_notifications.isEmpty) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final response = await ApiService.getNotifications(token);
      final List<dynamic> data = response['notifications'] ?? [];
      _notifications = data.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(AuthService authService) async {
    final token = authService.token;
    if (token == null) return;

    if (unreadCount == 0) return;

    // Optimistic update
    for (var n in _notifications) {
      n['isRead'] = true;
    }
    notifyListeners();

    try {
      await ApiService.markNotificationsRead(token);
    } catch (e) {
      debugPrint('Error marking notifications as read: $e');
      // In a real app, you might want to revert the optimistic update here if it fails
    }
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}

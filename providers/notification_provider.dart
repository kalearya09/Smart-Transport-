import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';

class NotificationProvider extends ChangeNotifier {
  final _uuid = const Uuid();
  List<AppNotification> _list = [];
  int _unread = 0;

  List<AppNotification> get list   => _list;
  int                   get unread => _unread;

  NotificationProvider() { _seed(); }

  void _seed() {
    _list = [
      AppNotification(id: _uuid.v4(), title: '🚌 Bus 101 arriving soon',
          body: 'Bus 101 arrives at your stop in 3 minutes.',
          type: 'arrival', timestamp: DateTime.now().subtract(const Duration(minutes: 2))),
      AppNotification(id: _uuid.v4(), title: '⚠️ Route 202 Delayed',
          body: 'Bus 202 is running 12 minutes late due to traffic.',
          type: 'delay', timestamp: DateTime.now().subtract(const Duration(minutes: 15))),
      AppNotification(id: _uuid.v4(), title: '✅ Trip Completed',
          body: 'You arrived at City Center. Have a great day!',
          type: 'info', timestamp: DateTime.now().subtract(const Duration(hours: 2)), isRead: true),
    ];
    _unread = _list.where((n) => !n.isRead).length;
  }

  void add({required String title, required String body, required String type}) {
    _list.insert(0, AppNotification(
      id: _uuid.v4(), title: title, body: body,
      type: type, timestamp: DateTime.now(),
    ));
    _unread++;
    notifyListeners();
  }

  void markRead(String id) {
    final i = _list.indexWhere((n) => n.id == id);
    if (i != -1 && !_list[i].isRead) {
      _list[i] = _list[i].copyWith(isRead: true);
      if (_unread > 0) _unread--;
      notifyListeners();
    }
  }

  void markAllRead() {
    _list = _list.map((n) => n.copyWith(isRead: true)).toList();
    _unread = 0;
    notifyListeners();
  }

  void delete(String id) {
    final n = _list.firstWhere((n) => n.id == id, orElse: () => _list.first);
    if (!n.isRead && _unread > 0) _unread--;
    _list.removeWhere((n) => n.id == id);
    notifyListeners();
  }
}
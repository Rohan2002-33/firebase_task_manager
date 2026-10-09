import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../screens/edit_task_screen.dart';
import 'task_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class _Channel {
  final String id;
  final String name;
  final String description;
  final Importance importance;
  final Priority priority;
  const _Channel(
      this.id, this.name, this.description, this.importance, this.priority);
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  // Different channel (sound / importance) per task priority.
  static const Map<String, _Channel> _channels = {
    'High': _Channel('tasks_high', 'High priority tasks',
        'Urgent task alerts', Importance.max, Priority.max),
    'Medium': _Channel('tasks_medium', 'Medium priority tasks',
        'Normal task alerts', Importance.high, Priority.high),
    'Low': _Channel('tasks_low', 'Low priority tasks',
        'Low key task alerts', Importance.low, Priority.low),
  };

  bool _ready = false;
  bool _hasPending = false;
  String? _pendingTaskId;

  /// Call once from main() after Firebase.initializeApp.
  Future<void> init() async {
    if (_ready) return;
    _ready = true;

    // 1. Local notifications setup
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _local.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (r) => _openFromTap(r.payload),
    );

    final android = _local.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    for (final c in _channels.values) {
      await android?.createNotificationChannel(AndroidNotificationChannel(
        c.id,
        c.name,
        description: c.description,
        importance: c.importance,
      ));
    }

    // 2. FCM setup
    final fcm = FirebaseMessaging.instance;
    await fcm.requestPermission(alert: true, badge: true, sound: true);

    // App in FOREGROUND -> FCM does not show UI, so we show a local notification.
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // App in BACKGROUND -> user taps the system notification.
    FirebaseMessaging.onMessageOpenedApp
        .listen((m) => _openFromTap(m.data['taskId']?.toString()));

    fcm.onTokenRefresh.listen((t) => saveToken(t));

    // App TERMINATED -> opened by tapping a notification.
    final launch = await _local.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      _hasPending = true;
      _pendingTaskId = launch!.notificationResponse?.payload;
    }
    final initial = await fcm.getInitialMessage();
    if (initial != null) {
      _hasPending = true;
      _pendingTaskId = initial.data['taskId']?.toString();
    }

    // 3. Print device token (use it in Firebase Console "Send test message")
    try {
      final token = await fcm.getToken();
      debugPrint('FCM TOKEN: $token');
    } catch (e) {
      debugPrint('FCM token error: $e');
    }
  }

  /// Save the device token under the signed-in user.
  Future<void> saveToken([String? token]) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final t = token ?? await FirebaseMessaging.instance.getToken();
      if (t == null) return;
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'email': user.email,
        'fcmToken': t,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('saveToken error: $e');
    }
  }

  /// Called by the task list screen when it is on screen.
  void onHomeReady() {
    saveToken();
    if (_hasPending) {
      final id = _pendingTaskId;
      _hasPending = false;
      _pendingTaskId = null;
      _openFromTap(id);
    }
  }

  void _onForegroundMessage(RemoteMessage m) {
    final title = (m.notification?.title ?? m.data['title'] ?? 'New Task')
        .toString();
    final body = (m.notification?.body ?? m.data['body'] ?? '').toString();
    showTaskNotification(
      title: title,
      body: body,
      taskId: m.data['taskId']?.toString(),
      priority: (m.data['priority'] ?? 'Medium').toString(),
    );
  }

  /// Show a local notification. Used for FCM foreground messages and new tasks.
  Future<void> showTaskNotification({
    required String title,
    required String body,
    String? taskId,
    String priority = 'Medium',
  }) async {
    final c = _channels[priority] ?? _channels['Medium']!;
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        c.id,
        c.name,
        channelDescription: c.description,
        importance: c.importance,
        priority: c.priority,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: const DarwinNotificationDetails(
          presentAlert: true, presentBadge: true, presentSound: true),
    );
    await _local.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000000),
      title,
      body,
      details,
      payload: taskId,
    );
  }

  /// Notification tapped -> open Task List, and the task if id is known.
  Future<void> _openFromTap(String? taskId) async {
    final nav = navigatorKey.currentState;
    if (nav == null || FirebaseAuth.instance.currentUser == null) {
      _hasPending = true;
      _pendingTaskId = taskId;
      return;
    }
    nav.popUntil((r) => r.isFirst); // back to Task List
    if (taskId == null || taskId.isEmpty) return;
    final task = await TaskService.instance.getTask(taskId);
    if (task != null) {
      nav.push(MaterialPageRoute(builder: (_) => EditTaskScreen(task: task)));
    }
  }
}
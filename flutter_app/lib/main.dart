import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'providers/auth_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/theme_provider.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';

final FlutterLocalNotificationsPlugin localNotifs = FlutterLocalNotificationsPlugin();

// Global navigator key so we can show dialogs from notification callbacks
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

const AndroidNotificationChannel _channel = AndroidNotificationChannel(
  'grahvarta_high_importance',
  'Grahvarta Notifications',
  importance: Importance.high,
  playSound: true,
);

@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Data-only messages: FCM won't auto-show a notification, so we do it manually.
  if (message.notification == null && message.data.isNotEmpty) {
    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.initialize(const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ));
    await plugin.show(
      message.hashCode,
      message.data['title'] ?? 'Grahvarta',
      message.data['body'] ?? '',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id, _channel.name,
          importance: Importance.high, priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }
}

Future<void> _initLocalNotifications() async {
  await localNotifs.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ),
  );
  await localNotifs
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(_channel);
}

void _listenForegroundMessages(BuildContext context) {
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    final notification = message.notification;
    // Show notification for both notification-messages and data-only messages
    final title = notification?.title ?? message.data['title'];
    final body = notification?.body ?? message.data['body'];
    if (title == null && body == null) return;
    localNotifs.show(
      message.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase init is crash-guarded — user works without it (push notifications just won't fire)
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
    await _initLocalNotifications();

    // Request notification permission (Android 13+)
    await FirebaseMessaging.instance.requestPermission(
      alert: true, badge: true, sound: true, provisional: false,
    );

    // Ensure FCM auto-init is enabled so token is refreshed after re-install
    await FirebaseMessaging.instance.setAutoInitEnabled(true);

    // Handle notification tap when app was fully terminated
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('[FCM] App opened from terminated state via notification: ${initialMessage.data}');
    }
  } catch (e) {
    debugPrint('Firebase init failed (non-fatal): $e');
  }

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.background,
  ));
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(const AstroTalkApp());
}

class AstroTalkApp extends StatefulWidget {
  const AstroTalkApp({super.key});

  @override
  State<AstroTalkApp> createState() => _AstroTalkAppState();
}

class _AstroTalkAppState extends State<AstroTalkApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        _listenForegroundMessages(context);
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer2<LocaleProvider, ThemeProvider>(
        builder: (_, localeProvider, themeProvider, __) => MaterialApp(
          title: 'AstroVaak',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.isDark ? ThemeMode.dark : ThemeMode.light,
          navigatorKey: navigatorKey,
          locale: localeProvider.locale,
          supportedLocales: const [
            Locale('en'), Locale('hi'), Locale('ta'),
            Locale('kn'), Locale('ml'), Locale('gu'),
            Locale('mr'), Locale('bn'), Locale('te'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const SplashScreen(),
        ),
      ),
    );
  }
}
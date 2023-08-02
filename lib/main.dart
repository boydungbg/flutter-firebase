import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_demo_app/firebase_options.dart';
import 'package:firebase_demo_app/screens/home_screen.dart';
import 'package:firebase_demo_app/screens/login_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

// App run Background
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  print("Handling a background message: ${message.messageId}");
}

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final fcmToken = await FirebaseMessaging.instance.getToken();
  print('FCM Token: $fcmToken');
  print('123');
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  await FirebaseMessaging.instance.setAutoInitEnabled(true);
  await FirebaseAuth.instance.useAuthEmulator('127.0.0.1', 9099);
  await messaging.requestPermission();

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Got a message whilst in the foreground!');
    print('Message data: ${message.data}');

    if (message.notification != null) {
      print('Message also contained a notification: ${message.notification}');
    }
  });

  Future<void> _firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    await Firebase.initializeApp();
    print("Handling a background message: ${message.messageId}");
  }

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // In this example, suppose that all messages contain a data field with the key 'type'.
  Future<void> setupInteractedMessage() async {
    // Get any messages which caused the application to open from
    // a terminated state.
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();

    // If the message also contains a data property with a "type" of "chat",
    // navigate to a chat screen
    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }

    // Also handle any interaction when the app is in the background via a
    // Stream listener
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  }

  void _handleMessage(RemoteMessage message) {
    print('message ${message.data}');
  }

  @override
  void initState() {
    super.initState();
    // Khi build dc chay xong thi ham addPostFrameCallback dc chay va chi chay duy nhat mot lan
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      // Lang nghe su kien authentication
      setupInteractedMessage();
      FirebaseAuth.instance.authStateChanges().listen((user) {
        if (user == null) {
          print('User is currently signed out!');
          navigatorKey.currentState
              ?.pushNamedAndRemoveUntil('/sign-in', (route) => false);
        } else {
          print('User is signed in!');
          navigatorKey.currentState
              ?.pushNamedAndRemoveUntil('/', (route) => false);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      navigatorKey: navigatorKey,
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (context) => const HomeScreen());
          case 'sign-in':
            return MaterialPageRoute(builder: (context) => const LoginScreen());
        }
      },
    );
  }
}

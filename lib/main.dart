import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'models/couple_model.dart';
import 'services/notification_service.dart';
import 'services/widget_service.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ── Read cached session ──────────────────────────────────────────────
  final prefs = await SharedPreferences.getInstance();
  final storedUid = prefs.getString('stored_uid');
  final cachedCoupleJson = prefs.getString('cached_couple_json');

  CoupleModel? cachedCouple;
  if (cachedCoupleJson != null) {
    try {
      cachedCouple = CoupleModel.fromJsonString(cachedCoupleJson);
    } catch (_) {}
  }

  // ── Resolve Firebase Auth user ───────────────────────────────────────
  User? initialUser = FirebaseAuth.instance.currentUser;

  if (initialUser == null && storedUid != null) {
    // STEP 1: Brief wait for Firebase to restore token from Keystore
    try {
      initialUser = await FirebaseAuth.instance
          .authStateChanges()
          .firstWhere((u) => u != null)
          .timeout(const Duration(seconds: 3));
    } catch (_) {}

    // STEP 2: If still null → silently re-authenticate via Google Sign-In.
    // Google maintains its own persistent session independently of Firebase.
    // This covers the case where Firebase's refresh token failed but the
    // Google account session on the device is still active (which it almost
    // always is — Google sessions last months/years).
    if (initialUser == null && !kIsWeb) {
      try {
        final googleUser = await GoogleSignIn().signInSilently(
          suppressErrors: true,
        );
        if (googleUser != null) {
          final googleAuth = await googleUser.authentication;
          final credential = GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );
          final result =
              await FirebaseAuth.instance.signInWithCredential(credential);
          initialUser = result.user;
          if (initialUser != null) {
            await prefs.setString('stored_uid', initialUser.uid);
            debugPrint('main: silent Google re-auth succeeded');
          }
        }
      } catch (e) {
        debugPrint('main: silent Google re-auth failed: $e');
      }
    }
  }

  await NotificationService.initialize();
  await WidgetService.initialize();

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppTheme.background,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(PetalsApp(
    initialUser: initialUser,
    cachedCouple: cachedCouple,
    cachedUid: storedUid,
  ));
}

class PetalsApp extends StatelessWidget {
  final User? initialUser;
  final CoupleModel? cachedCouple;
  final String? cachedUid;

  const PetalsApp({
    super.key,
    this.initialUser,
    this.cachedCouple,
    this.cachedUid,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, _) {
        return MaterialApp(
          title: 'Petals',
          debugShowCheckedModeBanner: false,
          themeMode: currentMode,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context),
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 520) {
                return Container(
                  color: const Color(0xFF1B1D24),
                  child: Center(
                    child: Container(
                      width: 480,
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: child ?? const SizedBox(),
                      ),
                    ),
                  ),
                );
              }
              return child ?? const SizedBox();
            },
          ),
        );
      },
      home: SplashScreen(
        initialUser: initialUser,
        cachedCouple: cachedCouple,
        cachedUid: cachedUid,
      ),
    );
  },
);
  }
}

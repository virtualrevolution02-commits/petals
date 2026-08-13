import 'package:flutter/material.dart';

import 'screens/petals_welcome_screen.dart';
import 'theme/petals_theme.dart';

void main() {
  runApp(const PetalsApp());
}

class PetalsApp extends StatelessWidget {
  const PetalsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Petals',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: PetalsColors.bgNavy,
        useMaterial3: true,
      ),
      home: PetalsWelcomeScreen(
        onGoogleSignIn: () {
          debugPrint('Continue with Google tapped');
        },
        onSignIn: (email, password) {
          debugPrint('Sign in -> $email');
          // TODO: wire up real authentication here.
        },
        onRegister: (email, password) {
          debugPrint('Register -> $email');
          // TODO: wire up real registration here.
        },
      ),
    );
  }
}

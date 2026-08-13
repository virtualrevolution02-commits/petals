# Petals 🌸

Petals is a photo-sharing Flutter application designed for couples to share intimate moments and display them directly on interactive home screen widgets.

## Features
- **Couple Pairing**: Connect with your partner securely.
- **Moment Sharing**: Capture and upload special moments with photos & captions.
- **Home Screen Widgets**: Dynamic Android home screen widgets (Small 2x2, Medium 4x2, Large 4x4, Compact 4x1) to view moments instantly.
- **Push Notifications**: Stay notified when your partner posts a new moment.

## Tech Stack
- **Framework**: [Flutter](https://flutter.dev/) (Dart)
- **Backend**: Firebase (Authentication, Firestore, Storage, Cloud Messaging)
- **Android Widgets**: `home_widget` package + Native Kotlin Android AppWidgets

## Setup & Running
1. Clone the repository:
   ```bash
   git clone https://github.com/exceptionzofficial/petals.git
   cd petals
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run the app:
   ```bash
   flutter run
   ```

## Build Release (AAB for Google Play)
```bash
flutter build appbundle --release
```

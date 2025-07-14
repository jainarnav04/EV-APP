# Easy Vahan

A modern Flutter application for vehicle management and services.

## 🚀 Features

- User Authentication (Email/Password, Google Sign-In)
- Vehicle Management
- Real-time Location Tracking
- Document Management
- Service History
- Push Notifications

## 🛠 Tech Stack

- **Framework**: Flutter
- **Language**: Dart
- **State Management**: GetX
- **Backend**: Firebase (Authentication, Firestore, Storage)
- **Maps**: Google Maps API

## 🚀 Getting Started

### Prerequisites

- Flutter SDK
- Android Studio / Xcode
- Google Maps API Key

### Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/jainarnav04/EV-APP.git
   cd EV-APP
   ```

2. **Get dependencies**
   ```bash
   flutter pub get
   ```

3. **Set up Google Maps API**
   - Get an API key from the [Google Cloud Console](https://console.cloud.google.com/)
   - Enable these APIs:
     - Maps SDK for Android
     - Maps SDK for iOS
     - Places API

4. **Run the app**
     ```bash
     flutter run --dart-define=GOOGLE_MAPS_API_KEY="GOOGLE_MAPS_API_KEY" --dart-define=WEB_API_KEY="WEB_API_KEY"--dart-define=WEB_APP_ID=1:WEB_APP_ID
     ```

### Environment Variables

Create a `run_app.bat` file (Windows) or set environment variables (macOS/Linux) with:
- `GOOGLE_MAPS_API_KEY`: Your Google Maps API key

### Important Security Note

Never commit your API keys to version control. The `.gitignore` is configured to exclude:
- `run_app.bat`
- `.env` files
- Other sensitive files
- **Local Storage**: Shared Preferences

## 📱 Supported Platforms

- Android (Primary)
- iOS
- Web
- Windows (Limited support)

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (3.32.6 or later)
- Dart SDK (3.8.1 or later)
- Android Studio / VS Code
- Java 17 JDK
- Firebase Account

### 🛠 Environment Setup

#### 1. Add Flutter to PATH
Add Flutter to your system's PATH environment variable:

**Windows:**
1. Search for "Environment Variables" in Windows Search
2. Click on "Edit the system environment variables"
3. Click "Environment Variables"
4. Under "System Variables", find and select "Path"
5. Click "Edit"
6. Click "New" and add the path to your Flutter SDK's `bin` directory:
   ```
   C:\src\flutter\bin
   ```
7. Click "OK" to save

**macOS/Linux:**
Add this line to your `~/.bash_profile` or `~/.zshrc`:
```bash
export PATH="$PATH:`pwd`/flutter/bin"
```
Then run:
```bash
source ~/.bash_profile  # or source ~/.zshrc
```

#### 2. Configure Java 17
1. Set `JAVA_HOME` environment variable to your JDK 17 installation path:
   - **Windows**: `C:\Program Files\Java\jdk-17`
   - **macOS/Linux**: `/usr/lib/jvm/java-17-openjdk`

2. Add Java to PATH:
   - Add `%JAVA_HOME%\bin` (Windows) or `$JAVA_HOME/bin` (macOS/Linux) to your system PATH

#### 3. Android SDK Setup
1. Install Android Studio
2. During installation, make sure to install:
   - Android SDK
   - Android SDK Platform
   - Android Virtual Device
3. Add Android SDK to PATH:
   - Windows: Add `%LOCALAPPDATA%\Android\Sdk\platform-tools`
   - macOS/Linux: Add `~/Library/Android/sdk/platform-tools` to PATH

#### Verify Installation
Open a new terminal and run:
```bash
flutter doctor
```
This should show all checks passing for Android toolchain and Java development kit.

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/jainarnav04/EV-APP.git
   cd EV-APP
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Create a new Firebase project
   - Add Android/iOS/Web app to your Firebase project
   - Download and add the configuration files:
     - Android: `android/app/google-services.json`
     - iOS: `ios/Runner/GoogleService-Info.plist`
     - Web: `web/firebase-config.js`

4. **Run the app**
   ```bash
   # For Android
   flutter run -d <device_id>
   
   # For iOS
   flutter run -d <device_id>
   
   # For web
   flutter run -d chrome
   ```

## 🔧 Configuration

### Environment Variables
Create a `.env` file in the root directory with the following variables:

```
GOOGLE_MAPS_API_KEY=your_google_maps_api_key
FIREBASE_API_KEY=your_firebase_api_key
```

### Android Setup
- Set `compileSdkVersion` to 35 in `android/app/build.gradle`
- Ensure Java 17 is configured in your environment

## 🤝 Contributing

1. Fork the repository
2. Create a new branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📞 Support

For support, email support@easyvahan.in or open an issue on GitHub.

---

Made with ❤️ by Easy Vahan Team

# Solace

**Solace** is a privacy-focused personal productivity and journaling app built with **Flutter**. It combines task management, scheduling, journaling, calendar, notifications, and security features in one offline-first application.

## ✨ Features

- 🔐 **Secure Authentication** — PIN lock and biometric authentication
- ✅ **Task Management** — Create, edit, delete, prioritize, categorize, and track tasks
- 📅 **Schedule & Calendar** — Daily/weekly scheduling and calendar views
- 📖 **Journal** — Rich-text journal entries with mood tracking
- 🔔 **Notifications** — Task reminders and overdue-task notifications
- 📊 **Productivity Dashboard** — Progress indicators and weekly statistics
- 💾 **Backup & Restore** — Encrypted backups (uses AES Encryption) with import/export support
- 🌙 **Themes** — Light, dark, and system themes
- 🔄 **Background Processing** — Automatic overdue-task checking

## 🏗️ Architecture

Solace follows a **feature-based Clean Architecture**:

```text
lib/
├── core/
│   ├── database/
│   ├── di/
│   ├── router/
│   ├── services/
│   └── theme/
│
└── features/
    ├── auth/
    ├── calendar/
    ├── journal/
    ├── schedule/
    ├── settings/
    └── tasks/
```

Each feature is organized into:

```text
data/
domain/
presentation/
```

## 🛠️ Tech Stack

- **Flutter & Dart**
- **BLoC** — State management
- **Drift + SQLite** — Local database
- **GetIt + Injectable** — Dependency injection
- **GoRouter** — Navigation
- **Flutter Secure Storage** — Secure credentials
- **Local Auth** — Biometrics
- **WorkManager** — Background tasks
- **Flutter Local Notifications** — Notifications
- **Flutter Quill** — Rich-text editor
- **FL Chart** — Productivity charts
- **AES Encryption** — Backup protection

## 🚀 Getting Started

### Requirements

- Flutter SDK
- Dart SDK
- Android Studio / VS Code
- Android SDK
- Java 17

### Installation

```bash
git clone https://github.com/Alvin-binoy/solace.git
cd solace

flutter pub get

dart run build_runner build --delete-conflicting-outputs

flutter run
```

### Testing

```bash
flutter analyze
flutter test
```

## 🔒 Privacy & Security

Solace is designed around local-first data storage. Application authentication uses secure storage and optional biometrics, while exported backups are encrypted before being saved or shared.


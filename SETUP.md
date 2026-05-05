# RecallOS Flutter — Setup Guide

## Prerequisites

Install Flutter SDK: https://docs.flutter.dev/get-started/install/windows

Once installed, verify with:
```
flutter doctor
```

## Getting Started

```bash
cd C:\Users\Sushobhan\AndroidStudioProjects\RecallOS_Flutter
flutter pub get
flutter run
```

## Project Structure

```
lib/
├── main.dart                    # Entry point
├── app.dart                     # App widget + go_router + bottom nav shell
├── core/
│   ├── theme/
│   │   ├── colors.dart          # Linear.com color palette
│   │   ├── typography.dart      # Inter + JetBrains Mono text styles
│   │   └── app_theme.dart       # Full MaterialApp dark theme
│   ├── database/
│   │   └── app_database.dart    # sqflite schema + all DAOs
│   ├── models/
│   │   ├── screenshot_model.dart
│   │   ├── todo_model.dart
│   │   └── stack_model.dart
│   └── services/
│       └── ocr_service.dart     # ML Kit OCR + auto-tagging
├── features/
│   ├── home/                    # Screenshot grid + search + filter
│   ├── todo/                    # Tasks by time-of-day
│   ├── stacks/                  # Screenshot collections
│   ├── screenshot_detail/       # Full image + extracted text
│   └── stack_detail/            # Stack contents + add/remove
└── shared/widgets/              # Reusable components
```

## Design Language: Linear.com

| Token        | Value        | Usage                        |
|--------------|--------------|------------------------------|
| bgBase       | `#0F0F0F`    | Scaffold background           |
| bgSurface    | `#141414`    | Cards, inputs                |
| bgElevated   | `#1A1A1A`    | Modals, overlays             |
| borderDefault| `#2A2A2A`    | All borders                  |
| accent       | `#5E6AD2`    | Primary actions, focus ring  |
| textPrimary  | `#F7F7F7`    | Body text                    |
| textMuted    | `#6B6B6B`    | Hints, timestamps            |

Font: **Inter** (body/UI) + **JetBrains Mono** (timestamps/code)

## Notes on `android/local.properties`

Update paths to match your machine:
```
sdk.dir=C\:\\Users\\YourName\\AppData\\Local\\Android\\sdk
flutter.sdk=C\:\\flutter
```

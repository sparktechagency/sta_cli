# STA CLI 🚀

**STA CLI** is a Dart-based command-line tool to scaffold Flutter projects with a clean **MVC architecture** powered by GetX.

> **Version 0.1.4** — Now with full Windows support!

---

~~~
███████╗████████╗ █████╗      ██████╗██╗     ██╗
██╔════╝╚══██╔══╝██╔══██╗    ██╔════╝██║     ██║
███████╗   ██║   ███████║    ██║     ██║     ██║
╚════██║   ██║   ██╔══██║    ██║     ██║     ██║
███████║   ██║   ██║  ██║    ╚██████╗███████╗██║
╚══════╝   ╚═╝   ╚═╝  ╚═╝     ╚═════╝╚══════╝╚═╝
~~~


## ✨ What It Generates

| Feature | Details |
|---|---|
| **Architecture** | MVC (Model-View-Controller) |
| **State Management** | GetX (`get`) |
| **Storage** | GetStorage |
| **Networking** | HTTP with token auto-refresh |
| **UI** | Shared widgets, theming, OTP field |
| **Auth Flow** | Splash → Sign In → Sign Up → Home |
| **Structure** | controller / model / repository / view / shared / core |

### Pre-installed Dependencies
```yaml
get: ^4.6.6
logger: ^2.4.0
top_snackbar_flutter: ^3.1.0
fluttertoast: ^8.2.8
http: ^1.2.1
loading_animation_widget: ^1.2.1
get_storage: ^2.1.1
pinput: ^5.0.0
```

---

## 📦 Installation

### Activate globally (Recommended)

**macOS / Linux / Windows:**
```bash
dart pub global activate sta_cli
```

## 🎯 Usage

```
sta create                    Interactive project creation
sta create my_awesome_app     Create project with given name
sta doctor                    Show environment info (Flutter & FVM)
sta --help                    Show help
sta --version                 Show version
```

---

## 🩺 Environment Doctor

Run `sta doctor` to check your Flutter and FVM setup:

```
  ═══════════════════════════════════════════════════
                  ENVIRONMENT DOCTOR
  ═══════════════════════════════════════════════════

  ✔ Flutter detected
      Version : 3.29.3
      Channel : stable
      Dart    : 3.7.2
      Path    : (via FVM)

  ✔ FVM v4.0.4
      Installed versions:
      ▶ 3.29.3 ← active
        3.27.4
        stable

  ✔ Ready! Run: sta create
```

---

## 🪄 Interactive Setup Process

When you run `sta create`, the CLI walks you through **4 steps**:

### Step 1 — Flutter / FVM Version
Choose between:
- **System Flutter** — uses `flutter` from your PATH
- **FVM** — prompts for a version (e.g. `3.19.0`, `stable`, `beta`)

### Step 2 — Project Details
- Project name (auto-sanitized to snake_case)
- Organization name (e.g. `com.mycompany`)
- Package ID is auto-composed: `com.mycompany.project_name`

### Step 3 — Project Location
Choose where to create the project:
- Current working directory
- `~/AndroidStudioProjects` (Android Studio default)
- Custom path

### Step 4 — Confirm & Create
Review the summary, then STA CLI:
1. Runs `flutter create`
2. Sets up FVM version in project (if selected)
3. Creates the full MVC folder structure
4. Writes all boilerplate source files
5. Updates `pubspec.yaml` with all dependencies
6. Runs `flutter pub get`

---

## 📁 Generated Project Structure

```
your_project/
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── controller/
│   │   ├── auth/
│   │   │   ├── sign_in_controller.dart
│   │   │   └── sign_up_controller.dart
│   │   └── credential/
│   │       └── credential_controller.dart
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_urls.dart
│   │   │   ├── assets_icon.dart
│   │   │   └── assets_image.dart
│   │   ├── dependency/
│   │   │   └── controller_binder.dart
│   │   ├── error/
│   │   │   └── app_exception.dart
│   │   ├── extensions/
│   │   │   └── space_gap.dart
│   │   ├── network/
│   │   │   ├── base_api_service.dart
│   │   │   └── network_api_service.dart
│   │   ├── router/
│   │   │   └── app_router.dart
│   │   ├── theme/
│   │   │   ├── app_colors.dart
│   │   │   └── app_theme.dart
│   │   ├── utils/
│   │   │   ├── logger.dart
│   │   │   └── messenger.dart
│   │   └── validators/
│   │       ├── validators.dart
│   │       └── validation/
│   │           ├── email_validation.dart
│   │           ├── number_validation.dart
│   │           └── password_validation.dart
│   ├── model/
│   │   └── auth/
│   │       └── login_request_model.dart
│   ├── repository/
│   │   └── auth/
│   │       └── auth_repo.dart
│   ├── shared/
│   │   ├── app_button.dart
│   │   ├── app_otp_field.dart
│   │   ├── app_text.dart
│   │   ├── app_text_field.dart
│   │   ├── custom_app_bar.dart
│   │   ├── lebeled_text_field.dart
│   │   └── or_divider.dart
│   └── view/
│       ├── auth/
│       │   ├── sign_in_view.dart
│       │   ├── sign_up_view.dart
│       │   └── splash_view.dart
│       └── home/
│           └── home_view.dart
└── assets/
    ├── images/
    └── icons/
```

---

## 🛠 Requirements

- Dart SDK ≥ 3.0.0
- Flutter installed in PATH **or** FVM (Flutter Version Management)
- **Supported OS:** Windows, macOS, Linux

---

## 🔧 Troubleshooting

### "flutter is not recognized as an internal or external command"

This error means Flutter is not in your system PATH. To fix:

1. **Install Flutter** from [flutter.dev](https://flutter.dev/docs/get-started/install)
2. **Add Flutter to PATH:**
   - **Windows:** Add `C:\path\to\flutter\bin` to your system PATH
   - **macOS/Linux:** Add `export PATH="$PATH:/path/to/flutter/bin"` to `~/.bashrc` or `~/.zshrc`
3. **Or use FVM:** Install [FVM](https://fvm.app/) and STA CLI will detect it automatically

### "FileSystemException: Exists failed, path = '...' (errno = 123)"

This was caused by incorrect path quoting on Windows. **Fixed in v0.1.3.**

### Folder already exists

STA CLI now automatically suggests alternative names (e.g., `my_app_1`, `my_app_2`) when a folder already exists. You can also choose to overwrite the existing folder.

---

## 📝 Changelog

### 0.1.4
- 🐛 Fixed Windows path quoting issue (`FileSystemException` errno 123)
- 🐛 Fixed "flutter is not recognized" detection with better error messages
- ✅ Added auto-increment folder naming (name_1, name_2, etc.) when folder exists
- ✅ Improved `pubspec.yaml` updating - properly handles existing dependencies
- ✅ Added helpful troubleshooting messages for common errors

---

Built with ❤️ — **STA CLI**

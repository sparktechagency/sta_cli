# STA CLI 🚀

**STA CLI** is a Dart-based command-line tool to scaffold Flutter projects with a clean **MVC architecture** powered by GetX.

---

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

### Option 1 — Activate globally (Recommended)

```bash
dart pub global activate --source path /path/to/sta_cli
```

Then use from anywhere:
```bash
sta create
sta create my_app
```

### Option 2 — Run directly with Dart

```bash
cd sta_cli
dart pub get
dart run bin/main.dart create
```

### Option 3 — Compile to native executable

```bash
cd sta_cli
dart pub get
dart compile exe bin/main.dart -o sta
# Move to your PATH:
sudo mv sta /usr/local/bin/sta
```

---

## 🎯 Usage

```
sta create                    Interactive project creation
sta create my_awesome_app     Create project with given name
sta --help                    Show help
sta --version                 Show version
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
- Flutter installed in PATH (or FVM)

---

Built with ❤️ — **STA CLI**

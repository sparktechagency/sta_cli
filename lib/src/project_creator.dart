import 'dart:io';
import 'package:path/path.dart' as p;
import 'colors.dart';

class ProjectCreator {
  final String projectName;
  final String projectPath;
  final String packageName;

  ProjectCreator({
    required this.projectName,
    required this.projectPath,
    required this.packageName,
  });

  Future<void> createStructure() async {
    final dirs = [
      'lib/controller/auth',
      'lib/controller/credential',
      'lib/core/constants',
      'lib/core/dependency',
      'lib/core/error',
      'lib/core/extensions',
      'lib/core/network',
      'lib/core/router',
      'lib/core/theme',
      'lib/core/utils',
      'lib/core/validators/validation',
      'lib/model/auth',
      'lib/repository/auth',
      'lib/shared',
      'lib/view/auth',
      'lib/view/home',
      'assets/images',
      'assets/icons',
      'assets/fonts',
    ];

    for (final dir in dirs) {
      final dirPath = p.join(projectPath, dir);
      await Directory(dirPath).create(recursive: true);
    }
  }

  Future<void> writeAllFiles() async {
    final files = _buildFileMap();
    for (final entry in files.entries) {
      final filePath = p.join(projectPath, entry.key);
      await File(filePath).writeAsString(entry.value);
      printSuccess('Created ${entry.key}');
    }
  }

  Map<String, String> _buildFileMap() {
    final projectPath = projectName;
    return {
      // ── main.dart ──────────────────────────────────────────────────────
      'lib/main.dart': '''import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  runApp(const MyApp());
}
''',

      // ── app.dart ───────────────────────────────────────────────────────
      'lib/app.dart': '''import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:$projectPath/core/dependency/controller_binder.dart';
import 'package:$projectPath/core/router/app_router.dart';

import 'core/theme/app_theme.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      initialBinding: ControllerBinder(),
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      getPages: AppRouter.routes,
      initialRoute: '/',
    );
  }
}
''',

      // ── core/constants ─────────────────────────────────────────────────
      'lib/core/constants/app_urls.dart': '''class AppUrls {
  static const String _baseUrl = 'https://your-api-url.com/api/v1';
 
  static const String login = '\$_baseUrl/auth/login/';

  static const String refreshToken = '\$_baseUrl/auth/refresh-token/';

  // TODO: Add your API endpoints here
}
''',

      'lib/core/constants/assets_image.dart': '''class AssetsImage {
  static const String _base = 'assets/images';

  // TODO: Add your image assets here
  // static const String logo = '\$_base/logo.png';
}
''',

      'lib/core/constants/assets_icon.dart': '''class AssetsIcon {
  static const String _base = 'assets/icons';

  // TODO: Add your icon assets here
  // static const String home = '\$_base/home.svg';
}
''',

      // ── core/dependency ────────────────────────────────────────────────
      'lib/core/dependency/controller_binder.dart': '''import 'package:get/get.dart';
import 'package:$projectPath/controller/credential/credential_controller.dart';

class ControllerBinder extends Bindings {
  @override
  void dependencies() {
    Get.put(CredentialController());
  }
}
''',

      // ── core/error ─────────────────────────────────────────────────────
      'lib/core/error/app_exception.dart': '''class AppException implements Exception {
  final String message;
  final String prefix;

  AppException(this.message, this.prefix);

  @override
  String toString() => '\$prefix\$message';
}

class FetchDataException extends AppException {
  FetchDataException(super.message) : super('Network Error: ');
}

class BadRequestException extends AppException {
  BadRequestException(super.message) : super('Bad Request: ');
}

class UnAuthorException extends AppException {
  UnAuthorException(super.message) : super('Unauthorized: ');
}

class ConflictException extends AppException {
  ConflictException(super.message) : super('Conflict: ');
}

class AppTimeoutException extends AppException {
  AppTimeoutException(super.message) : super('Timeout: ');
}

class UnIdentifyException extends AppException {
  UnIdentifyException(super.message) : super('Unknown Error: ');
}
''',

      // ── core/extensions ────────────────────────────────────────────────
      'lib/core/extensions/space_gap.dart': '''import 'package:flutter/material.dart';

extension SpaceGap on num {
  SizedBox get h => SizedBox(height: toDouble());
  SizedBox get w => SizedBox(width: toDouble());
}
''',

      // ── core/network ───────────────────────────────────────────────────
      'lib/core/network/base_api_service.dart': '''import 'network_api_service.dart';

abstract class BaseApiService {
  Future<dynamic> getRequest(String url);
  Future<dynamic> postRequest(String url, dynamic data);
  Future<dynamic> postFilesAndDataRequest(
    String url,
    List<FileData> filesData,
    Map<String, dynamic> data,
  );
  Future<dynamic> deleteRequest(String url);
  Future<dynamic> patchRequest(String url, dynamic data);
  Future<dynamic> patchFileRequest(String url, FileData fileData);
  Future<dynamic> putRequest(String url, dynamic data);
  Future<dynamic> patchFileAndDataRequest(
    String url,
    List<FileData>? filesData,
    Map<String, dynamic>? data,
  );
}
''',

      'lib/core/network/network_api_service.dart': '''import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart' hide Response, MultipartFile;
import 'package:http/http.dart';
import 'package:$projectPath/view/auth/sign_in_view.dart';
import '../../controller/credential/credential_controller.dart';
import '../constants/app_urls.dart';
import '../error/app_exception.dart';
import '../utils/logger.dart';
import 'base_api_service.dart';

class FileData {
  final File file;
  final String fileName;

  FileData({required this.file, required this.fileName});
}

class NetworkApiService extends BaseApiService {
  final CredentialController _credentialController = CredentialController.to;

  bool _isRefreshing = false;
  int _retryCount = 0;
  static const int _maxRetries = 2;

  @override
  Future getRequest(String url) async {
    logger.i('GET → \$url');
    try {
      final Response response = await get(
        Uri.parse(url),
        headers: _buildHeaders(),
      ).timeout(const Duration(seconds: 10));
      return await returnJson(response, () => getRequest(url));
    } on SocketException {
      throw FetchDataException('No Internet Connection');
    } on TimeoutException {
      throw AppTimeoutException('Request timed out.');
    }
  }

  @override
  Future postRequest(String url, dynamic data) async {
    logger.i('POST → \$url | data: \$data');
    try {
      final Response response = await post(
        Uri.parse(url),
        body: jsonEncode(data),
        headers: _buildHeaders(),
      ).timeout(const Duration(seconds: 10));
      return await returnJson(response, () => postRequest(url, data));
    } on SocketException {
      throw FetchDataException('No Internet Connection');
    } on TimeoutException {
      throw AppTimeoutException('Request timed out.');
    }
  }

  @override
  Future deleteRequest(String url) async {
    logger.i('DELETE → \$url');
    try {
      final Response response = await delete(
        Uri.parse(url),
        headers: _buildHeaders(),
      ).timeout(const Duration(seconds: 10));
      return await returnJson(response, () => deleteRequest(url));
    } on SocketException {
      throw FetchDataException('No Internet Connection');
    } on TimeoutException {
      throw AppTimeoutException('Request timed out.');
    }
  }

  @override
  Future postFilesAndDataRequest(
    String url,
    List<FileData> filesData,
    Map<String, dynamic> data,
  ) async {
    logger.i('POST Multipart → \$url');
    try {
      final request = MultipartRequest('POST', Uri.parse(url));
      request.headers.addAll(_buildHeaders());
      for (var fileData in filesData) {
        request.files.add(
          await MultipartFile.fromPath(fileData.fileName, fileData.file.path),
        );
      }
      request.fields['data'] = jsonEncode(data);
      final streamedResponse = await request.send();
      final response = await Response.fromStream(streamedResponse);
      return await returnJson(
          response, () => postFilesAndDataRequest(url, filesData, data));
    } on SocketException {
      throw FetchDataException('No Internet Connection');
    } on TimeoutException {
      throw AppTimeoutException('Request timed out.');
    }
  }

  @override
  Future patchRequest(String url, dynamic data) async {
    logger.i('PATCH → \$url | data: \$data');
    try {
      final Response response = await patch(
        Uri.parse(url),
        body: jsonEncode(data),
        headers: _buildHeaders(),
      ).timeout(const Duration(seconds: 10));
      return await returnJson(response, () => patchRequest(url, data));
    } on SocketException {
      throw FetchDataException('No Internet Connection');
    } on TimeoutException {
      throw AppTimeoutException('Request timed out.');
    }
  }

  @override
  Future patchFileRequest(String url, FileData fileData) async {
    logger.i('PATCH File → \$url');
    try {
      final request = MultipartRequest('PATCH', Uri.parse(url));
      request.headers.addAll(_buildHeaders());
      request.files.add(
        await MultipartFile.fromPath(fileData.fileName, fileData.file.path),
      );
      final streamedResponse = await request.send();
      final response = await Response.fromStream(streamedResponse);
      return await returnJson(response, () => patchFileRequest(url, fileData));
    } on SocketException {
      throw FetchDataException('No Internet Connection');
    } on TimeoutException {
      throw AppTimeoutException('Request timed out.');
    }
  }

  @override
  Future putRequest(String url, data) async {
    logger.i('PUT → \$url | data: \$data');
    try {
      final Response response = await put(
        Uri.parse(url),
        body: jsonEncode(data),
        headers: _buildHeaders(),
      ).timeout(const Duration(seconds: 10));
      return await returnJson(response, () => putRequest(url, data));
    } on SocketException {
      throw FetchDataException('No Internet Connection');
    } on TimeoutException {
      throw AppTimeoutException('Request timed out.');
    }
  }

  @override
  Future<dynamic> patchFileAndDataRequest(
    String url,
    List<FileData>? filesData,
    Map<String, dynamic>? data,
  ) async {
    logger.i('PATCH File+Data → \$url');
    try {
      final request = MultipartRequest('PATCH', Uri.parse(url));
      request.headers.addAll(_buildHeaders());
      if (filesData != null && filesData.isNotEmpty) {
        for (var fileData in filesData) {
          if (await fileData.file.exists()) {
            request.files.add(await MultipartFile.fromPath(
                fileData.fileName, fileData.file.path));
          }
        }
      }
      if (data != null && data.isNotEmpty) {
        request.fields['data'] = jsonEncode(data);
      }
      final streamedResponse = await request.send();
      final response = await Response.fromStream(streamedResponse);
      return await returnJson(
          response, () => patchFileAndDataRequest(url, filesData, data));
    } on SocketException {
      throw FetchDataException('No Internet connection');
    } on FileSystemException catch (e) {
      throw FetchDataException('File error: \${e.message}');
    } on TimeoutException {
      throw AppTimeoutException('Request timed out.');
    }
  }

  Future<bool> _refreshToken() async {
    if (_isRefreshing) {
      while (_isRefreshing) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return _credentialController.token.isNotEmpty;
    }
    _isRefreshing = true;
    try {
      logger.i('Refreshing token...');
      final Response response = await get(
        Uri.parse(AppUrls.refreshToken),
        headers: {
          'Content-Type': 'application/json',
          'token': _credentialController.refreshToken,
        },
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final newToken = jsonDecode(response.body)['data']['accessToken'];
        await _credentialController.updateAccessToken(newToken: newToken);
        return true;
      }
      return false;
    } on TimeoutException {
      throw AppTimeoutException('Request timed out.');
    } finally {
      _isRefreshing = false;
    }
  }

  Map<String, String> _buildHeaders() {
    final headers = {'Content-Type': 'application/json'};
    if (_credentialController.token.isNotEmpty) {
      headers['Authorization'] = _credentialController.token;
    }
    return headers;
  }

  Future<dynamic> returnJson(Response response, Function retry) async {
    switch (response.statusCode) {
      case 200:
      case 201:
        _retryCount = 0;
        return jsonDecode(response.body);
      case 400:
        _retryCount = 0;
        throw BadRequestException(response.body);
      case 404:
        _retryCount = 0;
        throw UnAuthorException(response.body);
      case 401:
        if (_retryCount >= _maxRetries) {
          _retryCount = 0;
          _isRefreshing = false;
          await _credentialController.clearUserData();
          Get.offAll(() => SignInView());
          throw UnAuthorException('Session Expired. Please log in again.');
        }
        _retryCount++;
        final bool refreshed = await _refreshToken();
        if (refreshed && _retryCount < _maxRetries) {
          return await retry();
        } else {
          _retryCount = 0;
          await _credentialController.clearUserData();
          Get.offAll(() => SignInView());
          throw UnAuthorException('Failed to refresh token. Logging out.');
        }
      case 409:
        _retryCount = 0;
        throw ConflictException(response.body);
      default:
        _retryCount = 0;
        throw UnIdentifyException(response.body);
    }
  }
}
''',

      // ── core/router ────────────────────────────────────────────────────
      'lib/core/router/app_router.dart': '''import 'package:get/get.dart';
import 'package:$projectPath/view/auth/sign_in_view.dart';
import 'package:$projectPath/view/auth/sign_up_view.dart';
import 'package:$projectPath/view/auth/splash_view.dart';
import 'package:$projectPath/view/home/home_view.dart';

class AppRouter {
  static final routes = [
    GetPage(
      name: '/',
      page: () => SplashView(),
      transition: Transition.native,
    ),
    GetPage(
      name: SignInView.routeName,
      page: () => SignInView(),
      transition: Transition.native,
    ),
    GetPage(
      name: SignUpView.routeName,
      page: () => SignUpView(),
      transition: Transition.native,
    ),
    GetPage(
      name: HomeView.routeName,
      page: () => HomeView(),
      transition: Transition.native,
    ),
  ];
}
''',

      // ── core/theme ─────────────────────────────────────────────────────
      'lib/core/theme/app_colors.dart': '''import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryColor = Color(0xFF6C63FF);
  static const Color secondaryColor = Color(0xFF03DAC6);
  static const Color errorColor = Color(0xFFB00020);
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
}
''',

      'lib/core/theme/app_theme.dart': '''import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    primaryColor: AppColors.primaryColor,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(backgroundColor: Colors.white, elevation: 0),
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryColor),
    brightness: Brightness.light,
    useMaterial3: true,
  );

  static final ThemeData darkTheme = ThemeData(
    primaryColor: AppColors.primaryColor,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primaryColor,
      brightness: Brightness.dark,
    ),
    brightness: Brightness.dark,
    useMaterial3: true,
  );
}
''',

      // ── core/utils ─────────────────────────────────────────────────────
      'lib/core/utils/logger.dart': '''import 'package:logger/logger.dart';

var logger = Logger(
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 5,
    lineLength: 80,
    colors: true,
    printEmojis: true,
  ),
);
''',

      'lib/core/utils/messenger.dart': '''import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

class Messenger {
  static void toastMessage(String message) {
    Fluttertoast.showToast(msg: message);
  }

  static void errorToast(Object? error) {
    final msg = _extractMessage(error ?? 'Unknown error');
    Fluttertoast.showToast(msg: msg);
  }

  static void errorSnackBar({
    Object? message = 'Unknown error',
    required BuildContext context,
  }) {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;
    showTopSnackBar(overlay, CustomSnackBar.error(message: _extractMessage(message!)));
  }

  static void infoSnackBar({
    required String message,
    required BuildContext context,
  }) {
    showTopSnackBar(Overlay.of(context), CustomSnackBar.info(message: message));
  }

  static void successSnackBar({
    required String message,
    required BuildContext context,
  }) {
    showTopSnackBar(
        Overlay.of(context), CustomSnackBar.success(message: message));
  }

  static String _extractMessage(Object input) {
    if (input is Map) return _msgFromMap(input.cast<String, dynamic>());
    final text = input.toString().trim();
    if (text.isEmpty) return 'An error occurred';
    try {
      final decoded = jsonDecode(text);
      if (decoded is Map) return _msgFromMap(decoded.cast<String, dynamic>());
    } catch (_) {}
    final match = RegExp(r'message:\\s*([^,}]+)').firstMatch(text);
    if (match != null) {
      final extracted = match.group(1)?.trim();
      if (extracted != null && extracted.isNotEmpty) return extracted;
    }
    return text;
  }

  static String _msgFromMap(Map<String, dynamic> m) {
    final v = m['msg'] ?? m['message'];
    if (v is String && v.trim().isNotEmpty) return v.trim();
    return 'An error occurred';
  }
}
''',

      // ── core/validators ────────────────────────────────────────────────
      'lib/core/validators/validators.dart': '''export 'validation/email_validation.dart';
export 'validation/password_validation.dart';
export 'validation/number_validation.dart';
''',

      'lib/core/validators/validation/email_validation.dart': '''String? emailValidator(String? value) {
  if (value == null || value.isEmpty) return 'Email is required';
  final regex = RegExp(r'^[\\w-.]+@([\\w-]+\\.)+[\\w-]{2,4}\$');
  if (!regex.hasMatch(value)) return 'Enter a valid email';
  return null;
}
''',

      'lib/core/validators/validation/password_validation.dart': '''String? passwordValidator(String? value) {
  if (value == null || value.isEmpty) return 'Password is required';
  if (value.length < 6) return 'Password must be at least 6 characters';
  return null;
}
''',

      'lib/core/validators/validation/number_validation.dart': '''String? numberValidator(String? value) {
  if (value == null || value.isEmpty) return 'This field is required';
  if (double.tryParse(value) == null) return 'Enter a valid number';
  return null;
}
''',

      // ── controller ─────────────────────────────────────────────────────
      'lib/controller/credential/credential_controller.dart': '''import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../core/utils/logger.dart';

class CredentialController extends GetxController {
  static CredentialController get to => Get.find<CredentialController>();

  final GetStorage _box = GetStorage();

  static const String _tokenKey = 'token';
  static const String _refreshTokenKey = 'refreshToken';
  static const String _uidKey = 'uid';

  final RxString _token = ''.obs;
  final RxString _refreshToken = ''.obs;
  final RxString _userId = ''.obs;

  String get token => _token.value;
  String get refreshToken => _refreshToken.value;
  String get userId => _userId.value;

  @override
  void onInit() {
    super.onInit();
    loadUserData();
  }

  Future<void> saveUserData({
    required String accessToken,
    required String refreshTokens,
  }) async {
    try {
      await _box.write(_tokenKey, accessToken);
      await _box.write(_refreshTokenKey, refreshTokens);
      _token.value = accessToken;
      _refreshToken.value = refreshTokens;
    } catch (e) {
      logger.e(e);
    }
  }

  Future<void> tempSaveUserData({
    required String accessToken,
    required String refreshTokens,
    required String uid,
  }) async {
    _token.value = accessToken;
    _refreshToken.value = refreshTokens;
    _userId.value = uid;
  }

  Future<void> loadUserData() async {
    try {
      _token.value = _box.read(_tokenKey) ?? '';
      _refreshToken.value = _box.read(_refreshTokenKey) ?? '';
      _userId.value = _box.read(_uidKey) ?? '';
    } catch (e) {
      logger.e('Error loading user data: \$e');
    }
  }

  Future<void> updateAccessToken({required String newToken}) async {
    try {
      _token.value = newToken;
      await _box.write(_tokenKey, newToken);
    } catch (e) {
      logger.e('Error updating access token: \$e');
    }
  }

  Future<bool> isUserLoggedIn() async {
    await loadUserData();
    return _token.value.isNotEmpty;
  }

  Future<void> clearUserData() async {
    try {
      await _box.remove(_tokenKey);
      await _box.remove(_refreshTokenKey);
      await _box.remove(_uidKey);
      _token.value = '';
      _refreshToken.value = '';
      _userId.value = '';
    } catch (e) {
      logger.e('Error clearing user data: \$e');
    }
  }

  bool isValid() => _token.value.isNotEmpty;
}
''',

      'lib/controller/auth/sign_in_controller.dart': '''import 'package:get/get.dart';
import 'package:$projectPath/core/network/network_api_service.dart';
import 'package:$projectPath/core/utils/logger.dart';
import 'package:$projectPath/model/auth/login_request_model.dart';
import 'package:$projectPath/repository/auth/auth_repo.dart';
import 'package:$projectPath/view/home/home_view.dart';

class SignInController extends GetxController {
  final _authRepo = AuthRepo();
  final RxBool isLoading = false.obs;

  Future<void> signIn({required String email, required String password}) async {
    try {
      isLoading.value = true;
      final model = LoginRequestModel(email: email, password: password);
      final response = await _authRepo.login(model);
      logger.i('Sign In Response: \$response');
      Get.offAllNamed(HomeView.routeName);
    } catch (e) {
      logger.e('Sign In Error: \$e');
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}
''',

      'lib/controller/auth/sign_up_controller.dart': '''import 'package:get/get.dart';
import 'package:$projectPath/core/utils/logger.dart';
import 'package:$projectPath/view/auth/sign_in_view.dart';

class SignUpController extends GetxController {
  final RxBool isLoading = false.obs;

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      isLoading.value = true;
      // TODO: Implement sign up logic
      logger.i('Sign Up: \$email');
      Get.offAllNamed(SignInView.routeName);
    } catch (e) {
      logger.e('Sign Up Error: \$e');
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}
''',

      // ── model ──────────────────────────────────────────────────────────
      'lib/model/auth/login_request_model.dart': '''class LoginRequestModel {
  final String email;
  final String password;

  LoginRequestModel({required this.email, required this.password});

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
      };
}
''',

      // ── repository ─────────────────────────────────────────────────────
      'lib/repository/auth/auth_repo.dart': '''import 'package:$projectPath/core/constants/app_urls.dart';
import 'package:$projectPath/core/network/network_api_service.dart';
import 'package:$projectPath/model/auth/login_request_model.dart';

class AuthRepo {
  final NetworkApiService _apiService = NetworkApiService();

  Future<dynamic> login(LoginRequestModel model) async {
    return await _apiService.postRequest(
      AppUrls.login,
      model.toJson(),
    );
  }
}
''',

      // ── shared widgets ─────────────────────────────────────────────────
      'lib/shared/app_button.dart': '''import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:$projectPath/core/theme/app_colors.dart';

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;
  final Color? color;
  final double? width;

  const AppButton({
    super.key,
    required this.label,
    this.onTap,
    this.isLoading = false,
    this.color,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? AppColors.primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: isLoading ? null : onTap,
        child: isLoading
            ? LoadingAnimationWidget.staggeredDotsWave(
                color: Colors.white,
                size: 30,
              )
            : Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
''',

      'lib/shared/app_text_field.dart': '''import 'package:flutter/material.dart';
import 'package:$projectPath/core/theme/app_colors.dart';

class AppTextField extends StatelessWidget {
  final String hint;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final int? maxLines;

  const AppTextField({
    super.key,
    required this.hint,
    this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.suffixIcon,
    this.prefixIcon,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: obscureText ? 1 : maxLines,
      decoration: InputDecoration(
        hintText: hint,
        suffixIcon: suffixIcon,
        prefixIcon: prefixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.textSecondary.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.textSecondary.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
''',

      'lib/shared/app_text.dart': '''import 'package:flutter/material.dart';
import 'package:$projectPath/core/theme/app_colors.dart';

class AppText extends StatelessWidget {
  final String text;
  final double? fontSize;
  final FontWeight? fontWeight;
  final Color? color;
  final TextAlign? textAlign;

  const AppText(
    this.text, {
    super.key,
    this.fontSize,
    this.fontWeight,
    this.color,
    this.textAlign,
  });

  factory AppText.heading(String text, {Color? color}) => AppText(
        text,
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: color ?? AppColors.textPrimary,
      );

  factory AppText.subheading(String text, {Color? color}) => AppText(
        text,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: color ?? AppColors.textPrimary,
      );

  factory AppText.body(String text, {Color? color}) => AppText(
        text,
        fontSize: 14,
        color: color ?? AppColors.textSecondary,
      );

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      style: TextStyle(
        fontSize: fontSize ?? 14,
        fontWeight: fontWeight ?? FontWeight.normal,
        color: color ?? AppColors.textPrimary,
      ),
    );
  }
}
''',

      'lib/shared/app_otp_field.dart': '''import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:$projectPath/core/theme/app_colors.dart';

class AppOtpField extends StatelessWidget {
  final void Function(String)? onCompleted;
  final TextEditingController? controller;
  final int length;

  const AppOtpField({
    super.key,
    this.onCompleted,
    this.controller,
    this.length = 6,
  });

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 52,
      height: 52,
      textStyle: const TextStyle(
        fontSize: 20,
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.textSecondary.withOpacity(0.3),
        ),
      ),
    );

    return Pinput(
      length: length,
      controller: controller,
      defaultPinTheme: defaultPinTheme,
      focusedPinTheme: defaultPinTheme.copyWith(
        decoration: defaultPinTheme.decoration!.copyWith(
          border: Border.all(color: AppColors.primaryColor, width: 2),
        ),
      ),
      onCompleted: onCompleted,
    );
  }
}
''',

      'lib/shared/custom_app_bar.dart': '''import 'package:flutter/material.dart';
import 'package:$projectPath/core/theme/app_colors.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBack;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBack = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
      centerTitle: true,
      backgroundColor: Colors.white,
      elevation: 0,
      leading: showBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
              onPressed: () => Navigator.pop(context),
            )
          : null,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
''',

      'lib/shared/lebeled_text_field.dart': '''import 'package:flutter/material.dart';
import 'package:$projectPath/core/theme/app_colors.dart';
import 'package:$projectPath/shared/app_text_field.dart';

class LabeledTextField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;

  const LabeledTextField({
    super.key,
    required this.label,
    required this.hint,
    this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        AppTextField(
          hint: hint,
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          suffixIcon: suffixIcon,
        ),
      ],
    );
  }
}
''',

      'lib/shared/or_divider.dart': '''import 'package:flutter/material.dart';
import 'package:$projectPath/core/theme/app_colors.dart';

class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(color: AppColors.textSecondary.withOpacity(0.3)),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'OR',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Divider(color: AppColors.textSecondary.withOpacity(0.3)),
        ),
      ],
    );
  }
}
''',

      // ── views ──────────────────────────────────────────────────────────
      'lib/view/auth/splash_view.dart': '''import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:$projectPath/core/theme/app_colors.dart';
import 'package:$projectPath/view/auth/sign_in_view.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      Get.offAllNamed(SignInView.routeName);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.flutter_dash, size: 80, color: Colors.white),
            const SizedBox(height: 16),
            Text(
              '${projectName.toUpperCase()}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
''',

      'lib/view/auth/sign_in_view.dart': '''import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:$projectPath/controller/auth/sign_in_controller.dart';
import 'package:$projectPath/core/validators/validators.dart';
import 'package:$projectPath/shared/app_button.dart';
import 'package:$projectPath/shared/app_text.dart';
import 'package:$projectPath/shared/lebeled_text_field.dart';
import 'package:$projectPath/view/auth/sign_up_view.dart';

class SignInView extends StatelessWidget {
  static const String routeName = '/sign-in';

  SignInView({super.key});

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _controller = Get.put(SignInController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 48),
                AppText.heading('Welcome Back 👋'),
                const SizedBox(height: 8),
                AppText.body('Sign in to your account'),
                const SizedBox(height: 40),
                LabeledTextField(
                  label: 'Email',
                  hint: 'Enter your email',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: emailValidator,
                ),
                const SizedBox(height: 20),
                LabeledTextField(
                  label: 'Password',
                  hint: 'Enter your password',
                  controller: _passwordController,
                  obscureText: true,
                  validator: passwordValidator,
                ),
                const SizedBox(height: 32),
                Obx(() => AppButton(
                      label: 'Sign In',
                      isLoading: _controller.isLoading.value,
                      onTap: () {
                        if (_formKey.currentState!.validate()) {
                          _controller.signIn(
                            email: _emailController.text.trim(),
                            password: _passwordController.text.trim(),
                          );
                        }
                      },
                    )),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AppText.body("Don't have an account? "),
                    GestureDetector(
                      onTap: () => Get.toNamed(SignUpView.routeName),
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(
                          color: Color(0xFF6C63FF),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
''',

      'lib/view/auth/sign_up_view.dart': '''import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:$projectPath/controller/auth/sign_up_controller.dart';
import 'package:$projectPath/core/validators/validators.dart';
import 'package:$projectPath/shared/app_button.dart';
import 'package:$projectPath/shared/app_text.dart';
import 'package:$projectPath/shared/lebeled_text_field.dart';

class SignUpView extends StatelessWidget {
  static const String routeName = '/sign-up';

  SignUpView({super.key});

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _controller = Get.put(SignUpController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 48),
                AppText.heading('Create Account ✨'),
                const SizedBox(height: 8),
                AppText.body('Sign up to get started'),
                const SizedBox(height: 40),
                LabeledTextField(
                  label: 'Full Name',
                  hint: 'Enter your name',
                  controller: _nameController,
                ),
                const SizedBox(height: 20),
                LabeledTextField(
                  label: 'Email',
                  hint: 'Enter your email',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: emailValidator,
                ),
                const SizedBox(height: 20),
                LabeledTextField(
                  label: 'Password',
                  hint: 'Enter your password',
                  controller: _passwordController,
                  obscureText: true,
                  validator: passwordValidator,
                ),
                const SizedBox(height: 32),
                Obx(() => AppButton(
                      label: 'Sign Up',
                      isLoading: _controller.isLoading.value,
                      onTap: () {
                        if (_formKey.currentState!.validate()) {
                          _controller.signUp(
                            name: _nameController.text.trim(),
                            email: _emailController.text.trim(),
                            password: _passwordController.text.trim(),
                          );
                        }
                      },
                    )),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AppText.body('Already have an account? '),
                    GestureDetector(
                      onTap: () => Get.back(),
                      child: const Text(
                        'Sign In',
                        style: TextStyle(
                          color: Color(0xFF6C63FF),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
''',

      'lib/view/home/home_view.dart': '''import 'package:flutter/material.dart';
import 'package:$projectPath/shared/custom_app_bar.dart';
import 'package:$projectPath/shared/app_text.dart';

class HomeView extends StatelessWidget {
  static const String routeName = '/home';

  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Home', showBack: false),
      body: const Center(
        child: AppText('Welcome to your app! 🚀'),
      ),
    );
  }
}
''',
    };
  }

  Future<void> updatePubspec() async {
    final pubspecPath = p.join(projectPath, 'pubspec.yaml');
    final file = File(pubspecPath);
    if (!await file.exists()) {
      throw Exception('pubspec.yaml not found at $pubspecPath');
    }

    String content = await file.readAsString();

    // Dependencies to add
    final depsToAdd = {
      'get': null,
      'logger': null,
      'top_snackbar_flutter': null,
      'fluttertoast': null,
      'http': null,
      'loading_animation_widget': null,
      'get_storage': null,
      'pinput': null,
    };

    // Build dependencies string (no version = use latest)
    final depsString = depsToAdd.keys
        .map((dep) => '  $dep:')
        .join('\n');

    // Check if dependencies already exist and skip those
    final lines = content.split('\n');
    final newLines = <String>[];
    bool inDependencies = false;
    bool addedDeps = false;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      // Track when we enter dependencies section
      if (line.trim() == 'dependencies:') {
        inDependencies = true;
        newLines.add(line);
        continue;
      }

      // When we hit flutter sdk in dependencies, add our deps after
      if (inDependencies && line.contains('sdk: flutter') && !addedDeps) {
        newLines.add(line);
        // Add dependencies after flutter sdk line
        newLines.add(depsString);
        addedDeps = true;
        continue;
      }

      // Check if we're leaving dependencies section (new section starts)
      if (inDependencies && !line.startsWith(' ') && !line.startsWith('\t') && line.trim().isNotEmpty && line.trim() != '') {
        inDependencies = false;
      }

      // Skip if this line is one of our dependencies that's already there
      bool skip = false;
      if (inDependencies) {
        for (final dep in depsToAdd.keys) {
          if (line.trim().startsWith('$dep:')) {
            skip = true;
            break;
          }
        }
      }

      if (!skip) {
        newLines.add(line);
      }
    }

    content = newLines.join('\n');

    // Add assets section if not present
    if (!content.contains('assets:')) {
      if (content.contains('uses-material-design: true')) {
        content = content.replaceFirst(
          'uses-material-design: true',
          '''uses-material-design: true

  assets:
    - assets/images/
    - assets/icons/
    - assets/fonts/''',
        );
      } else {
        // Add flutter section with assets at the end if it doesn't exist
        content += '''

flutter:
  uses-material-design: true

  assets:
    - assets/images/
    - assets/icons/
    - assets/fonts/
''';
      }
    }

    await file.writeAsString(content);
  }

  /// Updates the Android package name in build.gradle and AndroidManifest.xml
  Future<void> updateAndroidPackageName() async {
    // Update android/app/build.gradle
    final buildGradlePath = p.join(projectPath, 'android', 'app', 'build.gradle');
    final buildGradleFile = File(buildGradlePath);
    if (await buildGradleFile.exists()) {
      String content = await buildGradleFile.readAsString();
      // Update namespace
      content = content.replaceAllMapped(
        RegExp(r'namespace\s*=?\s*"[^"]+"'),
        (match) => 'namespace = "$packageName"',
      );
      // Update applicationId
      content = content.replaceAllMapped(
        RegExp(r'applicationId\s*=?\s*"[^"]+"'),
        (match) => 'applicationId = "$packageName"',
      );
      await buildGradleFile.writeAsString(content);
      printSuccess('Updated Android build.gradle');
    }

    // Update AndroidManifest.xml (main)
    final manifestPath = p.join(projectPath, 'android', 'app', 'src', 'main', 'AndroidManifest.xml');
    final manifestFile = File(manifestPath);
    if (await manifestFile.exists()) {
      String content = await manifestFile.readAsString();
      content = content.replaceAllMapped(
        RegExp(r'package\s*=\s*"([^"]+)"'),
        (match) => 'package="$packageName"',
      );
      await manifestFile.writeAsString(content);
      printSuccess('Updated Android AndroidManifest.xml');
    }

    // Update debug AndroidManifest.xml
    final debugManifestPath = p.join(projectPath, 'android', 'app', 'src', 'debug', 'AndroidManifest.xml');
    final debugManifestFile = File(debugManifestPath);
    if (await debugManifestFile.exists()) {
      String content = await debugManifestFile.readAsString();
      content = content.replaceAllMapped(
        RegExp(r'package\s*=\s*"([^"]+)"'),
        (match) => 'package="$packageName"',
      );
      await debugManifestFile.writeAsString(content);
    }

    // Update profile AndroidManifest.xml
    final profileManifestPath = p.join(projectPath, 'android', 'app', 'src', 'profile', 'AndroidManifest.xml');
    final profileManifestFile = File(profileManifestPath);
    if (await profileManifestFile.exists()) {
      String content = await profileManifestFile.readAsString();
      content = content.replaceAllMapped(
        RegExp(r'package\s*=\s*"([^"]+)"'),
        (match) => 'package="$packageName"',
      );
      await profileManifestFile.writeAsString(content);
    }

    // Update Kotlin MainActivity package
    await _updateKotlinPackage();
  }

  /// Updates Kotlin source files with new package name
  Future<void> _updateKotlinPackage() async {
    final parts = packageName.split('.');
    final kotlinPath = p.join(projectPath, 'android', 'app', 'src', 'main', 'kotlin');

    // Find existing MainActivity.kt
    final mainActivityFiles = await _findFiles(kotlinPath, 'MainActivity.kt');

    for (final file in mainActivityFiles) {
      String content = await file.readAsString();
      content = content.replaceAllMapped(
        RegExp(r'package\s+[\w.]+'),
        (match) => 'package $packageName',
      );

      // Create new directory structure based on package name
      final newDir = p.join(kotlinPath, parts.join(Platform.pathSeparator));
      await Directory(newDir).create(recursive: true);

      final newFilePath = p.join(newDir, 'MainActivity.kt');
      await File(newFilePath).writeAsString(content);

      // Remove old file if it's different
      if (file.path != newFilePath) {
        try {
          await file.delete();
          // Clean up empty directories
          var parent = file.parent;
          while (parent.path != kotlinPath) {
            if (await parent.list().isEmpty) {
              await parent.delete();
            }
            parent = parent.parent;
          }
        } catch (_) {}
      }
    }
  }

  /// Updates the iOS bundle identifier
  Future<void> updateIOSBundleIdentifier() async {
    // Update iOS project.pbxproj
    final pbxprojPath = p.join(projectPath, 'ios', 'Runner.xcodeproj', 'project.pbxproj');
    final pbxprojFile = File(pbxprojPath);
    if (await pbxprojFile.exists()) {
      String content = await pbxprojFile.readAsString();
      content = content.replaceAllMapped(
        RegExp(r'PRODUCT_BUNDLE_IDENTIFIER\s*=\s*([^;]+);'),
        (match) => 'PRODUCT_BUNDLE_IDENTIFIER = $packageName;',
      );
      await pbxprojFile.writeAsString(content);
      printSuccess('Updated iOS project.pbxproj');
    }

    // Update Info.plist if it has CFBundleIdentifier
    final infoPlistPath = p.join(projectPath, 'ios', 'Runner', 'Info.plist');
    final infoPlistFile = File(infoPlistPath);
    if (await infoPlistFile.exists()) {
      String content = await infoPlistFile.readAsString();
      // Update CFBundleIdentifier if it exists with a hardcoded value
      content = content.replaceAllMapped(
        RegExp(r'<key>CFBundleIdentifier</key>\s*<string>([^<]+)</string>'),
        (match) {
          final value = match.group(1)!;
          // Keep $(PRODUCT_BUNDLE_IDENTIFIER) if that's what's there
          if (value.contains('\$(PRODUCT_BUNDLE_IDENTIFIER)')) {
            return match.group(0)!;
          }
          return '<key>CFBundleIdentifier</key>\n\t<string>$packageName</string>';
        },
      );
      await infoPlistFile.writeAsString(content);
    }
  }

  /// Helper to find files recursively
  Future<List<File>> _findFiles(String dirPath, String fileName) async {
    final dir = Directory(dirPath);
    final files = <File>[];
    if (!await dir.exists()) return files;

    await for (final entity in dir.list(recursive: true)) {
      if (entity is File && p.basename(entity.path) == fileName) {
        files.add(entity);
      }
    }
    return files;
  }
}

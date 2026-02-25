import 'package:ansicolor/ansicolor.dart';

final _cyan = AnsiPen()..cyan(bold: true);
final _green = AnsiPen()..green(bold: true);
final _yellow = AnsiPen()..yellow(bold: true);
final _red = AnsiPen()..red(bold: true);
final _blue = AnsiPen()..blue(bold: true);
final _magenta = AnsiPen()..magenta(bold: true);
final _white = AnsiPen()..white(bold: true);
final _gray = AnsiPen()..gray(level: 0.5);

String cyan(String text) => _cyan(text);
String green(String text) => _green(text);
String yellow(String text) => _yellow(text);
String red(String text) => _red(text);
String blue(String text) => _blue(text);
String magenta(String text) => _magenta(text);
String white(String text) => _white(text);
String gray(String text) => _gray(text);

void printBanner() {
  print('');
  print(cyan('  ███████╗████████╗ █████╗      ██████╗██╗     ██╗'));
  print(cyan('  ██╔════╝╚══██╔══╝██╔══██╗    ██╔════╝██║     ██║'));
  print(cyan('  ███████╗   ██║   ███████║    ██║     ██║     ██║'));
  print(cyan('  ╚════██║   ██║   ██╔══██║    ██║     ██║     ██║'));
  print(cyan('  ███████║   ██║   ██║  ██║    ╚██████╗███████╗██║'));
  print(cyan('  ╚══════╝   ╚═╝   ╚═╝  ╚═╝     ╚═════╝╚══════╝╚═╝'));
  print('');
  print(magenta('  ✦ STA CLI — Flutter Project Generator v0.1.6 ✦'));
  print(gray('  Scaffold your Flutter MVC project in seconds'));
  print('');
}

void printStep(int step, int total, String message) {
  print(cyan('  [$step/$total] ') + white(message));
}

void printSuccess(String message) {
  print(green('  ✔ ') + message);
}

void printError(String message) {
  print(red('  ✘ ') + message);
}

void printInfo(String message) {
  print(blue('  ℹ ') + message);
}

void printWarning(String message) {
  print(yellow('  ⚠ ') + message);
}

void printDivider() {
  print(gray('  ${'─' * 50}'));
}

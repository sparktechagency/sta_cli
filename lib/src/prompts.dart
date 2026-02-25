import 'dart:io';
import 'colors.dart';

/// Prompt user with a question and return the answer.
String prompt(String question, {String? defaultValue}) {
  final defStr = defaultValue != null ? gray(' ($defaultValue)') : '';
  stdout.write('  ${cyan('?')} $question$defStr: ');
  var input = stdin.readLineSync()?.trim() ?? '';
  // Remove any surrounding quotes that might be pasted from file explorer
  input = input.replaceAll('"', '').replaceAll("'", '');
  return input.isEmpty && defaultValue != null ? defaultValue : input;
}

/// Ask user to select from options. Returns the selected index (0-based).
int selectOption(String question, List<String> options, {int defaultIndex = 0}) {
  print('  ${cyan('?')} $question');
  for (var i = 0; i < options.length; i++) {
    final isDefault = i == defaultIndex;
    final marker = isDefault ? green('▶') : ' ';
    print('    $marker ${cyan('${i + 1}.')} ${options[i]}${isDefault ? gray(' (default)') : ''}');
  }
  stdout.write('  ${gray('Enter number')} [1-${options.length}]: ');
  final input = stdin.readLineSync()?.trim() ?? '';
  if (input.isEmpty) return defaultIndex;
  final num = int.tryParse(input);
  if (num == null || num < 1 || num > options.length) {
    printWarning('Invalid selection, using default: ${options[defaultIndex]}');
    return defaultIndex;
  }
  return num - 1;
}

/// Confirm yes/no question. Returns true for yes.
bool confirm(String question, {bool defaultYes = true}) {
  final hint = defaultYes ? gray('[Y/n]') : gray('[y/N]');
  stdout.write('  ${cyan('?')} $question $hint: ');
  final input = stdin.readLineSync()?.trim().toLowerCase() ?? '';
  if (input.isEmpty) return defaultYes;
  return input == 'y' || input == 'yes';
}

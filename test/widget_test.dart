import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grocery_mate/theme/app_theme.dart';

void main() {
  test('AppTheme provides light and dark themes', () {
    expect(AppTheme.lightTheme.brightness, Brightness.light);
    expect(AppTheme.darkTheme.brightness, Brightness.dark);
    expect(AppTheme.primaryGreen, isNotNull);
  });
}

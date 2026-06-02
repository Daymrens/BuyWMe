import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:grocery_mate/providers/theme_provider.dart';

void main() {
  group('Dark Mode Provider Tests', () {
    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
    });

    test('Theme provider initializes with system theme on first launch', () {
      final notifier = ThemeNotifier();
      expect(notifier.state, ThemeMode.system);
    });

    test('Theme can be set to light mode', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      
      final notifier = container.read(themeProvider.notifier);
      await notifier.setTheme(ThemeMode.light);
      
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('theme_mode'), 'light');
    });

    test('Theme can be set to dark mode', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      
      final notifier = container.read(themeProvider.notifier);
      await notifier.setTheme(ThemeMode.dark);
      
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('theme_mode'), 'dark');
    });

    test('Theme can be set to system preference', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      
      final notifier = container.read(themeProvider.notifier);
      await notifier.setTheme(ThemeMode.system);
      
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('theme_mode'), 'system');
    });

    test('Theme can be toggled from dark to light', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      
      final notifier = container.read(themeProvider.notifier);
      await notifier.setTheme(ThemeMode.dark);
      expect(container.read(themeProvider), ThemeMode.dark);
      
      await notifier.toggleTheme();
      expect(container.read(themeProvider), ThemeMode.light);
    });

    test('Theme can be toggled from light to dark', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      
      final notifier = container.read(themeProvider.notifier);
      await notifier.setTheme(ThemeMode.light);
      expect(container.read(themeProvider), ThemeMode.light);
      
      await notifier.toggleTheme();
      expect(container.read(themeProvider), ThemeMode.dark);
    });

    test('Theme mode string conversion works', () {
      final darkString = ThemeNotifier.themeModeToString(ThemeMode.dark);
      final lightString = ThemeNotifier.themeModeToString(ThemeMode.light);
      final systemString = ThemeNotifier.themeModeToString(ThemeMode.system);
      
      expect(darkString, 'dark');
      expect(lightString, 'light');
      expect(systemString, 'system');
    });

    test('Theme string to mode conversion works', () {
      expect(ThemeNotifier.stringToThemeMode('dark'), ThemeMode.dark);
      expect(ThemeNotifier.stringToThemeMode('light'), ThemeMode.light);
      expect(ThemeNotifier.stringToThemeMode('system'), ThemeMode.system);
    });

    test('Invalid theme string defaults to system', () {
      expect(ThemeNotifier.stringToThemeMode('invalid'), ThemeMode.system);
      expect(ThemeNotifier.stringToThemeMode(''), ThemeMode.system);
      expect(ThemeNotifier.stringToThemeMode('unknown'), ThemeMode.system);
    });

    test('Theme preference persists across provider instances', () async {
      SharedPreferences.setMockInitialValues({});
      
      final container1 = ProviderContainer();
      final notifier1 = container1.read(themeProvider.notifier);
      await notifier1.setTheme(ThemeMode.dark);
      
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('theme_mode'), 'dark');
      
      final container2 = ProviderContainer();
      final notifier2 = container2.read(themeProvider.notifier);
      await notifier2.initialize();
      expect(container2.read(themeProvider), ThemeMode.dark);
    });

    test('First launch initializes with system theme', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      
      final notifier = container.read(themeProvider.notifier);
      await notifier.initialize();
      
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('theme_mode'), 'system');
      expect(container.read(themeProvider), ThemeMode.system);
    });

    test('Subsequent launches load saved theme', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'dark'});
      final container = ProviderContainer();
      
      final notifier = container.read(themeProvider.notifier);
      await notifier.initialize();
      
      expect(container.read(themeProvider), ThemeMode.dark);
    });
  });
}


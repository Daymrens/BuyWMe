import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:buyWMe/providers/theme_provider.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  late MockSharedPreferences mockPrefs;
  late ThemeNotifier notifier;

  setUp(() {
    mockPrefs = MockSharedPreferences();
    SharedPreferences.setMockInitialValues({});
    notifier = ThemeNotifier();
  });

  group('ThemeNotifier', () {
    test('initial state is ThemeMode.system', () {
      expect(notifier.state, ThemeMode.system);
    });

    test('initialize loads saved theme from preferences', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'dark'});

      await notifier.initialize();

      expect(notifier.state, ThemeMode.dark);
    });

    test('initialize defaults to system when no saved theme', () async {
      SharedPreferences.setMockInitialValues({});

      await notifier.initialize();

      expect(notifier.state, ThemeMode.system);
    });

    test('setTheme updates state and saves to preferences', () async {
      await notifier.setTheme(ThemeMode.light);

      expect(notifier.state, ThemeMode.light);
    });

    test('toggleTheme switches between light and dark', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'light'});
      await notifier.initialize();
      expect(notifier.state, ThemeMode.light);

      await notifier.toggleTheme();
      expect(notifier.state, ThemeMode.dark);

      await notifier.toggleTheme();
      expect(notifier.state, ThemeMode.light);
    });

    test('themeModeToString converts correctly', () {
      expect(ThemeNotifier.themeModeToString(ThemeMode.light), 'light');
      expect(ThemeNotifier.themeModeToString(ThemeMode.dark), 'dark');
      expect(ThemeNotifier.themeModeToString(ThemeMode.system), 'system');
    });

    test('stringToThemeMode converts correctly', () {
      expect(ThemeNotifier.stringToThemeMode('light'), ThemeMode.light);
      expect(ThemeNotifier.stringToThemeMode('dark'), ThemeMode.dark);
      expect(ThemeNotifier.stringToThemeMode('system'), ThemeMode.system);
      expect(ThemeNotifier.stringToThemeMode('invalid'), ThemeMode.system);
    });
  });
}
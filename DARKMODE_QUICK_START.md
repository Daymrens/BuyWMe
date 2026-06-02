# Dark Mode - Quick Start Guide

## For Users

### How to Change Theme
1. Open the app and navigate to the **Account** tab (last icon)
2. Scroll to **Preferences** section
3. Tap on **Theme** option
4. Choose from:
   - **System Preference** (follows your device settings)
   - **Light Mode** (always bright)
   - **Dark Mode** (always dark)
5. Tap your choice - theme changes instantly!

## For Developers

### Using Theme Colors
```dart
// Get theme colors
final isDark = Theme.of(context).brightness == Brightness.dark;

// Use theme colors in widgets
Container(
  color: isDark ? AppTheme.darkBg : AppTheme.lightBg,
  child: Text(
    'Hello',
    style: Theme.of(context).textTheme.bodyLarge,
  ),
)

// Use theme surfaces
Card(
  color: Theme.of(context).colorScheme.surface,
  child: Text('Card content'),
)
```

### Watching Theme Changes
```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    
    return Container(
      color: themeMode == ThemeMode.dark 
        ? AppTheme.darkBg 
        : AppTheme.lightBg,
    );
  }
}
```

### Changing Theme Programmatically
```dart
// Set specific theme
ref.read(themeProvider.notifier).setTheme(ThemeMode.dark);

// Toggle between light and dark
ref.read(themeProvider.notifier).toggleTheme();
```

## Files Modified
- `lib/theme/app_theme.dart` - Theme definitions
- `lib/providers/theme_provider.dart` - NEW: Theme state management
- `lib/app.dart` - Theme initialization
- `lib/screens/account/account_screen.dart` - Theme selector UI
- `lib/widgets/animated_checkmark.dart` - Color updates
- `lib/widgets/add_item_card_sheet.dart` - Color updates

## Available Colors in AppTheme
```dart
AppTheme.primaryGreen         // #00C853 (primary brand color)
AppTheme.gradientStart        // #00C853 (gradient)
AppTheme.gradientEnd          // #1DE9B6 (gradient)
AppTheme.darkBg               // #0A0E21 (dark background)
AppTheme.darkSurface          // #1D1F33 (dark surface)
AppTheme.lightBg              // #F5F7FA (light background)
AppTheme.lightSurface         // #FFFFFF (light surface)
```

## Testing
Run tests: `flutter test test/theme_test.dart`
All 12 theme tests pass ✅

## Troubleshooting

**Q: Theme not persisting?**
A: Check SharedPreferences is initialized and theme_mode key is saved.

**Q: Colors look wrong?**
A: Ensure you're using `Theme.of(context).colorScheme` instead of hardcoded colors.

**Q: App crashes on theme change?**
A: Make sure you're not accessing theme during build if not using ConsumerWidget.

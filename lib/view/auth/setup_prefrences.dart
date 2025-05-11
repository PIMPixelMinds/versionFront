import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../core/utils/locale_provider.dart';
import '../../../core/utils/theme_provider.dart';
import '../../../core/utils/notification_provider.dart';
import '../../../core/constants/app_colors.dart';

class SetupPreferencesPage extends StatelessWidget {
  const SetupPreferencesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    final localeProvider = Provider.of<LocaleProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final notificationProvider = Provider.of<NotificationProvider>(context);

    final currentLocale = localeProvider.locale?.languageCode ?? 'system';
    final currentThemeMode = themeProvider.themeMode;
    final notificationsEnabled = notificationProvider.notificationsEnabled;

    return Scaffold(
      appBar: AppBar(
  backgroundColor: Theme.of(context).brightness == Brightness.dark
      ? Colors.black
      : Colors.white, // ✅ noir en dark, blanc en light
  iconTheme: IconThemeData(
    color: Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black, // ✅ icônes adaptatives
  ),
  title: Text(
    locale.preferences,
    style: TextStyle(
      color: Theme.of(context).brightness == Brightness.dark
          ? Colors.white
          : Colors.black, // ✅ titre adaptatif
      fontWeight: FontWeight.bold,
    ),
  ),
  elevation: 0,
  centerTitle: true,
),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildCard(
              context,
              icon: Icons.language,
              title: locale.language,
              subtitle: currentLocale == 'en'
                  ? 'English'
                  : currentLocale == 'fr'
                      ? 'Français'
                      : locale.systemDefault,
              onTap: () => _showLanguageDialog(context, localeProvider),
            ),
            const SizedBox(height: 12),
            _buildCard(
              context,
              icon: Icons.brightness_6_rounded,
              title: locale.theme,
              subtitle: currentThemeMode == ThemeMode.light
                  ? locale.light
                  : currentThemeMode == ThemeMode.dark
                      ? locale.dark
                      : locale.systemDefault,
              onTap: () => _showThemeDialog(context, themeProvider),
            ),
            const SizedBox(height: 12),
            _buildSwitchCard(
              context,
              icon: Icons.notifications_active_rounded,
              title: locale.notifications,
              subtitle: notificationsEnabled
                  ? locale.notificationsOn
                  : locale.notificationsOff,
              value: notificationsEnabled,
              onChanged: (value) {
                notificationProvider.setNotificationsEnabled(value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context,
    {required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return Card(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: AppColors.primaryBlue, width: 1.5), // ✅ blue border
    ),
    color: isDark ? Colors.black : Colors.white, // ✅ dark/light background
    elevation: 0, // ✅ remove shadow for clean outline look
    child: ListTile(
      leading: Icon(icon, color: AppColors.primaryBlue),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    ),
  );
}

  Widget _buildSwitchCard(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String subtitle,
  required bool value,
  required ValueChanged<bool> onChanged,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return Card(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
    ),
    color: isDark ? Colors.black : Colors.white,
    elevation: 0,
    child: SwitchListTile(
      activeColor: AppColors.primaryBlue,
      activeTrackColor: AppColors.primaryBlue.withOpacity(0.4),
      secondary: Icon(icon, color: AppColors.primaryBlue),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
    ),
  );
}

  void _showLanguageDialog(BuildContext context, LocaleProvider localeProvider) {
    final locale = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(locale.selectLanguage),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        children: [
          _buildDialogOption(context, 'English', () {
            localeProvider.setLocale(const Locale('en'));
            Navigator.pop(context);
          }),
          _buildDialogOption(context, 'Français', () {
            localeProvider.setLocale(const Locale('fr'));
            Navigator.pop(context);
          }),
          _buildDialogOption(context, locale.systemDefault, () {
            localeProvider.setLocale(Locale(Platform.localeName.split('_')[0]));
            Navigator.pop(context);
          }),
        ],
      ),
    );
  }

  void _showThemeDialog(BuildContext context, ThemeProvider themeProvider) {
    final locale = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(locale.selectTheme),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        children: [
          _buildDialogOption(context, locale.light, () {
            themeProvider.setThemeMode(ThemeMode.light);
            Navigator.pop(context);
          }),
          _buildDialogOption(context, locale.dark, () {
            themeProvider.setThemeMode(ThemeMode.dark);
            Navigator.pop(context);
          }),
          _buildDialogOption(context, locale.systemDefault, () {
            themeProvider.setThemeMode(ThemeMode.system);
            Navigator.pop(context);
          }),
        ],
      ),
    );
  }

  Widget _buildDialogOption(BuildContext context, String text, VoidCallback onTap) {
    return SimpleDialogOption(
      child: Text(text, style: const TextStyle(fontSize: 16)),
      onPressed: onTap,
    );
  }
}
import 'package:flutter/material.dart';
import 'package:pim/core/constants/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:pim/viewmodel/notification_viewmodel.dart';
import 'package:pim/data/model/notification_model.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    return ChangeNotifierProvider(
      create: (_) => NotificationViewModel()..fetchNotifications(),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.primaryBlue,
          title: Text(localizations.notifications,
              style: TextStyle(fontSize: screenWidth * 0.045)),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                context.read<NotificationViewModel>().fetchNotifications();
              },
            ),
          ],
        ),
        body: Consumer<NotificationViewModel>(
          builder: (context, viewModel, _) {
            if (viewModel.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (viewModel.errorMessage != null &&
                viewModel.errorMessage!.isNotEmpty) {
              return Center(
                child: Text(
                  '${localizations.error}: ${viewModel.errorMessage}',
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }

            if (viewModel.notifications.isEmpty) {
              return Center(
                child: Text(
                  localizations.noNotifications,
                  style: const TextStyle(fontSize: 18, color: Colors.grey),
                ),
              );
            }

            final todayNotifs = viewModel.notifications
                .where((notif) => _isToday(notif.createdAt))
                .toList();

            final previousNotifs = viewModel.notifications
                .where((notif) => !_isToday(notif.createdAt))
                .toList();

            return Column(
              children: [
                Container(
                  width: double.infinity,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  child: TextButton.icon(
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(localizations.confirmation),
                          content: Text(localizations.confirmDeleteAll),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text(localizations.cancel),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: Text(localizations.delete),
                            ),
                          ],
                        ),
                      );

                      if (confirmed == true) {
                        await context
                            .read<NotificationViewModel>()
                            .deleteAllNotifications();
                      }
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: Text(localizations.removeAllNotifications),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryBlue,
                      textStyle: TextStyle(fontSize: screenWidth * 0.04),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (todayNotifs.isNotEmpty)
                        _buildSection(
                            localizations.today, todayNotifs, context),
                      if (previousNotifs.isNotEmpty)
                        _buildSection(localizations.previousNotifications,
                            previousNotifs, context),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSection(
      String title, List<Notifications> notifications, BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final iconPath = isDarkMode
        ? 'assets/notification_icon.png'
        : 'assets/notification_icon_light.png';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        ...notifications.map((notif) => Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5)),
              color: isDarkMode ? Colors.grey[850] : Colors.white,
              child: ListTile(
                title: Text(notif.title, style: const TextStyle(fontSize: 14)),
                subtitle: Text(notif.message),
              ),
            )),
        const SizedBox(height: 16),
      ],
    );
  }
}

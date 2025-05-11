import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pim/viewmodel/notification_viewmodel.dart';
import 'package:pim/data/model/notification_model.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  final Color primaryColor = const Color(0xFF1E88E5);

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NotificationViewModel()..fetchNotifications(),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: primaryColor,
          title: const Text('Notifications'),
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
                  'Error: ${viewModel.errorMessage}',
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }

            if (viewModel.notifications.isEmpty) {
              return const Center(
                child: Text(
                  'No notifications 🎉',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
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
                  color: primaryColor.withOpacity(0.1),
                  child: TextButton.icon(
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text("Confirm"),
                          content: const Text(
                              "Are you sure you want to delete all notifications?"),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text("Cancel"),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text("Delete"),
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
                    label: const Text('Remove All Notifications'),
                    style: TextButton.styleFrom(
                      foregroundColor: primaryColor,
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (todayNotifs.isNotEmpty)
                        _buildSection('Today', todayNotifs, context),
                      if (previousNotifs.isNotEmpty)
                        _buildSection(
                            'Previous Notifications', previousNotifs, context),
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
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    String iconPath = isDarkMode
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
                borderRadius: BorderRadius.circular(5),
              ),
              child: ListTile(
                leading: Image.asset(
                  iconPath,
                  width: 40,
                  height: 40,
                ),
                title: Text(
                  notif.title,
                  style: const TextStyle(fontSize: 14),
                ),
                subtitle: Text(notif.message),
              ),
            )),
        const SizedBox(height: 16),
      ],
    );
  }
}

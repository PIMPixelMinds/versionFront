import 'package:date_picker_timeline/date_picker_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pim/core/constants/app_colors.dart';
import 'package:pim/view/appointment/add_appointment.dart';
import 'package:pim/viewmodel/appointment_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

enum FilterStatus { Upcoming, Completed, Canceled }

class AppointmentPage extends StatefulWidget {
  const AppointmentPage({Key? key}) : super(key: key);

  @override
  State<AppointmentPage> createState() => _AppointmentPageState();
}

class _AppointmentPageState extends State<AppointmentPage> {
  FilterStatus status = FilterStatus.Upcoming;
  Alignment _alignment = Alignment.centerLeft;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppointmentViewModel>(context, listen: false)
          .fetchAppointments();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final local = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.black
            : Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Colors.black,
        ),
        title: Text(
          local.appointmentSchedule,
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: AppColors.primaryBlue, size: 28),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const AddAppointmentSheet(),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _weekDaysView(isDarkMode),
            const SizedBox(height: 16),
            _datePickerView(isDarkMode),
            const SizedBox(height: 16),
            _filterTabs(isDarkMode),
            const SizedBox(height: 16),
            Expanded(child: _appointmentList(isDarkMode)),
          ],
        ),
      ),
    );
  }

  Widget _weekDaysView(bool isDarkMode) {
    final local = AppLocalizations.of(context)!;
    final localeCode = Localizations.localeOf(context).languageCode;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            DateFormat.yMMMd(localeCode).format(DateTime.now()),
            style: TextStyle(
                fontSize: 18,
                color: isDarkMode ? Colors.grey[300] : Colors.grey[600]),
          ),
          const SizedBox(height: 4),
          Text(
            local.today,
            style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black),
          ),
        ]),
      ],
    );
  }

  Widget _datePickerView(bool isDarkMode) {
    return DatePicker(
      DateTime.now(),
      height: 80,
      width: 75,
      locale: Localizations.localeOf(context).languageCode, // ✅ ajout clé
      initialSelectedDate: DateTime.now(),
      selectionColor: AppColors.primaryBlue,
      selectedTextColor: Colors.white,
      dateTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: isDarkMode ? Colors.grey[400]! : Colors.black,
      ),
      monthTextStyle: const TextStyle(
        fontSize: 0,
        height: 0,
        color: Colors.transparent,
      ),
      dayTextStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: isDarkMode ? Colors.grey[400]! : Colors.black,
      ),
      controller: DatePickerController(),
    );
  }

  Widget _filterTabs(bool isDarkMode) {
    final local = AppLocalizations.of(context)!;

    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.grey[800]
            : Colors.grey[300], // ⬅ même couleur que TabBar
        borderRadius: BorderRadius.circular(25),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            alignment: _alignment,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: Container(
              width: MediaQuery.of(context).size.width / 2.7 - 26,
              height: 45,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          Row(
            children: FilterStatus.values.map((filterStatus) {
              final isSelected = status == filterStatus;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      status = filterStatus;
                      _alignment = switch (status) {
                        FilterStatus.Upcoming => Alignment.centerLeft,
                        FilterStatus.Completed => Alignment.center,
                        FilterStatus.Canceled => Alignment.centerRight,
                      };
                    });
                  },
                  child: Center(
                    child: Text(
                      _getStatusLabel(filterStatus, local),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : (isDarkMode ? Colors.white70 : Colors.black87),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _appointmentList(bool isDarkMode) {
    final local = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;

    return Consumer<AppointmentViewModel>(
      builder: (context, viewModel, _) {
        if (viewModel.isLoading)
          return const Center(child: CircularProgressIndicator());

        final filtered = viewModel.appointments
            .where((a) => a.status == status.name)
            .toList();

        if (filtered.isEmpty) {
          return Center(
            child: Text(
              local.noAppointments(_getStatusLabel(status, local)),
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode
                    ? const Color.fromARGB(179, 130, 130, 130)
                    : Colors.black87,
              ),
            ),
          );
        }

        return ListView.builder(
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final appointment = filtered[index];
            return Card(
              color:
                  isDarkMode ? Colors.black : Colors.white, // ✅ fond dynamique
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(
                  color: AppColors.primaryBlue, // ✅ bordure bleue
                  width: 1.5,
                ),
              ),
              elevation: 3,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading:
                    const Icon(Icons.event_note, color: AppColors.primaryBlue),
                title: Text(appointment.fullName),
                subtitle: Text(
                  DateFormat.yMMMd(locale).add_jm().format(appointment.date),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.cancel, color: AppColors.error),
                  onPressed: () async {
                    await viewModel.cancelAppointment(appointment.fullName);
                    await viewModel.fetchAppointments();
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _getStatusLabel(FilterStatus status, AppLocalizations local) {
    switch (status) {
      case FilterStatus.Upcoming:
        return local.upcoming;
      case FilterStatus.Completed:
        return local.completed;
      case FilterStatus.Canceled:
        return local.canceled;
    }
  }
}

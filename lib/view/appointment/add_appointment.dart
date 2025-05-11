import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:pim/data/model/appointment_mode.dart';
import 'package:pim/view/notifications/notification_firebase_api.dart';
import 'package:pim/viewmodel/appointment_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AddAppointmentSheet extends StatefulWidget {
  const AddAppointmentSheet({super.key});

  @override
  State<AddAppointmentSheet> createState() => _AddAppointmentSheetState();
}

class _AddAppointmentSheetState extends State<AddAppointmentSheet> {
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  DateTime? selectedDate;
  String? fcmToken;

  @override
  void initState() {
    super.initState();
    _fetchFcmToken();
  }

  Future<void> _fetchFcmToken() async {
    final token = await NotificationFirebaseApi().getFcmToken();
    setState(() => fcmToken = token);
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<AppointmentViewModel>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final mediaQuery = MediaQuery.of(context);
    final local = AppLocalizations.of(context)!;

    return SafeArea(
      child: Padding(
        padding: mediaQuery.viewInsets, // move sheet up when keyboard is open
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[900] : Colors.white,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(25)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Text(
                  local.newAppointment,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 20),
                _buildTextField(local.fullName, local.doctorName,
                    fullNameController, isDarkMode),
                const SizedBox(height: 16),
                _buildDatePickerField(isDarkMode),
                const SizedBox(height: 16),
                _buildPhoneField(isDarkMode),
                const SizedBox(height: 24),
                _buildBottomButton(viewModel, isDarkMode),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDatePickerField(bool isDarkMode) {
    final local = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: () => _selectDateTime(context),
      child: AbsorbPointer(
        child: TextFormField(
          decoration: InputDecoration(
            labelText: selectedDate != null
                ? DateFormat('yMMMd – HH:mm').format(selectedDate!)
                : local.appointmentDate,
            filled: true,
            fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            suffixIcon: const Icon(Icons.calendar_today, color: Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneField(bool isDarkMode) {
    final local = AppLocalizations.of(context)!;
    return IntlPhoneField(
      controller: phoneController,
      decoration: InputDecoration(
        labelText: local.phoneNumber,
        filled: true,
        fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      initialCountryCode: 'TN',
      onChanged: (phone) {},
    );
  }

  Widget _buildBottomButton(AppointmentViewModel viewModel, bool isDarkMode) {
    final local = AppLocalizations.of(context)!;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          if (fullNameController.text.isEmpty ||
              selectedDate == null ||
              phoneController.text.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Please fill all fields")),
            );
            return;
          }

          final appointment = Appointment(
            fullName: fullNameController.text.trim(),
            date: selectedDate!,
            phone: phoneController.text,
            status: "Upcoming",
            fcmToken: fcmToken ?? "",
          );

          await viewModel.addAppointment(appointment);

          if (viewModel.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(viewModel.errorMessage!)),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Appointment added successfully!")),
            );
            await viewModel.fetchAppointments();
            Navigator.of(context).pop();
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: viewModel.isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(local.newAppointment,
                style: TextStyle(fontSize: 16, color: Colors.white)),
      ),
    );
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2026),
    );

    if (pickedDate == null) return;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime == null) return;

    final combinedDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    setState(() => selectedDate = combinedDateTime);
  }

  Widget _buildTextField(String label, String hint,
      TextEditingController controller, bool isDarkMode) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
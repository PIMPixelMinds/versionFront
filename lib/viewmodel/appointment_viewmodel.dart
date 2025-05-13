import 'package:flutter/material.dart';
import 'package:pim/data/model/appointment_mode.dart';
import '../data/repositories/appointment_repository.dart';

class AppointmentViewModel extends ChangeNotifier {
  final AppointmentRepository _repository = AppointmentRepository();

  bool isLoading = false;
  String? errorMessage;
  List<Appointment> appointments = [];

  Future<void> addAppointment(Appointment appointment) async {
    isLoading = true;
    notifyListeners();

    try {
      await _repository.addAppointment(appointment);
      errorMessage = null;
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateAppointment(
    String name, {
    required String newFullName,
    required String newDate,
    required String newPhone,
  }) async {
    isLoading = true;
    notifyListeners();

    try {
      await _repository.updateAppointment(
        name,
        newFullName: newFullName,
        newDate: newDate,
        newPhone: newPhone,
      );
      errorMessage = null;
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> cancelAppointment(String name) async {
    isLoading = true;
    notifyListeners();

    try {
      await _repository.cancelAppointment(name);
      errorMessage = null;
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAppointments() async {
    isLoading = true;
    notifyListeners();

    try {
      final data = await _repository.displayAppointments();
      appointments = (data['appointment'] as List)
          .map((item) => Appointment.fromJson(item))
          .toList();
      errorMessage = null;
    } catch (error) {
      errorMessage = error.toString();
    }

    isLoading = false;
    notifyListeners();
  }

  String? _userId;
  String? get userId => _userId;

  Future<void> fetchMyAppointmentUserId() async {
    isLoading = true;
    notifyListeners();

    try {
      _userId = await _repository.getMyAppointmentUserId();
      errorMessage = null;
    } catch (e) {
      errorMessage = e.toString();
      _userId = null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}

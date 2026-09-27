import 'package:flutter/foundation.dart';
import 'package:sikarir/features/training/data/models/training_schedule_model.dart';
import 'package:sikarir/features/training/data/repositories/training_schedule_repository.dart';

class TrainingScheduleProvider extends ChangeNotifier {
  final TrainingScheduleRepository repository;

  TrainingScheduleProvider({TrainingScheduleRepository? repository})
      : repository = repository ?? TrainingScheduleRepository();

  bool _isLoading = false;
  List<TrainingScheduleModel> _schedules = [];
  String _filter = 'Semua'; // 'Semua', 'tatap_muka', 'online'
  String? _errorMessage;

  bool get isLoading => _isLoading;
  List<TrainingScheduleModel> get schedules {
    if (_filter == 'Semua') return _schedules;
    return _schedules.where((s) => s.type.toLowerCase() == _filter.toLowerCase()).toList();
  }
  List<TrainingScheduleModel> get allSchedules => _schedules;
  String get filter => _filter;
  String? get errorMessage => _errorMessage;

  void setFilter(String val) {
    _filter = val;
    notifyListeners();
  }

  Future<void> fetchSchedules([String? token]) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await repository.getSchedules(token);
      _schedules = res;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

import 'package:flutter/foundation.dart';
import 'package:sikarir/features/training/data/models/training_class_model.dart';
import 'package:sikarir/features/training/data/repositories/training_class_repository.dart';

class TrainingClassProvider extends ChangeNotifier {
  final TrainingClassRepository repository;

  TrainingClassProvider({TrainingClassRepository? repository})
      : repository = repository ?? TrainingClassRepository();

  bool _isLoading = false;
  List<TrainingClassModel> _classes = [];
  TrainingClassModel? _selectedClass;
  String _filter = 'Semua'; // 'Semua', 'berlangsung', 'akan_datang', 'selesai'
  String? _errorMessage;

  bool get isLoading => _isLoading;
  List<TrainingClassModel> get classes {
    if (_filter == 'Semua') return _classes;
    return _classes.where((c) => c.status.toLowerCase() == _filter.toLowerCase()).toList();
  }
  List<TrainingClassModel> get allClasses => _classes;
  TrainingClassModel? get selectedClass => _selectedClass;
  String get filter => _filter;
  String? get errorMessage => _errorMessage;

  void setFilter(String val) {
    _filter = val;
    notifyListeners();
  }

  Future<void> fetchClasses([String? token]) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await repository.getMyClasses(token);
      _classes = res;
      if (_selectedClass == null && res.isNotEmpty) {
        _selectedClass = res.first;
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchClassDetail(String id, [String? token]) async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await repository.getClassDetail(id, token);
      _selectedClass = res;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

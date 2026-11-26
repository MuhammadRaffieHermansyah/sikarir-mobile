import 'package:flutter/foundation.dart';
import 'package:sikarir/features/job/data/models/job_model.dart';
import 'package:sikarir/features/job/data/repositories/job_repository.dart';

class JobProvider extends ChangeNotifier {
  final JobRepository repository;

  JobProvider({JobRepository? repository}) : repository = repository ?? JobRepository();

  bool _isLoading = false;
  bool _isOffline = false;
  List<JobVacancyModel> _jobs = [];
  String _searchQuery = '';
  String _selectedCategory = 'Semua Jurusan';
  String? _errorMessage;

  bool get isLoading => _isLoading;

  /// True jika data berasal dari fallback lokal (API tidak tersedia)
  bool get isOffline => _isOffline;

  List<JobVacancyModel> get jobs {
    return _jobs.where((job) {
      final q = _searchQuery.toLowerCase();
      final matchesSearch = q.isEmpty ||
          job.title.toLowerCase().contains(q) ||
          job.companyName.toLowerCase().contains(q) ||
          job.qualification.toLowerCase().contains(q) ||
          job.location.toLowerCase().contains(q) ||
          job.description.toLowerCase().contains(q);

      bool matchesFilter = true;
      if (_selectedCategory == '📍 DKI & Jawa Barat') {
        final loc = job.location.toLowerCase();
        matchesFilter = loc.contains('jakarta') ||
            loc.contains('dki') ||
            loc.contains('jawa barat') ||
            loc.contains('jabar') ||
            loc.contains('bandung') ||
            loc.contains('bekasi') ||
            loc.contains('bogor') ||
            loc.contains('depok') ||
            loc.contains('tangerang') ||
            loc.contains('cikarang');
      } else if (_selectedCategory == '⏱ Full-Time') {
        final t = job.type.toLowerCase();
        matchesFilter = t.contains('full-time') || t.contains('full time') || t.contains('penuh');
      }

      return matchesSearch && matchesFilter;
    }).toList();
  }

  List<JobVacancyModel> get allJobs => _jobs;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  String? get errorMessage => _errorMessage;

  void setSearchQuery(String q) {
    _searchQuery = q;
    notifyListeners();
  }

  void setCategory(String cat) {
    _selectedCategory = cat;
    notifyListeners();
  }

  void toggleBookmark(String id) {
    final idx = _jobs.indexWhere((j) => j.id == id);
    if (idx != -1) {
      _jobs[idx] = _jobs[idx].copyWith(isBookmarked: !_jobs[idx].isBookmarked);
      notifyListeners();
    }
  }

  Future<void> fetchJobs([String? token]) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await repository.getJobs(token);
      _jobs = result.jobs;
      _isOffline = result.isOffline;
      if (kDebugMode) {
        debugPrint(
          'JobProvider: ${_jobs.length} lowongan dimuat. isOffline=$_isOffline',
        );
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isOffline = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

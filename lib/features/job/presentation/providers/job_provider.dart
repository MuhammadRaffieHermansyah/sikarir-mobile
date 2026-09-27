import 'package:flutter/foundation.dart';
import 'package:sikarir/features/job/data/models/job_model.dart';
import 'package:sikarir/features/job/data/repositories/job_repository.dart';

class JobProvider extends ChangeNotifier {
  final JobRepository repository;

  JobProvider({JobRepository? repository}) : repository = repository ?? JobRepository();

  bool _isLoading = false;
  List<JobVacancyModel> _jobs = [];
  String _searchQuery = '';
  String _selectedCategory = 'Semua Jurusan';
  String? _errorMessage;

  bool get isLoading => _isLoading;
  List<JobVacancyModel> get jobs {
    return _jobs.where((job) {
      final matchesSearch = job.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          job.companyName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          job.qualification.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesSearch;
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
      final res = await repository.getJobs(token);
      _jobs = res;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> applyJob(String jobId, [String? token]) async {
    try {
      await repository.applyJob(jobId, token);
    } catch (_) {}
  }
}

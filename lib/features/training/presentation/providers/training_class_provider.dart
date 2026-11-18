import 'package:flutter/foundation.dart';
import 'package:sikarir/features/training/data/models/training_catalog_model.dart';
import 'package:sikarir/features/training/data/models/training_class_model.dart';
import 'package:sikarir/features/training/data/repositories/training_class_repository.dart';

class TrainingClassProvider extends ChangeNotifier {
  final TrainingClassRepository repository;

  TrainingClassProvider({TrainingClassRepository? repository})
      : repository = repository ?? TrainingClassRepository();

  // Catalog State
  bool _isLoadingCatalog = false;
  List<TrainingCatalogModel> _catalog = [];
  String _catalogCategoryFilter = 'Semua';
  String _searchQuery = '';
  String? _catalogError;

  // Enrolled Classes State
  bool _isLoading = false;
  List<TrainingClassModel> _classes = [];
  TrainingClassModel? _selectedClass;
  String _filter = 'Semua'; // 'Semua', 'berlangsung', 'akan_datang', 'selesai'
  String? _errorMessage;

  // Enrollment action State
  bool _isEnrolling = false;

  // Getters - Catalog
  bool get isLoadingCatalog => _isLoadingCatalog;
  String get catalogCategoryFilter => _catalogCategoryFilter;
  String get searchQuery => _searchQuery;
  String? get catalogError => _catalogError;

  List<TrainingCatalogModel> get catalog {
    return _catalog.map((item) {
      final enrolled = isUserEnrolled(item.id, item.jadwalId);
      return item.copyWith(isEnrolled: enrolled);
    }).where((item) {
      // 1. Filter Category
      if (_catalogCategoryFilter != 'Semua') {
        final matchesCat = item.category.toLowerCase().contains(_catalogCategoryFilter.toLowerCase());
        final matchesStatus = item.status.toLowerCase() == _catalogCategoryFilter.toLowerCase();
        if (!matchesCat && !matchesStatus) return false;
      }
      // 2. Search Query
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final inTitle = item.title.toLowerCase().contains(q);
        final inDesc = item.description.toLowerCase().contains(q);
        final inSkkni = item.skkniCode.toLowerCase().contains(q);
        final inCat = item.category.toLowerCase().contains(q);
        final inLoc = item.location.toLowerCase().contains(q);
        final inInst = item.instructor.toLowerCase().contains(q);
        if (!inTitle && !inDesc && !inSkkni && !inCat && !inLoc && !inInst) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  List<TrainingCatalogModel> get allCatalog => _catalog;

  // Getters - Classes
  bool get isLoading => _isLoading;
  List<TrainingClassModel> get classes {
    if (_filter == 'Semua') return _classes;
    return _classes.where((c) => c.status.toLowerCase() == _filter.toLowerCase()).toList();
  }
  List<TrainingClassModel> get allClasses => _classes;
  TrainingClassModel? get selectedClass => _selectedClass;
  String get filter => _filter;
  String? get errorMessage => _errorMessage;
  bool get isEnrolling => _isEnrolling;

  // Filters & Search
  void setCatalogFilter(String val) {
    _catalogCategoryFilter = val;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setFilter(String val) {
    _filter = val;
    notifyListeners();
  }

  bool isUserEnrolled(String pelatihanId, [String? jadwalId]) {
    return _classes.any((c) =>
        (c.pelatihanId.isNotEmpty && c.pelatihanId == pelatihanId) ||
        (jadwalId != null && jadwalId.isNotEmpty && c.jadwalId.isNotEmpty && c.jadwalId == jadwalId) ||
        (c.id.isNotEmpty && c.id == pelatihanId));
  }

  // Fetch Catalog
  Future<void> fetchCatalog([String? token]) async {
    _isLoadingCatalog = true;
    _catalogError = null;
    notifyListeners();

    try {
      final res = await repository.getCatalog(token);
      _catalog = res;
    } catch (e) {
      _catalogError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoadingCatalog = false;
      notifyListeners();
    }
  }

  // Fetch Enrolled Classes
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
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Detail Class
  Future<void> fetchClassDetail(String id, [String? token]) async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await repository.getClassDetail(id, token);
      _selectedClass = res;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Enroll Training
  Future<bool> enrollTraining({
    required String jadwalId,
    String? pesertaId,
    String? token,
  }) async {
    _isEnrolling = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await repository.enrollTraining(
        jadwalId: jadwalId,
        pesertaId: pesertaId,
        token: token,
      );
      if (success) {
        // Refresh classes and catalog
        await fetchClasses(token);
        await fetchCatalog(token);
      }
      return success;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      _isEnrolling = false;
      notifyListeners();
    }
  }
}

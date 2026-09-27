import 'package:flutter/foundation.dart';
import 'package:sikarir/features/certificate/data/models/certificate_model.dart';
import 'package:sikarir/features/certificate/data/repositories/certificate_repository.dart';

class CertificateProvider extends ChangeNotifier {
  final CertificateRepository repository;

  CertificateProvider({CertificateRepository? repository})
      : repository = repository ?? CertificateRepository();

  bool _isLoading = false;
  List<CertificateModel> _certificates = [];
  String? _errorMessage;

  bool get isLoading => _isLoading;
  List<CertificateModel> get certificates => _certificates;
  String? get errorMessage => _errorMessage;

  Future<void> fetchCertificates([String? token]) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await repository.getCertificates(token);
      _certificates = res;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

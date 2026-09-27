import 'package:flutter/foundation.dart';
import 'package:sikarir/features/partner/data/models/partner_model.dart';
import 'package:sikarir/features/partner/data/repositories/partner_repository.dart';

class PartnerProvider extends ChangeNotifier {
  final PartnerRepository repository;

  PartnerProvider({PartnerRepository? repository})
      : repository = repository ?? PartnerRepository();

  bool _isLoading = false;
  List<PartnerModel> _partners = [];
  String? _errorMessage;

  bool get isLoading => _isLoading;
  List<PartnerModel> get partners => _partners;
  String? get errorMessage => _errorMessage;

  Future<void> fetchPartners([String? token]) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await repository.getPartners(token);
      _partners = res;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

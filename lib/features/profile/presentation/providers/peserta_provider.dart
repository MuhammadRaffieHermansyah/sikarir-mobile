import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sikarir/features/profile/data/models/peserta_profile_model.dart';
import 'package:sikarir/features/profile/data/services/peserta_service.dart';

class PesertaProvider extends ChangeNotifier {
  final PesertaService service;

  PesertaProvider({PesertaService? service})
      : service = service ?? PesertaService();

  bool _isLoading = false;
  PesertaProfile? _profile;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  PesertaProfile? get profile => _profile;
  String? get errorMessage => _errorMessage;

  bool get isProfileComplete => _profile?.isProfileComplete ?? false;

  Future<void> fetchProfile([String? token]) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await service.getMyProfile(token);
      _profile = res;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile(
    Map<String, dynamic> data, [
    String? token,
    File? pasFotoFile,
  ]) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await service.updateMyProfile(data, token, pasFotoFile);
      _profile = updated;
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> enrollTraining({
    required String jadwalId,
    String? token,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await service.enrollTraining(
        jadwalId: jadwalId,
        pesertaId: _profile?.idPeserta,
        token: token,
      );
      return success;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

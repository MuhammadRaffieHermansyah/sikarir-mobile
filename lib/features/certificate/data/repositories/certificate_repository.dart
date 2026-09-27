import 'package:sikarir/features/certificate/data/models/certificate_model.dart';
import 'package:sikarir/features/certificate/data/services/certificate_service.dart';

class CertificateRepository {
  final CertificateService service;

  CertificateRepository({CertificateService? service})
      : service = service ?? CertificateService();

  Future<List<CertificateModel>> getCertificates([String? token]) async {
    return await service.getCertificates(token);
  }
}

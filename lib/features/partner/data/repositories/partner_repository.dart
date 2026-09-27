import 'package:sikarir/features/partner/data/models/partner_model.dart';
import 'package:sikarir/features/partner/data/services/partner_service.dart';

class PartnerRepository {
  final PartnerService service;

  PartnerRepository({PartnerService? service}) : service = service ?? PartnerService();

  Future<List<PartnerModel>> getPartners([String? token]) async {
    return await service.getPartners(token);
  }
}

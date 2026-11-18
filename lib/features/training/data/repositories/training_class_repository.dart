import 'package:sikarir/features/training/data/models/training_catalog_model.dart';
import 'package:sikarir/features/training/data/models/training_class_model.dart';
import 'package:sikarir/features/training/data/services/training_class_service.dart';

class TrainingClassRepository {
  final TrainingClassService service;

  TrainingClassRepository({TrainingClassService? service})
      : service = service ?? TrainingClassService();

  Future<List<TrainingCatalogModel>> getCatalog([String? token]) async {
    return await service.getCatalog(token);
  }

  Future<bool> enrollTraining({
    required String jadwalId,
    String? pesertaId,
    String? token,
  }) async {
    return await service.enrollTraining(
      jadwalId: jadwalId,
      pesertaId: pesertaId,
      token: token,
    );
  }

  Future<List<TrainingClassModel>> getMyClasses([String? token]) async {
    return await service.getMyClasses(token);
  }

  Future<TrainingClassModel?> getClassDetail(String id, [String? token]) async {
    return await service.getClassDetail(id, token);
  }
}

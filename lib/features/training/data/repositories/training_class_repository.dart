import 'package:sikarir/features/training/data/models/training_class_model.dart';
import 'package:sikarir/features/training/data/services/training_class_service.dart';

class TrainingClassRepository {
  final TrainingClassService service;

  TrainingClassRepository({TrainingClassService? service})
      : service = service ?? TrainingClassService();

  Future<List<TrainingClassModel>> getMyClasses([String? token]) async {
    return await service.getMyClasses(token);
  }

  Future<TrainingClassModel?> getClassDetail(String id, [String? token]) async {
    return await service.getClassDetail(id, token);
  }
}

import 'package:sikarir/features/training/data/models/training_schedule_model.dart';
import 'package:sikarir/features/training/data/services/training_schedule_service.dart';

class TrainingScheduleRepository {
  final TrainingScheduleService service;

  TrainingScheduleRepository({TrainingScheduleService? service})
      : service = service ?? TrainingScheduleService();

  Future<List<TrainingScheduleModel>> getSchedules([String? token]) async {
    return await service.getSchedules(token);
  }
}

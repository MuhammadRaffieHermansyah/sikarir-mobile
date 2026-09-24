import 'package:sikarir/features/job/data/models/job_model.dart';
import 'package:sikarir/features/job/data/services/job_service.dart';

class JobRepository {
  final JobService service;

  JobRepository({JobService? service}) : service = service ?? JobService();

  Future<List<JobVacancyModel>> getJobs([String? token]) async {
    return await service.getJobs(token);
  }

  Future<void> applyJob(String jobId, [String? token]) async {
    await service.applyJob(jobId, token);
  }
}

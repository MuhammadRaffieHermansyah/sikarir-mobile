import 'package:sikarir/features/job/data/models/job_model.dart';
import 'package:sikarir/features/job/data/services/job_service.dart';

class JobRepository {
  final JobService service;

  JobRepository({JobService? service}) : service = service ?? JobService();

  Future<List<JobVacancyModel>> getJobs([String? token]) async {
    return await service.getJobs(token);
  }

  /// Returns a Map with keys: success (bool), message (String), need_profile_completion (bool)
  Future<Map<String, dynamic>> applyJob(String jobId, [String? token]) async {
    return await service.applyJob(jobId, token);
  }

  Future<List<Map<String, dynamic>>> getMyApplications([String? token]) async {
    return await service.getMyApplications(token);
  }
}

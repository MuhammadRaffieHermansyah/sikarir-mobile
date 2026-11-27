import 'package:sikarir/features/job/data/models/job_model.dart';
import 'package:sikarir/features/job/data/services/job_service.dart';

/// Hasil fetch lowongan: data jobs + flag apakah sedang pakai data offline.
class JobFetchResult {
  final List<JobVacancyModel> jobs;
  final bool isOffline;

  const JobFetchResult({required this.jobs, this.isOffline = false});
}

class JobRepository {
  final JobService service;

  JobRepository({JobService? service}) : service = service ?? JobService();

  /// Ambil lowongan dari API. Gagal → [JobApiException] diteruskan ke provider
  /// agar layar menampilkan pesan dan "Coba lagi", bukan data contoh.
  Future<JobFetchResult> getJobs([String? token]) async {
    final jobs = await service.getJobs(token);
    return JobFetchResult(jobs: jobs);
  }

  /// Returns a Map with keys: success (bool), message (String), need_profile_completion (bool)
  Future<Map<String, dynamic>> applyJob(String jobId, [String? token]) async {
    return await service.applyJob(jobId, token);
  }

  Future<List<Map<String, dynamic>>> getMyApplications([String? token]) async {
    return await service.getMyApplications(token);
  }
}

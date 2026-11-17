import 'package:flutter/foundation.dart';
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

  /// Ambil lowongan dari API.
  /// - Jika berhasil → [JobFetchResult] dengan `isOffline = false`
  /// - Jika API error → gunakan data fallback lokal, `isOffline = true`
  Future<JobFetchResult> getJobs([String? token]) async {
    try {
      final jobs = await service.getJobs(token);
      return JobFetchResult(jobs: jobs);
    } on JobApiException catch (e) {
      if (kDebugMode) debugPrint('JobRepository: API gagal → fallback. $e');
      return JobFetchResult(jobs: service.getFallbackJobs(), isOffline: true);
    }
  }

  /// Returns a Map with keys: success (bool), message (String), need_profile_completion (bool)
  Future<Map<String, dynamic>> applyJob(String jobId, [String? token]) async {
    return await service.applyJob(jobId, token);
  }

  Future<List<Map<String, dynamic>>> getMyApplications([String? token]) async {
    return await service.getMyApplications(token);
  }
}

import 'package:flutter/foundation.dart';
import 'package:sikarir/features/instructor/data/models/attendance_session_model.dart';
import 'package:sikarir/features/instructor/data/models/class_module_model.dart';
import 'package:sikarir/features/instructor/data/services/instructor_service.dart';
import 'package:sikarir/features/training/data/models/training_class_model.dart';

/// State untuk instruktur (kelas diampu) sekaligus cache modul per kelas,
/// yang juga dibaca peserta pada halaman detail kelas.
class InstructorProvider extends ChangeNotifier {
  final InstructorService service;

  InstructorProvider({InstructorService? service})
    : service = service ?? InstructorService();

  bool _isLoadingClasses = false;
  List<TrainingClassModel> _classes = [];
  String? _classesError;

  final Map<String, List<ClassModule>> _modules = {};
  final Set<String> _loadingModules = {};
  final Map<String, String> _moduleErrors = {};

  bool _isSaving = false;
  String? _ownerId;

  bool get isLoadingClasses => _isLoadingClasses;
  List<TrainingClassModel> get classes => _classes;
  String? get classesError => _classesError;
  bool get isSaving => _isSaving;

  List<ClassModule> modulesOf(String classId) => _modules[classId] ?? const [];
  bool isLoadingModules(String classId) => _loadingModules.contains(classId);
  String? moduleError(String classId) => _moduleErrors[classId];
  bool hasLoadedModules(String classId) => _modules.containsKey(classId);

  /// Dipanggil saat akun berganti/logout agar data pengguna lama tidak bocor.
  /// Tidak memanggil notifyListeners karena dijalankan saat build.
  void bindUser(String? userId) {
    if (_ownerId == userId) return;
    _ownerId = userId;
    _classes = [];
    _classesError = null;
    _modules.clear();
    _moduleErrors.clear();
    _loadingModules.clear();
    _sessions.clear();
    _sessionErrors.clear();
    _loadingSessions.clear();
  }

  String _msg(Object e) => e.toString().replaceFirst('Exception: ', '');

  Future<void> fetchTeachingClasses(String? token) async {
    _isLoadingClasses = true;
    _classesError = null;
    notifyListeners();
    try {
      _classes = await service.getTeachingClasses(token);
    } catch (e) {
      _classesError = _msg(e);
    } finally {
      _isLoadingClasses = false;
      notifyListeners();
    }
  }

  Future<void> fetchModules(String classId, String? token) async {
    _loadingModules.add(classId);
    _moduleErrors.remove(classId);
    notifyListeners();
    try {
      final list = await service.getModules(classId, token);
      list.sort((a, b) => a.meetingNumber.compareTo(b.meetingNumber));
      _modules[classId] = list;
    } catch (e) {
      _moduleErrors[classId] = _msg(e);
    } finally {
      _loadingModules.remove(classId);
      notifyListeners();
    }
  }

  /// Menjalankan aksi tulis lalu memuat ulang modul agar data selalu sinkron.
  Future<void> _mutate(
    String classId,
    String? token,
    Future<void> Function() action,
  ) async {
    _isSaving = true;
    notifyListeners();
    try {
      await action();
      await fetchModules(classId, token);
    } catch (e) {
      throw Exception(_msg(e));
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> addModule({
    required String classId,
    required String title,
    required String description,
    required int meetingNumber,
    String? token,
  }) => _mutate(
    classId,
    token,
    () => service.createModule(
      classId: classId,
      title: title,
      description: description,
      meetingNumber: meetingNumber,
      token: token,
    ),
  );

  Future<void> deleteModule(String classId, String moduleId, String? token) =>
      _mutate(classId, token, () => service.deleteModule(moduleId, token));

  Future<void> addMaterial({
    required String classId,
    required String moduleId,
    required String title,
    required MaterialKind kind,
    String? url,
    String? content,
    String? filePath,
    String? token,
  }) => _mutate(
    classId,
    token,
    () => service.addMaterial(
      moduleId: moduleId,
      title: title,
      kind: kind,
      url: url,
      content: content,
      filePath: filePath,
      token: token,
    ),
  );

  Future<void> deleteMaterial(
    String classId,
    String materialId,
    String? token,
  ) => _mutate(classId, token, () => service.deleteMaterial(materialId, token));

  // --- Sesi presensi ---
  final Map<String, List<AttendanceSession>> _sessions = {};
  final Set<String> _loadingSessions = {};
  final Map<String, String> _sessionErrors = {};

  List<AttendanceSession> sessionsOf(String classId) =>
      _sessions[classId] ?? const [];
  bool isLoadingSessions(String classId) => _loadingSessions.contains(classId);
  bool hasLoadedSessions(String classId) => _sessions.containsKey(classId);
  String? sessionError(String classId) => _sessionErrors[classId];

  Future<void> fetchSessions(String classId, String? token) async {
    _loadingSessions.add(classId);
    _sessionErrors.remove(classId);
    notifyListeners();
    try {
      final list = await service.getAttendanceSessions(classId, token);
      list.sort((a, b) => a.meetingNumber.compareTo(b.meetingNumber));
      _sessions[classId] = list;
    } catch (e) {
      _sessionErrors[classId] = _msg(e);
    } finally {
      _loadingSessions.remove(classId);
      notifyListeners();
    }
  }

  Future<void> _mutateSessions(
    String classId,
    String? token,
    Future<void> Function() action,
  ) async {
    _isSaving = true;
    notifyListeners();
    try {
      await action();
      await fetchSessions(classId, token);
    } catch (e) {
      throw Exception(_msg(e));
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> createSession(
    String classId,
    AttendanceSessionInput input,
    String? token,
  ) => _mutateSessions(
    classId,
    token,
    () => service.createAttendanceSession(classId, input, token),
  );

  Future<void> setSessionOpen(
    String classId,
    String sessionId,
    bool open,
    String? token,
  ) => _mutateSessions(
    classId,
    token,
    () => service.setAttendanceSessionOpen(sessionId, open, token),
  );

  Future<void> deleteSession(String classId, String sessionId, String? token) =>
      _mutateSessions(
        classId,
        token,
        () => service.deleteAttendanceSession(sessionId, token),
      );
}

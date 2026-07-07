import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:whisper_ggml_plus/whisper_ggml_plus.dart';
import '../../core/notifications/notification_service.dart';
import '../repositories/session_repository.dart';

class SettingsNotifier extends ChangeNotifier {
  static const _boxName = 'settings';

  int _threshold = 45;
  bool _isActive = true;
  int _notificationHour = 20;
  int _notificationMinute = 0;
  bool _isScoreActive = true;

  String _appLanguage = 'en';
  String _speechLanguage = 'en';

  bool _isDownloadingModel = false;
  bool _isModelReady = false;
  String? _downloadError;

  final WhisperController _whisperController = WhisperController();

  SettingsNotifier() {
    final box = Hive.box(_boxName);
    _threshold = box.get('threshold', defaultValue: 45) as int;
    _isActive = box.get('isActive', defaultValue: true) as bool;
    _notificationHour = box.get('notificationHour', defaultValue: 20) as int;
    _notificationMinute = box.get('notificationMinute', defaultValue: 0) as int;
    _isScoreActive = box.get('isScoreActive', defaultValue: true) as bool;

    // Detect device language globally on first start
    final deviceLang = PlatformDispatcher.instance.locale.languageCode == 'de' ? 'de' : 'en';
    _appLanguage = box.get('appLanguage', defaultValue: deviceLang) as String;
    _speechLanguage = box.get('speechLanguage', defaultValue: deviceLang) as String;

    _initModelReady();
  }

  int get threshold => _threshold;
  bool get isActive => _isActive;
  int get notificationHour => _notificationHour;
  int get notificationMinute => _notificationMinute;
  bool get isScoreActive => _isScoreActive;

  String get appLanguage => _appLanguage;
  String get speechLanguage => _speechLanguage;

  bool get isDownloadingModel => _isDownloadingModel;
  bool get isModelReady => _isModelReady;
  String? get downloadError => _downloadError;

  Future<void> _initModelReady() async {
    _isModelReady = await isModelDownloaded();
    notifyListeners();
  }

  Future<void> setThreshold(int value) async {
    _threshold = value;
    final box = Hive.box(_boxName);
    await box.put('threshold', value);
    notifyListeners();
    await _reschedule();
  }

  Future<void> setActive(bool value) async {
    _isActive = value;
    final box = Hive.box(_boxName);
    await box.put('isActive', value);
    notifyListeners();
    await _reschedule();
  }

  Future<void> setNotificationTime(int hour, int minute) async {
    _notificationHour = hour;
    _notificationMinute = minute;
    final box = Hive.box(_boxName);
    await box.put('notificationHour', hour);
    await box.put('notificationMinute', minute);
    notifyListeners();
    await _reschedule();
  }

  Future<void> setScoreActive(bool value) async {
    _isScoreActive = value;
    final box = Hive.box(_boxName);
    await box.put('isScoreActive', value);
    notifyListeners();
    await _reschedule();
  }

  // Set App Language
  Future<void> setAppLanguage(String lang) async {
    _appLanguage = lang;
    final box = Hive.box(_boxName);
    await box.put('appLanguage', lang);
    notifyListeners();
  }

  // Whisper model file management
  WhisperModel get modelForSpeechLanguage {
    return _speechLanguage == 'de' ? WhisperModel.tiny : WhisperModel.tinyEn;
  }

  Future<bool> isModelDownloaded() async {
    try {
      final path = await _whisperController.getPath(modelForSpeechLanguage);
      final file = File(path);
      return file.existsSync() && file.lengthSync() > 1000000;
    } catch (e) {
      debugPrint('Error checking model download status: $e');
      return false;
    }
  }

  Future<void> downloadSpeechModel() async {
    if (_isDownloadingModel) return;

    _isDownloadingModel = true;
    _isModelReady = false;
    _downloadError = null;
    notifyListeners();

    try {
      final model = modelForSpeechLanguage;
      debugPrint('Downloading Whisper model: ${model.modelName}...');
      await _whisperController.downloadModel(model);
      debugPrint('Download finished successfully.');
      _isModelReady = true;
    } catch (e) {
      debugPrint('Download failed: $e');
      _downloadError = e.toString();
      _isModelReady = false;
    } finally {
      _isDownloadingModel = false;
      notifyListeners();
    }
  }

  Future<void> deleteSpeechModel(String lang) async {
    try {
      final model = lang == 'de' ? WhisperModel.tiny : WhisperModel.tinyEn;
      final path = await _whisperController.getPath(model);
      final file = File(path);
      if (file.existsSync()) {
        debugPrint('Deleting Whisper model for $lang at $path...');
        await file.delete();
      }
      _isModelReady = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting speech model: $e');
    }
  }

  // Set Speech/Model Language (with download trigger)
  Future<void> setSpeechLanguage(String lang) async {
    final oldLang = _speechLanguage;
    if (oldLang == lang) return;

    // 1. Delete the old language model to save space
    await deleteSpeechModel(oldLang);

    // 2. Set the new language
    _speechLanguage = lang;
    final box = Hive.box(_boxName);
    await box.put('speechLanguage', lang);
    _isModelReady = false;
    notifyListeners();

    // 3. Download the new model
    await downloadSpeechModel();
  }

  Future<void> _reschedule() async {
    try {
      final sessions = SessionRepository().getAll();
      final score = NotificationService.calculateWeeklyAverageScore(sessions);
      await NotificationService.updateSchedule(
        isActive: _isActive,
        hour: _notificationHour,
        minute: _notificationMinute,
        isScoreActive: _isScoreActive,
        threshold: _threshold,
        weeklyAverageScore: score,
      );
    } catch (error, stackTrace) {
      debugPrint('Failed to reschedule score reminder: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}

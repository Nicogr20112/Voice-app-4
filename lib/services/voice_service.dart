import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'db_service.dart';

class VoiceService {
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();

  final SpeechToText _speech = SpeechToText();
  final DbService _db = DbService();

  bool _isListening = false;
  bool _isEnabled = false;
  bool _initialized = false;

  // Stream for UI updates
  final StreamController<int> _wordCountController = StreamController<int>.broadcast();
  final StreamController<bool> _listeningController = StreamController<bool>.broadcast();
  final StreamController<List<double>> _waveformController = StreamController<List<double>>.broadcast();

  Stream<int> get wordCountStream => _wordCountController.stream;
  Stream<bool> get listeningStream => _listeningController.stream;
  Stream<List<double>> get waveformStream => _waveformController.stream;

  bool get isListening => _isListening;
  bool get isEnabled => _isEnabled;

  // Buffer for current recognition session
  String _currentBuffer = '';
  Timer? _silenceTimer;
  Timer? _waveformTimer;

  Future<bool> initialize() async {
    if (_initialized) return true;
    _initialized = await _speech.initialize(
      onStatus: _onStatus,
      onError: (e) => _onError(e),
    );

    // Restore previous enabled state
    final prefs = await SharedPreferences.getInstance();
    _isEnabled = prefs.getBool('recording_enabled') ?? false;

    if (_isEnabled && _initialized) {
      await startListening();
    }

    return _initialized;
  }

  void _onStatus(String status) {
    if (status == 'done' || status == 'notListening') {
      if (_currentBuffer.trim().isNotEmpty) {
        _saveBuffer();
      }
      // Restart if still enabled
      if (_isEnabled && _initialized) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (_isEnabled) _startSession();
        });
      }
    }
  }

  void _onError(dynamic error) {
    _isListening = false;
    _listeningController.add(false);
    if (_isEnabled) {
      Future.delayed(const Duration(seconds: 2), () {
        if (_isEnabled) _startSession();
      });
    }
  }

  Future<void> startListening() async {
    if (!_initialized) await initialize();
    _isEnabled = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('recording_enabled', true);
    await _startSession();
    _startWaveformSimulation();
  }

  Future<void> stopListening() async {
    _isEnabled = false;
    _isListening = false;
    _silenceTimer?.cancel();
    _waveformTimer?.cancel();
    await _speech.stop();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('recording_enabled', false);
    _listeningController.add(false);
    _waveformController.add(List.filled(28, 0.0));
    if (_currentBuffer.trim().isNotEmpty) {
      await _saveBuffer();
    }
  }

  Future<void> _startSession() async {
    if (!_isEnabled || !_initialized) return;
    _currentBuffer = '';
    _isListening = true;
    _listeningController.add(true);

    await _speech.listen(
      onResult: (result) {
        _currentBuffer = result.recognizedWords;
        // Real-time word count update
        final words = _currentBuffer.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
        if (words > 0) {
          // We update the stream so the UI refreshes
          _updateLiveCount();
        }
        // Reset silence timer
        _silenceTimer?.cancel();
        _silenceTimer = Timer(const Duration(seconds: 3), () {
          if (_currentBuffer.trim().isNotEmpty) {
            _saveBuffer();
          }
        });
      },
      listenFor: const Duration(minutes: 5),
      pauseFor: const Duration(seconds: 5),
      localeId: 'es_ES',
      listenMode: ListenMode.dictation,
      partialResults: true,
    );
  }

  Future<void> _saveBuffer() async {
    final text = _currentBuffer.trim();
    if (text.isEmpty) return;
    final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    await _db.insertEntry(text, words);
    _currentBuffer = '';
    final total = await _db.getTodayWordCount();
    _wordCountController.add(total);
  }

  Future<void> _updateLiveCount() async {
    final saved = await _db.getTodayWordCount();
    final liveWords = _currentBuffer.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    _wordCountController.add(saved + liveWords);
  }

  void _startWaveformSimulation() {
    _waveformTimer?.cancel();
    _waveformTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!_isEnabled) return;
      final bars = List.generate(28, (i) {
        final base = 0.1 + (i % 3) * 0.1;
        return base + (DateTime.now().millisecondsSinceEpoch % 1000) / 3000.0 * (i % 5 + 1) * 0.15;
      });
      _waveformController.add(bars);
    });
  }

  /// Get top words from today
  Future<Map<String, int>> getTopWords() async {
    final entries = await _db.getTodayEntries();
    final Map<String, int> freq = {};
    final stopWords = {
      'el', 'la', 'los', 'las', 'un', 'una', 'unos', 'unas', 'de', 'del',
      'al', 'a', 'en', 'y', 'o', 'que', 'es', 'se', 'no', 'por', 'con',
      'para', 'su', 'sus', 'lo', 'le', 'me', 'te', 'si', 'ya', 'más',
      'pero', 'como', 'este', 'esta', 'esto', 'ese', 'esa', 'muy',
      'the', 'a', 'an', 'is', 'in', 'on', 'at', 'to', 'of', 'and',
    };
    for (final entry in entries) {
      final text = (entry['transcript'] as String).toLowerCase();
      final words = text.split(RegExp(r'[\s,\.!?;:]+'));
      for (final word in words) {
        final clean = word.replaceAll(RegExp(r'[^a-záéíóúüñ]', caseSensitive: false), '');
        if (clean.length > 3 && !stopWords.contains(clean)) {
          freq[clean] = (freq[clean] ?? 0) + 1;
        }
      }
    }
    final sorted = freq.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted.take(8));
  }

  /// Generate a local summary (no AI needed — pure analysis)
  Future<Map<String, dynamic>> generateSummary({String? date}) async {
    final db = DbService();
    final targetDate = date ?? DbService.todayKey();
    final entries = await db.getEntriesForDate(targetDate);
    final summary = await db.getDailySummary(targetDate);
    final totalWords = summary?['total_words'] as int? ?? 0;

    // Compute top words
    final Map<String, int> freq = {};
    final stopWords = {
      'el', 'la', 'los', 'las', 'un', 'una', 'de', 'del', 'al', 'a', 'en',
      'y', 'o', 'que', 'es', 'se', 'no', 'por', 'con', 'para', 'su', 'lo',
      'le', 'me', 'te', 'si', 'ya', 'más', 'pero', 'como', 'muy', 'este',
    };
    final allText = StringBuffer();
    for (final e in entries) {
      allText.write('${e['transcript']} ');
    }
    final words = allText.toString().toLowerCase().split(RegExp(r'[\s,\.!?;:]+'));
    for (final word in words) {
      final clean = word.replaceAll(RegExp(r'[^a-záéíóúüñ]', caseSensitive: false), '');
      if (clean.length > 3 && !stopWords.contains(clean)) {
        freq[clean] = (freq[clean] ?? 0) + 1;
      }
    }
    final sorted = freq.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final topWords = sorted.take(6).toList();

    // Determine tone
    String tone = 'neutral y calmado';
    if (totalWords > 4000) tone = 'muy activo y expresivo';
    else if (totalWords > 2000) tone = 'activo y directo';
    else if (totalWords < 500) tone = 'tranquilo y reservado';

    // Build summary text
    String summaryText;
    if (totalWords == 0) {
      summaryText = 'No hay palabras registradas para este día. Activa el micrófono para empezar a registrar.';
    } else {
      final topWordNames = topWords.take(3).map((e) => e.key).join(', ');
      summaryText = 'Hoy pronunciaste $totalWords palabras. '
          'Las más frecuentes fueron: $topWordNames. '
          '${_toneDescription(totalWords, entries.length)}';
    }

    // Hourly data
    final hourly = await db.getTodayHourlyBreakdown();

    return {
      'total_words': totalWords,
      'top_words': topWords,
      'tone': tone,
      'summary': summaryText,
      'entries_count': entries.length,
      'hourly': hourly,
      'date': targetDate,
    };
  }

  String _toneDescription(int words, int sessions) {
    if (sessions > 10) return 'Tuviste muchas ráfagas de conversación a lo largo del día.';
    if (sessions > 5) return 'Tu actividad vocal fue constante durante el día.';
    if (sessions == 1) return 'Tuviste una sola sesión de habla larga y continua.';
    return 'Alternaste períodos de silencio con conversación.';
  }

  void dispose() {
    _wordCountController.close();
    _listeningController.close();
    _waveformController.close();
    _silenceTimer?.cancel();
    _waveformTimer?.cancel();
  }
}

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DbService {
  static final DbService _instance = DbService._internal();
  factory DbService() => _instance;
  DbService._internal();

  Database? _db;

  Future<Database> get db async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'voz.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE entries (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL,
            transcript TEXT NOT NULL,
            word_count INTEGER NOT NULL,
            timestamp INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE daily_summary (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL UNIQUE,
            summary TEXT,
            total_words INTEGER DEFAULT 0,
            top_words TEXT,
            tone TEXT,
            updated_at INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  /// Insert a transcription entry
  Future<void> insertEntry(String transcript, int wordCount) async {
    final database = await db;
    final now = DateTime.now();
    final dateStr = _dateKey(now);
    await database.insert('entries', {
      'date': dateStr,
      'transcript': transcript,
      'word_count': wordCount,
      'timestamp': now.millisecondsSinceEpoch,
    });
    await _updateDailyCount(dateStr, wordCount, transcript);
  }

  Future<void> _updateDailyCount(String date, int newWords, String newText) async {
    final database = await db;
    final existing = await database.query(
      'daily_summary',
      where: 'date = ?',
      whereArgs: [date],
    );
    if (existing.isEmpty) {
      await database.insert('daily_summary', {
        'date': date,
        'total_words': newWords,
        'top_words': '',
        'tone': '',
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      });
    } else {
      final current = (existing.first['total_words'] as int? ?? 0);
      await database.update(
        'daily_summary',
        {
          'total_words': current + newWords,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'date = ?',
        whereArgs: [date],
      );
    }
  }

  /// Get today's total word count
  Future<int> getTodayWordCount() async {
    final database = await db;
    final dateStr = _dateKey(DateTime.now());
    final result = await database.query(
      'daily_summary',
      where: 'date = ?',
      whereArgs: [dateStr],
    );
    if (result.isEmpty) return 0;
    return result.first['total_words'] as int? ?? 0;
  }

  /// Get all transcripts for today
  Future<List<Map<String, dynamic>>> getTodayEntries() async {
    final database = await db;
    final dateStr = _dateKey(DateTime.now());
    return database.query(
      'entries',
      where: 'date = ?',
      whereArgs: [dateStr],
      orderBy: 'timestamp ASC',
    );
  }

  /// Get entries per hour for today (for the timeline chart)
  Future<Map<int, int>> getTodayHourlyBreakdown() async {
    final database = await db;
    final dateStr = _dateKey(DateTime.now());
    final entries = await database.query(
      'entries',
      where: 'date = ?',
      whereArgs: [dateStr],
    );
    final Map<int, int> hourly = {};
    for (final e in entries) {
      final ts = e['timestamp'] as int;
      final hour = DateTime.fromMillisecondsSinceEpoch(ts).hour;
      hourly[hour] = (hourly[hour] ?? 0) + (e['word_count'] as int? ?? 0);
    }
    return hourly;
  }

  /// Get all days with data for history
  Future<List<Map<String, dynamic>>> getHistory() async {
    final database = await db;
    return database.query(
      'daily_summary',
      orderBy: 'date DESC',
      limit: 30,
    );
  }

  /// Get entries for a specific date
  Future<List<Map<String, dynamic>>> getEntriesForDate(String date) async {
    final database = await db;
    return database.query(
      'entries',
      where: 'date = ?',
      whereArgs: [date],
      orderBy: 'timestamp ASC',
    );
  }

  /// Save AI-generated summary
  Future<void> saveSummary(String date, String summary, String topWords, String tone) async {
    final database = await db;
    await database.update(
      'daily_summary',
      {
        'summary': summary,
        'top_words': topWords,
        'tone': tone,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'date = ?',
      whereArgs: [date],
    );
  }

  /// Get daily summary record
  Future<Map<String, dynamic>?> getDailySummary(String date) async {
    final database = await db;
    final result = await database.query(
      'daily_summary',
      where: 'date = ?',
      whereArgs: [date],
    );
    return result.isEmpty ? null : result.first;
  }

  String _dateKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  static String todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}

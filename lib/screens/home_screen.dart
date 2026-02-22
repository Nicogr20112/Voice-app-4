import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme.dart';
import '../services/voice_service.dart';
import '../services/db_service.dart';
import '../widgets/widgets.dart';
import 'summary_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final VoiceService _voice = VoiceService();
  final DbService _db = DbService();

  int _wordCount = 0;
  bool _isListening = false;
  Map<String, int> _topWords = {};
  int _sessionCount = 0;
  String _startTime = '';
  StreamSubscription? _wordSub;
  StreamSubscription? _listenSub;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // Request mic permission
    await Permission.microphone.request();
    if (await Permission.microphone.isDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Se necesita permiso de micrófono')),
        );
      }
      return;
    }

    await _voice.initialize();
    _wordSub = _voice.wordCountStream.listen((count) {
      if (mounted) setState(() => _wordCount = count);
    });
    _listenSub = _voice.listeningStream.listen((listening) {
      if (mounted) setState(() => _isListening = listening);
    });

    setState(() => _isListening = _voice.isListening);
    await _loadData();

    // Refresh top words every 30s
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) => _loadData());
  }

  Future<void> _loadData() async {
    final count = await _db.getTodayWordCount();
    final topWords = await _voice.getTopWords();
    final entries = await _db.getTodayEntries();

    DateTime? firstEntry;
    if (entries.isNotEmpty) {
      final ts = entries.first['timestamp'] as int;
      firstEntry = DateTime.fromMillisecondsSinceEpoch(ts);
    }

    if (mounted) {
      setState(() {
        _wordCount = count;
        _topWords = topWords;
        _sessionCount = entries.length;
        _startTime = firstEntry != null
            ? '${firstEntry.hour.toString().padLeft(2, '0')}:${firstEntry.minute.toString().padLeft(2, '0')}'
            : '';
      });
    }
  }

  Future<void> _toggleListening() async {
    if (_isListening || _voice.isEnabled) {
      await _voice.stopListening();
    } else {
      await _voice.startListening();
    }
    setState(() => _isListening = _voice.isEnabled);
  }

  String _formatCount(int n) {
    if (n >= 1000) {
      final thousands = n ~/ 1000;
      final remainder = n % 1000;
      return '$thousands.${remainder.toString().padLeft(3, '0')}';
    }
    return n.toString();
  }

  @override
  void dispose() {
    _wordSub?.cancel();
    _listenSub?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dayStr = _dayName(now.weekday);
    final dateStr = '${now.day} ${_monthName(now.month)}';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Voz', style: AppTheme.label.copyWith(letterSpacing: 0.12, fontSize: 13)),
              ],
            ),
          ),

          // Big word count
          const SizedBox(height: 32),
          Text('Palabras hoy', style: AppTheme.label),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: AppTheme.bigNumber,
              children: [
                TextSpan(text: _formatCount(_wordCount).replaceAll('.', '')),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$dayStr $dateStr${_startTime.isNotEmpty ? ' · empezaste a las $_startTime' : ''}',
            style: AppTheme.label,
          ),

          const SizedBox(height: 20),

          // Recording toggle badge
          GestureDetector(
            onTap: _toggleListening,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _isListening
                    ? AppColors.red.withOpacity(0.12)
                    : AppColors.surface2,
                border: Border.all(
                  color: _isListening
                      ? AppColors.red.withOpacity(0.3)
                      : AppColors.border,
                ),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isListening)
                    _PulsingDot()
                  else
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: AppColors.muted,
                        shape: BoxShape.circle,
                      ),
                    ),
                  const SizedBox(width: 8),
                  Text(
                    _isListening ? 'escuchando tu voz · pulsa para parar' : 'registro pausado · pulsa para activar',
                    style: GoogleFonts.dmMono(
                      fontSize: 12,
                      color: _isListening ? AppColors.red : AppColors.muted,
                      letterSpacing: 0.05,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Waveform
          const SizedBox(height: 16),
          WaveformWidget(active: _isListening),

          // Divider
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 28),
            child: Divider(color: AppColors.border, thickness: 1),
          ),

          // Stats row
          Row(
            children: [
              Expanded(
                child: StatCard(
                  value: _sessionCount > 0
                      ? '${(_wordCount / (_sessionCount * 0.5)).round()}m'
                      : '–',
                  label: 'promedio',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: StatCard(value: '$_sessionCount', label: 'ráfagas')),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  value: _isListening ? '●' : '○',
                  label: _isListening ? 'activo' : 'pausado',
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // Top words
          if (_topWords.isNotEmpty) ...[
            Text('palabras más usadas', style: AppTheme.label),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _topWords.entries
                  .map((e) => WordPill(word: e.key, count: e.value))
                  .toList(),
            ),
            const SizedBox(height: 28),
          ],

          // Summary button
          GestureDetector(
            onTap: () async {
              final result = await _voice.generateSummary();
              if (mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SummaryScreen(data: result),
                  ),
                );
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('✦ ', style: TextStyle(color: AppColors.bg, fontSize: 15)),
                  Text(
                    'generar resumen del día',
                    style: GoogleFonts.syne(
                      color: AppColors.bg,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.03,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _dayName(int d) {
    const days = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];
    return days[(d - 1) % 7];
  }

  String _monthName(int m) {
    const months = ['ene','feb','mar','abr','may','jun','jul','ago','sep','oct','nov','dic'];
    return months[m - 1];
  }
}

class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 1.0, end: 0.3).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Opacity(
        opacity: _anim.value,
        child: Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            color: AppColors.red,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

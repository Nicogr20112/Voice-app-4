import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../services/db_service.dart';
import '../services/voice_service.dart';
import 'summary_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final DbService _db = DbService();
  List<Map<String, dynamic>> _history = [];
  int _maxWords = 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final history = await _db.getHistory();
    final max = history.isEmpty
        ? 1
        : history
            .map((e) => e['total_words'] as int? ?? 0)
            .reduce((a, b) => a > b ? a : b);
    if (mounted) {
      setState(() {
        _history = history;
        _maxWords = max == 0 ? 1 : max;
      });
    }
  }

  String _formatDate(String dateKey) {
    final parts = dateKey.split('-');
    if (parts.length != 3) return dateKey;
    final now = DateTime.now();
    final dt = DateTime(
      int.tryParse(parts[0]) ?? now.year,
      int.tryParse(parts[1]) ?? now.month,
      int.tryParse(parts[2]) ?? now.day,
    );
    final diff = now.difference(dt).inDays;
    if (diff == 0) return 'hoy';
    if (diff == 1) return 'ayer';
    return '${_dayName(dt.weekday)} ${dt.day} ${_monthName(dt.month)}';
  }

  String _dayName(int d) {
    const days = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];
    return days[(d - 1) % 7];
  }

  String _monthName(int m) {
    const months = ['ene','feb','mar','abr','may','jun','jul','ago','sep','oct','nov','dic'];
    return months[(m - 1).clamp(0, 11)];
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 28, bottom: 20),
            child: Text(
              'Historial',
              style: GoogleFonts.syne(
                color: AppColors.text,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ),

          if (_history.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 60),
                child: Text(
                  'Todavía no hay datos.\nActiva el micrófono para empezar.',
                  textAlign: TextAlign.center,
                  style: AppTheme.label.copyWith(height: 1.8),
                ),
              ),
            )
          else ...[
            Text('últimos 30 días', style: AppTheme.label),
            const SizedBox(height: 14),
            ..._history.map((item) {
              final date = item['date'] as String? ?? '';
              final words = item['total_words'] as int? ?? 0;
              final ratio = words / _maxWords;
              return _HistoryItem(
                dateLabel: _formatDate(date),
                words: words,
                ratio: ratio,
                onTap: () async {
                  final voice = VoiceService();
                  final result = await voice.generateSummary(date: date);
                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SummaryScreen(data: result),
                      ),
                    );
                  }
                },
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final String dateLabel;
  final int words;
  final double ratio;
  final VoidCallback onTap;

  const _HistoryItem({
    required this.dateLabel,
    required this.words,
    required this.ratio,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dateLabel, style: AppTheme.label.copyWith(fontSize: 11)),
                  const SizedBox(height: 4),
                  Text(
                    _formatWords(words),
                    style: GoogleFonts.syne(
                      color: AppColors.text,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 80,
                      height: 4,
                      child: Stack(
                        children: [
                          Container(color: AppColors.surface2),
                          FractionallySizedBox(
                            widthFactor: ratio.clamp(0.0, 1.0),
                            child: Container(
                              color: AppColors.accent2.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.muted, size: 22),
          ],
        ),
      ),
    );
  }

  String _formatWords(int n) {
    if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(1).replaceAll('.', ',')}k';
    }
    return n.toString();
  }
}

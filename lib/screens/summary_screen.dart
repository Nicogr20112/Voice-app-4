import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../widgets/widgets.dart';

class SummaryScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const SummaryScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final totalWords = data['total_words'] as int? ?? 0;
    final tone = data['tone'] as String? ?? '';
    final summaryText = data['summary'] as String? ?? '';
    final topWords = data['top_words'] as List? ?? [];
    final hourly = data['hourly'] as Map<int, int>? ?? {};
    final date = data['date'] as String? ?? '';

    // Format date label
    final parts = date.split('-');
    final dateLabel = parts.length == 3
        ? '${parts[2]} ${_monthName(int.tryParse(parts[1]) ?? 1)} ${parts[0]}'
        : date;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 24),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.arrow_back_ios, color: AppColors.muted, size: 14),
                      const SizedBox(width: 6),
                      Text('volver', style: AppTheme.label.copyWith(fontSize: 13)),
                    ],
                  ),
                ),
              ),

              Text(dateLabel.toLowerCase(), style: AppTheme.label),
              const SizedBox(height: 10),

              // Title
              RichText(
                text: TextSpan(
                  style: AppTheme.heading,
                  children: [
                    const TextSpan(text: 'Tu día en '),
                    TextSpan(
                      text: '$totalWords',
                      style: AppTheme.heading.copyWith(color: AppColors.accent2),
                    ),
                    const TextSpan(text: ' palabras'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Summary text card
              SummaryCard(
                label: 'resumen',
                child: Text(
                  summaryText,
                  style: AppTheme.body,
                ),
              ),

              // Hourly timeline
              if (hourly.isNotEmpty)
                SummaryCard(
                  label: 'actividad por hora',
                  child: HourlyTimeline(hourly: hourly),
                ),

              // Tone card
              if (tone.isNotEmpty)
                SummaryCard(
                  label: 'tono detectado',
                  child: Text(
                    'Tono $_tone',
                    style: AppTheme.body,
                  ),
                ),

              // Top words card
              if (topWords.isNotEmpty)
                SummaryCard(
                  label: 'palabras más usadas',
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: topWords
                        .map((e) => WordPill(
                              word: e.key as String,
                              count: e.value as int,
                            ))
                        .toList(),
                  ),
                ),

              // Stats cards
              Row(
                children: [
                  Expanded(
                    child: _StatMini(
                      value: '$totalWords',
                      label: 'palabras',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatMini(
                      value: _estimateMinutes(totalWords),
                      label: 'aprox. hablando',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _tone => (data['tone'] as String? ?? '').toLowerCase();

  String _estimateMinutes(int words) {
    // Average speaking rate ~130 words/min
    final minutes = (words / 130).round();
    if (minutes < 60) return '${minutes}min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '${h}h ${m}m';
  }

  String _monthName(int m) {
    const months = ['ene','feb','mar','abr','may','jun','jul','ago','sep','oct','nov','dic'];
    if (m < 1 || m > 12) return '';
    return months[m - 1];
  }
}

class _StatMini extends StatelessWidget {
  final String value;
  final String label;
  const _StatMini({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: GoogleFonts.syne(
                  color: AppColors.text,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5)),
          const SizedBox(height: 4),
          Text(label.toUpperCase(),
              style: AppTheme.label.copyWith(fontSize: 10)),
        ],
      ),
    );
  }
}

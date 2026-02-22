import 'dart:math';
import 'package:flutter/material.dart';
import '../theme.dart';

/// Waveform animation widget
class WaveformWidget extends StatefulWidget {
  final bool active;
  final List<double>? bars;

  const WaveformWidget({super.key, required this.active, this.bars});

  @override
  State<WaveformWidget> createState() => _WaveformWidgetState();
}

class _WaveformWidgetState extends State<WaveformWidget>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  final int barCount = 28;
  final _rng = Random();

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(barCount, (i) {
      final ctrl = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 600 + _rng.nextInt(600)),
      )..repeat(reverse: true);
      return ctrl;
    });
  }

  @override
  void didUpdateWidget(WaveformWidget old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) {
      for (final c in _controllers) c.repeat(reverse: true);
    } else if (!widget.active && old.active) {
      for (final c in _controllers) {
        c.animateTo(0, duration: const Duration(milliseconds: 400));
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: Row(
        children: List.generate(barCount, (i) {
          final baseH = 6.0 + (i % 5) * 4.0;
          final maxH = baseH + 16 + _rng.nextDouble() * 8;
          return AnimatedBuilder(
            animation: _controllers[i],
            builder: (_, __) {
              final h = widget.active
                  ? baseH + (maxH - baseH) * _controllers[i].value
                  : 4.0;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1.5),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  width: 3,
                  height: h,
                  decoration: BoxDecoration(
                    color: AppColors.accent2.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

/// Pill chip for top words
class WordPill extends StatelessWidget {
  final String word;
  final int count;

  const WordPill({super.key, required this.word, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(word, style: AppTheme.body.copyWith(fontSize: 13, color: AppColors.text)),
          const SizedBox(width: 8),
          Text('×$count', style: AppTheme.label.copyWith(color: AppColors.accent2, fontSize: 11)),
        ],
      ),
    );
  }
}

/// Stat card
class StatCard extends StatelessWidget {
  final String value;
  final String label;

  const StatCard({super.key, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: AppTheme.heading.copyWith(fontSize: 22, letterSpacing: -0.5)),
          const SizedBox(height: 4),
          Text(label.toUpperCase(), style: AppTheme.label.copyWith(fontSize: 10)),
        ],
      ),
    );
  }
}

/// Summary card container
class SummaryCard extends StatelessWidget {
  final String label;
  final Widget child;

  const SummaryCard({super.key, required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: AppTheme.label.copyWith(fontSize: 10)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// Timeline bar chart (hourly)
class HourlyTimeline extends StatelessWidget {
  final Map<int, int> hourly;

  const HourlyTimeline({super.key, required this.hourly});

  @override
  Widget build(BuildContext context) {
    final maxVal = hourly.values.isEmpty ? 1 : hourly.values.reduce(max);
    final hours = List.generate(20, (i) => i + 7); // 7h to 23h

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 48,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: hours.map((h) {
              final val = hourly[h] ?? 0;
              final ratio = maxVal > 0 ? val / maxVal : 0.0;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1.5),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.surface2,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: FractionallySizedBox(
                              heightFactor: ratio.clamp(0.05, 1.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.accent2.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: ['8h', '12h', '16h', '20h']
              .map((l) => Text(l, style: AppTheme.label.copyWith(fontSize: 9)))
              .toList(),
        ),
      ],
    );
  }
}

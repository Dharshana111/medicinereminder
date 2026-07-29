import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medreminder/app/theme.dart';

// ─────────────────────────────────────────────────────────
//  AdherenceChart – circular pie showing taken / missed / late
// ─────────────────────────────────────────────────────────
class AdherenceChart extends StatefulWidget {
  /// Overall adherence percentage 0–100.
  final double percentage;
  final double size;
  final double? takenPercent;
  final double? missedPercent;
  final double? latePercent;

  const AdherenceChart({
    super.key,
    required this.percentage,
    this.size = 150,
    this.takenPercent,
    this.missedPercent,
    this.latePercent,
  });

  @override
  State<AdherenceChart> createState() => _AdherenceChartState();
}

class _AdherenceChartState extends State<AdherenceChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get _taken => widget.takenPercent ?? widget.percentage;
  double get _missed => widget.missedPercent ?? (100 - widget.percentage);
  double get _late => widget.latePercent ?? 0;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final factor = _animation.value;
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: widget.size * 0.3,
                  startDegreeOffset: -90,
                  sections: _buildSections(factor),
                  borderData: FlBorderData(show: false),
                ),
              ),
              // Center percentage label
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(widget.percentage * factor).toInt()}%',
                    style: GoogleFonts.poppins(
                      fontSize: widget.size * 0.16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    'Adherence',
                    style: GoogleFonts.poppins(
                      fontSize: widget.size * 0.08,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  List<PieChartSectionData> _buildSections(double factor) {
    final taken = _taken * factor;
    final missed = _missed * factor;
    final late_ = _late * factor;
    final remaining = (100 - taken - missed - late_).clamp(0, 100);

    return [
      if (taken > 0)
        PieChartSectionData(
          color: AppTheme.success,
          value: taken,
          radius: widget.size * 0.18,
          showTitle: false,
        ),
      if (missed > 0)
        PieChartSectionData(
          color: AppTheme.error,
          value: missed,
          radius: widget.size * 0.18,
          showTitle: false,
        ),
      if (late_ > 0)
        PieChartSectionData(
          color: AppTheme.warning,
          value: late_,
          radius: widget.size * 0.18,
          showTitle: false,
        ),
      if (remaining > 0)
        PieChartSectionData(
          color: AppTheme.divider,
          value: remaining.toDouble(),
          radius: widget.size * 0.14,
          showTitle: false,
        ),
    ];
  }
}

// ─────────────────────────────────────────────────────────
//  WeeklyBarChart – 7‑day bar chart of taken medicines
// ─────────────────────────────────────────────────────────
class WeeklyBarChart extends StatefulWidget {
  final Map<String, int> data;

  const WeeklyBarChart({super.key, required this.data});

  @override
  State<WeeklyBarChart> createState() => _WeeklyBarChartState();
}

class _WeeklyBarChartState extends State<WeeklyBarChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  static const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get _maxY {
    if (widget.data.isEmpty) return 5;
    final maxVal = widget.data.values.fold<int>(0, (a, b) => a > b ? a : b);
    return maxVal < 5 ? 5 : (maxVal + 1).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final factor = _animation.value;
        return AspectRatio(
          aspectRatio: 1.6,
          child: BarChart(
            BarChartData(
              maxY: _maxY,
              alignment: BarChartAlignment.spaceAround,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      '${rod.toY.toInt()}',
                      GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    interval: _maxY > 10 ? (_maxY / 5).ceilToDouble() : 1,
                    getTitlesWidget: (value, meta) {
                      if (value == meta.max) return const SizedBox.shrink();
                      return Text(
                        value.toInt().toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: AppTheme.textHint,
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= _dayLabels.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          _dayLabels[idx],
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval:
                    _maxY > 10 ? (_maxY / 5).ceilToDouble() : 1,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: AppTheme.divider,
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: _buildBarGroups(factor),
            ),
            duration: Duration.zero,
          ),
        );
      },
    );
  }

  List<BarChartGroupData> _buildBarGroups(double factor) {
    return List.generate(_dayLabels.length, (i) {
      final label = _dayLabels[i];
      final value = (widget.data[label] ?? 0).toDouble() * factor;
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: value,
            width: 16,
            gradient: const LinearGradient(
              colors: [AppTheme.primaryLight, AppTheme.primary],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: _maxY,
              color: AppTheme.primarySurface,
            ),
          ),
        ],
      );
    });
  }
}

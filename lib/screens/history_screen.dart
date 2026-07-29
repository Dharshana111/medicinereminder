import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:medreminder/app/theme.dart';
import 'package:medreminder/models/medicine_history.dart';
import 'package:medreminder/services/storage_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  DateTime _selectedDate = DateTime.now();
  String _selectedFilter = 'All';
  List<MedicineHistory> _historyList = [];

  final List<String> _filters = ['All', 'Taken', 'Missed', 'Late'];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animController.forward();
    _loadHistory();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _loadHistory() {
    final history = StorageService.getHistoryByDate(_selectedDate);
    setState(() {
      if (_selectedFilter == 'All') {
        _historyList = history;
      } else {
        _historyList = history
            .where((h) =>
                h.status.toLowerCase() == _selectedFilter.toLowerCase())
            .toList();
      }
      // Sort by scheduled time descending
      _historyList.sort((a, b) => b.scheduledTime.compareTo(a.scheduledTime));
    });
  }

  List<DateTime> _getLast7Days() {
    final today = DateTime.now();
    return List.generate(7, (i) {
      return DateTime(today.year, today.month, today.day - (6 - i));
    });
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'taken':
        return Icons.check_circle_rounded;
      case 'missed':
        return Icons.cancel_rounded;
      case 'late':
        return Icons.watch_later_rounded;
      case 'pending':
        return Icons.schedule_rounded;
      default:
        return Icons.circle_outlined;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'taken':
        return AppTheme.success;
      case 'missed':
        return AppTheme.error;
      case 'late':
        return AppTheme.warning;
      case 'pending':
        return AppTheme.textHint;
      default:
        return AppTheme.textHint;
    }
  }

  Color _getStatusBgColor(String status) {
    switch (status) {
      case 'taken':
        return AppTheme.successLight;
      case 'missed':
        return AppTheme.errorLight;
      case 'late':
        return AppTheme.warningLight;
      default:
        return AppTheme.surface;
    }
  }

  String _getStatusLabel(String status) {
    return status[0].toUpperCase() + status.substring(1);
  }

  void _clearHistory() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        title: Row(
          children: [
            const Icon(Icons.warning_rounded, color: AppTheme.error, size: 24),
            const SizedBox(width: AppTheme.spacingSm),
            Text(
              'Clear History?',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: Text(
          'This will permanently delete all medicine history records. This action cannot be undone.',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AppTheme.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await StorageService.clearHistory();
              _loadHistory();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: Text(
              'Clear All',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildDateSelector(),
            const SizedBox(height: AppTheme.spacingSm),
            _buildFilterChips(),
            const SizedBox(height: AppTheme.spacingSm),
            Expanded(
              child: _historyList.isEmpty
                  ? _buildEmptyState()
                  : _buildHistoryList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacingMd,
        AppTheme.spacingMd,
        AppTheme.spacingSm,
        AppTheme.spacingSm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'History',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          PopupMenuButton<String>(
            icon: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primarySurface,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: const Icon(Icons.more_vert_rounded,
                  color: AppTheme.textSecondary),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            onSelected: (value) {
              if (value == 'clear') _clearHistory();
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    const Icon(Icons.delete_sweep_rounded,
                        color: AppTheme.error, size: 20),
                    const SizedBox(width: AppTheme.spacingSm),
                    Text(
                      'Clear History',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppTheme.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    final days = _getLast7Days();
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingSm),
        itemCount: days.length,
        itemBuilder: (context, index) {
          final day = days[index];
          final isSelected = _isSameDay(day, _selectedDate);
          final isToday = _isSameDay(day, DateTime.now());

          return GestureDetector(
            onTap: () {
              setState(() => _selectedDate = day);
              _loadHistory();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              width: 56,
              margin: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingXs,
                vertical: AppTheme.spacingXs,
              ),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primary : Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primary
                      : isToday
                          ? AppTheme.primaryLight
                          : AppTheme.divider,
                  width: isToday && !isSelected ? 1.5 : 1,
                ),
                boxShadow: isSelected ? AppTheme.cardShadow : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('E').format(day).substring(0, 3),
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.8)
                          : AppTheme.textHint,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${day.day}',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : AppTheme.textPrimary,
                    ),
                  ),
                  if (isToday && !isSelected)
                    Container(
                      width: 5,
                      height: 5,
                      margin: const EdgeInsets.only(top: 2),
                      decoration: const BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter;

          return Padding(
            padding: const EdgeInsets.only(right: AppTheme.spacingSm),
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedFilter = filter);
                _loadHistory();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingMd,
                  vertical: AppTheme.spacingSm,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primary : Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primary
                        : AppTheme.divider,
                  ),
                ),
                child: Text(
                  filter,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : AppTheme.textSecondary,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHistoryList() {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacingMd,
        AppTheme.spacingSm,
        AppTheme.spacingMd,
        AppTheme.spacingLg,
      ),
      itemCount: _historyList.length,
      itemBuilder: (context, index) {
        return _buildHistoryCard(_historyList[index], index);
      },
    );
  }

  Widget _buildHistoryCard(MedicineHistory entry, int index) {
    final statusColor = _getStatusColor(entry.status);
    final statusBgColor = _getStatusBgColor(entry.status);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 80)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          boxShadow: AppTheme.softShadow,
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Color-coded left border
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppTheme.radiusMd),
                    bottomLeft: Radius.circular(AppTheme.radiusMd),
                  ),
                ),
              ),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  child: Row(
                    children: [
                      // Status icon
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: statusBgColor,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusSm),
                        ),
                        child: Icon(
                          _getStatusIcon(entry.status),
                          color: statusColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingSm),
                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.medicineName,
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(Icons.schedule_rounded,
                                    size: 13, color: AppTheme.textHint),
                                const SizedBox(width: 4),
                                Text(
                                  'Scheduled: ${DateFormat('hh:mm a').format(entry.scheduledTime)}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: AppTheme.textHint,
                                  ),
                                ),
                              ],
                            ),
                            if (entry.takenTime != null) ...[
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(Icons.check_rounded,
                                      size: 13, color: statusColor),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Taken: ${DateFormat('hh:mm a').format(entry.takenTime!)}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: statusColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusBgColor,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusFull),
                        ),
                        child: Text(
                          _getStatusLabel(entry.status),
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing2Xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.primarySurface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.event_note_rounded,
                size: 48,
                color: AppTheme.primaryLight.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Text(
              'No history for this date',
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              _isSameDay(_selectedDate, DateTime.now())
                  ? 'Take your medicines to see them here'
                  : 'No medicines were tracked on this day',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppTheme.textHint,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medreminder/app/theme.dart';

class TimePickerChip extends StatelessWidget {
  final TimeOfDay time;
  final VoidCallback? onDelete;
  final bool isSelected;

  const TimePickerChip({
    super.key,
    required this.time,
    this.onDelete,
    this.isSelected = false,
  });

  /// Format a TimeOfDay into '8:30 AM' style.
  String _formatTime(TimeOfDay t) {
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final filled = isSelected;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      padding: EdgeInsets.only(
        left: 14,
        right: onDelete != null ? 6 : 14,
        top: 8,
        bottom: 8,
      ),
      decoration: BoxDecoration(
        color: filled ? AppTheme.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(
          color: filled ? AppTheme.primary : AppTheme.primaryLight,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.access_time_rounded,
            size: 16,
            color: filled ? Colors.white : AppTheme.primary,
          ),
          const SizedBox(width: 6),
          Text(
            _formatTime(time),
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: filled ? Colors.white : AppTheme.primary,
            ),
          ),
          if (onDelete != null) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onDelete,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: filled
                      ? Colors.white.withOpacity(0.25)
                      : AppTheme.primarySurface,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close_rounded,
                  size: 14,
                  color: filled ? Colors.white : AppTheme.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

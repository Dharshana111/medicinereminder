import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medreminder/app/theme.dart';
import 'package:medreminder/models/medicine.dart';

class MedicineCard extends StatelessWidget {
  final Medicine medicine;
  final VoidCallback? onTap;
  final VoidCallback? onTakePressed;
  final bool showTakeButton;

  const MedicineCard({
    super.key,
    required this.medicine,
    this.onTap,
    this.onTakePressed,
    this.showTakeButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Row(
          children: [
            // ── Medicine Image ──
            _buildImage(),
            const SizedBox(width: AppTheme.spacingMd),

            // ── Medicine Info ──
            Expanded(child: _buildInfo(context)),

            // ── Take Button ──
            if (showTakeButton && medicine.isActive) ...[
              const SizedBox(width: AppTheme.spacingSm),
              _buildTakeButton(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    return Hero(
      tag: 'medicine_image_${medicine.id}',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        child: SizedBox(
          width: 60,
          height: 60,
          child: medicine.imagePath != null &&
                  File(medicine.imagePath!).existsSync()
              ? Image.file(
                  File(medicine.imagePath!),
                  fit: BoxFit.cover,
                )
              : Container(
                  decoration: const BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                  ),
                  child: const Icon(
                    Icons.medication_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Name + active indicator
        Row(
          children: [
            // Active / inactive dot
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color:
                    medicine.isActive ? AppTheme.success : AppTheme.textHint,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppTheme.spacingXs),
            Expanded(
              child: Text(
                medicine.name,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),

        // Dosage
        Text(
          medicine.dosage,
          style: Theme.of(context).textTheme.bodySmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppTheme.spacingXs),

        // Schedule time chips + frequency
        Row(
          children: [
            Icon(
              Icons.access_time_rounded,
              size: 14,
              color: AppTheme.primaryLight,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                '${medicine.formattedSchedule}  •  ${medicine.frequencyLabel}',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTakeButton() {
    return SizedBox(
      height: 36,
      child: ElevatedButton(
        onPressed: onTakePressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.success,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: const Text('Take'),
      ),
    );
  }
}

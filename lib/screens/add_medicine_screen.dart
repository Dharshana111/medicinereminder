import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:medreminder/app/theme.dart';
import 'package:medreminder/models/medicine.dart';
import 'package:medreminder/utils/constants.dart';
import 'package:medreminder/utils/validators.dart';
import 'package:medreminder/services/storage_service.dart';
import 'package:medreminder/services/notification_service.dart';
import 'package:medreminder/services/image_service.dart';
import 'package:medreminder/widgets/custom_text_field.dart';

class AddMedicineScreen extends StatefulWidget {
  final Medicine? medicine;

  const AddMedicineScreen({super.key, this.medicine});

  @override
  State<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dosageController = TextEditingController();

  String _frequency = AppConstants.frequencyDaily;
  List<TimeOfDay> _scheduleTimes = [];
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  String? _imagePath;
  bool _isSaving = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  bool get _isEditing => widget.medicine != null;

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

    if (_isEditing) {
      _prefillForm(widget.medicine!);
    }
  }

  void _prefillForm(Medicine med) {
    _nameController.text = med.name;
    _descriptionController.text = med.description;
    _dosageController.text = med.dosage;
    _frequency = med.frequency;
    _scheduleTimes = List.from(med.scheduleTimes);
    _startDate = med.startDate;
    _endDate = med.endDate;
    _imagePath = med.imagePath;
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _dosageController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLg),
        ),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppTheme.spacingLg),
              Text(
                'Add Medicine Photo',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: AppTheme.spacingMd),
              ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.primarySurface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: const Icon(Icons.camera_alt_rounded,
                      color: AppTheme.primary),
                ),
                title: Text('Camera',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                subtitle: Text('Take a photo',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: AppTheme.textHint)),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _captureImage(fromCamera: true);
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.primarySurface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: const Icon(Icons.photo_library_rounded,
                      color: AppTheme.primary),
                ),
                title: Text('Gallery',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                subtitle: Text('Choose from gallery',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: AppTheme.textHint)),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _captureImage(fromCamera: false);
                },
              ),
              const SizedBox(height: AppTheme.spacingSm),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _captureImage({required bool fromCamera}) async {
    try {
      final tempPath = await ImageService.pickImage(fromCamera: fromCamera);
      if (tempPath != null) {
        final savedPath = await ImageService.saveImage(tempPath);
        setState(() => _imagePath = savedPath);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  void _removeImage() async {
    if (_imagePath != null) {
      try {
        await ImageService.deleteImage(_imagePath!);
      } catch (_) {}
      setState(() => _imagePath = null);
    }
  }

  Future<void> _addTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppTheme.primary,
                  onPrimary: Colors.white,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _scheduleTimes.add(picked));
    }
  }

  void _removeTime(int index) {
    setState(() => _scheduleTimes.removeAt(index));
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppTheme.primary,
                  onPrimary: Colors.white,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate.add(const Duration(days: 7)),
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 730)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppTheme.primary,
                  onPrimary: Colors.white,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  Future<void> _saveMedicine() async {
    if (!_formKey.currentState!.validate()) return;

    if (_scheduleTimes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning_rounded, color: Colors.white, size: 20),
              const SizedBox(width: AppTheme.spacingSm),
              Text('Please add at least one schedule time',
                  style: GoogleFonts.poppins(color: Colors.white)),
            ],
          ),
          backgroundColor: AppTheme.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final medicine = Medicine(
        id: _isEditing ? widget.medicine!.id : null,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        dosage: _dosageController.text.trim(),
        imagePath: _imagePath,
        scheduleTimes: _scheduleTimes,
        frequency: _frequency,
        startDate: _startDate,
        endDate: _endDate,
        isActive: true,
        createdAt: _isEditing ? widget.medicine!.createdAt : null,
      );

      if (_isEditing) {
        if (widget.medicine != null) {
          await NotificationService.cancelMedicineNotifications(widget.medicine!);
        }
        await StorageService.updateMedicine(medicine);
      } else {
        await StorageService.saveMedicine(medicine);
      }

      // Schedule notifications for each time
      for (final time in _scheduleTimes) {
        await NotificationService.scheduleMedicineNotification(medicine, time);
      }

      NotificationService.scheduleVoiceAlerts();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 20),
              const SizedBox(width: AppTheme.spacingSm),
              Text(
                _isEditing
                    ? 'Medicine updated successfully!'
                    : 'Medicine added successfully!',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            ],
          ),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Medicine' : 'Add Medicine'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppTheme.error),
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Medicine Details'),
                      const SizedBox(height: AppTheme.spacingSm),
                      _buildDetailsSection(),
                      const SizedBox(height: AppTheme.spacingLg),
                      _buildSectionTitle('Medicine Image'),
                      const SizedBox(height: AppTheme.spacingSm),
                      _buildImageSection(),
                      const SizedBox(height: AppTheme.spacingLg),
                      _buildSectionTitle('Schedule'),
                      const SizedBox(height: AppTheme.spacingSm),
                      _buildScheduleSection(),
                      const SizedBox(height: AppTheme.spacingLg),
                    ],
                  ),
                ),
              ),
            ),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
      ),
    );
  }

  Widget _buildDetailsSection() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        children: [
          CustomTextField(
            controller: _nameController,
            label: 'Medicine Name',
            hint: 'e.g. Amoxicillin',
            prefixIcon: Icons.medication_outlined,
            validator: Validators.medicineName,
          ),
          const SizedBox(height: AppTheme.spacingMd),
          CustomTextField(
            controller: _descriptionController,
            label: 'Description',
            hint: 'Brief description or notes',
            prefixIcon: Icons.description_outlined,
            maxLines: 3,
          ),
          const SizedBox(height: AppTheme.spacingMd),
          CustomTextField(
            controller: _dosageController,
            label: 'Dosage',
            hint: 'e.g. 500mg, 2 tablets',
            prefixIcon: Icons.local_pharmacy_outlined,
            validator: Validators.dosage,
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.softShadow,
      ),
      child: _imagePath != null ? _buildImagePreview() : _buildImagePicker(),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: double.infinity,
        height: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: AppTheme.primary.withOpacity(0.3),
            width: 1.5,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
          color: AppTheme.primarySurface,
        ),
        child: CustomPaint(
          painter: _DashedBorderPainter(
            color: AppTheme.primary.withOpacity(0.3),
            radius: AppTheme.radiusMd,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  color: AppTheme.primary,
                  size: 28,
                ),
              ),
              const SizedBox(height: AppTheme.spacingSm),
              Text(
                'Tap to add medicine photo',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: AppTheme.spacingXs),
              Text(
                'Camera or Gallery',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppTheme.textHint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: kIsWeb
              ? Image.network(
                  _imagePath!,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                )
              : Image.file(
                  File(_imagePath!),
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
        ),
        Positioned(
          top: AppTheme.spacingSm,
          right: AppTheme.spacingSm,
          child: GestureDetector(
            onTap: _removeImage,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.9),
                shape: BoxShape.circle,
                boxShadow: AppTheme.softShadow,
              ),
              child: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleSection() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Frequency selector
          Text(
            'Frequency',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Row(
            children: [
              _buildFrequencyChip('Daily', AppConstants.frequencyDaily),
              const SizedBox(width: AppTheme.spacingSm),
              _buildFrequencyChip('Weekly', AppConstants.frequencyWeekly),
              const SizedBox(width: AppTheme.spacingSm),
              _buildFrequencyChip('One Time', AppConstants.frequencyOneTime),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),
          const Divider(),
          const SizedBox(height: AppTheme.spacingMd),

          // Time slots
          Text(
            'Schedule Times',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Wrap(
            spacing: AppTheme.spacingSm,
            runSpacing: AppTheme.spacingSm,
            children: [
              ..._scheduleTimes.asMap().entries.map((entry) {
                final index = entry.key;
                final time = entry.value;
                return _buildTimeChip(time, index);
              }),
              ActionChip(
                avatar: const Icon(Icons.add_rounded,
                    size: 18, color: AppTheme.primary),
                label: Text(
                  'Add Time',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.primary,
                  ),
                ),
                backgroundColor: AppTheme.primarySurface,
                side: BorderSide(
                  color: AppTheme.primary.withOpacity(0.3),
                ),
                onPressed: _addTime,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),
          const Divider(),
          const SizedBox(height: AppTheme.spacingMd),

          // Start Date
          _buildDateField(
            label: 'Start Date',
            date: _startDate,
            onTap: _pickStartDate,
            icon: Icons.calendar_today_rounded,
          ),

          // End Date (only for daily/weekly)
          if (_frequency != AppConstants.frequencyOneTime) ...[
            const SizedBox(height: AppTheme.spacingMd),
            _buildDateField(
              label: 'End Date (optional)',
              date: _endDate,
              onTap: _pickEndDate,
              icon: Icons.event_rounded,
              isOptional: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFrequencyChip(String label, String value) {
    final isSelected = _frequency == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _frequency = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary : AppTheme.primarySurface,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            border: Border.all(
              color: isSelected
                  ? AppTheme.primary
                  : AppTheme.primary.withOpacity(0.15),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppTheme.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeChip(TimeOfDay time, int index) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';

    return Chip(
      label: Text(
        '$hour:$minute $period',
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
      backgroundColor: AppTheme.primary,
      deleteIcon: const Icon(Icons.close_rounded, size: 16, color: Colors.white),
      onDeleted: () => _removeTime(index),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
    required IconData icon,
    bool isOptional = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMd,
          vertical: AppTheme.spacingSm + 4,
        ),
        decoration: BoxDecoration(
          color: AppTheme.primarySurface,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primaryLight, size: 20),
            const SizedBox(width: AppTheme.spacingSm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppTheme.textHint,
                    ),
                  ),
                  Text(
                    date != null
                        ? DateFormat('MMM dd, yyyy').format(date)
                        : 'Tap to select',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: date != null
                          ? AppTheme.textPrimary
                          : AppTheme.textHint,
                    ),
                  ),
                ],
              ),
            ),
            if (isOptional && date != null)
              GestureDetector(
                onTap: () => setState(() => _endDate = null),
                child: const Icon(Icons.close_rounded,
                    size: 18, color: AppTheme.textHint),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacingMd,
        AppTheme.spacingSm,
        AppTheme.spacingMd,
        AppTheme.spacingMd,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: _isSaving ? null : _saveMedicine,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 56,
          decoration: BoxDecoration(
            gradient: _isSaving ? null : AppTheme.primaryGradient,
            color: _isSaving ? AppTheme.primaryLight : null,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            boxShadow: AppTheme.elevatedShadow,
          ),
          child: Center(
            child: _isSaving
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isEditing
                            ? Icons.save_rounded
                            : Icons.add_circle_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      const SizedBox(width: AppTheme.spacingSm),
                      Text(
                        _isEditing ? 'Update Medicine' : 'Save Medicine',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        title: Text(
          'Delete Medicine?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'This will permanently remove "${widget.medicine!.name}" and all its scheduled notifications.',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AppTheme.textSecondary,
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
              await NotificationService.cancelMedicineNotifications(
                  widget.medicine!);
              await StorageService.deleteMedicine(widget.medicine!.id);
              NotificationService.scheduleVoiceAlerts();
              if (!mounted) return;
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
            ),
            child: Text(
              'Delete',
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
}

/// Custom painter for dashed border effect
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;

  _DashedBorderPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    const dashWidth = 8.0;
    const dashSpace = 5.0;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();

    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final end = (distance + dashWidth).clamp(0, metric.length);
        final extracted = metric.extractPath(distance, end.toDouble());
        canvas.drawPath(extracted, paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

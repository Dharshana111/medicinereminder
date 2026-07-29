import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medreminder/app/theme.dart';
import 'package:medreminder/app/routes.dart';
import 'package:medreminder/models/medicine.dart';
import 'package:medreminder/models/medicine_history.dart';
import 'package:medreminder/services/storage_service.dart';
import 'package:medreminder/services/notification_service.dart';
import 'package:medreminder/widgets/medicine_card.dart';
import 'package:medreminder/widgets/adherence_chart.dart';
import 'package:medreminder/widgets/stat_card.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  List<Medicine> _medicines = [];
  int _takenCount = 0;
  int _missedCount = 0;
  int _pendingCount = 0;
  double _adherenceRate = 0;
  Map<String, int> _weeklyStats = {};
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));
    _loadData();
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _loadData() {
    final profile = StorageService.getUserProfile();
    final medicines = StorageService.getMedicines();

    setState(() {
      _userName = profile?.name ?? 'User';
      _medicines = medicines.where((m) => m.isActive).toList();
      _takenCount = StorageService.getTodayTakenCount();
      _missedCount = StorageService.getTodayMissedCount();
      _pendingCount = StorageService.getTodayPendingCount();
      _weeklyStats = StorageService.getWeeklyStats();

      final total = _takenCount + _missedCount + _pendingCount;
      _adherenceRate = total > 0 ? (_takenCount / total) * 100 : 0;
    });
  }

  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(milliseconds: 400));
    _loadData();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }

  void _onTakeMedicine(Medicine medicine) {
    final now = DateTime.now();
    final history = MedicineHistory(
      medicineId: medicine.id,
      medicineName: medicine.name,
      scheduledTime: now,
      takenTime: now,
      status: 'taken',
    );
    StorageService.saveHistory(history);
    NotificationService.speakReminder(medicine.name);
    _loadData();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: AppTheme.spacingSm),
            Text(
              '${medicine.name} marked as taken!',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ],
        ),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      floatingActionButton: _buildFAB(),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.primary,
          onRefresh: _onRefresh,
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader()),
                  SliverToBoxAdapter(child: _buildStatsGrid()),
                  SliverToBoxAdapter(child: _buildAdherenceSection()),
                  SliverToBoxAdapter(child: _buildWeeklySection()),
                  SliverToBoxAdapter(child: _buildTodayMedicinesSection()),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 100),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: AppTheme.elevatedShadow,
      ),
      child: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.addMedicine).then((_) {
            _loadData();
          });
        },
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacingMd,
        AppTheme.spacingLg,
        AppTheme.spacingMd,
        AppTheme.spacingSm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_getGreeting()} 👋',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXs),
                Text(
                  _userName,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXs),
                Text(
                  DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now()),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.textHint,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              // Profile is handled by the bottom nav tab
            },
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _getInitials(_userName),
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingSm,
      ),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: AppTheme.spacingSm,
        mainAxisSpacing: AppTheme.spacingSm,
        childAspectRatio: 1.3,
        children: [
          StatCard(
            title: 'Total Medicines',
            value: '${_medicines.length}',
            icon: Icons.medication_rounded,
            color: AppTheme.primary,
          ),
          StatCard(
            title: 'Taken Today',
            value: '$_takenCount',
            icon: Icons.check_circle_rounded,
            color: AppTheme.success,
          ),
          StatCard(
            title: 'Missed',
            value: '$_missedCount',
            icon: Icons.cancel_rounded,
            color: AppTheme.error,
          ),
          StatCard(
            title: 'Upcoming',
            value: '$_pendingCount',
            icon: Icons.schedule_rounded,
            color: AppTheme.warning,
          ),
        ],
      ),
    );
  }

  Widget _buildAdherenceSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacingMd,
        AppTheme.spacingLg,
        AppTheme.spacingMd,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Today's Adherence",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              children: [
                AdherenceChart(percentage: _adherenceRate),
                const SizedBox(height: AppTheme.spacingMd),
                Text(
                  _adherenceRate >= 80
                      ? 'Great job! Keep it up! 🎉'
                      : _adherenceRate >= 50
                          ? "You're doing okay, stay consistent! 💪"
                          : "Don't forget your medicines! 🔔",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklySection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacingMd,
        AppTheme.spacingLg,
        AppTheme.spacingMd,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weekly Progress',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              boxShadow: AppTheme.cardShadow,
            ),
            child: WeeklyBarChart(data: _weeklyStats),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayMedicinesSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacingMd,
        AppTheme.spacingLg,
        AppTheme.spacingMd,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Today's Schedule",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              if (_medicines.isNotEmpty)
                TextButton(
                  onPressed: () {
                    // Navigate to history tab — handled by parent HomeScreen
                  },
                  child: Text(
                    'See All',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          if (_medicines.isEmpty)
            _buildEmptyState()
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _medicines.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppTheme.spacingSm),
              itemBuilder: (context, index) {
                final medicine = _medicines[index];
                return MedicineCard(
                  medicine: medicine,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.editMedicine,
                      arguments: medicine,
                    ).then((_) => _loadData());
                  },
                  onTakePressed: () => _onTakeMedicine(medicine),
                  showTakeButton: true,
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: AppTheme.spacing2Xl,
        horizontal: AppTheme.spacingLg,
      ),
      decoration: BoxDecoration(
        color: AppTheme.primarySurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: AppTheme.primary.withOpacity(0.1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: AppTheme.softShadow,
            ),
            child: Icon(
              Icons.medication_liquid_rounded,
              size: 40,
              color: AppTheme.primaryLight.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Text(
            'No medicines yet',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Text(
            'Add your first medicine to start\ntracking your health journey',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppTheme.textHint,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.addMedicine).then((_) {
                _loadData();
              });
            },
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text('Add Medicine'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingLg,
                vertical: AppTheme.spacingSm + 4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

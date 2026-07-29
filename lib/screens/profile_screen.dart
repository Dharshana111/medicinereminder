import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:medreminder/app/theme.dart';
import 'package:medreminder/app/routes.dart';
import 'package:medreminder/utils/constants.dart';
import 'package:medreminder/models/user_profile.dart';
import 'package:medreminder/services/storage_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  UserProfile? _profile;
  bool _notificationsEnabled = true;
  bool _voiceAlertsEnabled = true;
  int _totalMedicines = 0;
  int _activeMedicines = 0;
  double _adherenceRate = 0;

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
    _loadData();
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
      _profile = profile;
      _totalMedicines = medicines.length;
      _activeMedicines = medicines.where((m) => m.isActive).length;
      _adherenceRate = StorageService.getAdherenceRate();
    });
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }

  void _editProfile() {
    Navigator.pushNamed(context, AppRoutes.registration).then((_) {
      _loadData();
    });
  }

  void _resetApp() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.errorLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_rounded,
                  color: AppTheme.error, size: 22),
            ),
            const SizedBox(width: AppTheme.spacingSm),
            Expanded(
              child: Text(
                'Reset App?',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        content: Text(
          'This will permanently delete all your data including your profile, medicines, and history. This action cannot be undone.',
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
              // Clear all medicines
              final medicines = StorageService.getMedicines();
              for (final med in medicines) {
                await StorageService.deleteMedicine(med.id);
              }
              if (!mounted) return;
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.splash,
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
            ),
            child: Text(
              'Reset Everything',
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
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              _buildProfileHeader(),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingMd,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: AppTheme.spacingLg),
                    _buildPersonalDetailsCard(),
                    const SizedBox(height: AppTheme.spacingMd),
                    _buildAdditionalInfoCard(),
                    const SizedBox(height: AppTheme.spacingMd),
                    _buildSettingsCard(),
                    const SizedBox(height: AppTheme.spacingMd),
                    _buildMedicineStatsCard(),
                    const SizedBox(height: AppTheme.spacingLg),
                    _buildEditProfileButton(),
                    const SizedBox(height: AppTheme.spacingMd),
                    _buildAppInfoSection(),
                    const SizedBox(height: AppTheme.spacingMd),
                    _buildResetButton(),
                    const SizedBox(height: AppTheme.spacing2Xl),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + AppTheme.spacingLg,
        bottom: AppTheme.spacingXl,
      ),
      decoration: const BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(AppTheme.radiusXl),
          bottomRight: Radius.circular(AppTheme.radiusXl),
        ),
      ),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
              border: Border.all(
                color: Colors.white.withOpacity(0.4),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryDark.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: Text(
                _profile != null ? _getInitials(_profile!.name) : 'U',
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          // Name
          Text(
            _profile?.name ?? 'User',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXs),
          // Email
          Text(
            _profile?.email ?? '',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalDetailsCard() {
    if (_profile == null) return const SizedBox.shrink();

    return _buildCard(
      title: 'Personal Details',
      icon: Icons.person_rounded,
      children: [
        _buildInfoRow(Icons.cake_rounded, 'Age', '${_profile!.age} years'),
        _buildDivider(),
        _buildInfoRow(Icons.calendar_today_rounded, 'Date of Birth',
            DateFormat('MMM dd, yyyy').format(_profile!.dob)),
        _buildDivider(),
        _buildInfoRow(
          _profile!.gender == 'Male'
              ? Icons.male_rounded
              : _profile!.gender == 'Female'
                  ? Icons.female_rounded
                  : Icons.transgender_rounded,
          'Gender',
          _profile!.gender,
        ),
        _buildDivider(),
        _buildInfoRow(Icons.phone_rounded, 'Phone', _profile!.phone),
        _buildDivider(),
        _buildInfoRow(Icons.location_on_rounded, 'Address', _profile!.address),
        _buildDivider(),
        _buildInfoRow(
            Icons.bloodtype_rounded, 'Blood Group', _profile!.bloodGroup),
        _buildDivider(),
        _buildInfoRow(Icons.monitor_weight_rounded, 'Weight',
            '${_profile!.weight.toStringAsFixed(1)} kg'),
        _buildDivider(),
        _buildInfoRow(Icons.height_rounded, 'Height',
            '${_profile!.height.toStringAsFixed(1)} cm'),
      ],
    );
  }

  Widget _buildAdditionalInfoCard() {
    if (_profile == null) return const SizedBox.shrink();

    final hasEmergency =
        _profile!.emergencyContact != null &&
        _profile!.emergencyContact!.isNotEmpty;
    final hasAllergies =
        _profile!.allergies != null && _profile!.allergies!.isNotEmpty;

    if (!hasEmergency && !hasAllergies) return const SizedBox.shrink();

    return _buildCard(
      title: 'Additional Info',
      icon: Icons.info_rounded,
      children: [
        if (hasEmergency)
          _buildInfoRow(Icons.emergency_rounded, 'Emergency Contact',
              _profile!.emergencyContact!),
        if (hasEmergency && hasAllergies) _buildDivider(),
        if (hasAllergies)
          _buildInfoRow(Icons.warning_amber_rounded, 'Allergies',
              _profile!.allergies!),
      ],
    );
  }

  Widget _buildSettingsCard() {
    return _buildCard(
      title: 'Settings',
      icon: Icons.settings_rounded,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            'Notifications',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
          subtitle: Text(
            'Receive medicine reminders',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppTheme.textHint,
            ),
          ),
          secondary: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primarySurface,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: const Icon(Icons.notifications_rounded,
                color: AppTheme.primary, size: 20),
          ),
          value: _notificationsEnabled,
          activeThumbColor: AppTheme.primary,
          onChanged: (val) => setState(() => _notificationsEnabled = val),
        ),
        _buildDivider(),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            'Voice Alerts',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
          subtitle: Text(
            'Speak medicine name aloud',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppTheme.textHint,
            ),
          ),
          secondary: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primarySurface,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: const Icon(Icons.record_voice_over_rounded,
                color: AppTheme.primary, size: 20),
          ),
          value: _voiceAlertsEnabled,
          activeThumbColor: AppTheme.primary,
          onChanged: (val) => setState(() => _voiceAlertsEnabled = val),
        ),
      ],
    );
  }

  Widget _buildMedicineStatsCard() {
    return _buildCard(
      title: 'Medicine Stats',
      icon: Icons.analytics_rounded,
      children: [
        _buildStatsRow(
          icon: Icons.medication_rounded,
          label: 'Total Medicines',
          value: '$_totalMedicines',
          color: AppTheme.primary,
        ),
        _buildDivider(),
        _buildStatsRow(
          icon: Icons.check_circle_rounded,
          label: 'Active Medicines',
          value: '$_activeMedicines',
          color: AppTheme.success,
        ),
        _buildDivider(),
        _buildStatsRow(
          icon: Icons.show_chart_rounded,
          label: 'Overall Adherence',
          value: '${_adherenceRate.toStringAsFixed(1)}%',
          color: _adherenceRate >= 80
              ? AppTheme.success
              : _adherenceRate >= 50
                  ? AppTheme.warning
                  : AppTheme.error,
        ),
      ],
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.primarySurface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusXs),
                ),
                child: Icon(icon, color: AppTheme.primary, size: 18),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSm),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryLight),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppTheme.textHint,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSm),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      color: AppTheme.divider,
    );
  }

  Widget _buildEditProfileButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: _editProfile,
        icon: const Icon(Icons.edit_rounded, size: 20),
        label: Text(
          'Edit Profile',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.primary,
          side: const BorderSide(color: AppTheme.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
        ),
      ),
    );
  }

  Widget _buildAppInfoSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.primarySurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(AppTheme.radiusXs),
                ),
                child: const Icon(
                  Icons.medical_services_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Text(
                AppConstants.appName,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            'Version ${AppConstants.appVersion}',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppTheme.textHint,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Text(
            'Made with ♥ for your health',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResetButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: _resetApp,
        icon: const Icon(Icons.restart_alt_rounded, size: 20),
        label: Text(
          'Reset App',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.error,
          side: const BorderSide(color: AppTheme.error, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
        ),
      ),
    );
  }
}

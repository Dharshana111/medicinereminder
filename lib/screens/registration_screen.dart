import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:medreminder/app/theme.dart';
import 'package:medreminder/app/routes.dart';
import 'package:medreminder/utils/constants.dart';
import 'package:medreminder/utils/validators.dart';
import 'package:medreminder/models/user_profile.dart';
import 'package:medreminder/services/storage_service.dart';
import 'package:medreminder/widgets/custom_text_field.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  // ── Controllers ──
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _dobController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  final _allergiesController = TextEditingController();

  // ── Dropdown values ──
  String? _selectedGender;
  String? _selectedBloodGroup;
  DateTime? _selectedDob;

  // ── Section entrance animations ──
  late final List<AnimationController> _sectionControllers;
  late final List<Animation<double>> _sectionFades;
  late final List<Animation<Offset>> _sectionSlides;

  static const _sectionCount = 5; // header + 4 form sections

  @override
  void initState() {
    super.initState();
    _initSectionAnimations();
    _playSectionAnimations();
  }

  void _initSectionAnimations() {
    _sectionControllers = List.generate(
      _sectionCount,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      ),
    );

    _sectionFades = _sectionControllers
        .map((c) => CurvedAnimation(parent: c, curve: Curves.easeOut))
        .toList();

    _sectionSlides = _sectionControllers
        .map((c) => Tween<Offset>(
              begin: const Offset(0, 0.15),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: c, curve: Curves.easeOutCubic)))
        .toList();
  }

  void _playSectionAnimations() {
    for (int i = 0; i < _sectionCount; i++) {
      Future.delayed(Duration(milliseconds: 120 * i), () {
        if (mounted) _sectionControllers[i].forward();
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _dobController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _emergencyContactController.dispose();
    _allergiesController.dispose();
    for (final c in _sectionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Date Picker ──
  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime(now.year - 25),
      firstDate: DateTime(1900),
      lastDate: now,
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
      setState(() {
        _selectedDob = picked;
        _dobController.text = DateFormat('dd MMM yyyy').format(picked);
        // Auto-calculate age
        int age = now.year - picked.year;
        if (now.month < picked.month ||
            (now.month == picked.month && now.day < picked.day)) {
          age--;
        }
        _ageController.text = age.toString();
      });
    }
  }

  // ── Submit ──
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your date of birth')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final profile = UserProfile(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        bloodGroup: _selectedBloodGroup ?? AppConstants.bloodGroups.first,
        gender: _selectedGender ?? AppConstants.genders.first,
        age: int.parse(_ageController.text.trim()),
        weight: double.parse(_weightController.text.trim()),
        height: double.parse(_heightController.text.trim()),
        dob: _selectedDob!,
        emergencyContact: _emergencyContactController.text.trim().isEmpty
            ? null
            : _emergencyContactController.text.trim(),
        allergies: _allergiesController.text.trim().isEmpty
            ? null
            : _allergiesController.text.trim(),
      );

      await StorageService.saveUserProfile(profile);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: AppTheme.spacingSm),
              Text(
                'Welcome, ${profile.name}!',
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

      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppTheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ── Helpers ──
  Widget _animatedSection(int index, Widget child) {
    return FadeTransition(
      opacity: _sectionFades[index],
      child: SlideTransition(
        position: _sectionSlides[index],
        child: child,
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppTheme.spacingLg,
        bottom: AppTheme.spacingMd,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primarySurface,
              borderRadius: BorderRadius.circular(AppTheme.radiusXs),
            ),
            child: Icon(icon, size: 18, color: AppTheme.primary),
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
    );
  }

  Widget _buildDropdown({
    required String label,
    required IconData icon,
    required List<String> items,
    required String? value,
    required ValueChanged<String?> onChanged,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppTheme.primaryLight),
          filled: true,
          fillColor: AppTheme.primarySurface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            borderSide: const BorderSide(color: AppTheme.primary, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: AppTheme.textPrimary,
        ),
        dropdownColor: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: onChanged,
        validator: validator,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingLg,
            vertical: AppTheme.spacingMd,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ═══ Header Card ═══
                _animatedSection(0, _buildHeaderCard()),

                // ═══ Personal Information ═══
                _animatedSection(1, _buildPersonalSection()),

                // ═══ Contact Details ═══
                _animatedSection(2, _buildContactSection()),

                // ═══ Health Information ═══
                _animatedSection(3, _buildHealthSection()),

                // ═══ Additional (Optional) ═══
                _animatedSection(4, _buildAdditionalSection()),

                // ═══ Submit Button ═══
                const SizedBox(height: AppTheme.spacingLg),
                _buildSubmitButton(),
                const SizedBox(height: AppTheme.spacing2Xl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════
  // BUILD SECTIONS
  // ══════════════════════════════════════════════

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.elevatedShadow,
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_add_alt_1_rounded,
              size: 32,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Text(
            'Create Your Profile',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Text(
            'Let\'s personalize your medicine reminders',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white.withOpacity(0.85),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Personal Information', Icons.person_outline),
        CustomTextField(
          controller: _nameController,
          label: 'Full Name',
          hint: 'Enter your full name',
          prefixIcon: Icons.person_outline,
          validator: Validators.name,
        ),
        const SizedBox(height: AppTheme.spacingMd),
        CustomTextField(
          controller: _ageController,
          label: 'Age',
          hint: 'Your age',
          prefixIcon: Icons.cake_outlined,
          keyboardType: TextInputType.number,
          validator: Validators.age,
        ),
        const SizedBox(height: AppTheme.spacingMd),
        CustomTextField(
          controller: _dobController,
          label: 'Date of Birth',
          hint: 'Select your date of birth',
          prefixIcon: Icons.calendar_today_outlined,
          readOnly: true,
          onTap: _pickDateOfBirth,
          validator: (value) =>
              Validators.required(value, 'Date of birth'),
        ),
        const SizedBox(height: AppTheme.spacingMd),
        _buildDropdown(
          label: 'Gender',
          icon: Icons.wc_outlined,
          items: AppConstants.genders,
          value: _selectedGender,
          onChanged: (v) => setState(() => _selectedGender = v),
          validator: (v) =>
              v == null ? 'Please select your gender' : null,
        ),
      ],
    );
  }

  Widget _buildContactSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: AppTheme.spacingLg),
        _sectionHeader('Contact Details', Icons.phone_outlined),
        CustomTextField(
          controller: _phoneController,
          label: 'Phone Number',
          hint: 'Enter your phone number',
          prefixIcon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          validator: Validators.phone,
        ),
        const SizedBox(height: AppTheme.spacingMd),
        CustomTextField(
          controller: _emailController,
          label: 'Email Address',
          hint: 'Enter your email',
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: Validators.email,
        ),
        const SizedBox(height: AppTheme.spacingMd),
        CustomTextField(
          controller: _addressController,
          label: 'Address',
          hint: 'Enter your full address',
          prefixIcon: Icons.location_on_outlined,
          maxLines: 2,
          validator: Validators.address,
        ),
      ],
    );
  }

  Widget _buildHealthSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: AppTheme.spacingLg),
        _sectionHeader('Health Information', Icons.favorite_outline),
        _buildDropdown(
          label: 'Blood Group',
          icon: Icons.bloodtype_outlined,
          items: AppConstants.bloodGroups,
          value: _selectedBloodGroup,
          onChanged: (v) => setState(() => _selectedBloodGroup = v),
          validator: (v) =>
              v == null ? 'Please select your blood group' : null,
        ),
        CustomTextField(
          controller: _weightController,
          label: 'Weight (kg)',
          hint: 'e.g. 65.5',
          prefixIcon: Icons.monitor_weight_outlined,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: Validators.weight,
        ),
        const SizedBox(height: AppTheme.spacingMd),
        CustomTextField(
          controller: _heightController,
          label: 'Height (cm)',
          hint: 'e.g. 170',
          prefixIcon: Icons.height_outlined,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: Validators.height,
        ),
      ],
    );
  }

  Widget _buildAdditionalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: AppTheme.spacingLg),
        _sectionHeader('Additional (Optional)', Icons.info_outline),
        CustomTextField(
          controller: _emergencyContactController,
          label: 'Emergency Contact',
          hint: 'Emergency phone number',
          prefixIcon: Icons.emergency_outlined,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: AppTheme.spacingMd),
        CustomTextField(
          controller: _allergiesController,
          label: 'Allergies',
          hint: 'List any known allergies',
          prefixIcon: Icons.warning_amber_outlined,
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          boxShadow: AppTheme.elevatedShadow,
        ),
        child: ElevatedButton(
          onPressed: _isSubmitting ? null : _submitForm,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Get Started',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingSm),
                    const Icon(Icons.arrow_forward_rounded,
                        color: Colors.white, size: 20),
                  ],
                ),
        ),
      ),
    );
  }
}

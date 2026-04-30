import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../theme/app_colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _profilePhotoBase64;
  final _name = TextEditingController();
  final _registrationId = TextEditingController();
  final _dob = TextEditingController();
  String? _gender;

  final _occupation = TextEditingController();
  String? _skills;
  final _yearsOfExperience = TextEditingController();
  final _volunteerExperience = TextEditingController();
  String? _areasOfHelp;
  bool _knowsEnglish = false;
  bool _knowsHindi = false;
  final _otherLanguage = TextEditingController();

  String _phoneCode = '+91';
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  String? _state;
  final _pincode = TextEditingController();

  bool _connectedToNGO = false;
  final _ngoName = TextEditingController();
  final _socialMedia = TextEditingController();
  final _additionalInfo = TextEditingController();

  bool _prefilled = false;

  final List<String> _indianStates = [
    'Andaman and Nicobar Islands', 'Andhra Pradesh', 'Arunachal Pradesh', 'Assam',
    'Bihar', 'Chandigarh', 'Chhattisgarh', 'Dadra and Nagar Haveli and Daman and Diu',
    'Delhi', 'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jammu and Kashmir',
    'Jharkhand', 'Karnataka', 'Kerala', 'Ladakh', 'Lakshadweep', 'Madhya Pradesh',
    'Maharashtra', 'Manipur', 'Meghalaya', 'Mizoram', 'Nagaland', 'Odisha',
    'Puducherry', 'Punjab', 'Rajasthan', 'Sikkim', 'Tamil Nadu', 'Telangana',
    'Tripura', 'Uttar Pradesh', 'Uttarakhand', 'West Bengal'
  ];

  @override
  void dispose() {
    _name.dispose();
    _registrationId.dispose();
    _dob.dispose();
    _occupation.dispose();
    _yearsOfExperience.dispose();
    _volunteerExperience.dispose();
    _otherLanguage.dispose();
    _phone.dispose();
    _email.dispose();
    _address.dispose();
    _city.dispose();
    _pincode.dispose();
    _ngoName.dispose();
    _socialMedia.dispose();
    _additionalInfo.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _profilePhotoBase64 = base64Encode(bytes);
        });
      }
    } catch (e) {
      if (!mounted) return;
      NotificationService.showMessage(context, 'Failed to pick image: $e');
    }
  }

  Future<void> _save() async {
    final isVolunteer = context.read<AuthService>().currentUser?.role == 'volunteer';

    if (_name.text.trim().isEmpty ||
        _phone.text.trim().isEmpty ||
        _email.text.trim().isEmpty ||
        _address.text.trim().isEmpty ||
        _city.text.trim().isEmpty ||
        _state == null ||
        _pincode.text.trim().isEmpty) {
      NotificationService.showMessage(context, 'Please fill all mandatory fields marked with *');
      return;
    }

    if (isVolunteer && (_occupation.text.trim().isEmpty || _skills == null)) {
      NotificationService.showMessage(context, 'Volunteer fields marked with * are required');
      return;
    }

    try {
      final auth = context.read<AuthService>();

      final languages = <String>[];
      if (_knowsEnglish) languages.add('English');
      if (_knowsHindi) languages.add('Hindi');
      if (_otherLanguage.text.trim().isNotEmpty) {
        languages.add(_otherLanguage.text.trim());
      }

      await auth.updateProfile(
        name: _name.text.trim(),
        voterIdVerified: auth.currentUser?.voterIdVerified ?? false,
        isAnonymous: auth.currentUser?.isAnonymous ?? false,
        profilePhoto: _profilePhotoBase64,
        registrationId: _registrationId.text.trim(),
        dateOfBirth: _dob.text.trim(),
        gender: _gender,
        occupation: _occupation.text.trim(),
        skills: _skills,
        yearsOfExperience: _yearsOfExperience.text.trim(),
        volunteerExperience: _volunteerExperience.text.trim(),
        areasOfHelp: _areasOfHelp ?? _skills,
        languagesKnown: languages,
        phone: '$_phoneCode ${_phone.text.trim()}'.trim(),
        address: _address.text.trim(),
        city: _city.text.trim(),
        state: _state,
        pincode: _pincode.text.trim(),
        connectedToNGO: _connectedToNGO,
        ngoName: _connectedToNGO ? _ngoName.text.trim() : '',
        socialMediaLink: _socialMedia.text.trim(),
        additionalInfo: _additionalInfo.text.trim(),
      );
      if (!mounted) return;
      NotificationService.showMessage(context, 'Profile updated successfully!');
      Navigator.pop(context);
    } catch (err) {
      if (!mounted) return;
      NotificationService.showMessage(
          context, err.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _prefill() {
    final user = context.read<AuthService>().currentUser;
    if (user == null || _prefilled) return;
    _prefilled = true;

    _profilePhotoBase64 = user.profilePhoto;
    _name.text = user.name;
    _email.text = user.email;

    _registrationId.text = user.registrationId ?? '';
    _dob.text = user.dateOfBirth ?? '';
    _gender = user.gender;

    _occupation.text = user.occupation ?? '';
    _skills = user.skills;
    _yearsOfExperience.text = user.yearsOfExperience ?? '';
    _volunteerExperience.text = user.volunteerExperience ?? '';
    _areasOfHelp = user.areasOfHelp;

    _knowsEnglish = user.languagesKnown.contains('English');
    _knowsHindi = user.languagesKnown.contains('Hindi');
    final others = user.languagesKnown
        .where((l) => l != 'English' && l != 'Hindi')
        .toList();
    if (others.isNotEmpty) {
      _otherLanguage.text = others.join(', ');
    }

    if (user.phone != null && user.phone!.startsWith('+')) {
      final parts = user.phone!.split(' ');
      if (parts.length > 1) {
        _phoneCode = parts[0];
        _phone.text = parts.sublist(1).join(' ');
      } else {
        _phone.text = user.phone!;
      }
    } else {
      _phone.text = user.phone ?? '';
    }

    _address.text = user.address ?? '';
    _city.text = user.city ?? '';
    if (_indianStates.contains(user.state)) {
      _state = user.state;
    }
    _pincode.text = user.pincode ?? '';

    _connectedToNGO = user.connectedToNGO;
    _ngoName.text = user.ngoName ?? '';
    _socialMedia.text = user.socialMediaLink ?? '';
    _additionalInfo.text = user.additionalInfo ?? '';
  }

  @override
  Widget build(BuildContext context) {
    _prefill();
    final auth = context.watch<AuthService>();
    final user = auth.currentUser;
    final isVolunteer = user?.role == 'volunteer';

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(isVolunteer ? 'Volunteer Profile' : 'Edit Profile'),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isVolunteer ? 'Create Volunteer Profile' : 'Edit Your Profile',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isVolunteer 
                          ? 'Complete your profile to get more opportunities and help those in need.'
                          : 'Update your personal information to keep your profile current.',
                        style: const TextStyle(color: Color(0xFF6B7280), fontSize: 15),
                      ),
                      const SizedBox(height: 40),
                      if (isVolunteer) ...[
                        _buildStepperHeader(),
                        const SizedBox(height: 40),
                      ],
                      _buildBasicInfo(),
                      const SizedBox(height: 24),
                      _buildExperienceSkills(),
                      const SizedBox(height: 24),
                      _buildContactPreferences(),
                      const SizedBox(height: 24),
                      _buildAdditionalInfo(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
              _buildBottomBar(auth.loading, isVolunteer),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepperHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          _stepperItem(1, 'Basic Info', true),
          _stepperConnector(true),
          _stepperItem(2, 'Experience', true),
          _stepperConnector(true),
          _stepperItem(3, 'Contact', true),
          _stepperConnector(true),
          _stepperItem(4, 'Review', true),
        ],
      ),
    );
  }

  Widget _stepperItem(int step, String label, bool isActive) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? AppColors.primary : Colors.white,
              border: Border.all(color: isActive ? AppColors.primary : const Color(0xFFE5E7EB), width: 1.5),
            ),
            child: Center(
              child: Text(
                '$step',
                style: TextStyle(color: isActive ? Colors.white : const Color(0xFF9CA3AF), fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF1A1A2E))),
        ],
      ),
    );
  }

  Widget _stepperConnector(bool isActive) {
    return Container(width: 40, height: 1, color: isActive ? AppColors.primary : const Color(0xFFE5E7EB), margin: const EdgeInsets.only(bottom: 20));
  }

  Widget _buildBasicInfo() {
    return _sectionCard(
      title: '1. Basic Information',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfilePhotoUpload(),
          const SizedBox(width: 32),
          Expanded(
            child: Column(
              children: [
                _buildTextField(label: 'Full Name *', controller: _name, hint: 'e.g. Supriya'),
                const SizedBox(height: 20),
                _buildRow(
                  _buildTextField(label: 'Date of Birth', controller: _dob, hint: 'DD/MM/YYYY', icon: Icons.calendar_today_outlined),
                  _buildDropdown(
                    label: 'Gender',
                    value: _gender,
                    items: ['Male', 'Female', 'Other'],
                    onChanged: (val) => setState(() => _gender = val),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExperienceSkills() {
    final isVolunteer = context.read<AuthService>().currentUser?.role == 'volunteer';
    return _sectionCard(
      title: isVolunteer ? '2. Experience & Skills' : '2. Professional Info',
      child: Column(
        children: [
          isVolunteer
              ? _buildRow(
                  _buildTextField(label: 'Occupation', controller: _occupation, hint: 'e.g. Teacher'),
                  _buildDropdown(
                    label: 'Skills / Areas of Interest',
                    value: _skills,
                    items: ['First Aid', 'Counseling', 'Legal Advice', 'General Help'],
                    onChanged: (val) => setState(() => _skills = val),
                  ),
                )
              : _buildTextField(label: 'Occupation', controller: _occupation, hint: 'e.g. Teacher'),
          const SizedBox(height: 20),
          isVolunteer
              ? _buildRow(
                  _buildTextField(label: 'Years of Experience', controller: _yearsOfExperience, hint: 'e.g. 5'),
                  _buildTextField(label: 'About Yourself', controller: _volunteerExperience, hint: 'Describe your background', maxLines: 3),
                )
              : _buildTextField(label: 'About Yourself', controller: _volunteerExperience, hint: 'Describe your background', maxLines: 3),
        ],
      ),
    );
  }

  Widget _buildContactPreferences() {
    return _sectionCard(
      title: '3. Contact Information',
      child: Column(
        children: [
          _buildRow(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Phone Number *', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE5E7EB)), borderRadius: BorderRadius.circular(8)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _phoneCode,
                          items: ['+91', '+1', '+44'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                          onChanged: (val) => setState(() => _phoneCode = val!),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: _buildTextField(label: '', controller: _phone, hint: 'Mobile number', showLabel: false)),
                  ],
                ),
              ],
            ),
            _buildTextField(label: 'Email Address *', controller: _email, hint: 'your@email.com'),
          ),
          const SizedBox(height: 20),
          _buildTextField(label: 'Address *', controller: _address, hint: 'House no, Street...'),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildTextField(label: 'City *', controller: _city, hint: 'City')),
              const SizedBox(width: 16),
              Expanded(child: _buildDropdown(label: 'State *', value: _state, items: _indianStates, onChanged: (val) => setState(() => _state = val))),
              const SizedBox(width: 16),
              Expanded(child: _buildTextField(label: 'Pincode *', controller: _pincode, hint: 'Pincode')),
            ],
          ),
          const SizedBox(height: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Languages Known', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 24,
                children: [
                  _buildCheckbox('English', _knowsEnglish, (val) => setState(() => _knowsEnglish = val!)),
                  _buildCheckbox('Hindi', _knowsHindi, (val) => setState(() => _knowsHindi = val!)),
                  SizedBox(width: 180, child: _buildTextField(label: '', controller: _otherLanguage, hint: 'Other language', showLabel: false)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfo() {
    final isVolunteer = context.read<AuthService>().currentUser?.role == 'volunteer';
    return _sectionCard(
      title: isVolunteer ? '4. Additional Information' : '4. Links',
      child: Column(
        children: [
          if (isVolunteer) ...[
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Connected to any NGO?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildRadio(true, 'Yes', _connectedToNGO, (val) => setState(() => _connectedToNGO = val!)),
                          const SizedBox(width: 24),
                          _buildRadio(false, 'No', _connectedToNGO, (val) => setState(() => _connectedToNGO = val!)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(child: _buildTextField(label: 'NGO Name', controller: _ngoName, hint: 'Enter NGO name', enabled: _connectedToNGO)),
              ],
            ),
            const SizedBox(height: 20),
          ],
          _buildTextField(label: 'Social Media Link', controller: _socialMedia, hint: 'LinkedIn/Portfolio URL'),
          if (isVolunteer) ...[
            const SizedBox(height: 20),
            _buildTextField(label: 'Anything else you want to tell us?', controller: _additionalInfo, hint: 'Tell us more about your mission', maxLines: 4),
          ],
        ],
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3F4F6)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
          const SizedBox(height: 32),
          child,
        ],
      ),
    );
  }

  Widget _buildBottomBar(bool isLoading, bool isVolunteer) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFF3F4F6)))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              side: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: isLoading ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(isVolunteer ? 'Save Volunteer Profile →' : 'Update Profile', style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(Widget left, Widget right) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: left), const SizedBox(width: 20), Expanded(child: right)]);
  }

  Widget _buildTextField({required String label, required TextEditingController controller, String? hint, IconData? icon, int maxLines = 1, bool enabled = true, bool showLabel = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel) Text(label, style: const TextStyle(fontSize: 14, color: Color(0xFF374151), fontWeight: FontWeight.w500)),
        if (showLabel) const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          enabled: enabled,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
            suffixIcon: icon != null ? Icon(icon, color: const Color(0xFF9CA3AF), size: 20) : null,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary)),
            filled: !enabled,
            fillColor: !enabled ? const Color(0xFFF9FAFB) : null,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({required String label, required String? value, required List<String> items, required void Function(String?) onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Color(0xFF374151), fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF9CA3AF)),
          isExpanded: true,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary)),
          ),
          hint: Text(label, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14)),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 14)))).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildCheckbox(String label, bool value, void Function(bool?) onChanged) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(value: value, onChanged: onChanged, activeColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))),
        Text(label, style: const TextStyle(fontSize: 14)),
      ],
    );
  }

  Widget _buildRadio(bool value, String label, bool groupValue, void Function(bool?) onChanged) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Radio<bool>(value: value, groupValue: groupValue, onChanged: onChanged, activeColor: AppColors.primary),
        Text(label, style: const TextStyle(fontSize: 14)),
      ],
    );
  }

  Widget _buildProfilePhotoUpload() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Profile Photo', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 12),
        InkWell(
          onTap: _pickImage,
          borderRadius: BorderRadius.circular(60),
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFF9FAFB),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              image: _profilePhotoBase64 != null && _profilePhotoBase64!.isNotEmpty
                  ? DecorationImage(image: MemoryImage(base64Decode(_profilePhotoBase64!)), fit: BoxFit.cover)
                  : null,
            ),
            child: _profilePhotoBase64 == null || _profilePhotoBase64!.isEmpty
                ? const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.camera_alt, color: AppColors.primary, size: 30), SizedBox(height: 4), Text('Upload', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600))])
                : null,
          ),
        ),
      ],
    );
  }
}

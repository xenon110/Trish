import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../../core/theme.dart';
import '../../core/auth_service.dart';
import '../../widgets/custom_button.dart';
import '../home/main_navigation_screen.dart';

class ProfileOnboardingScreen extends StatefulWidget {
  const ProfileOnboardingScreen({super.key});

  @override
  State<ProfileOnboardingScreen> createState() => _ProfileOnboardingScreenState();
}

class _ProfileOnboardingScreenState extends State<ProfileOnboardingScreen> {
  final PageController _pageController = PageController();
  final AuthService _authService = AuthService();

  int _currentStep = 0;
  bool _isLoading = false;
  bool _isLoadingLocation = false;
  final TextEditingController _locationController = TextEditingController();

  // Photos
  final List<String?> _photos = List.filled(6, null); // URLs after upload
  int? _uploadingIndex; // Which slot is currently uploading
  final ImagePicker _picker = ImagePicker();

  // Form Data
  final Map<String, dynamic> _data = {
    'full_name': '',
    'birthday': null,
    'gender': 'Woman',
    'interested_in': 'Men',
    'location': 'Mumbai, India',
    'bio': '',
    'job': '',
    'education': '',
    'interests': <String>[],
    'lifestyle': {
      'drinking': 'Socially',
      'smoking': 'Never',
      'fitness': 'Regularly',
    },
    'religion': 'None',
    'relationship_type': 'Serious',
    'height': 170.0,
    'zodiac': 'Aries',
    'future_plans': 'Marriage & Kids',
    'prompts': [
      {'question': 'My ideal weekend...', 'answer': ''}
    ],
  };

  final List<String> _genderOptions = ['Man', 'Woman', 'Non-binary', 'Other'];
  final List<String> _interestedInOptions = ['Men', 'Women', 'Everyone'];
  final List<String> _interestOptions = [
    '🎵 Music', '✈️ Travel', '🎨 Art', '🎮 Gaming', '💪 Fitness',
    '🍳 Cooking', '🎬 Movies', '🌿 Nature', '📸 Photography', '💃 Dance',
    '📚 Reading', '🐾 Pets', '☕ Coffee', '🧘 Yoga', '🏊 Swimming',
  ];
  final List<String> _relationshipOptions = ['Serious', 'Casual', 'Marriage', 'Friendship', 'Exploring'];
  final List<String> _zodiacOptions = ['Aries', 'Taurus', 'Gemini', 'Cancer', 'Leo', 'Virgo', 'Libra', 'Scorpio', 'Sagittarius', 'Capricorn', 'Aquarius', 'Pisces'];

  static const _accent = AppTheme.primaryMaroon;
  static const _accentLight = Color(0xFFFDECEC);

  void _nextStep() {
    if (_currentStep < 12) {
      _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    } else {
      _finishOnboarding();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    }
  }

  Future<void> _fetchCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      // Check & request permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied. Please enable it in settings.')),
          );
        }
        return;
      }

      // Try last known position first (instant, no GPS cold start) — mobile only
      Position? position;
      if (!kIsWeb) {
        position = await Geolocator.getLastKnownPosition();
      }

      // If no cached position or on web, get fresh one with low accuracy + short timeout
      position ??= await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 5),
      );

      // Reverse geocode — use HTTP on web (geocoding pkg doesn't support web)
      String locationString = 'Unknown';
      if (kIsWeb) {
        try {
          final response = await http.get(Uri.parse(
            'https://nominatim.openstreetmap.org/reverse?lat=${position.latitude}&lon=${position.longitude}&format=json',
          ), headers: {'Accept-Language': 'en'});
          if (response.statusCode == 200) {
            final json = jsonDecode(response.body);
            final address = json['address'] as Map?;
            final city = address?['city'] ?? address?['town'] ?? address?['village'] ?? address?['county'] ?? 'Unknown';
            final country = address?['country'] ?? '';
            locationString = country.isNotEmpty ? '$city, $country' : city;
          }
        } catch (_) {
          locationString = '${position.latitude.toStringAsFixed(2)}, ${position.longitude.toStringAsFixed(2)}';
        }
      } else {
        final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          final city = place.locality ?? place.subAdministrativeArea ?? place.administrativeArea ?? 'Unknown';
          final country = place.country ?? '';
          locationString = country.isNotEmpty ? '$city, $country' : city;
        }
      }

      if (mounted) {
        setState(() {
          _data['location'] = locationString;
          _locationController.text = locationString;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not get location: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _pickPhoto(int index) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
        maxWidth: 1080,
      );
      if (image == null) return;

      setState(() => _uploadingIndex = index);

      final user = _authService.currentUser;
      if (user == null) return;

      final Uint8List bytes = await image.readAsBytes();
      final fileName = '${user.id}/profile_${index}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final imageUrl = await _authService.uploadImage('moments', fileName, bytes);

      setState(() {
        _photos[index] = imageUrl;
        _uploadingIndex = null;
        // Save non-null URLs to form data
        _data['profile_photos'] = _photos.where((p) => p != null).toList();
        // First photo becomes avatar
        if (index == 0) _data['avatar_url'] = imageUrl;
      });
    } catch (e) {
      setState(() => _uploadingIndex = null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: ${e.toString()}'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _finishOnboarding() async {
    setState(() => _isLoading = true);
    try {
      if (_data['birthday'] != null && _data['birthday'] is DateTime) {
        final birthDate = _data['birthday'] as DateTime;
        final today = DateTime.now();
        int age = today.year - birthDate.year;
        if (today.month < birthDate.month || (today.month == birthDate.month && today.day < birthDate.day)) age--;
        _data['age'] = age;
        _data['birthday'] = birthDate.toIso8601String();
      }
      await _authService.updateProfile(_data);
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_currentStep + 1) / 13;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF444444), size: 18),
                onPressed: _previousStep,
              )
            : const SizedBox.shrink(),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${_currentStep + 1}',
              style: TextStyle(color: _accent, fontWeight: FontWeight.w800, fontSize: 15),
            ),
            Text(
              ' / 13',
              style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.w500, fontSize: 15),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 400),
            builder: (ctx, val, _) => LinearProgressIndicator(
              value: val,
              backgroundColor: Colors.grey[100],
              valueColor: const AlwaysStoppedAnimation<Color>(_accent),
              minHeight: 3,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _finishOnboarding,
            child: Text('Skip', style: TextStyle(color: Colors.grey[400], fontSize: 14, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (page) => setState(() => _currentStep = page),
        children: [
          _buildNameStep(),
          _buildBirthdayStep(),
          _buildGenderStep(),
          _buildInterestedInStep(),
          _buildLocationStep(),
          _buildPhotosStep(),
          _buildBioStep(),
          _buildInterestsStep(),
          _buildJobEduStep(),
          _buildLifestyleStep(),
          _buildRelationshipStep(),
          _buildDetailsStep(),
          _buildPromptsStep(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 0, 28, 20),
          child: CustomButton(
            text: _isLoading ? 'Saving...' : (_currentStep == 12 ? '🎉  Finish' : 'Continue'),
            onPressed: _isLoading ? () {} : _nextStep,
          ),
        ),
      ),
    );
  }

  // ── Step Container ──────────────────────────────────────────────

  Widget _stepContainer({required String emoji, required String title, required String subtitle, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 36),
          Text(emoji, style: const TextStyle(fontSize: 40)),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A1A),
              height: 1.2,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: TextStyle(fontSize: 15, color: Colors.grey[500], height: 1.5, fontWeight: FontWeight.w400),
          ),
          const SizedBox(height: 40),
          Expanded(child: child),
        ],
      ),
    );
  }

  // ── Steps ───────────────────────────────────────────────────────

  Widget _buildNameStep() {
    return _stepContainer(
      emoji: '👋',
      title: "What's your\nname?",
      subtitle: "This is how you'll appear on Trish.",
      child: TextField(
        autofocus: true,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500, color: Color(0xFF1A1A1A)),
        decoration: InputDecoration(
          hintText: "Your name...",
          hintStyle: TextStyle(color: Colors.grey[300], fontSize: 24, fontWeight: FontWeight.w400),
          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey[200]!, width: 2)),
          focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: _accent, width: 2)),
        ),
        onChanged: (val) => _data['full_name'] = val,
      ),
    );
  }

  Widget _buildBirthdayStep() {
    return _stepContainer(
      emoji: '🎂',
      title: "When's your\nbirthday?",
      subtitle: "Your age will be shown, but not your birthday.",
      child: Column(children: [
        GestureDetector(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime.now().subtract(const Duration(days: 365 * 22)),
              firstDate: DateTime(1950),
              lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
              builder: (context, child) => Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: const ColorScheme.light(primary: _accent, onPrimary: Colors.white, onSurface: Color(0xFF1A1A1A)),
                ),
                child: child!,
              ),
            );
            if (date != null) setState(() => _data['birthday'] = date);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[200]!, width: 2))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _data['birthday'] == null
                      ? "Select Date"
                      : "${(_data['birthday'] as DateTime).day} / ${(_data['birthday'] as DateTime).month} / ${(_data['birthday'] as DateTime).year}",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: _data['birthday'] == null ? Colors.grey[300] : const Color(0xFF1A1A1A),
                  ),
                ),
                Icon(Icons.calendar_month_outlined, color: _accent, size: 26),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildGenderStep() {
    return _stepContainer(
      emoji: '🌈',
      title: "How do you\nidentify?",
      subtitle: "Everyone is welcome on Trish.",
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: _genderOptions.map((g) => _pill(g, _data['gender'] == g, () => setState(() => _data['gender'] = g))).toList(),
      ),
    );
  }

  Widget _buildInterestedInStep() {
    return _stepContainer(
      emoji: '❤️',
      title: "Who are you\ninterested in?",
      subtitle: "You can always change this later.",
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: _interestedInOptions.map((o) => _pill(o, _data['interested_in'] == o, () => setState(() => _data['interested_in'] = o))).toList(),
      ),
    );
  }

  Widget _buildLocationStep() {
    return _stepContainer(
      emoji: '📍',
      title: "Where do you\nlive?",
      subtitle: "We'll find matches near you.",
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        TextField(
          controller: _locationController,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Color(0xFF1A1A1A)),
          decoration: InputDecoration(
            hintText: "Your city...",
            hintStyle: TextStyle(color: Colors.grey[300], fontSize: 20, fontWeight: FontWeight.w400),
            prefixIcon: Icon(Icons.location_on_outlined, color: _accent, size: 22),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey[200]!, width: 2)),
            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: _accent, width: 2)),
          ),
          onChanged: (val) => _data['location'] = val,
        ),
        const SizedBox(height: 28),
        GestureDetector(
          onTap: _isLoadingLocation ? null : _fetchCurrentLocation,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            decoration: BoxDecoration(
              color: _isLoadingLocation ? Colors.grey[100] : _accentLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _accent.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _isLoadingLocation
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: _accent),
                      )
                    : Icon(Icons.my_location_rounded, color: _accent, size: 20),
                const SizedBox(width: 10),
                Text(
                  _isLoadingLocation ? 'Detecting location...' : 'Use current location',
                  style: TextStyle(
                    color: _isLoadingLocation ? Colors.grey : _accent,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildPhotosStep() {
    return _stepContainer(
      emoji: '📸',
      title: "Add your first\nphotos",
      subtitle: "Profiles with photos get 6× more matches.",
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.72,
        ),
        itemCount: 6,
        itemBuilder: (context, index) {
          final url = _photos[index];
          final isUploading = _uploadingIndex == index;

          return GestureDetector(
            onTap: isUploading ? null : () => _pickPhoto(index),
            child: Stack(
              children: [
                // Slot background / photo preview
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: url != null ? Colors.transparent : Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: url != null ? _accent.withOpacity(0.3) : Colors.grey[200]!,
                      width: url != null ? 2 : 1,
                    ),
                  ),
                  child: url != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.network(url, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                        )
                      : isUploading
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: _accent)),
                                  const SizedBox(height: 8),
                                  Text('Uploading...', style: TextStyle(color: _accent, fontSize: 10, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  index == 0 ? Icons.add_photo_alternate_outlined : Icons.add_circle_outline,
                                  color: index == 0 ? _accent : Colors.grey[300],
                                  size: index == 0 ? 32 : 24,
                                ),
                                if (index == 0) ...[
                                  const SizedBox(height: 6),
                                  Text("Main", style: TextStyle(color: _accent, fontSize: 11, fontWeight: FontWeight.w600)),
                                ],
                              ],
                            ),
                ),
                // Remove button (X)
                if (url != null)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _photos[index] = null;
                          _data['profile_photos'] = _photos.where((p) => p != null).toList();
                          if (index == 0) _data['avatar_url'] = null;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                        child: const Icon(Icons.close_rounded, color: Colors.white, size: 13),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }


  Widget _buildBioStep() {
    return _stepContainer(
      emoji: '✍️',
      title: "Tell us about\nyourself",
      subtitle: "A great bio helps you stand out.",
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: TextField(
          maxLines: 6,
          style: const TextStyle(fontSize: 16, color: Color(0xFF1A1A1A), height: 1.6),
          decoration: InputDecoration(
            hintText: "e.g. Coffee addict. Dog lover. Always planning the next adventure...",
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15, height: 1.5),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.all(18),
          ),
          onChanged: (val) => _data['bio'] = val,
        ),
      ),
    );
  }

  Widget _buildInterestsStep() {
    return _stepContainer(
      emoji: '🎯',
      title: "What are you\ninto?",
      subtitle: "Pick your top interests to find better matches.",
      child: SingleChildScrollView(
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _interestOptions.map((interest) {
            final isSelected = (_data['interests'] as List).contains(interest);
            return _pill(interest, isSelected, () {
              setState(() {
                if (isSelected) {
                  (_data['interests'] as List).remove(interest);
                } else {
                  (_data['interests'] as List).add(interest);
                }
              });
            });
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildJobEduStep() {
    return _stepContainer(
      emoji: '💼',
      title: "Career &\nEducation",
      subtitle: "Optional, but it helps break the ice.",
      child: Column(children: [
        _underlineField("Job title (e.g. Designer)", (val) => _data['job'] = val),
        const SizedBox(height: 28),
        _underlineField("Education (e.g. Delhi University)", (val) => _data['education'] = val),
      ]),
    );
  }

  Widget _buildLifestyleStep() {
    return _stepContainer(
      emoji: '🌿',
      title: "Your lifestyle",
      subtitle: "Honesty here leads to better matches.",
      child: Column(children: [
        _lifestylePicker("🍷  Drinking", ['Never', 'Socially', 'Often'], 'drinking'),
        const SizedBox(height: 20),
        _lifestylePicker("🚬  Smoking", ['Never', 'Occasionally', 'Regularly'], 'smoking'),
        const SizedBox(height: 20),
        _lifestylePicker("🏋️  Fitness", ['Not active', 'Occasionally', 'Regularly'], 'fitness'),
      ]),
    );
  }

  Widget _buildRelationshipStep() {
    return _stepContainer(
      emoji: '💞',
      title: "What are you\nlooking for?",
      subtitle: "Be honest — it saves everyone's time.",
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: _relationshipOptions.map((o) => _pill(o, _data['relationship_type'] == o, () => setState(() => _data['relationship_type'] = o))).toList(),
      ),
    );
  }

  Widget _buildDetailsStep() {
    return _stepContainer(
      emoji: '✨',
      title: "Just a bit\nmore about you",
      subtitle: "These help people connect on a deeper level.",
      child: Column(children: [
        _detailPicker("Zodiac ♊", _zodiacOptions, 'zodiac'),
        const SizedBox(height: 20),
        _detailPicker("Religion", ['None', 'Christian', 'Hindu', 'Muslim', 'Sikh', 'Buddhist', 'Jewish', 'Other'], 'religion'),
        const SizedBox(height: 20),
        _detailPicker("Future plans", ['Not sure yet', 'Marriage', 'Kids', 'Marriage & Kids', 'No kids'], 'future_plans'),
      ]),
    );
  }

  Widget _buildPromptsStep() {
    return _stepContainer(
      emoji: '💬',
      title: "Your ice\nbreaker",
      subtitle: "A fun answer that shows your personality.",
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
            decoration: BoxDecoration(
              color: _accentLight,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: const Text(
              "My ideal weekend...",
              style: TextStyle(color: _accent, fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: TextField(
              maxLines: 4,
              style: const TextStyle(fontSize: 16, color: Color(0xFF1A1A1A), height: 1.5),
              decoration: InputDecoration(
                hintText: "...involves good food, great people, and something spontaneous.",
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                border: InputBorder.none,
              ),
              onChanged: (val) => _data['prompts'][0]['answer'] = val,
            ),
          ),
        ]),
      ),
    );
  }

  // ── Helper Widgets ───────────────────────────────────────────────

  Widget _pill(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? _accent : Colors.white,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: isSelected ? _accent : Colors.grey[200]!, width: 1.5),
          boxShadow: isSelected
              ? [BoxShadow(color: _accent.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 4))]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF444444),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _underlineField(String hint, Function(String) onChanged, {TextEditingController? controller}) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Color(0xFF1A1A1A)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[300], fontSize: 20, fontWeight: FontWeight.w400),
        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey[200]!, width: 2)),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: _accent, width: 2)),
      ),
      onChanged: onChanged,
    );
  }

  Widget _lifestylePicker(String label, List<String> options, String key) {
    String current = _data['lifestyle'][key] ?? options.first;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF333333))),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: options.contains(current) ? current : options.first,
              style: TextStyle(color: _accent, fontWeight: FontWeight.w700, fontSize: 14),
              icon: Icon(Icons.keyboard_arrow_down_rounded, color: _accent),
              items: options.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) { if (val != null) setState(() => _data['lifestyle'][key] = val); },
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailPicker(String label, List<String> options, String key) {
    String current = _data[key] ?? options.first;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF333333))),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: options.contains(current) ? current : options.first,
              style: TextStyle(color: _accent, fontWeight: FontWeight.w700, fontSize: 14),
              icon: Icon(Icons.keyboard_arrow_down_rounded, color: _accent),
              items: options.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) { if (val != null) setState(() => _data[key] = val); },
            ),
          ),
        ],
      ),
    );
  }
}

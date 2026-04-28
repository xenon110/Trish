import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../../core/theme.dart';
import '../../core/auth_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final AuthService _auth = AuthService();
  static const _maroon = AppTheme.primaryMaroon;
  Map<String, dynamic> _data = {};
  bool _isUploadingAvatar = false;
  bool _isSaving = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _data = Map<String, dynamic>.from(_auth.currentUser?.userMetadata ?? {});
  }

  String _val(String key, [String fallback = 'Add']) {
    final v = _data[key];
    if (v == null || v.toString().isEmpty) return fallback;
    return v.toString();
  }

  void _onUpdate(Map<String, dynamic> updates) {
    setState(() {
      _data.addAll(updates);
      _hasChanges = true;
    });
  }

  Future<void> _saveAll() async {
    setState(() => _isSaving = true);
    try {
      await _auth.updateProfile(_data);
      if (mounted) {
        _snack('Profile updated!', ok: true);
        setState(() => _hasChanges = false);
        // Small delay to let the user see the snackbar if we were to stay, 
        // but typically popping is better.
        Navigator.pop(context);
      }
    } catch (e) {
      _snack('Failed to save: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Avatar ──────────────────────────────────────────────────
  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final XFile? img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75, maxWidth: 800);
    if (img == null) return;
    setState(() => _isUploadingAvatar = true);
    try {
      final Uint8List bytes = await img.readAsBytes();
      final fn = '${_auth.currentUser!.id}/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final url = await _auth.uploadImage('moments', fn, bytes);
      _onUpdate({'avatar_url': url});
      _snack('Photo uploaded! Don\'t forget to save.', ok: true);
    } catch (e) {
      _snack('Failed: $e');
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  // ── GPS ─────────────────────────────────────────────────────
  Future<void> _gps(Function(String) onDone) async {
    try {
      LocationPermission p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
      if (p == LocationPermission.deniedForever || p == LocationPermission.denied) return;
      Position? pos;
      if (!kIsWeb) pos = await Geolocator.getLastKnownPosition();
      pos ??= await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.low, timeLimit: const Duration(seconds: 6));
      String city = '${pos.latitude.toStringAsFixed(2)}, ${pos.longitude.toStringAsFixed(2)}';
      if (kIsWeb) {
        final r = await http.get(Uri.parse('https://nominatim.openstreetmap.org/reverse?lat=${pos.latitude}&lon=${pos.longitude}&format=json'), headers: {'Accept-Language': 'en'});
        if (r.statusCode == 200) {
          final j = jsonDecode(r.body)['address'] as Map?;
          final c = j?['city'] ?? j?['town'] ?? j?['village'] ?? '';
          final co = j?['country'] ?? '';
          if (c.toString().isNotEmpty) city = co.toString().isNotEmpty ? '$c, $co' : c.toString();
        }
      } else {
        final marks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
        if (marks.isNotEmpty) {
          final pl = marks.first;
          final c = pl.locality ?? pl.administrativeArea ?? '';
          final co = pl.country ?? '';
          if (c.isNotEmpty) city = co.isNotEmpty ? '$c, $co' : c;
        }
      }
      onDone(city);
    } catch (_) {}
  }

  void _snack(String msg, {bool ok = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: ok ? const Color(0xFF34C759) : Colors.redAccent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  // ── Bottom sheets ────────────────────────────────────────────

  void _textSheet(String title, String key, {bool isNumber = false, int maxLines = 1, String? hint}) {
    final ctrl = TextEditingController(text: _val(key, ''));
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 24, left: 24, right: 24, top: 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(4)))),
          const SizedBox(height: 20),
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 20),
          TextField(
            controller: ctrl,
            maxLines: maxLines,
            autofocus: true,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            inputFormatters: isNumber ? [FilteringTextInputFormatter.digitsOnly] : [],
            decoration: InputDecoration(
              hintText: hint ?? 'Enter $title',
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _maroon, width: 1.5)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                final v = isNumber ? (int.tryParse(ctrl.text.trim()) ?? 0) : ctrl.text.trim();
                if (ctrl.text.trim().isNotEmpty) _onUpdate({key: v});
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _maroon,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
            ),
          ),
        ]),
      ),
    );
  }

  void _locationSheet(String title, String key) {
    final ctrl = TextEditingController(text: _val(key, ''));
    bool detecting = false;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setM) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 24, left: 24, right: 24, top: 20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(4)))),
            const SizedBox(height: 20),
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 20),
            TextField(
              controller: ctrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'City, Country',
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _maroon, width: 1.5)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: detecting ? null : () async {
                setM(() => detecting = true);
                await _gps((city) { ctrl.text = city; });
                setM(() => detecting = false);
              },
              child: Row(children: [
                Icon(Icons.my_location_rounded, size: 16, color: detecting ? Colors.grey : _maroon),
                const SizedBox(width: 6),
                Text(detecting ? 'Detecting...' : 'Use current location', style: TextStyle(color: detecting ? Colors.grey : _maroon, fontWeight: FontWeight.w600, fontSize: 14)),
              ]),
            ),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: () { Navigator.pop(ctx); if (ctrl.text.trim().isNotEmpty) _onUpdate({key: ctrl.text.trim()}); },
              style: ElevatedButton.styleFrom(backgroundColor: _maroon, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
            )),
          ]),
        ),
      ),
    );
  }

  void _optionsSheet(String title, String key, List<String> options) {
    final current = _val(key, '');
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setM) {
          String selected = current;
          return Column(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 20),
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Wrap(
                  spacing: 10, runSpacing: 10,
                  children: options.map((o) {
                    final sel = selected == o;
                    return GestureDetector(
                      onTap: () {
                        setM(() => selected = o);
                        Future.delayed(const Duration(milliseconds: 180), () {
                          Navigator.pop(ctx);
                          _onUpdate({key: o});
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: sel ? _maroon : Colors.white,
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(color: sel ? _maroon : Colors.grey[200]!, width: 1.5),
                          boxShadow: sel ? [BoxShadow(color: _maroon.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 3))] : [],
                        ),
                        child: Text(o, style: TextStyle(color: sel ? Colors.white : const Color(0xFF333333), fontWeight: FontWeight.w600, fontSize: 14)),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ]);
        },
      ),
    );
  }

  void _multiOptionsSheet(String title, String key, List<String> options) {
    List<String> current = [];
    if (_data[key] is List) current = List<String>.from(_data[key]);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setM) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          builder: (_, sc) => Column(children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 20),
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                controller: sc,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Wrap(
                  spacing: 10, runSpacing: 10,
                  children: options.map((o) {
                    final sel = current.contains(o);
                    return GestureDetector(
                      onTap: () => setM(() => sel ? current.remove(o) : current.add(o)),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: sel ? _maroon : Colors.white,
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(color: sel ? _maroon : Colors.grey[200]!, width: 1.5),
                          boxShadow: sel ? [BoxShadow(color: _maroon.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 3))] : [],
                        ),
                        child: Text(o, style: TextStyle(color: sel ? Colors.white : const Color(0xFF333333), fontWeight: FontWeight.w600, fontSize: 14)),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(width: double.infinity, child: ElevatedButton(
                onPressed: () { Navigator.pop(ctx); _onUpdate({key: current}); },
                style: ElevatedButton.styleFrom(backgroundColor: _maroon, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
              )),
            ),
          ]),
        ),
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final avatarUrl = _data['avatar_url'];
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Color(0xFF1A1A1A)), onPressed: () => Navigator.pop(context)),
        title: const Text('Edit Profile', style: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.w800, fontSize: 18)),
        centerTitle: true,
        actions: [
          if (_isSaving) 
            const Padding(padding: EdgeInsets.all(16), child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: _maroon)))
          else
            TextButton(
              onPressed: _hasChanges ? _saveAll : null,
              child: Text(
                'Save',
                style: TextStyle(
                  color: _hasChanges ? _maroon : Colors.grey,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Avatar ─────────────────────────────────────────
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: GestureDetector(
                onTap: _pickAvatar,
                child: Stack(children: [
                  CircleAvatar(
                    radius: 52,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : const AssetImage('assets/image/connection.jpg') as ImageProvider,
                    child: _isUploadingAvatar ? Container(decoration: BoxDecoration(color: Colors.black45, shape: BoxShape.circle), child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)) : null,
                  ),
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: _maroon, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                      child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 15),
                    ),
                  ),
                ]),
              ),
            ),
          ),

          // ── About you ──────────────────────────────────────
          _header('About you'),
          _row(icon: Icons.cake_outlined,       label: 'Age',       value: _val('age'),       onTap: () => _textSheet('Age', 'age', isNumber: true)),
          _row(icon: Icons.work_outline_rounded, label: 'Work',      value: _val('job'),       onTap: () => _textSheet('Work', 'job', hint: 'Job title')),
          _row(icon: Icons.school_outlined,      label: 'Education', value: _val('education'), onTap: () => _textSheet('Education', 'education', hint: 'School or college')),
          _row(icon: Icons.waving_hand_outlined, label: 'Gender',    value: _val('gender'),    onTap: () => _optionsSheet('Gender', 'gender', ['Man', 'Woman', 'Non-binary', 'Genderqueer', 'Agender', 'Other'])),
          _row(icon: Icons.location_on_outlined, label: 'Location',  value: _val('location'),  onTap: () => _locationSheet('Location', 'location')),
          _row(icon: Icons.home_outlined,        label: 'Hometown',  value: _val('hometown'),  onTap: () => _locationSheet('Hometown', 'hometown'), isLast: true),

          // ── Bio ────────────────────────────────────────────
          _header('Bio'),
          _row(icon: Icons.edit_note_rounded, label: 'About me', value: (_data['bio'] ?? '').toString().isNotEmpty ? 'Added' : 'Add', onTap: () => _textSheet('About me', 'bio', maxLines: 5, hint: 'Write a short bio...'), isLast: true),

          // ── More about you ─────────────────────────────────
          _header('More about you'),
          _row(icon: Icons.straighten_rounded,      label: 'Height',          value: _val('height'),           onTap: () => _textSheet('Height (cm)', 'height', isNumber: true)),
          _row(icon: Icons.fitness_center_rounded,  label: 'Exercise',        value: _val('exercise'),          onTap: () => _optionsSheet('Exercise', 'exercise', ['Active', 'Sometimes', 'Rarely', 'Never'])),
          _row(icon: Icons.wine_bar_outlined,       label: 'Drinking',        value: _val('drinking'),          onTap: () => _optionsSheet('Drinking', 'drinking', ['Sober', 'Sober curious', "Don't drink", 'Drink socially', 'Drink often'])),
          _row(icon: Icons.smoke_free_rounded,      label: 'Smoking',         value: _val('smoking'),           onTap: () => _optionsSheet('Smoking', 'smoking', ['Non-smoker', 'Smoker', 'Trying to quit', 'Social smoker'])),
          _row(icon: Icons.search_rounded,          label: 'Looking for',     value: _val('relationship_type'), onTap: () => _optionsSheet('Looking for', 'relationship_type', ['Long-term', 'Something casual', 'Marriage', 'New friends', "I'm not sure yet"])),
          _row(icon: Icons.child_friendly_outlined, label: 'Want kids',       value: _val('want_kids'),         onTap: () => _optionsSheet('Want kids', 'want_kids', ['Want kids', "Don't want kids", 'Open to kids', 'Not sure yet'])),
          _row(icon: Icons.family_restroom_rounded, label: 'Have kids',       value: _val('have_kids'),         onTap: () => _optionsSheet('Have kids', 'have_kids', ['Yes', 'No'])),
          _row(icon: Icons.stars_rounded,           label: 'Zodiac',          value: _val('zodiac'),            onTap: () => _optionsSheet('Zodiac', 'zodiac', ['Aries ♈', 'Taurus ♉', 'Gemini ♊', 'Cancer ♋', 'Leo ♌', 'Virgo ♍', 'Libra ♎', 'Scorpio ♏', 'Sagittarius ♐', 'Capricorn ♑', 'Aquarius ♒', 'Pisces ♓'])),
          _row(icon: Icons.account_balance_outlined,label: 'Politics',        value: _val('politics'),          onTap: () => _optionsSheet('Politics', 'politics', ['Apolitical', 'Liberal', 'Moderate', 'Conservative', 'Other'])),
          _row(icon: Icons.self_improvement_rounded,label: 'Religion',        value: _val('religion'),          onTap: () => _optionsSheet('Religion', 'religion', ['Agnostic', 'Atheist', 'Buddhist', 'Catholic', 'Christian', 'Hindu', 'Jewish', 'Muslim', 'Sikh', 'Spiritual', 'Other'])),
          _row(icon: Icons.family_restroom_rounded, label: 'Family Plans',    value: _val('future_plans'),      onTap: () => _optionsSheet('Family Plans', 'future_plans', ['Want children', 'Open to children', 'Not sure yet', 'Don’t want children', 'Have & want more', 'Have & don’t want more'])),
          _row(icon: Icons.language_rounded,        label: 'Languages',       value: (_data['languages'] is List && (_data['languages'] as List).isNotEmpty) ? '${(_data['languages'] as List).length} added' : 'Add', onTap: () => _multiOptionsSheet('Languages', 'languages', ['English', 'Hindi', 'Spanish', 'French', 'German', 'Chinese', 'Japanese', 'Arabic', 'Russian', 'Portuguese', 'Bengali', 'Punjabi']), isLast: true),

          // ── Interests ──────────────────────────────────────
          _header('Interests'),
          _row(
            icon: Icons.interests_outlined,
            label: 'Pick interests',
            value: (_data['interests'] is List && (_data['interests'] as List).isNotEmpty) ? '${(_data['interests'] as List).length} added' : 'Add',
            onTap: () => _multiOptionsSheet('Interests', 'interests', ['Music', 'Travel', 'Art', 'Gaming', 'Fitness', 'Cooking', 'Movies', 'Nature', 'Photography', 'Dance', 'Reading', 'Pets', 'Coffee', 'Yoga', 'Swimming', 'Hiking', 'Fashion', 'Sports', 'Tech', 'Foodie']),
            isLast: true,
          ),

          const SizedBox(height: 40),
        ]),
      ),
    );
  }

  // ── Row widget ───────────────────────────────────────────────
  Widget _row({required IconData icon, required String label, required String value, required VoidCallback onTap, bool isLast = false}) {
    final isEmpty = value == 'Add';
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: !isLast ? const Border(bottom: BorderSide(color: Color(0xFFF0F0F0), width: 1)) : null,
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Container(
          width: 38, height: 38,
          decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 18, color: const Color(0xFF666666)),
        ),
        title: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF1A1A1A))),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(
            value.length > 22 ? '${value.substring(0, 22)}...' : value,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: isEmpty ? const Color(0xFFB0B0B0) : const Color(0xFF555555)),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFFCCCCCC), size: 20),
        ]),
      ),
    );
  }

  Widget _header(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
    );
  }
}

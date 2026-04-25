import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../core/auth_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final AuthService _authService = AuthService();
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _ageController;
  late TextEditingController _locationController;
  late TextEditingController _genderController;
  late TextEditingController _hobbyController;
  List<String> _interests = [];
  bool _isLoading = false;
  bool _isLocationLoading = false;
  double? _latitude;
  double? _longitude;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    final user = _authService.currentUser;
    final metadata = user?.userMetadata;
    
    _nameController = TextEditingController(text: metadata?['full_name'] ?? '');
    _bioController = TextEditingController(text: metadata?['bio'] ?? 'Tell us about yourself...');
    _ageController = TextEditingController(text: (metadata?['age'] ?? 18).toString());
    _locationController = TextEditingController(text: metadata?['location'] ?? 'New York');
    _genderController = TextEditingController(text: metadata?['gender'] ?? 'Man');
    _hobbyController = TextEditingController(text: metadata?['hobby'] ?? 'Photography');
    
    _latitude = metadata?['latitude'] != null ? (metadata?['latitude'] as num).toDouble() : null;
    _longitude = metadata?['longitude'] != null ? (metadata?['longitude'] as num).toDouble() : null;
    _avatarUrl = metadata?['avatar_url'];
    
    final interestsData = metadata?['interests'];
    if (interestsData is List) {
      _interests = List<String>.from(interestsData);
    } else {
      _interests = ['Photography', 'Dogs', 'Coffee']; // Defaults
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _ageController.dispose();
    _locationController.dispose();
    _genderController.dispose();
    _hobbyController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLocationLoading = true);
    
    try {
      // 1. Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Location services are disabled.';
      }

      // 2. Check and request permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permissions are denied.';
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions are permanently denied.';
      }

      // 3. Get coordinates
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );

      _latitude = position.latitude;
      _longitude = position.longitude;

      // 4. Reverse geocode (with multiple retries)
      String address = "Location Found";
      int retries = 0;
      bool success = false;
      
      while (retries < 2 && !success) {
        try {
          // Increase delay on each retry
          await Future.delayed(Duration(milliseconds: 500 * (retries + 1)));
          
          List<Placemark> placemarks = await placemarkFromCoordinates(
            position.latitude, 
            position.longitude
          ).timeout(const Duration(seconds: 5));

          if (placemarks.isNotEmpty) {
            final Placemark place = placemarks[0];
            final List<String> parts = [];
            
            if (place.locality != null && place.locality!.isNotEmpty) parts.add(place.locality!);
            if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) parts.add(place.administrativeArea!);
            
            if (parts.isNotEmpty) {
              address = parts.join(", ");
              success = true;
            }
          }
        } catch (e) {
          retries++;
        }
      }

      if (!success) {
        try {
          // Final fallback to OpenStreetMap web API
          final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?lat=${position.latitude}&lon=${position.longitude}&format=json&addressdetails=1');
          final response = await http.get(url, headers: {'User-Agent': 'TrishApp/1.0'}).timeout(const Duration(seconds: 5));
          
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            final addressMap = data['address'];
            if (addressMap != null) {
              final String city = addressMap['city'] ?? addressMap['town'] ?? addressMap['village'] ?? addressMap['suburb'] ?? '';
              final String state = addressMap['state'] ?? addressMap['country'] ?? '';
              
              if (city.isNotEmpty && state.isNotEmpty) {
                address = "$city, $state";
              } else if (city.isNotEmpty) {
                address = city;
              } else if (state.isNotEmpty) {
                address = state;
              }
              success = true;
            }
          }
        } catch (e) {
          // Silent fail on web fallback
        }
      }

      if (!success) {
        // Final fallback if everything fails
        address = "${position.latitude.toStringAsFixed(2)}, ${position.longitude.toStringAsFixed(2)}";
      }
      
      if (mounted) {
        setState(() {
          _locationController.text = address;
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not get location: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLocationLoading = false);
    }
  }

  Future<void> _pickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 800,
    );

    if (image == null) return;

    setState(() => _isLoading = true);

    try {
      final Uint8List fileBytes = await image.readAsBytes();
      // Using 'moments' bucket as it is confirmed to exist in the project
      final String bucket = 'moments';
      // Use a timestamped filename to prevent caching issues
      final String fileName = '${_authService.currentUser!.id}/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final String publicUrl = await _authService.uploadImage(
        bucket,
        fileName,
        fileBytes,
      );

      setState(() {
        _avatarUrl = publicUrl;
      });

      // Automatically save to profile
      await _authService.updateProfile({
        'avatar_url': _avatarUrl,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);
    try {
      await _authService.updateProfile({
        'full_name': _nameController.text.trim(),
        'bio': _bioController.text.trim(),
        'age': int.tryParse(_ageController.text.trim()) ?? 18,
        'location': _locationController.text.trim(),
        'latitude': _latitude,
        'longitude': _longitude,
        'location_updated_at': DateTime.now().toIso8601String(),
        'gender': _genderController.text.trim(),
        'hobby': _hobbyController.text.trim(),
        'interests': _interests,
        'avatar_url': _avatarUrl,
      });
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile updated successfully!', style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: const Color(0xFF34C759),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddTagDialog() {
    final TextEditingController tagController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Interest'),
        content: TextField(
          controller: tagController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter interest (e.g. Hiking)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (tagController.text.trim().isNotEmpty) {
                setState(() {
                  _interests.add(tagController.text.trim());
                });
              }
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFAFA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: AppTheme.primaryMaroon),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: Color(0xFF2C2C2E),
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildImageUpload(),
              const SizedBox(height: 32),
              _buildSectionTitle('Name'),
              _buildTextField(_nameController, 'Your Name'),
              const SizedBox(height: 24),
              _buildSectionTitle('Bio'),
              _buildTextField(_bioController, 'Tell us about yourself...', maxLines: 4),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        _buildSectionTitle('Age'),
                        _buildTextField(_ageController, 'Age', keyboardType: TextInputType.number),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildSectionTitle('Location'),
                            _buildLocationPickerButton(),
                          ],
                        ),
                        _buildTextField(_locationController, 'e.g. New York'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        _buildSectionTitle('Gender'),
                        _buildTextField(_genderController, 'e.g. Man, Woman'),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: [
                        _buildSectionTitle('Primary Hobby'),
                        _buildTextField(_hobbyController, 'e.g. Hiking'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Interests / Tags'),
              _buildTagEditor(),
              const SizedBox(height: 48),
              _buildSaveButton(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageUpload() {
    return Stack(
      children: [
        CircleAvatar(
          radius: 64,
          backgroundColor: Colors.grey.shade200,
          backgroundImage: _avatarUrl != null 
              ? NetworkImage(_avatarUrl!) 
              : const AssetImage('assets/image/connection.jpg') as ImageProvider,
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: _pickAndUploadImage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryMaroon,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryMaroon.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF2C2C2E),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildLocationPickerButton() {
    return GestureDetector(
      onTap: _isLocationLoading ? null : _getCurrentLocation,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppTheme.primaryMaroon.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: _isLocationLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryMaroon),
              )
            : const Icon(Icons.my_location_rounded, color: AppTheme.primaryMaroon, size: 16),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF8E8E93), fontSize: 15),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
      style: const TextStyle(
        color: Color(0xFF2C2C2E),
        fontWeight: FontWeight.w600,
        fontSize: 15,
      ),
    );
  }

  Widget _buildTagEditor() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ..._interests.map((interest) => _buildExistingTag(interest)),
          GestureDetector(
            onTap: _showAddTagDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7F8),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEBEBEB)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded, color: Color(0xFF8E8E93), size: 16),
                  SizedBox(width: 4),
                  Text(
                    'Add',
                    style: TextStyle(color: Color(0xFF8E8E93), fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExistingTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primaryMaroon.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(color: AppTheme.primaryMaroon, fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () {
              setState(() {
                _interests.remove(label);
              });
            },
            child: Icon(Icons.close_rounded, color: AppTheme.primaryMaroon, size: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveChanges,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryMaroon,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 4,
          shadowColor: AppTheme.primaryMaroon.withOpacity(0.3),
        ),
        child: _isLoading
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text('Save Changes', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme.dart';
import '../../core/auth_service.dart';
import '../../core/ui_helpers.dart';

class MomentsScreen extends StatefulWidget {
  const MomentsScreen({super.key});

  @override
  State<MomentsScreen> createState() => _MomentsScreenState();
}

class _MomentsScreenState extends State<MomentsScreen> {
  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();
  List<String> _moments = [];
  bool _isLoading = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadMoments();
  }

  void _loadMoments() {
    final user = _authService.currentUser;
    final momentsData = user?.userMetadata?['moments'];
    if (momentsData is List) {
      setState(() {
        _moments = List<String>.from(momentsData);
      });
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70, // Compress for faster upload
      );

      if (image == null) return;

      setState(() => _isUploading = true);

      final user = _authService.currentUser;
      if (user == null) return;

      final fileName = '${user.id}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final bytes = await image.readAsBytes();

      // Upload to Supabase Storage (Assumes a bucket named 'moments' exists and is public)
      final imageUrl = await _authService.uploadImage('moments', fileName, bytes);

      // Update user metadata
      final updatedMoments = [..._moments, imageUrl];
      await _authService.updateProfile({'moments': updatedMoments});

      if (mounted) {
        setState(() {
          _moments = updatedMoments;
          _isUploading = false;
        });
        UIHelpers.showSnackBar(context, 'Moment uploaded successfully!');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        UIHelpers.showSnackBar(context, 'Error uploading moment: ${e.toString()}');
      }
    }
  }

  Future<void> _deleteMoment(String url) async {
    try {
      final updatedMoments = _moments.where((m) => m != url).toList();
      await _authService.updateProfile({'moments': updatedMoments});
      
      setState(() {
        _moments = updatedMoments;
      });
      
      if (mounted) {
        UIHelpers.showSnackBar(context, 'Moment deleted.');
      }
    } catch (e) {
      if (mounted) {
        UIHelpers.showSnackBar(context, 'Error deleting moment: ${e.toString()}');
      }
    }
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
          'My Moments',
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildUploadSection(),
              const SizedBox(height: 32),
              const Text(
                'Gallery',
                style: TextStyle(
                  color: Color(0xFF2C2C2E),
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              if (_moments.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40.0),
                    child: Text(
                      'No moments yet. Share your first one!',
                      style: TextStyle(color: Colors.grey[400], fontSize: 16),
                    ),
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _moments.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.0,
                  ),
                  itemBuilder: (context, index) {
                    final url = _moments[index];
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Image.network(
                            url,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () => _deleteMoment(url),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEBEBEB), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.primaryMaroon.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: _isUploading 
              ? Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(color: AppTheme.primaryMaroon, strokeWidth: 2),
                )
              : Icon(Icons.cloud_upload_rounded, color: AppTheme.primaryMaroon, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            _isUploading ? 'Uploading...' : 'Upload New Moment',
            style: const TextStyle(
              color: Color(0xFF2C2C2E),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Share a photo with your matches',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF8E8E93),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isUploading ? null : _pickAndUploadImage,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryMaroon,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Select Photo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

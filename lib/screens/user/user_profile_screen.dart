import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_constants.dart';
import '../../utils/app_theme.dart';
import '../../widgets/loading_widget.dart' as lw;

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _firestoreService = FirestoreService();

  final _nameController = TextEditingController();
  final _headlineController = TextEditingController();
  final _locationController = TextEditingController();
  final _skillsController = TextEditingController();

  UserModel? _user;
  bool _loading = true;
  bool _saving = false;
  bool _uploadingResume = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _headlineController.dispose();
    _locationController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = await _authService.getCurrentUserModel();
    if (mounted) {
      setState(() {
        _user = user;
        _loading = false;
        if (user != null) {
          _nameController.text = user.fullName;
          _headlineController.text = user.headline;
          _locationController.text = user.location;
          _skillsController.text = user.skills.join(', ');
        }
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final skills = _skillsController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      await _firestoreService.updateUserProfile(uid, {
        'fullName': _nameController.text.trim(),
        'headline': _headlineController.text.trim(),
        'location': _locationController.text.trim(),
        'skills': skills,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppConstants.msgProfileUpdated),
            backgroundColor: AppTheme.primary,
          ),
        );
        await _loadProfile();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppConstants.msgFailedProfile)),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _uploadResume() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result == null) return;

    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null) return;

    setState(() => _uploadingResume = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final ref = FirebaseStorage.instance
          .ref()
          .child('${AppConstants.storageResumes}/$uid/resume.pdf');
      await ref.putData(bytes);
      final downloadUrl = await ref.getDownloadURL();
      await _firestoreService
          .updateUserProfile(uid, {'resumeUrl': downloadUrl});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppConstants.msgResumeUploaded),
            backgroundColor: AppTheme.primary,
          ),
        );
        await _loadProfile();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppConstants.msgFailedResume)),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingResume = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: _loading
          ? const lw.LoadingWidget(message: 'Loading profile...')
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 36,
                              backgroundColor:
                                  AppTheme.primary.withValues(alpha: 0.5),
                              child: Text(
                                (_user?.fullName.isNotEmpty == true
                                        ? _user!.fullName[0]
                                        : _user?.email.isNotEmpty == true
                                            ? _user!.email[0]
                                            : '?')
                                    .toUpperCase(),
                                style: const TextStyle(
                                  color: AppTheme.primary,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _user?.fullName.isNotEmpty == true
                                        ? _user!.fullName
                                        : 'Student',
                                    style:
                                        Theme.of(context).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _user?.email ?? '',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  if (_user?.headline.isNotEmpty == true) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      _user!.headline,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                              color: AppTheme.primary,
                                              fontStyle: FontStyle.italic),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Edit profile card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Edit Profile',
                                style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Full Name *',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? AppConstants.valNameRequired
                                  : null,
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _headlineController,
                              decoration: const InputDecoration(
                                labelText: 'Headline (e.g. Frontend Intern)',
                                prefixIcon: Icon(Icons.badge_outlined),
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _locationController,
                              decoration: const InputDecoration(
                                labelText: 'Location',
                                prefixIcon: Icon(Icons.location_on_outlined),
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _skillsController,
                              decoration: const InputDecoration(
                                labelText: 'Skills (comma separated)',
                                prefixIcon: Icon(Icons.star_outline),
                              ),
                              maxLines: 2,
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: _saving ? null : _saveProfile,
                              child: _saving
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2),
                                    )
                                  : const Text('Save Changes'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Resume card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Resume',
                                style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 8),
                            if (_user?.resumeUrl != null) ...[
                              Row(
                                children: [
                                  const Icon(Icons.picture_as_pdf,
                                      color: AppTheme.error, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Resume uploaded',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(color: AppTheme.primary),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                            ] else ...[
                              Text(
                                'No resume uploaded yet.',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 12),
                            ],
                            OutlinedButton.icon(
                              onPressed:
                                  _uploadingResume ? null : _uploadResume,
                              icon: _uploadingResume
                                  ? const SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : const Icon(Icons.upload_file_outlined),
                              label: Text(_user?.resumeUrl != null
                                  ? 'Replace Resume (PDF)'
                                  : 'Upload Resume (PDF)'),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Skills display
                    if (_user?.skills.isNotEmpty == true) ...[
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Skills',
                                  style:
                                      Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _user!.skills
                                    .map((skill) => Chip(
                                          label: Text(skill),
                                          backgroundColor:
                                              AppTheme.primary.withValues(alpha: 0.5),
                                          labelStyle: const TextStyle(
                                              color: AppTheme.primary,
                                              fontSize: 13),
                                        ))
                                    .toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}


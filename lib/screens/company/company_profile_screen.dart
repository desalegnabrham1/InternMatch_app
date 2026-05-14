import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_constants.dart';
import '../../utils/app_theme.dart';
import '../../widgets/loading_widget.dart' as lw;

class CompanyProfileScreen extends StatefulWidget {
  const CompanyProfileScreen({super.key});

  @override
  State<CompanyProfileScreen> createState() => _CompanyProfileScreenState();
}

class _CompanyProfileScreenState extends State<CompanyProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _firestoreService = FirestoreService();

  final _companyNameController = TextEditingController();
  final _websiteController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  UserModel? _user;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _websiteController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = await _authService.getCurrentUserModel();
    if (mounted) {
      setState(() {
        _user = user;
        _loading = false;
        if (user != null) {
          _companyNameController.text = user.companyName;
          _websiteController.text = user.website;
          _descriptionController.text = user.description;
          _locationController.text = user.location;
        }
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      await _firestoreService.updateUserProfile(uid, {
        'companyName': _companyNameController.text.trim(),
        'website': _websiteController.text.trim(),
        'description': _descriptionController.text.trim(),
        'location': _locationController.text.trim(),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Company Profile')),
      body: _loading
          ? const lw.LoadingWidget(message: 'Loading profile...')
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar / banner card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: Text(
                                  (_user?.companyName.isNotEmpty == true
                                          ? _user!.companyName[0]
                                          : 'C')
                                      .toUpperCase(),
                                  style: const TextStyle(
                                    color: AppTheme.primary,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _user?.companyName.isNotEmpty == true
                                        ? _user!.companyName
                                        : 'Company',
                                    style:
                                        Theme.of(context).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _user?.email ?? '',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  if (_user?.location.isNotEmpty == true) ...[
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on_outlined,
                                            size: 14,
                                            color: AppTheme.textSecondary),
                                        const SizedBox(width: 4),
                                        Text(
                                          _user!.location,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium,
                                        ),
                                      ],
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
                              controller: _companyNameController,
                              decoration: const InputDecoration(
                                labelText: 'Company Name *',
                                prefixIcon: Icon(Icons.business_outlined),
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? AppConstants.valCompanyNameRequired
                                  : null,
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _websiteController,
                              keyboardType: TextInputType.url,
                              decoration: const InputDecoration(
                                labelText: 'Website',
                                prefixIcon: Icon(Icons.language_outlined),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return null;
                                if (!AppConstants.urlRegex.hasMatch(v.trim())) {
                                  return AppConstants.valUrl;
                                }
                                return null;
                              },
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
                              controller: _descriptionController,
                              maxLines: 4,
                              decoration: const InputDecoration(
                                labelText: 'Company Description',
                                alignLabelWithHint: true,
                              ),
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

                    // About section (read-only)
                    if (_user?.description.isNotEmpty == true) ...[
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('About',
                                  style:
                                      Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 10),
                              Text(
                                _user!.description,
                                style: Theme.of(context).textTheme.bodyLarge,
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


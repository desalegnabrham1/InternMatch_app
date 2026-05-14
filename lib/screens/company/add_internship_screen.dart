import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/internship_model.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_constants.dart';
import '../../utils/app_theme.dart';

class AddInternshipScreen extends StatefulWidget {
  const AddInternshipScreen({super.key});

  @override
  State<AddInternshipScreen> createState() => _AddInternshipScreenState();
}

class _AddInternshipScreenState extends State<AddInternshipScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();

  final _titleController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _requirementController = TextEditingController();
  final _contactEmailController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _deadlineController = TextEditingController();

  bool _loading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _companyNameController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _requirementController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    _deadlineController.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      _deadlineController.text =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final internship = InternshipModel(
        id: '',
        title: _titleController.text.trim(),
        companyName: _companyNameController.text.trim(),
        location: _locationController.text.trim(),
        description: _descriptionController.text.trim(),
        requirement: _requirementController.text.trim(),
        contactEmail: _contactEmailController.text.trim(),
        contactPhone: _contactPhoneController.text.trim(),
        deadline: _deadlineController.text.trim(),
        createdBy: uid,
        createdAt: DateTime.now(),
      );
      await _firestoreService.addInternship(internship);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(AppConstants.msgInternshipPosted),
              backgroundColor: AppTheme.primary),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        final message = e is FirebaseException &&
                e.message != null &&
                e.message!.trim().isNotEmpty
            ? e.message!
            : AppConstants.msgFailedPost;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post Internship')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildCard([
                _buildField(_titleController, 'Job Title *', Icons.title,
                    required: true),
                const SizedBox(height: 14),
                _buildField(
                    _companyNameController, 'Company Name *', Icons.business,
                    required: true),
                const SizedBox(height: 14),
                _buildField(_locationController, 'Location *',
                    Icons.location_on_outlined,
                    required: true),
              ]),
              const SizedBox(height: 12),
              _buildCard([
                _buildField(_descriptionController, 'Job Description *',
                    Icons.description_outlined,
                    required: true, maxLines: 4),
                const SizedBox(height: 14),
                _buildField(_requirementController, 'Requirements *',
                    Icons.checklist_outlined,
                    required: true, maxLines: 4),
              ]),
              const SizedBox(height: 12),
              _buildCard([
                _buildField(_contactEmailController, 'Contact Email *',
                    Icons.email_outlined,
                    required: true, keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 14),
                _buildField(_contactPhoneController, 'Contact Phone',
                    Icons.phone_outlined,
                    keyboardType: TextInputType.phone),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _deadlineController,
                  readOnly: true,
                  onTap: _pickDeadline,
                  decoration: const InputDecoration(
                    labelText: 'Application Deadline *',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                    suffixIcon: Icon(Icons.arrow_drop_down),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Please select a deadline'
                      : null,
                ),
              ]),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Post Internship'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool required = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: maxLines == 1 ? Icon(icon) : null,
        alignLabelWithHint: maxLines > 1,
      ),
      validator: (v) {
        if (required && (v == null || v.trim().isEmpty)) {
          return AppConstants.valRequired;
        }
        // Specific format validators based on keyboard type
        if (v != null && v.trim().isNotEmpty) {
          if (keyboardType == TextInputType.emailAddress) {
            if (!AppConstants.emailRegex.hasMatch(v.trim())) {
              return AppConstants.valEmail;
            }
          } else if (keyboardType == TextInputType.phone) {
            if (!AppConstants.phoneRegex.hasMatch(v.trim())) {
              return AppConstants.valPhone;
            }
          }
        }
        return null;
      },
    );
  }
}

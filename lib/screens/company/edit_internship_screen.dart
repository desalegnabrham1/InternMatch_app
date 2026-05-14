import 'package:flutter/material.dart';
import '../../models/internship_model.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_constants.dart';
import '../../utils/app_theme.dart';

class EditInternshipScreen extends StatefulWidget {
  final InternshipModel internship;

  const EditInternshipScreen({super.key, required this.internship});

  @override
  State<EditInternshipScreen> createState() => _EditInternshipScreenState();
}

class _EditInternshipScreenState extends State<EditInternshipScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();

  late final TextEditingController _titleController;
  late final TextEditingController _companyNameController;
  late final TextEditingController _locationController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _requirementController;
  late final TextEditingController _contactEmailController;
  late final TextEditingController _contactPhoneController;
  late final TextEditingController _deadlineController;

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final i = widget.internship;
    _titleController = TextEditingController(text: i.title);
    _companyNameController = TextEditingController(text: i.companyName);
    _locationController = TextEditingController(text: i.location);
    _descriptionController = TextEditingController(text: i.description);
    _requirementController = TextEditingController(text: i.requirement);
    _contactEmailController = TextEditingController(text: i.contactEmail);
    _contactPhoneController = TextEditingController(text: i.contactPhone);
    _deadlineController = TextEditingController(text: i.deadline);
  }

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
    DateTime initial;
    try {
      initial = DateTime.parse(_deadlineController.text);
    } catch (_) {
      initial = DateTime.now().add(const Duration(days: 30));
    }
    final date = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(DateTime.now())
          ? DateTime.now().add(const Duration(days: 1))
          : initial,
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
      final updated = widget.internship.copyWith(
        title: _titleController.text.trim(),
        companyName: _companyNameController.text.trim(),
        location: _locationController.text.trim(),
        description: _descriptionController.text.trim(),
        requirement: _requirementController.text.trim(),
        contactEmail: _contactEmailController.text.trim(),
        contactPhone: _contactPhoneController.text.trim(),
        deadline: _deadlineController.text.trim(),
      );
      await _firestoreService.updateInternship(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(AppConstants.msgInternshipUpdated),
              backgroundColor: AppTheme.primary),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppConstants.msgFailedUpdate)),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Internship')),
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
                _buildField(
                    _locationController, 'Location *', Icons.location_on_outlined,
                    required: true),
              ]),
              const SizedBox(height: 12),
              _buildCard([
                _buildField(
                    _descriptionController, 'Job Description *',
                    Icons.description_outlined,
                    required: true,
                    maxLines: 4),
                const SizedBox(height: 14),
                _buildField(
                    _requirementController, 'Requirements *',
                    Icons.checklist_outlined,
                    required: true,
                    maxLines: 4),
              ]),
              const SizedBox(height: 12),
              _buildCard([
                _buildField(
                    _contactEmailController, 'Contact Email *',
                    Icons.email_outlined,
                    required: true,
                    keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 14),
                _buildField(
                    _contactPhoneController, 'Contact Phone',
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
                    : const Text('Save Changes'),
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

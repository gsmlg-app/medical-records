import 'package:flutter/material.dart';
import 'package:app_locale/app_locale.dart';
import 'package:app_database/app_database.dart';

class DoctorFormWidget extends StatefulWidget {
  final String? initialName;
  final String? initialLevel;
  final int? initialDepartmentId;
  final List<Department> availableDepartments;
  final bool isEditMode;
  final VoidCallback? onCancel;
  final Function(String name, int departmentId, String? level) onSave;

  const DoctorFormWidget({
    super.key,
    this.initialName,
    this.initialLevel,
    this.initialDepartmentId,
    required this.availableDepartments,
    this.isEditMode = false,
    this.onCancel,
    required this.onSave,
  });

  @override
  State<DoctorFormWidget> createState() => _DoctorFormWidgetState();
}

class _DoctorFormWidgetState extends State<DoctorFormWidget> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _levelController;
  int? _selectedDepartmentId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _levelController = TextEditingController(text: widget.initialLevel ?? '');
    _selectedDepartmentId = widget.initialDepartmentId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _levelController.dispose();
    super.dispose();
  }

  void _onSave() async {
    if (_formKey.currentState!.validate() && _selectedDepartmentId != null) {
      setState(() {
        _isSubmitting = true;
      });

      try {
        await widget.onSave(
          _nameController.text.trim(),
          _selectedDepartmentId!,
          _levelController.text.trim().isEmpty ? null : _levelController.text.trim(),
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
        }
      }
    }
  }

  void _onCancel() {
    if (widget.onCancel != null) {
      widget.onCancel!();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: context.l10n.doctorName,
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.person),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return context.l10n.fieldRequired;
              }
              return null;
            },
            textInputAction: TextInputAction.next,
            enabled: !_isSubmitting,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            value: _selectedDepartmentId,
            decoration: InputDecoration(
              labelText: context.l10n.departments,
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.business_outlined),
            ),
            items: widget.availableDepartments.map((department) {
              return DropdownMenuItem<int>(
                value: department.id,
                child: Text(department.name),
              );
            }).toList(),
            validator: (value) {
              if (value == null) {
                return 'Please select a department';
              }
              return null;
            },
            onChanged: (_isSubmitting || widget.availableDepartments.isEmpty) ? null : (value) {
              setState(() {
                _selectedDepartmentId = value;
              });
            },
          ),
          if (widget.availableDepartments.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'No departments available. Please add a department first.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _levelController,
            decoration: InputDecoration(
              labelText: context.l10n.doctorTitle,
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.workspace_premium_outlined),
              hintText: 'e.g., Attending Physician, Resident',
            ),
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _onSave(),
            enabled: !_isSubmitting,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSubmitting ? null : _onCancel,
                  child: Text(context.l10n.cancel),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: (_isSubmitting || _selectedDepartmentId == null) ? null : _onSave,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(widget.isEditMode
                          ? context.l10n.save
                          : context.l10n.addDoctor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
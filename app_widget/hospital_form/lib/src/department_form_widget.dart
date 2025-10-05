import 'package:flutter/material.dart';
import 'package:app_locale/app_locale.dart';
import 'package:app_database/app_database.dart';

class DepartmentFormWidget extends StatefulWidget {
  final String? initialName;
  final String? initialCategory;
  final bool isEditMode;
  final VoidCallback? onCancel;
  final Function(String name, String? category) onSave;

  const DepartmentFormWidget({
    super.key,
    this.initialName,
    this.initialCategory,
    this.isEditMode = false,
    this.onCancel,
    required this.onSave,
  });

  @override
  State<DepartmentFormWidget> createState() => _DepartmentFormWidgetState();
}

class _DepartmentFormWidgetState extends State<DepartmentFormWidget> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _categoryController;
  String? _selectedCategory;
  bool _isSubmitting = false;

  // Predefined department categories
  static const List<String> _departmentCategories = [
    'InternalMedicine',
    'Surgery',
    'Pediatrics',
    'ObstetricsGynecology',
    'TraditionalChineseMedicine',
    'ClinicalDepartment',
    'MedicalTechnologyDepartment',
    'NursingDepartment',
    'PharmacyDepartment',
    'AdministrativeDepartment',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _categoryController = TextEditingController(text: widget.initialCategory ?? '');
    _selectedCategory = widget.initialCategory;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  String _getCategoryDisplayName(String category) {
    switch (category) {
      case 'InternalMedicine':
        return 'Internal Medicine';
      case 'ObstetricsGynecology':
        return 'Obstetrics & Gynecology';
      case 'TraditionalChineseMedicine':
        return 'Traditional Chinese Medicine';
      case 'ClinicalDepartment':
        return 'Clinical Department';
      case 'MedicalTechnologyDepartment':
        return 'Medical Technology Department';
      case 'NursingDepartment':
        return 'Nursing Department';
      case 'PharmacyDepartment':
        return 'Pharmacy Department';
      case 'AdministrativeDepartment':
        return 'Administrative Department';
      case 'Surgery':
        return 'Surgery';
      case 'Pediatrics':
        return 'Pediatrics';
      default:
        return category;
    }
  }

  void _onSave() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      try {
        await widget.onSave(_nameController.text.trim(), _selectedCategory);
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
              labelText: context.l10n.departmentName,
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.business),
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
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: InputDecoration(
              labelText: context.l10n.departmentCategory,
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.category),
            ),
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('None'),
              ),
              ..._departmentCategories.map((category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(_getCategoryDisplayName(category)),
                );
              }),
            ],
            onChanged: _isSubmitting ? null : (value) {
              setState(() {
                _selectedCategory = value;
              });
            },
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
                  onPressed: _isSubmitting ? null : _onSave,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(widget.isEditMode
                          ? context.l10n.save
                          : context.l10n.addDepartment),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
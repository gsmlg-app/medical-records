import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_locale/app_locale.dart';
import 'package:hospital_form_bloc/hospital_form_bloc.dart';

class HospitalFormWidget extends StatefulWidget {
  final String? initialName;
  final String? initialAddress;
  final String? initialType;
  final String? initialLevel;
  final bool isEditMode;
  final VoidCallback? onCancel;
  final VoidCallback? onSave;

  const HospitalFormWidget({
    super.key,
    this.initialName,
    this.initialAddress,
    this.initialType,
    this.initialLevel,
    this.isEditMode = false,
    this.onCancel,
    this.onSave,
  });

  @override
  State<HospitalFormWidget> createState() => _HospitalFormWidgetState();
}

class _HospitalFormWidgetState extends State<HospitalFormWidget> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _typeController;
  late final TextEditingController _levelController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _addressController = TextEditingController(
      text: widget.initialAddress ?? '',
    );
    _typeController = TextEditingController(text: widget.initialType ?? '');
    _levelController = TextEditingController(text: widget.initialLevel ?? '');

    // Initialize the form bloc with initial values
    context.read<HospitalFormBloc>().add(
      InitializeForm(
        name: widget.initialName,
        address: widget.initialAddress,
        type: widget.initialType,
        level: widget.initialLevel,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _typeController.dispose();
    _levelController.dispose();
    super.dispose();
  }

  void _onFieldChanged(String value, Function(String) onChanged) {
    onChanged(value);
  }

  void _onSave() {
    if (_formKey.currentState!.validate()) {
      context.read<HospitalFormBloc>().add(FormSubmitted());
      if (widget.onSave != null) {
        widget.onSave!();
      }
    }
  }

  void _onCancel() {
    if (widget.onCancel != null) {
      widget.onCancel!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<HospitalFormBloc, HospitalFormState>(
      listener: (context, state) {
        if (state is HospitalFormSubmissionFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error), backgroundColor: Colors.red),
          );
        } else if (state is HospitalFormSubmissionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
      child: BlocBuilder<HospitalFormBloc, HospitalFormState>(
        builder: (context, state) {
          bool isSubmitting = false;
          String? errorText;

          if (state is HospitalFormLoaded) {
            isSubmitting = state.isSubmitting;
          } else if (state is HospitalFormSubmissionInProgress) {
            isSubmitting = true;
          } else if (state is HospitalFormSubmissionFailure) {
            isSubmitting = false;
            errorText = state.error;
          } else if (state is HospitalFormSubmissionSuccess) {
            isSubmitting = false;
          }

          return Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: context.l10n.hospitalName,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.local_hospital),
                    errorText: state is HospitalFormLoaded && !state.isNameValid
                        ? context.l10n.fieldRequired
                        : null,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return context.l10n.fieldRequired;
                    }
                    return null;
                  },
                  onChanged: (value) => _onFieldChanged(value, (val) {
                    context.read<HospitalFormBloc>().add(NameChanged(val));
                  }),
                  textInputAction: TextInputAction.next,
                  enabled: !isSubmitting,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: context.l10n.address,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.location_on_outlined),
                  ),
                  maxLines: 2,
                  onChanged: (value) => _onFieldChanged(value, (val) {
                    context.read<HospitalFormBloc>().add(AddressChanged(val));
                  }),
                  textInputAction: TextInputAction.next,
                  enabled: !isSubmitting,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _typeController,
                  decoration: InputDecoration(
                    labelText: context.l10n.hospitalType,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.business_outlined),
                    hintText: context.l10n.hospitalTypeHint,
                  ),
                  onChanged: (value) => _onFieldChanged(value, (val) {
                    context.read<HospitalFormBloc>().add(TypeChanged(val));
                  }),
                  textInputAction: TextInputAction.next,
                  enabled: !isSubmitting,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _levelController,
                  decoration: InputDecoration(
                    labelText: context.l10n.hospitalLevel,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.star_outline),
                    hintText: context.l10n.hospitalLevelHint,
                  ),
                  onChanged: (value) => _onFieldChanged(value, (val) {
                    context.read<HospitalFormBloc>().add(LevelChanged(val));
                  }),
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _onSave(),
                  enabled: !isSubmitting,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isSubmitting ? null : _onCancel,
                        child: Text(context.l10n.cancel),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed:
                            (isSubmitting ||
                                !(state is HospitalFormLoaded &&
                                    state.isNameValid))
                            ? null
                            : _onSave,
                        child: isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                widget.isEditMode
                                    ? context.l10n.save
                                    : context.l10n.addHospital,
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

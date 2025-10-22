import 'dart:async';

import 'dart:io';
import 'package:app_database/app_database.dart';
import 'package:app_logging/app_logging.dart';
import 'package:app_utils/app_utils.dart';
import 'package:form_bloc/form_bloc.dart';
import 'package:visit_location_bloc/visit_location_bloc.dart';
import 'package:visit_resource_bloc/visit_resource_bloc.dart';
import 'package:visit_data_bloc/visit_data_bloc.dart';
import 'package:equatable/equatable.dart';

part 'event.dart';
part 'state.dart';

/// {@template visit_form_bloc_refactored}
/// Refactored VisitFormBloc that coordinates smaller, focused BLoCs.
/// This BLoC is now focused only on form validation and coordination.
/// {@endtemplate}
class VisitFormBlocRefactored extends FormBloc<String, String> {
  /// {@macro visit_form_bloc_refactored}
  final VisitLocationBloc _locationBloc;
  final VisitResourceBloc _resourceBloc;
  final VisitDataBloc _dataBloc;
  final _fieldHelper = FieldDependencyHelper();

  /// Visit to populate for editing
  Visit? visitToEdit;

  /// Field BLoCs for form validation
  late final SelectFieldBloc<int?, dynamic> hospitalFieldBloc;
  late final SelectFieldBloc<int?, dynamic> departmentFieldBloc;
  late final SelectFieldBloc<int?, dynamic> doctorFieldBloc;
  late final SelectFieldBloc<VisitCategory, dynamic> categoryFieldBloc;
  late final InputFieldBloc<DateTime, dynamic> dateFieldBloc;
  late final TextFieldBloc detailsFieldBloc;

  /// {@macro visit_form_bloc_refactored}
  VisitFormBlocRefactored({
    required VisitLocationBloc locationBloc,
    required VisitResourceBloc resourceBloc,
    required VisitDataBloc dataBloc,
    this.visitToEdit,
  })  : _locationBloc = locationBloc,
        _resourceBloc = resourceBloc,
        _dataBloc = dataBloc,
        super(isLoading: true) {
    AppLogger().d('VisitFormBlocRefactored constructor started');

    // Initialize field BLoCs
    _initializeFieldBlocs();

    // Add field BLoCs to form
    _addFieldBlocs();

    // Set up event handlers
    _setupEventHandlers();

    AppLogger().d('VisitFormBlocRefactored constructor completed');
  }

  void _initializeFieldBlocs() {
    hospitalFieldBloc = SelectFieldBloc<int?, dynamic>(
      initialValue: null,
      items: const [null],
      validators: [FieldBlocValidators.required],
    );

    departmentFieldBloc = SelectFieldBloc<int?, dynamic>(
      initialValue: null,
      items: const [null],
    );

    doctorFieldBloc = SelectFieldBloc<int?, dynamic>(
      initialValue: null,
      items: const [null],
    );

    categoryFieldBloc = SelectFieldBloc<VisitCategory, dynamic>(
      initialValue: VisitCategory.values.first,
      items: VisitCategory.values,
      validators: [FieldBlocValidators.required],
    );

    dateFieldBloc = InputFieldBloc<DateTime, dynamic>(
      initialValue: DateTime.now(),
      validators: [
        FieldBlocValidators.required,
        (value) {
          if (value.isAfter(DateTime.now())) {
            return 'Date cannot be in the future';
          }
          return null;
        },
      ],
    );

    detailsFieldBloc = TextFieldBloc(
      validators: [
        FieldBlocValidators.required,
        (value) {
          if (value.isEmpty) return null;
          if (value.length < 10) {
            return 'Details must be at least 10 characters';
          }
          if (value.length > 1000) {
            return 'Details must be less than 1000 characters';
          }
          return null;
        },
      ],
    );
  }

  void _addFieldBlocs() {
    addFieldBloc(fieldBloc: hospitalFieldBloc);
    addFieldBloc(fieldBloc: departmentFieldBloc);
    addFieldBloc(fieldBloc: doctorFieldBloc);
    addFieldBloc(fieldBloc: categoryFieldBloc);
    addFieldBloc(fieldBloc: dateFieldBloc);
    addFieldBloc(fieldBloc: detailsFieldBloc);
  }

  void _setupEventHandlers() {
    // Set up field dependencies
    hospitalFieldBloc.stream.listen((state) {
      if (state.value != null) {
        _locationBloc.add(HospitalChanged(state.value));
        _updateFieldItems();
      }
    });

    departmentFieldBloc.stream.listen((state) {
      if (state.value != null) {
        _locationBloc.add(DepartmentChanged(state.value));
        _updateFieldItems();
      }
    });

    // Listen to location bloc state changes
    _locationBloc.stream.listen((state) {
      if (state is VisitLocationStateLoaded) {
        _updateFieldItemsFromLocationState(state);
      }
    });
  }

  @override
  void onLoading() async {
    try {
      AppLogger().d('VisitFormBlocRefactored onLoading() started');

      // Load location data
      _locationBloc.add(const LoadHospitals());

      // If editing, load existing visit data and resources
      if (visitToEdit != null) {
        await _loadExistingVisitData();
      }

      emitLoaded();
    } catch (e) {
      AppLogger().e('Failed to load form data: $e');
      emitFailure(failureResponse: 'Failed to load form data: ${e.toString()}');
    }
  }

  @override
  void onSubmitting() async {
    try {
      // Extract form values
      final category = categoryFieldBloc.value!;
      final date = dateFieldBloc.value;
      final details = detailsFieldBloc.value;
      final hospitalId = hospitalFieldBloc.value;
      final departmentId = departmentFieldBloc.value;
      final doctorId = doctorFieldBloc.value;

      // Get treatment ID from route or context
      final treatmentId = _getTreatmentId();

      if (visitToEdit != null) {
        // Update existing visit
        _dataBloc.add(UpdateVisitData(
          visitId: visitToEdit!.id,
          treatmentId: treatmentId,
          category: category,
          date: date,
          details: details,
          hospitalId: hospitalId,
          departmentId: departmentId,
          doctorId: doctorId,
        ));
      } else {
        // Create new visit
        _dataBloc.add(CreateVisit(
          treatmentId: treatmentId,
          category: category,
          date: date,
          details: details,
          hospitalId: hospitalId,
          departmentId: departmentId,
          doctorId: doctorId,
        ));
      }

// Listen for result
    _dataBloc.stream.listen((state) {
      if (state is VisitDataStateSuccess) {
        emitSuccess(successResponse: state.message);
      } else if (state is VisitDataStateError) {
        emitFailure(failureResponse: state.message);
      }
    });

    // Wait for completion
    await _fieldHelper.waitForCondition(
      () => state is VisitFormStateReady || state is VisitFormStateError,
      timeout: const Duration(seconds: 10),
    );
    } catch (e) {
      AppLogger().e('Failed to submit form: $e');
      emitFailure(failureResponse: 'Failed to save visit: ${e.toString()}');
    }
  }

  Future<void> _loadExistingVisitData() async {
    if (visitToEdit == null) return;

    final visit = visitToEdit!;

    // Load resources for existing visit
    _resourceBloc.add(LoadResources(visit.id));

    // Populate form fields
    await _fieldHelper.executeCascadingFieldUpdates([
      () async {
        final category = VisitCategory.values.firstWhere(
          (c) => c.value == visit.category,
        );
        categoryFieldBloc.updateValue(category);
        final completer = Completer<void>();
        Timer.run(() => completer.complete());
        return completer.future;
      },
      () async {
        dateFieldBloc.updateValue(visit.date);
        detailsFieldBloc.updateValue(visit.details);
        final completer = Completer<void>();
        Timer.run(() => completer.complete());
        return completer.future;
      },
      () async {
        if (visit.hospitalId != null) {
          hospitalFieldBloc.updateValue(visit.hospitalId);
        }
        final completer = Completer<void>();
        Timer.run(() => completer.complete());
        return completer.future;
      },
      () async {
        if (visit.departmentId != null) {
          departmentFieldBloc.updateValue(visit.departmentId);
        }
        final completer = Completer<void>();
        Timer.run(() => completer.complete());
        return completer.future;
      },
      () async {
        if (visit.doctorId != null) {
          doctorFieldBloc.updateValue(visit.doctorId);
        }
        final completer = Completer<void>();
        Timer.run(() => completer.complete());
        return completer.future;
      },
    ]);
  }

  void _updateFieldItems() {
    final locationState = _locationBloc.state;
    if (locationState is VisitLocationStateLoaded) {
      _updateFieldItemsFromLocationState(locationState);
    }
  }

  void _updateFieldItemsFromLocationState(VisitLocationStateLoaded state) {
    // Update hospital field items
    final hospitalItems = [null, ...state.hospitals.map((h) => h.id)];
    hospitalFieldBloc.updateItems(hospitalItems);

    // Update department field items
    final departmentItems = [null, ...state.departments.map((d) => d.id)];
    departmentFieldBloc.updateItems(departmentItems);

    // Update doctor field items
    final doctorItems = [null, ...state.doctors.map((d) => d.id)];
    doctorFieldBloc.updateItems(doctorItems);
  }

  int _getTreatmentId() {
    // This should be injected or passed via constructor
    // For now, return a default value
    return visitToEdit?.treatmentId ?? 1;
  }

  /// Quick add department
  Future<bool> quickAddDepartment(String name, {String? category}) async {
    try {
      _locationBloc.add(QuickAddDepartment(name, category: category));
      
      final success = await _fieldHelper.waitForCondition(
        () => _locationBloc.state is VisitLocationStateLoaded,
        timeout: const Duration(seconds: 5),
      );
      
      return success;
    } catch (e) {
      AppLogger().e('Failed to add department: $e');
      return false;
    }
  }

  /// Quick add doctor
  Future<bool> quickAddDoctor(String name, {String? title, String? specialty}) async {
    try {
      _locationBloc.add(QuickAddDoctor(name, title: title, specialty: specialty));
      
      final success = await _fieldHelper.waitForCondition(
        () => _locationBloc.state is VisitLocationStateLoaded,
        timeout: const Duration(seconds: 5),
      );
      
      return success;
    } catch (e) {
      AppLogger().e('Failed to add doctor: $e');
      return false;
    }
  }

  /// Add resource to current visit
  Future<void> addResource(File file) async {
    if (visitToEdit != null) {
      _resourceBloc.add(AddResource(file, visitToEdit!.id));
    }
  }

  /// Get current resources
  List<Resource> getCurrentResources() {
    return _resourceBloc.getCurrentResources();
  }

  @override
  Future<void> close() async {
    _fieldHelper.dispose();
    return super.close();
  }
}
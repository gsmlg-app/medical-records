import 'dart:async';
import 'dart:convert';

import 'package:app_database/app_database.dart';
import 'package:drift/drift.dart' show Value;
import 'package:equatable/equatable.dart';
import 'package:form_bloc/form_bloc.dart';
import 'package:visit_bloc/visit_bloc.dart';

part 'event.dart';
part 'state.dart';

/// {@template visit_form_bloc}
/// VisitFormBloc handles visit form validation and submission.
/// {@endtemplate}
class VisitFormBloc extends FormBloc<String, String> {
  /// {@macro visit_form_bloc}
  final AppDatabase _database;

  /// VisitBloc for notifying state changes
  final VisitBloc? _visitBloc;

  /// Available hospitals for selection
  List<Hospital> availableHospitals = [];

  /// Available departments for selection
  List<Department> availableDepartments = [];

  /// Available doctors for selection
  List<Doctor> availableDoctors = [];

  /// Visit to populate for editing
  Visit? visitToEdit;

  /// Quick add a new department for the selected hospital
  Future<bool> quickAddDepartment(String name, {String? category}) async {
    try {
      final hospitalId = hospitalFieldBloc.value;
      if (hospitalId == null) {
        print('DEBUG: Cannot add department - no hospital selected');
        return false;
      }

      // Create the department
      final departmentId = await _database.createDepartment(
        DepartmentsCompanion(name: Value(name), category: Value(category)),
      );

      print('DEBUG: Created new department with ID: $departmentId');

      // Get current hospital to update its departmentIds
      final hospitals = await _database.getAllHospitals();
      final hospital = hospitals.firstWhere((h) => h.id == hospitalId);

      // Parse existing department IDs from JSON
      final currentIds = <int>[];
      if (hospital.departmentIds.isNotEmpty) {
        try {
          final ids = (json.decode(hospital.departmentIds) as List)
              .map((e) => int.parse(e.toString()))
              .toList();
          currentIds.addAll(ids);
        } catch (e) {
          print('DEBUG: Error parsing existing departmentIds: $e');
        }
      }

      // Add new department ID
      currentIds.add(departmentId);

      // Update hospital with JSON-encoded department IDs
      await _database.updateHospital(
        hospital.copyWith(departmentIds: json.encode(currentIds)),
      );

      print('DEBUG: Updated hospital with new department ID');

      // Refresh the available departments list
      availableDepartments = await _database.getAllDepartments();

      // Update available hospitals list to reflect the change
      availableHospitals = await _database.getAllHospitals();

      // Update department options to include the new department
      _updateDepartmentOptions();

      // Select the newly created department
      departmentFieldBloc.updateValue(departmentId);

      return true;
    } catch (e) {
      print('DEBUG: Failed to add department: $e');
      return false;
    }
  }

  // Stream subscriptions
  StreamSubscription? _hospitalSubscription;
  StreamSubscription? _departmentSubscription;

  VisitFormBloc(this._database, {this.visitToEdit, VisitBloc? visitBloc})
    : _visitBloc = visitBloc,
      super(isLoading: true) {
    print(
      'DEBUG: VisitFormBloc constructor called with visitToEdit: ${visitToEdit?.id}',
    );
    // Add field blocs
    addFieldBloc(fieldBloc: categoryFieldBloc);
    addFieldBloc(fieldBloc: dateFieldBloc);
    addFieldBloc(fieldBloc: detailsFieldBloc);
    addFieldBloc(fieldBloc: hospitalFieldBloc);
    addFieldBloc(fieldBloc: departmentFieldBloc);
    addFieldBloc(fieldBloc: doctorFieldBloc);
    print('DEBUG: VisitFormBloc constructor completed');
  }

  /// Visit Category field bloc
  late final categoryFieldBloc = SelectFieldBloc<VisitCategory, dynamic>(
    name: 'category',
    items: VisitCategory.values,
    initialValue: VisitCategory.outpatient, // Always start with safe default
    validators: [FieldBlocValidators.required],
  );

  /// Visit Date field bloc
  late final dateFieldBloc = InputFieldBloc<DateTime, dynamic>(
    name: 'date',
    initialValue: visitToEdit?.date ?? DateTime.now(),
    validators: [FieldBlocValidators.required],
  );

  /// Visit Details field bloc
  late final detailsFieldBloc = TextFieldBloc(
    name: 'details',
    initialValue: visitToEdit?.details ?? '',
    validators: [], // No validators - details field is optional
  );

  /// Hospital field bloc
  late final hospitalFieldBloc = SelectFieldBloc<int?, dynamic>(
    name: 'hospitalId',
    items: [null], // Start with just null to prevent dropdown assertion errors
    validators: [], // No validators for optional field
  );

  /// Department field bloc
  late final departmentFieldBloc = SelectFieldBloc<int?, dynamic>(
    name: 'departmentId',
    items: [null], // Start with just null to prevent dropdown assertion errors
    validators: [], // No validators for optional field
  );

  /// Doctor field bloc
  late final doctorFieldBloc = SelectFieldBloc<int?, dynamic>(
    name: 'doctorId',
    items: [null], // Start with just null to prevent dropdown assertion errors
    validators: [], // No validators for optional field
  );

  @override
  void onLoading() async {
    try {
      print('DEBUG: VisitFormBloc onLoading() started');

      // Load all data in parallel
      final hospitalsFuture = _database.getAllHospitals();
      final departmentsFuture = _database.getAllDepartments();
      final doctorsFuture = _database.getAllDoctors();

      final results = await Future.wait([
        hospitalsFuture,
        departmentsFuture,
        doctorsFuture,
      ]);

      availableHospitals = results[0] as List<Hospital>;
      availableDepartments = results[1] as List<Department>;
      availableDoctors = results[2] as List<Doctor>;

      print(
        'DEBUG: Loaded ${availableHospitals.length} hospitals, ${availableDepartments.length} departments, ${availableDoctors.length} doctors',
      );

      // Prepare items - always include null as first option
      final hospitalItems = [null, ...availableHospitals.map((h) => h.id)];
      final doctorItems = [null, ...availableDoctors.map((d) => d.id)];

      print(
        'DEBUG: Prepared items - hospitals: ${hospitalItems.length}, doctors: ${doctorItems.length}',
      );

      // CRITICAL: Update items FIRST, then ensure values are valid
      // This prevents dropdown assertion errors by ensuring value always exists in items

      // Update hospital field
      hospitalFieldBloc.updateItems(hospitalItems);
      // Ensure value is valid (null is always in items)
      if (!hospitalItems.contains(hospitalFieldBloc.value)) {
        hospitalFieldBloc.updateValue(null);
      }

      // Update department field (filtered by hospital)
      _updateDepartmentOptions();
      // Ensure value is valid (null is always in items)
      final departmentItems = departmentFieldBloc.state.items;
      if (!departmentItems.contains(departmentFieldBloc.value)) {
        departmentFieldBloc.updateValue(null);
      }

      // Update doctor field
      doctorFieldBloc.updateItems(doctorItems);
      // Ensure value is valid (null is always in items)
      if (!doctorItems.contains(doctorFieldBloc.value)) {
        doctorFieldBloc.updateValue(null);
      }

      print('DEBUG: Updated all field items and ensured valid values');

      // Now that items are loaded, populate form with existing visit data if provided
      if (visitToEdit != null) {
        // Use a small delay to ensure all field updates are processed
        await Future.delayed(const Duration(milliseconds: 100));
        _populateFormAfterItemsLoaded();
      }

      // Use emitLoaded to indicate the form is ready for interaction
      emitLoaded();

      // Set up field dependencies differently for Add vs Edit
      if (visitToEdit != null) {
        // For edit visits, set up dependencies immediately after a short delay
        Future.delayed(const Duration(milliseconds: 200), () {
          _setupFieldDependencies();
        });
      } else {
        // For add visits, DON'T set up dependencies here
        // They will be set up manually from the UI after a longer delay
        print('DEBUG: Skipping automatic field dependency setup for Add Visit');
      }
    } catch (e) {
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

      if (visitToEdit != null) {
        // Update existing visit
        if (_visitBloc != null) {
          // Use VisitBloc to update the visit and notify listeners
          // Wait for the VisitBloc to complete the update before emitting success
          bool updateCompleted = false;
          String? errorMessage;

          // Listen for the completion of the update
          final subscription = _visitBloc!.stream.listen((state) {
            if (state is VisitOperationSuccess) {
              updateCompleted = true;
            } else if (state is VisitError) {
              errorMessage = state.message;
              updateCompleted = true;
            }
          });

          // Dispatch the update event
          _visitBloc!.add(
            UpdateVisit(
              id: visitToEdit!.id,
              treatmentId: visitToEdit!.treatmentId,
              category: category,
              date: date,
              details: details,
              hospitalId: hospitalId,
              departmentId: departmentId,
              doctorId: doctorId,
            ),
          );

          // Wait for the update to complete (with timeout)
          int attempts = 0;
          while (!updateCompleted && attempts < 50) {
            await Future.delayed(Duration(milliseconds: 100));
            attempts++;
          }

          await subscription.cancel();

          if (errorMessage != null) {
            emitFailure(failureResponse: errorMessage);
          } else if (updateCompleted) {
            // Update the visitToEdit reference to reflect the changes
            if (visitToEdit != null) {
              visitToEdit = Visit(
                id: visitToEdit!.id,
                treatmentId: visitToEdit!.treatmentId,
                category: category.value,
                date: date,
                details: details,
                hospitalId: hospitalId,
                departmentId: departmentId,
                doctorId: doctorId,
                createdAt: visitToEdit!.createdAt,
                updatedAt: DateTime.now(),
              );
            }

            emitSuccess(successResponse: 'Visit saved successfully!');
          } else {
            emitFailure(failureResponse: 'Update timed out');
          }
        } else {
          // Fallback: Update directly in database (won't notify UI)
          final updatedVisit = Visit(
            id: visitToEdit!.id,
            treatmentId: visitToEdit!.treatmentId,
            category: category.value,
            date: date,
            details: details,
            hospitalId: hospitalId,
            departmentId: departmentId,
            doctorId: doctorId,
            createdAt: visitToEdit!.createdAt,
            updatedAt: DateTime.now(),
          );

          await _database.updateVisit(updatedVisit);

          // Update the visitToEdit reference to reflect the changes
          visitToEdit = updatedVisit;

          emitSuccess(successResponse: 'Visit saved successfully!');
        }
      } else {
        // Create new visit - this would need treatmentId from context
        // For now, we'll emit a failure since we don't have all required data
        emitFailure(
          failureResponse: 'Cannot create visit: treatmentId is required',
        );
      }
    } catch (e) {
      emitFailure(failureResponse: 'Failed to save visit: ${e.toString()}');
    }
  }

  void _setupFieldDependencies() {
    print('DEBUG: Setting up field dependencies');

    // Cancel any existing subscriptions to avoid duplicates
    _hospitalSubscription?.cancel();
    _departmentSubscription?.cancel();

    // Listen to hospital field changes with a delay to avoid immediate updates
    _hospitalSubscription = hospitalFieldBloc.stream.listen((_) {
      print(
        'DEBUG: Hospital field changed - clearing department and doctor, updating options',
      );

      // Use a microtask to delay the updates and avoid dropdown assertion errors
      Future.microtask(() {
        // Update department options filtered by hospital
        _updateDepartmentOptions();

        // Clear dependent field values AFTER updating items to ensure valid state
        departmentFieldBloc.updateValue(null);
        doctorFieldBloc.updateValue(null);

        // Update doctor options based on new hospital selection
        _updateDoctorOptions();
      });
    });

    // Listen to department field changes with a delay to avoid immediate updates
    _departmentSubscription = departmentFieldBloc.stream.listen((_) {
      print(
        'DEBUG: Department field changed - clearing doctor, updating options',
      );

      // Use a microtask to delay the updates and avoid dropdown assertion errors
      Future.microtask(() {
        // Update doctor options first
        _updateDoctorOptions();

        // Clear doctor field value AFTER updating items to ensure valid state
        doctorFieldBloc.updateValue(null);
      });
    });
  }

  /// Sets up field dependencies for Add Visit forms without immediate triggers
  void _setupFieldDependenciesForAdd() {
    print(
      'DEBUG: Setting up field dependencies for Add Visit (no immediate triggers)',
    );

    // Cancel any existing subscriptions to avoid duplicates
    _hospitalSubscription?.cancel();
    _departmentSubscription?.cancel();

    // For Add Visit, we need to be more careful about stream initialization
    // Use a different approach that doesn't trigger immediate updates

    // Get current values to skip them
    final initialHospitalValue = hospitalFieldBloc.value;
    final initialDepartmentValue = departmentFieldBloc.value;

    // Listen to hospital field changes, but skip the initial value
    _hospitalSubscription = hospitalFieldBloc.stream.listen((value) {
      if (value == initialHospitalValue) {
        print('DEBUG: Skipping initial hospital field value: $value');
        return;
      }

      print(
        'DEBUG: Hospital field changed from $initialHospitalValue to $value - clearing department and doctor, updating options',
      );

      // Use a microtask to delay the updates and avoid dropdown assertion errors
      Future.microtask(() {
        // Update department options filtered by hospital
        _updateDepartmentOptions();

        // Clear dependent field values AFTER updating items to ensure valid state
        departmentFieldBloc.updateValue(null);
        doctorFieldBloc.updateValue(null);

        // Update doctor options based on new hospital selection
        _updateDoctorOptions();
      });
    });

    // Listen to department field changes, but skip the initial value
    _departmentSubscription = departmentFieldBloc.stream.listen((value) {
      if (value == initialDepartmentValue) {
        print('DEBUG: Skipping initial department field value: $value');
        return;
      }

      print(
        'DEBUG: Department field changed from $initialDepartmentValue to $value - clearing doctor, updating options',
      );

      // Use a microtask to delay the updates and avoid dropdown assertion errors
      Future.microtask(() {
        // Update doctor options first
        _updateDoctorOptions();

        // Clear doctor field value AFTER updating items to ensure valid state
        doctorFieldBloc.updateValue(null);
      });
    });
  }

  /// Called when hospital field changes
  void _onHospitalChanged() {
    final hospitalId = hospitalFieldBloc.value;
    print('DEBUG: Hospital changed to: $hospitalId');

    // 1. Clear department value (always clear when hospital changes)
    print('DEBUG: Clearing department selection due to hospital change');
    departmentFieldBloc.updateValue(null);

    // 2. Clear doctor value (always clear when hospital changes)
    print('DEBUG: Clearing doctor selection due to hospital change');
    doctorFieldBloc.updateValue(null);

    // 3. Update department options (departments are not filtered by hospital)
    final departmentItems = [null, ...availableDepartments.map((d) => d.id)];
    print(
      'DEBUG: Updating department options with ${departmentItems.length} items',
    );
    departmentFieldBloc.updateItems(departmentItems);

    // 4. Update doctor options based on new hospital
    _updateDoctorOptions();
  }

  /// Called when department field changes
  void _onDepartmentChanged() {
    final departmentId = departmentFieldBloc.value;
    print('DEBUG: Department changed to: $departmentId');

    // 1. Clear doctor value (always clear when department changes)
    print('DEBUG: Clearing doctor selection due to department change');
    doctorFieldBloc.updateValue(null);

    // 2. Update doctor options based on current hospital and new department
    _updateDoctorOptions();
  }

  /// Updates doctor options based on current hospital and department filters
  void _updateDoctorOptions() {
    final hospitalId = hospitalFieldBloc.value;
    final departmentId = departmentFieldBloc.value;

    print(
      'DEBUG: Updating doctor options with hospitalId: $hospitalId, departmentId: $departmentId',
    );

    List<Doctor> filteredDoctors = availableDoctors;

    // Filter by hospital if selected
    if (hospitalId != null) {
      filteredDoctors = filteredDoctors
          .where((d) => d.hospitalId == hospitalId)
          .toList();
      print(
        'DEBUG: Filtered doctors by hospital: ${filteredDoctors.length} remaining',
      );
    }

    // Filter by department if selected
    if (departmentId != null) {
      filteredDoctors = filteredDoctors
          .where((d) => d.departmentId == departmentId)
          .toList();
      print(
        'DEBUG: Filtered doctors by department: ${filteredDoctors.length} remaining',
      );
    }

    final doctorItems = [null, ...filteredDoctors.map((d) => d.id)];
    print(
      'DEBUG: Updating doctor field with ${doctorItems.length} items, current doctor value: ${doctorFieldBloc.value}',
    );

    // Update doctor items (value is already cleared by calling methods)
    doctorFieldBloc.updateItems(doctorItems);
  }

  /// Updates department options based on current hospital filter
  void _updateDepartmentOptions() {
    final hospitalId = hospitalFieldBloc.value;

    print('DEBUG: Updating department options with hospitalId: $hospitalId');

    List<Department> filteredDepartments = availableDepartments;

    // Filter by hospital if selected
    if (hospitalId != null) {
      // Find the hospital and get its department IDs
      final hospital = availableHospitals
          .where((h) => h.id == hospitalId)
          .firstOrNull;
      if (hospital != null && hospital.departmentIds.isNotEmpty) {
        try {
          // Parse JSON array of department IDs
          final departmentIds = (json.decode(hospital.departmentIds) as List)
              .map((e) => int.parse(e.toString()))
              .toList();

          filteredDepartments = availableDepartments
              .where((d) => departmentIds.contains(d.id))
              .toList();
          print(
            'DEBUG: Filtered departments by hospital: ${filteredDepartments.length} remaining',
          );
        } catch (e) {
          print('DEBUG: Error parsing hospital departmentIds: $e');
          // If parsing fails, show no departments
          filteredDepartments = [];
        }
      } else {
        // Hospital has no departments
        filteredDepartments = [];
        print('DEBUG: Hospital has no departments assigned');
      }
    }

    final departmentItems = [null, ...filteredDepartments.map((d) => d.id)];
    print(
      'DEBUG: Updating department field with ${departmentItems.length} items, current department value: ${departmentFieldBloc.value}',
    );

    // Update department items (value is already cleared by calling methods)
    departmentFieldBloc.updateItems(departmentItems);
  }

  /// Internal method to populate form after items are loaded
  void _populateFormAfterItemsLoaded() {
    if (visitToEdit == null) return;

    final visit = visitToEdit!;

    print(
      'DEBUG: Populating form with visit data - hospitalId: ${visit.hospitalId}, departmentId: ${visit.departmentId}, doctorId: ${visit.doctorId}',
    );

    // Update field blocs with visit data (non-cascading fields first)
    final category = VisitCategory.values.firstWhere(
      (c) => c.value == visit.category,
    );
    categoryFieldBloc.updateValue(category);
    dateFieldBloc.updateValue(visit.date);
    detailsFieldBloc.updateValue(visit.details);

    // For cascading fields, validate values exist before setting them
    if (visit.hospitalId != null &&
        availableHospitals.any((h) => h.id == visit.hospitalId)) {
      hospitalFieldBloc.updateValue(visit.hospitalId);

      // Wait for hospital to be set, then set department if valid
      Future.delayed(const Duration(milliseconds: 100), () {
        if (visit.departmentId != null &&
            availableDepartments.any((d) => d.id == visit.departmentId)) {
          departmentFieldBloc.updateValue(visit.departmentId);

          // Wait for department to be set, then set doctor if valid
          Future.delayed(const Duration(milliseconds: 100), () {
            if (visit.doctorId != null &&
                availableDoctors.any((d) => d.id == visit.doctorId)) {
              // Check if doctor is valid for current hospital/department filter
              final filteredDoctors = availableDoctors.where((d) {
                final hospitalMatch =
                    visit.hospitalId == null ||
                    d.hospitalId == visit.hospitalId;
                final departmentMatch =
                    visit.departmentId == null ||
                    d.departmentId == visit.departmentId;
                return hospitalMatch && departmentMatch;
              }).toList();

              if (filteredDoctors.any((d) => d.id == visit.doctorId)) {
                doctorFieldBloc.updateValue(visit.doctorId);
              } else {
                print(
                  'DEBUG: Doctor ${visit.doctorId} is not valid for current filters, setting to null',
                );
                doctorFieldBloc.updateValue(null);
              }
            }
          });
        }
      });
    } else {
      print(
        'DEBUG: Hospital ${visit.hospitalId} not found in available hospitals',
      );
    }
  }

  /// Public method to populate form with visit data
  void populateForm(Visit visit) {
    visitToEdit = visit;

    // Update field blocs with visit data
    final category = VisitCategory.values.firstWhere(
      (c) => c.value == visit.category,
    );
    categoryFieldBloc.updateValue(category);
    dateFieldBloc.updateValue(visit.date);
    detailsFieldBloc.updateValue(visit.details);
    hospitalFieldBloc.updateValue(visit.hospitalId);
    departmentFieldBloc.updateValue(visit.departmentId);
    doctorFieldBloc.updateValue(visit.doctorId);
  }

  /// Public method to set up field dependencies after UI is stable
  /// Call this method for Add Visit forms after the UI is rendered
  void setupFieldDependencies() {
    print('DEBUG: Manually setting up field dependencies');
    if (visitToEdit != null) {
      _setupFieldDependencies();
    } else {
      _setupFieldDependenciesForAdd();
    }
  }

  /// Public method to reset form
  void resetForm() {
    categoryFieldBloc.updateValue(VisitCategory.outpatient);
    dateFieldBloc.updateValue(DateTime.now());
    detailsFieldBloc.updateValue('');
    hospitalFieldBloc.updateValue(null);
    departmentFieldBloc.updateValue(null);
    doctorFieldBloc.updateValue(null);
    visitToEdit = null;
  }

  @override
  Future<void> close() async {
    await _hospitalSubscription?.cancel();
    await _departmentSubscription?.cancel();
    return super.close();
  }
}

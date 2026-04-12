import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:app_database/app_database.dart';
import 'package:app_logging/app_logging.dart';
import 'package:app_storage/app_storage.dart';
import 'package:app_utils/field_dependency_helper.dart';
import 'package:drift/drift.dart' show Value;
import 'package:equatable/equatable.dart';
import 'package:duskmoon_form/duskmoon_form.dart';
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

  /// Resource storage service
  final ResourceStorageService _storageService = ResourceStorageService();

  /// Available hospitals for selection
  List<Hospital> availableHospitals = [];

  /// Available departments for selection
  List<Department> availableDepartments = [];

  /// Available doctors for selection
  List<Doctor> availableDoctors = [];

  /// Visit to populate for editing
  Visit? visitToEdit;

  /// Resources associated with this visit
  List<Resource> resources = [];

  /// Field dependency helper for managing cascading field updates
  final _fieldHelper = FieldDependencyHelper();

  /// Refresh hospitals list from database and update dropdown options
  /// Optional parameter to select the most recently added hospital
  Future<void> refreshHospitals({bool selectNewest = false}) async {
    try {
      AppLogger().d('Refreshing hospitals list, selectNewest: $selectNewest');

      // Store current hospital count to identify new hospital
      final previousCount = availableHospitals.length;

      // Reload hospitals from database
      availableHospitals = await _database.getAllHospitals();

      // Update hospital field items - this is the key fix!
      final hospitalItems = [null, ...availableHospitals.map((h) => h.id)];
      AppLogger().d(
        'Updating hospital field items with ${hospitalItems.length} options',
      );
      AppLogger().d(
        'Hospital items before update: ${hospitalFieldBloc.state.items.length}',
      );

      // Ensure current value is valid BEFORE updating items to prevent assertion errors
      final currentValue = hospitalFieldBloc.value;
      var newValue = currentValue;

      if (!hospitalItems.contains(currentValue)) {
        AppLogger().d(
          'Current hospital value $currentValue not in new items, setting to null',
        );
        newValue = null;
      }

      // If requested and a new hospital was added, select the most recent one
      if (selectNewest && availableHospitals.length > previousCount) {
        // Sort by creation date (or assume the last one is the newest)
        final sortedHospitals = List<Hospital>.from(availableHospitals)
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final newestHospital = sortedHospitals.first;

        AppLogger().d('Selecting newly added hospital: ${newestHospital.name}');
        newValue = newestHospital.id;
      }

      // Update items first
      hospitalFieldBloc.updateItems(hospitalItems);
      AppLogger().d(
        'Hospital items after update: ${hospitalFieldBloc.state.items.length}',
      );

      // Then update value if needed
      if (newValue != currentValue) {
        hospitalFieldBloc.updateValue(newValue);
        AppLogger().d('Updated hospital value from $currentValue to $newValue');
      }

      AppLogger().d(
        'Refreshed hospitals with ${availableHospitals.length} items',
      );

      // Update department options since hospital list changed
      await _updateDepartmentOptions();

      // Emit a state change to trigger UI rebuild
      // This ensures the dropdown updates when hospitals are refreshed
      emitLoaded();
    } catch (e) {
      AppLogger().e('Failed to refresh hospitals: $e');
    }
  }

  /// Quick add a new department for the selected hospital
  Future<bool> quickAddDepartment(String name, {String? category}) async {
    try {
      final hospitalId = hospitalFieldBloc.value;
      if (hospitalId == null) {
        AppLogger().w('Cannot add department - no hospital selected');
        return false;
      }

      // Create the department
      final departmentId = await _database.createDepartment(
        DepartmentsCompanion(name: Value(name), category: Value(category)),
      );

      AppLogger().d('Created new department with ID: $departmentId');

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
          AppLogger().e('Error parsing existing departmentIds: $e');
        }
      }

      // Add new department ID
      currentIds.add(departmentId);

      // Update hospital with JSON-encoded department IDs
      await _database.updateHospital(
        hospital.copyWith(departmentIds: json.encode(currentIds)),
      );

      AppLogger().d('Updated hospital with new department ID');

      // Refresh the available departments list
      availableDepartments = await _database.getAllDepartments();

      // Update available hospitals list to reflect the change
      availableHospitals = await _database.getAllHospitals();

      // Update department options to include the new department
      await _updateDepartmentOptions();

      // Select the newly created department
      departmentFieldBloc.updateValue(departmentId);

      return true;
    } catch (e) {
      AppLogger().e('Failed to add department: $e');
      return false;
    }
  }

  /// Quick add a new doctor for the selected hospital and department
  Future<bool> quickAddDoctor(
    String name, {
    String? title,
    String? specialty,
  }) async {
    try {
      final hospitalId = hospitalFieldBloc.value;
      final departmentId = departmentFieldBloc.value;

      if (hospitalId == null) {
        AppLogger().w('Cannot add doctor - no hospital selected');
        return false;
      }

      if (departmentId == null) {
        AppLogger().w('Cannot add doctor - no department selected');
        return false;
      }

      // Create the doctor
      // Combine title and specialty into a level string
      String? doctorLevel;
      if (title != null && specialty != null) {
        doctorLevel = '$title - $specialty';
      } else if (title != null) {
        doctorLevel = title;
      } else if (specialty != null) {
        doctorLevel = specialty;
      }

      final doctorId = await _database.createDoctor(
        DoctorsCompanion(
          name: Value(name),
          hospitalId: Value(hospitalId),
          departmentId: Value(departmentId),
          level: Value(doctorLevel),
        ),
      );

      AppLogger().d('Created new doctor with ID: $doctorId');

      // Refresh the available doctors list
      availableDoctors = await _database.getAllDoctors();

      // Update doctor options to include the new doctor
      _updateDoctorOptions();

      // Select the newly created doctor
      doctorFieldBloc.updateValue(doctorId);

      return true;
    } catch (e) {
      AppLogger().e('Failed to add doctor: $e');
      return false;
    }
  }

  // Stream subscriptions
  StreamSubscription? _hospitalSubscription;
  StreamSubscription? _departmentSubscription;

  VisitFormBloc(this._database, {this.visitToEdit, VisitBloc? visitBloc})
    : _visitBloc = visitBloc,
      super(isLoading: true) {
    AppLogger().d(
      'VisitFormBloc constructor called with visitToEdit: ${visitToEdit?.id}',
    );
    // Add field blocs
    addFieldBloc(fieldBloc: categoryFieldBloc);
    addFieldBloc(fieldBloc: dateFieldBloc);
    addFieldBloc(fieldBloc: detailsFieldBloc);
    addFieldBloc(fieldBloc: hospitalFieldBloc);
    addFieldBloc(fieldBloc: departmentFieldBloc);
    addFieldBloc(fieldBloc: doctorFieldBloc);
    AppLogger().d('VisitFormBloc constructor completed');
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
      AppLogger().d('VisitFormBloc onLoading() started');

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

      AppLogger().d(
        'Loaded ${availableHospitals.length} hospitals, ${availableDepartments.length} departments, ${availableDoctors.length} doctors',
      );

      // Prepare items - always include null as first option
      final hospitalItems = [null, ...availableHospitals.map((h) => h.id)];
      final doctorItems = [null, ...availableDoctors.map((d) => d.id)];

      AppLogger().d(
        'Prepared items - hospitals: ${hospitalItems.length}, doctors: ${doctorItems.length}',
      );

      // CRITICAL: Update items FIRST, then ensure values are valid
      // This prevents dropdown assertion errors by ensuring value always exists in items

      // Update hospital field with safe pattern
      final currentHospitalValue = hospitalFieldBloc.value;
      var newHospitalValue = currentHospitalValue;

      if (!hospitalItems.contains(currentHospitalValue)) {
        AppLogger().d(
          'Hospital value $currentHospitalValue not in items, setting to null',
        );
        newHospitalValue = null;
      }

      hospitalFieldBloc.updateItems(hospitalItems);

      if (newHospitalValue != currentHospitalValue) {
        hospitalFieldBloc.updateValue(newHospitalValue);
        AppLogger().d(
          'Updated hospital value from $currentHospitalValue to $newHospitalValue',
        );
      }

      // Update department field (filtered by hospital)
      await _updateDepartmentOptions();
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

      AppLogger().d('Updated all field items and ensured valid values');

      // Now that items are loaded, populate form with existing visit data if provided
      if (visitToEdit != null) {
        // Load resources for existing visit
        await loadResourcesForVisit(visitToEdit!.id);

        // Use field helper to ensure all field updates are processed
        await _fieldHelper.executeAfterFieldUpdate(() async {
          // Yield to event loop to ensure field updates are processed
          final completer = Completer<void>();
          Timer.run(() => completer.complete());
          return completer.future;
        }, () => _populateFormAfterItemsLoaded());
      }

      // Use emitLoaded to indicate the form is ready for interaction
      emitLoaded();

      // Set up field dependencies differently for Add vs Edit
      if (visitToEdit != null) {
        // For edit visits, set up dependencies using field helper
        _fieldHelper.executeAfterFieldUpdate(() async {
          final completer = Completer<void>();
          Timer.run(() => completer.complete());
          return completer.future;
        }, () => _setupFieldDependencies());
      } else {
        // For add visits, DON'T set up dependencies here
        // They will be set up manually from the UI after a longer delay
        AppLogger().d(
          'Skipping automatic field dependency setup for Add Visit',
        );
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
          final subscription = _visitBloc.stream.listen((state) {
            if (state is VisitOperationSuccess) {
              updateCompleted = true;
            } else if (state is VisitError) {
              errorMessage = state.message;
              updateCompleted = true;
            }
          });

          // Dispatch the update event
          _visitBloc.add(
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

          // Wait for the update to complete using field helper
          await _fieldHelper.waitForCondition(
            () => updateCompleted,
            timeout: const Duration(seconds: 5),
          );

          await subscription.cancel();

          if (errorMessage != null) {
            emitFailure(failureResponse: errorMessage);
          } else if (updateCompleted) {
            // Save resources for the visit
            await _saveResources(visitToEdit!.id);

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

          // Save resources for the visit
          await _saveResources(updatedVisit.id);

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
    AppLogger().d('Setting up field dependencies');

    // Cancel any existing subscriptions to avoid duplicates
    _hospitalSubscription?.cancel();
    _departmentSubscription?.cancel();

    // Listen to hospital field changes with a delay to avoid immediate updates
    _hospitalSubscription = hospitalFieldBloc.stream.listen((_) {
      AppLogger().d(
        'Hospital field changed - clearing department and doctor, updating options',
      );

      // Use a microtask to delay the updates and avoid dropdown assertion errors
      Future.microtask(() async {
        // Update department options filtered by hospital
        await _updateDepartmentOptions();

        // Clear dependent field values AFTER updating items to ensure valid state
        departmentFieldBloc.updateValue(null);
        doctorFieldBloc.updateValue(null);

        // Update doctor options based on new hospital selection
        _updateDoctorOptions();
      });
    });

    // Listen to department field changes with a delay to avoid immediate updates
    _departmentSubscription = departmentFieldBloc.stream.listen((_) {
      AppLogger().d(
        'Department field changed - clearing doctor, updating options',
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
    AppLogger().d(
      'Setting up field dependencies for Add Visit (no immediate triggers)',
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
      if (value.value == initialHospitalValue) {
        AppLogger().d('Skipping initial hospital field value: $value');
        return;
      }

      AppLogger().d(
        'Hospital field changed from $initialHospitalValue to $value - clearing department and doctor, updating options',
      );

      // Use a microtask to delay the updates and avoid dropdown assertion errors
      Future.microtask(() async {
        // Update department options filtered by hospital
        await _updateDepartmentOptions();

        // Clear dependent field values AFTER updating items to ensure valid state
        departmentFieldBloc.updateValue(null);
        doctorFieldBloc.updateValue(null);

        // Update doctor options based on new hospital selection
        _updateDoctorOptions();
      });
    });

    // Listen to department field changes, but skip the initial value
    _departmentSubscription = departmentFieldBloc.stream.listen((value) {
      if (value.value == initialDepartmentValue) {
        AppLogger().d('Skipping initial department field value: $value');
        return;
      }

      AppLogger().d(
        'Department field changed from $initialDepartmentValue to $value - clearing doctor, updating options',
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

  /// Updates doctor options based on current hospital and department filters
  void _updateDoctorOptions() {
    final hospitalId = hospitalFieldBloc.value;
    final departmentId = departmentFieldBloc.value;

    AppLogger().d(
      'Updating doctor options with hospitalId: $hospitalId, departmentId: $departmentId',
    );

    List<Doctor> filteredDoctors = availableDoctors;

    // Filter by hospital if selected
    if (hospitalId != null) {
      filteredDoctors = filteredDoctors
          .where((d) => d.hospitalId == hospitalId)
          .toList();
      AppLogger().d(
        'Filtered doctors by hospital: ${filteredDoctors.length} remaining',
      );
    }

    // Filter by department if selected
    if (departmentId != null) {
      filteredDoctors = filteredDoctors
          .where((d) => d.departmentId == departmentId)
          .toList();
      AppLogger().d(
        'Filtered doctors by department: ${filteredDoctors.length} remaining',
      );
    }

    final doctorItems = [null, ...filteredDoctors.map((d) => d.id)];
    AppLogger().d(
      'Updating doctor field with ${doctorItems.length} items, current doctor value: ${doctorFieldBloc.value}',
    );

    // Ensure current value is valid BEFORE updating items to prevent assertion errors
    final currentValue = doctorFieldBloc.value;
    var newValue = currentValue;

    if (!doctorItems.contains(currentValue)) {
      AppLogger().d(
        'Doctor value $currentValue not in new items, setting to null',
      );
      newValue = null;
    }

    // Update items first
    doctorFieldBloc.updateItems(doctorItems);

    // Then update value if needed
    if (newValue != currentValue) {
      doctorFieldBloc.updateValue(newValue);
      AppLogger().d('Updated doctor value from $currentValue to $newValue');
    }
  }

  /// Updates department options based on current hospital filter
  /// Validates department IDs and cleans up invalid references
  Future<void> _updateDepartmentOptions() async {
    final hospitalId = hospitalFieldBloc.value;

    AppLogger().d('Updating department options with hospitalId: $hospitalId');

    List<Department> filteredDepartments = availableDepartments;
    bool hospitalUpdated = false;

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

          // Validate department IDs and filter out invalid ones
          final validDepartmentIds = <int>[];
          for (final deptId in departmentIds) {
            if (availableDepartments.any((d) => d.id == deptId)) {
              validDepartmentIds.add(deptId);
            } else {
              AppLogger().w(
                'Department ID $deptId not found in available departments, marking for removal',
              );
            }
          }

          // If we found invalid department IDs, update the hospital
          if (validDepartmentIds.length != departmentIds.length) {
            AppLogger().d(
              'Cleaning up ${departmentIds.length - validDepartmentIds.length} invalid department IDs from hospital',
            );

            // Update hospital with cleaned department IDs
            final updatedHospital = hospital.copyWith(
              departmentIds: json.encode(validDepartmentIds),
            );
            await _database.updateHospital(updatedHospital);

            // Update local hospital list
            final hospitalIndex = availableHospitals.indexWhere(
              (h) => h.id == hospitalId,
            );
            if (hospitalIndex != -1) {
              availableHospitals[hospitalIndex] = updatedHospital;
              hospitalUpdated = true;
            }
          }

          // Filter departments by valid department IDs
          filteredDepartments = availableDepartments
              .where((d) => validDepartmentIds.contains(d.id))
              .toList();

          AppLogger().d(
            'Filtered departments by hospital: ${filteredDepartments.length} remaining from ${validDepartmentIds.length} valid department IDs',
          );
        } catch (e) {
          AppLogger().e('Error parsing hospital departmentIds: $e');
          // If parsing fails, show no departments and clear the invalid data
          filteredDepartments = [];

          // Clear invalid departmentIds from hospital
          try {
            final updatedHospital = hospital.copyWith(departmentIds: '');
            await _database.updateHospital(updatedHospital);

            // Update local hospital list
            final hospitalIndex = availableHospitals.indexWhere(
              (h) => h.id == hospitalId,
            );
            if (hospitalIndex != -1) {
              availableHospitals[hospitalIndex] = updatedHospital;
              hospitalUpdated = true;
            }

            AppLogger().d(
              'Cleared invalid departmentIds from hospital due to parsing error',
            );
          } catch (updateError) {
            AppLogger().e(
              'Failed to clear invalid departmentIds: $updateError',
            );
          }
        }
      } else {
        // Hospital has no departments
        filteredDepartments = [];
        AppLogger().d('Hospital has no departments assigned');
      }
    }

    final departmentItems = [null, ...filteredDepartments.map((d) => d.id)];
    AppLogger().d(
      'Updating department field with ${departmentItems.length} items, current department value: ${departmentFieldBloc.value}',
    );

    // Ensure current value is valid BEFORE updating items to prevent assertion errors
    final currentValue = departmentFieldBloc.value;
    var newValue = currentValue;

    if (!departmentItems.contains(currentValue)) {
      AppLogger().d(
        'Department value $currentValue not in new items, setting to null',
      );
      newValue = null;
    }

    // Update items first
    departmentFieldBloc.updateItems(departmentItems);

    // Then update value if needed
    if (newValue != currentValue) {
      departmentFieldBloc.updateValue(newValue);
      AppLogger().d('Updated department value from $currentValue to $newValue');
    }

    // If we updated the hospital, emit a state change to refresh the UI
    if (hospitalUpdated) {
      AppLogger().d(
        'Hospital department IDs were cleaned up, emitting state change',
      );
      emitLoaded();
    }
  }

  /// Internal method to populate form after items are loaded
  Future<void> _populateFormAfterItemsLoaded() async {
    if (visitToEdit == null) return;

    final visit = visitToEdit!;

    AppLogger().d(
      'Populating form with visit data - hospitalId: ${visit.hospitalId}, departmentId: ${visit.departmentId}, doctorId: ${visit.doctorId}',
    );

    // Update field blocs with visit data (non-cascading fields first)
    final category = VisitCategory.values.firstWhere(
      (c) => c.value == visit.category,
    );
    categoryFieldBloc.updateValue(category);
    dateFieldBloc.updateValue(visit.date);
    detailsFieldBloc.updateValue(visit.details);

    // For cascading fields, use field helper to properly sequence updates
    if (visit.hospitalId != null &&
        availableHospitals.any((h) => h.id == visit.hospitalId)) {
      await _fieldHelper.executeCascadingFieldUpdates([
        () async {
          hospitalFieldBloc.updateValue(visit.hospitalId);
          final completer = Completer<void>();
          Timer.run(() => completer.complete());
          return completer.future;
        },
        () async {
          if (visit.departmentId != null &&
              availableDepartments.any((d) => d.id == visit.departmentId)) {
            departmentFieldBloc.updateValue(visit.departmentId);
          }
          final completer = Completer<void>();
          Timer.run(() => completer.complete());
          return completer.future;
        },
        () async {
          if (visit.doctorId != null &&
              availableDoctors.any((d) => d.id == visit.doctorId)) {
            // Check if doctor is valid for current hospital/department filter
            final filteredDoctors = availableDoctors.where((d) {
              final hospitalMatch =
                  visit.hospitalId == null || d.hospitalId == visit.hospitalId;
              final departmentMatch =
                  visit.departmentId == null ||
                  d.departmentId == visit.departmentId;
              return hospitalMatch && departmentMatch;
            }).toList();

            if (filteredDoctors.any((d) => d.id == visit.doctorId)) {
              doctorFieldBloc.updateValue(visit.doctorId);
            } else {
              AppLogger().w(
                'Doctor ${visit.doctorId} is not valid for current filters, setting to null',
              );
              doctorFieldBloc.updateValue(null);
            }
          }
        },
      ]);
    } else {
      AppLogger().w(
        'Hospital ${visit.hospitalId} not found in available hospitals',
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
    AppLogger().d('Manually setting up field dependencies');
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
    resources.clear();
  }

  /// Add a resource to the current visit
  Future<bool> addResource(
    File sourceFile,
    ResourceType type, {
    String? notes,
  }) async {
    try {
      // Create a temporary visit ID if this is a new visit
      // In a real implementation, this should handle the case where visit doesn't exist yet
      int tempVisitId =
          visitToEdit?.id ?? DateTime.now().millisecondsSinceEpoch;

      // Store the file
      final relativePath = await _storageService.storeResourceFile(
        visitId: tempVisitId,
        sourceFile: sourceFile,
        type: type,
      );

      // Create resource record
      final newResource = Resource(
        id: DateTime.now().millisecondsSinceEpoch, // Temporary ID
        visitId: tempVisitId,
        type: type.value, // Convert enum to string
        filePath: relativePath,
        name: null,
        notes: notes,
        rotation: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Add to local resources list
      resources.add(newResource);

      AppLogger().d('Added resource: ${newResource.filePath}');
      return true;
    } catch (e) {
      AppLogger().e('Failed to add resource: $e');
      return false;
    }
  }

  /// Remove a resource from the current visit
  Future<bool> removeResource(Resource resource) async {
    try {
      // Delete file
      await _storageService.deleteResourceFile(resource.filePath);

      // Remove from local list
      resources.removeWhere((r) => r.id == resource.id);

      AppLogger().d('Removed resource: ${resource.filePath}');
      return true;
    } catch (e) {
      AppLogger().e('Failed to remove resource: $e');
      return false;
    }
  }

  /// Save resources to the database for a specific visit
  Future<void> _saveResources(int visitId) async {
    try {
      AppLogger().d('Saving ${resources.length} resources for visit $visitId');

      // Get existing resources from database
      final existingResources = await _database.getResourcesByVisit(visitId);
      final existingResourceIds = existingResources.map((r) => r.id).toSet();

      // Track which resources to keep
      final currentResourceIds = resources.map((r) => r.id).toSet();

      // Delete resources that were removed
      for (final existing in existingResources) {
        if (!currentResourceIds.contains(existing.id)) {
          AppLogger().d('Deleting removed resource: ${existing.filePath}');
          await _database.deleteResource(existing.id);
          // Also delete the file
          await _storageService.deleteResourceFile(existing.filePath);
        }
      }

      // Add or update resources
      for (final resource in resources) {
        // Update visitId if it was temporary (-1)
        final actualVisitId = resource.visitId == -1
            ? visitId
            : resource.visitId;

        if (existingResourceIds.contains(resource.id)) {
          // Update existing resource
          AppLogger().d('Updating existing resource: ${resource.filePath}');
          await _database.updateResource(
            resource.copyWith(
              visitId: actualVisitId,
              updatedAt: DateTime.now(),
            ),
          );
        } else {
          // Create new resource
          AppLogger().d('Creating new resource: ${resource.filePath}');

          // If the resource was created with temporary visit ID, move the file
          if (resource.visitId == -1 && visitId != -1) {
            // Move file from temporary directory to actual visit directory
            final oldFile = await _storageService.getResourceFile(
              resource.filePath,
            );
            if (await oldFile.exists()) {
              // Store with correct visit ID
              // Determine resource type from the stored type string
              ResourceType resourceType;
              switch (resource.type) {
                case 'image':
                  resourceType = ResourceType.image;
                  break;
                case 'video':
                  resourceType = ResourceType.video;
                  break;
                case 'audio':
                  resourceType = ResourceType.audio;
                  break;
                case 'other':
                  resourceType = ResourceType.other;
                  break;
                default:
                  resourceType = ResourceType.document;
              }

              final newRelativePath = await _storageService.storeResourceFile(
                visitId: visitId,
                sourceFile: oldFile,
                type: resourceType,
              );

              // Delete old temporary file
              await _storageService.deleteResourceFile(resource.filePath);

              // Create resource with new path
              await _database.createResource(
                ResourcesCompanion.insert(
                  visitId: visitId,
                  type: resource.type,
                  filePath: newRelativePath,
                  name: Value(resource.name),
                  notes: Value(resource.notes),
                  rotation: Value(resource.rotation),
                  createdAt: Value(resource.createdAt),
                  updatedAt: Value(DateTime.now()),
                ),
              );
            }
          } else {
            // Resource already has correct visit ID, just save to database
            await _database.createResource(
              ResourcesCompanion.insert(
                visitId: actualVisitId,
                type: resource.type,
                filePath: resource.filePath,
                name: Value(resource.name),
                notes: Value(resource.notes),
                rotation: Value(resource.rotation),
                createdAt: Value(resource.createdAt),
                updatedAt: Value(DateTime.now()),
              ),
            );
          }
        }
      }

      AppLogger().d('Successfully saved ${resources.length} resources');

      // Reload resources to get correct IDs from database
      await loadResourcesForVisit(visitId);
    } catch (e, stackTrace) {
      AppLogger().e('Failed to save resources: $e', e, stackTrace);
      throw Exception('Failed to save resources: $e');
    }
  }

  /// Load resources for a specific visit
  Future<void> loadResourcesForVisit(int visitId) async {
    try {
      final visitResources = await _database.getResourcesByVisit(visitId);
      resources = visitResources;
      AppLogger().d('Loaded ${resources.length} resources for visit $visitId');
    } catch (e) {
      AppLogger().e('Failed to load resources for visit $visitId: $e');
      resources = [];
    }
  }

  /// Clear all resources (for new visits)
  void clearResources() {
    resources.clear();
  }

  /// Get resources for the current visit
  List<Resource> getCurrentResources() {
    return List.unmodifiable(resources);
  }

  /// Save resources for a specific visit (public method for AddVisitScreen)
  Future<void> saveResourcesForVisit(int visitId) async {
    await _saveResources(visitId);
  }

  @override
  Future<void> close() async {
    await _hospitalSubscription?.cancel();
    await _departmentSubscription?.cancel();
    _fieldHelper.dispose();
    return super.close();
  }
}

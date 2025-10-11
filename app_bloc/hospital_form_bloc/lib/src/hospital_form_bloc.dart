import 'package:bloc/bloc.dart';

import 'hospital_form_event.dart';
import 'hospital_form_state.dart';

class HospitalFormBloc extends Bloc<HospitalFormEvent, HospitalFormState> {
  HospitalFormBloc() : super(HospitalFormInitial()) {
    on<InitializeForm>(_onInitializeForm);
    on<NameChanged>(_onNameChanged);
    on<AddressChanged>(_onAddressChanged);
    on<TypeChanged>(_onTypeChanged);
    on<LevelChanged>(_onLevelChanged);
    on<FormSubmitted>(_onFormSubmitted);
    on<FormReset>(_onFormReset);
    on<HospitalFormSuccess>(_onHospitalFormSuccess);
    on<HospitalFormFailure>(_onHospitalFormFailure);
  }

  void _onInitializeForm(
    InitializeForm event,
    Emitter<HospitalFormState> emit,
  ) {
    emit(HospitalFormLoadInProgress());

    final name = event.name ?? '';
    final address = event.address ?? '';
    final type = event.type ?? '';
    final level = event.level ?? '';
    final isNameValid = name.trim().isNotEmpty;

    emit(
      HospitalFormLoaded(
        name: name,
        address: address,
        type: type,
        level: level,
        isNameValid: isNameValid,
      ),
    );
  }

  void _onNameChanged(NameChanged event, Emitter<HospitalFormState> emit) {
    if (state is HospitalFormLoaded) {
      final currentState = state as HospitalFormLoaded;
      final isNameValid = event.name.trim().isNotEmpty;
      emit(currentState.copyWith(name: event.name, isNameValid: isNameValid));
    }
  }

  void _onAddressChanged(
    AddressChanged event,
    Emitter<HospitalFormState> emit,
  ) {
    if (state is HospitalFormLoaded) {
      final currentState = state as HospitalFormLoaded;
      emit(currentState.copyWith(address: event.address));
    }
  }

  void _onTypeChanged(TypeChanged event, Emitter<HospitalFormState> emit) {
    if (state is HospitalFormLoaded) {
      final currentState = state as HospitalFormLoaded;
      emit(currentState.copyWith(type: event.type));
    }
  }

  void _onLevelChanged(LevelChanged event, Emitter<HospitalFormState> emit) {
    if (state is HospitalFormLoaded) {
      final currentState = state as HospitalFormLoaded;
      emit(currentState.copyWith(level: event.level));
    }
  }

  void _onFormSubmitted(FormSubmitted event, Emitter<HospitalFormState> emit) {
    if (state is HospitalFormLoaded) {
      final currentState = state as HospitalFormLoaded;
      if (currentState.isNameValid) {
        emit(
          HospitalFormSubmissionInProgress(
            name: currentState.name,
            address: currentState.address,
            type: currentState.type,
            level: currentState.level,
          ),
        );
      }
    }
  }

  void _onFormReset(FormReset event, Emitter<HospitalFormState> emit) {
    emit(
      HospitalFormLoaded(
        name: '',
        address: '',
        type: '',
        level: '',
        isNameValid: false,
      ),
    );
  }

  void _onHospitalFormSuccess(
    HospitalFormSuccess event,
    Emitter<HospitalFormState> emit,
  ) {
    if (state is HospitalFormSubmissionInProgress) {
      emit(HospitalFormSubmissionSuccess('Hospital added successfully!'));
    }
  }

  void _onHospitalFormFailure(
    HospitalFormFailure event,
    Emitter<HospitalFormState> emit,
  ) {
    if (state is HospitalFormSubmissionInProgress) {
      final currentState = state as HospitalFormSubmissionInProgress;
      emit(
        HospitalFormSubmissionFailure(
          error: event.error,
          name: currentState.name,
          address: currentState.address,
          type: currentState.type,
          level: currentState.level,
        ),
      );
    }
  }

  // Helper method to check if form is valid
  bool get isFormValid {
    if (state is HospitalFormLoaded) {
      final currentState = state as HospitalFormLoaded;
      return currentState.isNameValid;
    }
    return false;
  }

  // Helper method to handle successful submission
  void handleSubmissionSuccess() {
    add(HospitalFormSuccess());
  }

  // Helper method to handle submission failure
  void handleSubmissionFailure(String error) {
    add(HospitalFormFailure(error));
  }

  // Helper method to get current form data
  Map<String, String?> get formData {
    if (state is HospitalFormLoaded) {
      final currentState = state as HospitalFormLoaded;
      return {
        'name': currentState.name.trim().isEmpty
            ? null
            : currentState.name.trim(),
        'address': currentState.address.trim().isEmpty
            ? null
            : currentState.address.trim(),
        'type': currentState.type.trim().isEmpty
            ? null
            : currentState.type.trim(),
        'level': currentState.level.trim().isEmpty
            ? null
            : currentState.level.trim(),
      };
    } else if (state is HospitalFormSubmissionInProgress) {
      final currentState = state as HospitalFormSubmissionInProgress;
      return {
        'name': currentState.name.trim().isEmpty
            ? null
            : currentState.name.trim(),
        'address': currentState.address.trim().isEmpty
            ? null
            : currentState.address.trim(),
        'type': currentState.type.trim().isEmpty
            ? null
            : currentState.type.trim(),
        'level': currentState.level.trim().isEmpty
            ? null
            : currentState.level.trim(),
      };
    }
    return {};
  }
}

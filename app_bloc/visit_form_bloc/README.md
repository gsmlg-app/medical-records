# Visit Form BLoC

A BLoC for managing visit form state and validation in the medical records app.

## Features

- Form validation for visit fields (category, date, details)
- Real-time form validity checking
- State management for all visit form inputs
- Support for optional fields (hospital, department, doctor, additional information)
- Reset and populate functionality

## Usage

```dart
BlocProvider(
  create: (_) => VisitFormBloc(),
  child: VisitForm(...),
)
```

## State Management

The BLoC manages the following state:

- `category`: Visit category (outpatient/inpatient)
- `date`: Visit date (required)
- `details`: Visit details (required)
- `hospitalId`: Optional hospital reference
- `departmentId`: Optional department reference
- `doctorId`: Optional doctor reference
- `informations`: Additional information (JSON)

## Events

- `VisitFormCategoryChanged`
- `VisitFormDateChanged`
- `VisitFormDetailsChanged`
- `VisitFormHospitalIdChanged`
- `VisitFormDepartmentIdChanged`
- `VisitFormDoctorIdChanged`
- `VisitFormInformationsChanged`
- `VisitFormPopulate`
- `VisitFormReset`
# Bloc package treatment_form

## Getting started

Import package in project.

```yaml
treatment_form_bloc: any
```

## Usage

Import bloc in provider

```dart
import 'package:treatment_form_bloc/treatment_form_bloc.dart';


BlocProvider<TreatmentFormBloc>(
    create: (BuildContext context) => TreatmentFormBloc(),
),

```

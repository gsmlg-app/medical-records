# Bloc package treatment

## Getting started

Import package in project.

```yaml
treatment_bloc: any
```

## Usage

Import bloc in provider

```dart
import 'package:treatment_bloc/treatment_bloc.dart';


BlocProvider<TreatmentBloc>(
    create: (BuildContext context) => TreatmentBloc(),
),

```

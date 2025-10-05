# Bloc package visit

## Getting started

Import package in project.

```yaml
visit_bloc: any
```

## Usage

Import bloc in provider

```dart
import 'package:visit_bloc/visit_bloc.dart';


BlocProvider<VisitBloc>(
    create: (BuildContext context) => VisitBloc(),
),

```

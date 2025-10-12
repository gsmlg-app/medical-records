import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:form_bloc/form_bloc.dart';
import 'package:visit_form_bloc/visit_form_bloc.dart';
import 'package:app_resources/app_resources.dart';

/// Resources section widget that wraps the ResourcesSection component
class ResourcesSectionWrapper extends StatelessWidget {
  const ResourcesSectionWrapper({required this.visitFormBloc});

  final VisitFormBloc visitFormBloc;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VisitFormBloc, FormBlocState<String, String>>(
      builder: (context, state) {
        return ResourcesSection(
          visitId: visitFormBloc.visitToEdit?.id,
          resources: visitFormBloc.getCurrentResources(),
          onResourcesChanged: (resources) {
            // Resources are managed locally in the bloc
            // The form submission will handle saving them to the database
          },
          isReadOnly: false, // Allow adding/removing resources
        );
      },
    );
  }
}
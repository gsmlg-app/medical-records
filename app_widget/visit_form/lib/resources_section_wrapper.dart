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
          // Pass a modifiable copy of the resources list to avoid
          // "unsupported operation: cannot add to an unmodifiable list" error
          resources: List.from(visitFormBloc.getCurrentResources()),
          onResourcesChanged: (resources) {
            // Update the VisitFormBloc's resource list when resources change
            visitFormBloc.resources.clear();
            visitFormBloc.resources.addAll(resources);
            // Trigger a rebuild to reflect the updated resource count
            visitFormBloc.emitLoaded();
          },
          isReadOnly: false, // Allow adding/removing resources
        );
      },
    );
  }
}

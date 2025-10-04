import 'package:app_adaptive_widgets/app_adaptive_widgets.dart';
import 'package:app_locale/app_locale.dart';
import 'package:flutter/material.dart';
import 'package:medical_records/destination.dart';

class TreatmentsScreen extends StatelessWidget {
  static const name = 'Treatments';
  static const path = '/treatments';

  const TreatmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppAdaptiveScaffold(
      selectedIndex: Destinations.indexOf(const Key(name), context),
      onSelectedIndexChange: (idx) => Destinations.changeHandler(
        idx,
        context,
      ),
      destinations: Destinations.navs(context),
      body: (context) => SafeArea(
        child: CustomScrollView(
          slivers: <Widget>[
            SliverAppBar(
              title: Text(context.l10n.treatmentsTitle),
              floating: true,
            ),
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.medical_services_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.l10n.noTreatments,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Navigate to add treatment screen
                      },
                      icon: const Icon(Icons.add),
                      label: Text(context.l10n.addTreatment),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      smallSecondaryBody: AdaptiveScaffold.emptyBuilder,
    );
  }
}
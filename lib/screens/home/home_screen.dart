import 'package:app_adaptive_widgets/app_adaptive_widgets.dart';
import 'package:app_artwork/app_artwork.dart';
import 'package:app_locale/app_locale.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:medical_records/destination.dart';

class HomeScreen extends StatelessWidget {
  static const name = 'Home Screen';
  static const path = '/home';

  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    double w = screenWidth;
    if (screenHeight < screenWidth) {
      w = screenHeight;
    }

    return AppAdaptiveScaffold(
      selectedIndex: Destinations.indexOf(const Key(HomeScreen.name), context),
      onSelectedIndexChange: (idx) => Destinations.changeHandler(
        idx,
        context,
      ),
      destinations: Destinations.navs(context),
      appBar: AppBar(
        title: Text(context.l10n.appName),
        centerTitle: true,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // App Header
              Center(
                child: Column(
                  children: [
                    LaddingPageLottie(
                      width: w * 0.2,
                      height: w * 0.2,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.l10n.appName,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: Text(
                        context.l10n.appDescription,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),

              // Quick Actions
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Quick Access',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Card(
                            child: InkWell(
                              onTap: () => context.goNamed('TreatmentsScreen'),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.medical_services_outlined,
                                      size: 48,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      context.l10n.treatmentsTitle,
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      context.l10n.viewTreatments,
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Card(
                            child: InkWell(
                              onTap: () => context.goNamed('HospitalsScreen'),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.local_hospital_outlined,
                                      size: 48,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      context.l10n.hospitalsTitle,
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      context.l10n.viewHospitals,
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:app_adaptive_widgets/app_adaptive_widgets.dart';
import 'package:app_locale/app_locale.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hospital_bloc/hospital_bloc.dart';
import 'package:medical_records/destination.dart';
import 'package:medical_records/screens/hospitals/widgets/hospital_list_item.dart';
import 'package:medical_records/screens/hospitals/add_hospital_screen.dart';

class HospitalsScreen extends StatefulWidget {
  static const name = 'Hospitals';
  static const path = '/hospitals';

  const HospitalsScreen({super.key});

  @override
  State<HospitalsScreen> createState() => _HospitalsScreenState();
}

class _HospitalsScreenState extends State<HospitalsScreen> {
  @override
  void initState() {
    super.initState();
    // Load hospitals when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HospitalBloc>().add(LoadHospitals());
    });
  }

  void _addHospital() {
    context.goNamed(AddHospitalScreen.name);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HospitalBloc, HospitalState>(
      listener: (context, state) {
        if (state is HospitalOperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        } else if (state is HospitalError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          floatingActionButton:
              state is HospitalLoaded && state.hospitals.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 80),
                      child: FloatingActionButton(
                        onPressed: _addHospital,
                        child: const Icon(Icons.add),
                      ),
                    )
                  : null,
          body: AppAdaptiveScaffold(
            selectedIndex:
                Destinations.indexOf(const Key(HospitalsScreen.name), context),
            onSelectedIndexChange: (idx) => Destinations.changeHandler(
              idx,
              context,
            ),
            destinations: Destinations.navs(context),
            body: (context) => SafeArea(
              child: CustomScrollView(
                slivers: <Widget>[
                  SliverAppBar(
                    title: Text(context.l10n.hospitalsTitle),
                    floating: true,
                  ),
                  _buildContent(context, state),
                  // Add bottom padding to prevent FAB from covering the last item
                  const SliverPadding(
                    padding: EdgeInsets.only(bottom: 80),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, HospitalState state) {
    if (state is HospitalLoading || state is HospitalInitial) {
      return const SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (state is HospitalLoaded) {
      if (state.hospitals.isEmpty) {
        return SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.local_hospital_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  context.l10n.noHospitals,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _addHospital,
                  icon: const Icon(Icons.add),
                  label: Text(context.l10n.addHospital),
                ),
              ],
            ),
          ),
        );
      }

      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final hospital = state.hospitals[index];
            return HospitalListItem(hospital: hospital);
          },
          childCount: state.hospitals.length,
        ),
      );
    }

    if (state is HospitalError) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                state.message,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  context.read<HospitalBloc>().add(LoadHospitals());
                },
                child: Text(context.l10n.retry),
              ),
            ],
          ),
        ),
      );
    }

    return const SliverFillRemaining(
      child: Center(
        child: Text('An unexpected error occurred.'),
      ),
    );
  }
}
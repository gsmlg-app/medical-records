import 'package:app_database/app_database.dart';
import 'package:app_feedback/app_feedback.dart';
import 'package:app_locale/app_locale.dart';
import 'package:duskmoon_widgets/duskmoon_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hospital_bloc/hospital_bloc.dart';
import 'package:intl/intl.dart';
import 'package:medical_records/screens/hospitals/edit_hospital_screen.dart';

class HospitalListItem extends StatelessWidget {
  final Hospital hospital;

  const HospitalListItem({
    super.key,
    required this.hospital,
  });

  void _editHospital(BuildContext context) {
    context.goNamed(EditHospitalScreen.name, pathParameters: {'id': hospital.id.toString()});
  }

  void _manageDepartmentsAndDoctors(BuildContext context) {
    context.goNamed('DepartmentAndDoctor', pathParameters: {'id': hospital.id.toString()});
  }

  void _deleteHospital(BuildContext context) {
    showDmDialog(
      context: context,
      title: Text(context.l10n.deleteHospital),
      content: Text(context.l10n.deleteHospitalConfirmation),
      actions: [
        DmButton(
          onPressed: () => context.pop(),
          variant: DmButtonVariant.text,
          child: Text(context.l10n.cancel),
        ),
        DmButton(
          onPressed: () {
            context.pop();
            context.read<HospitalBloc>().add(DeleteHospital(hospital.id));
          },
          variant: DmButtonVariant.text,
          child: Text(
            context.l10n.delete,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final errorColor = Theme.of(context).colorScheme.error;
    final onErrorColor = Theme.of(context).colorScheme.onError;

    return DmCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Dismissible(
        key: Key(hospital.id.toString()),
        direction: DismissDirection.endToStart,
        background: Container(
          color: errorColor,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 16),
          child: Icon(
            Icons.delete,
            color: onErrorColor,
            size: 24,
          ),
        ),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.endToStart) {
            _deleteHospital(context);
            return false; // Don't dismiss, let the BLoC handle it
          }
          return false;
        },
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Icon(
              Icons.local_hospital,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          title: Text(
            hospital.name,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hospital.address != null && hospital.address!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        hospital.address!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ),
                  ],
                ),
              ],
              if (hospital.type != null && hospital.type!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.business_outlined,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      hospital.type!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ],
              if (hospital.level != null && hospital.level!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.star_outline,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      hospital.level!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Text(
                'Added ${DateFormat('MMM dd, yyyy').format(hospital.createdAt)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
            ],
          ),
          trailing: PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  _editHospital(context);
                  break;
                case 'departments_doctors':
                  _manageDepartmentsAndDoctors(context);
                  break;
                case 'delete':
                  _deleteHospital(context);
                  break;
              }
            },
            itemBuilder: (context) {
              final menuErrorColor = Theme.of(context).colorScheme.error;
              return [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      const Icon(Icons.edit_outlined),
                      const SizedBox(width: 8),
                      Text(context.l10n.edit),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'departments_doctors',
                  child: Row(
                    children: [
                      const Icon(Icons.medical_services_outlined),
                      const SizedBox(width: 8),
                      Text(context.l10n.departmentAndDoctor),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: menuErrorColor),
                      const SizedBox(width: 8),
                      Text(context.l10n.delete, style: TextStyle(color: menuErrorColor)),
                    ],
                  ),
                ),
              ];
            },
          ),
          onTap: () => _editHospital(context),
        ),
      ),
    );
  }
}

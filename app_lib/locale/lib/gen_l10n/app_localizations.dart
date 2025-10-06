import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen_l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Medical Records'**
  String get appName;

  /// No description provided for @errorOccurred.
  ///
  /// In en, this message translates to:
  /// **'Error Occurred'**
  String get errorOccurred;

  /// No description provided for @backToHome.
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get backToHome;

  /// No description provided for @welcomeHome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to my app'**
  String get welcomeHome;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navTreatments.
  ///
  /// In en, this message translates to:
  /// **'Treatments'**
  String get navTreatments;

  /// No description provided for @navHospitals.
  ///
  /// In en, this message translates to:
  /// **'Hospitals'**
  String get navHospitals;

  /// No description provided for @navSetting.
  ///
  /// In en, this message translates to:
  /// **'Setting'**
  String get navSetting;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Setting'**
  String get settingsTitle;

  /// No description provided for @smenuTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get smenuTheme;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @accentColor.
  ///
  /// In en, this message translates to:
  /// **'Accent Color'**
  String get accentColor;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @appDescription.
  ///
  /// In en, this message translates to:
  /// **'Manage your medical records, treatments, and hospital information in one place.'**
  String get appDescription;

  /// No description provided for @treatmentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Treatments'**
  String get treatmentsTitle;

  /// No description provided for @hospitalsTitle.
  ///
  /// In en, this message translates to:
  /// **'Hospitals'**
  String get hospitalsTitle;

  /// No description provided for @viewTreatments.
  ///
  /// In en, this message translates to:
  /// **'View Treatments'**
  String get viewTreatments;

  /// No description provided for @viewHospitals.
  ///
  /// In en, this message translates to:
  /// **'View Hospitals'**
  String get viewHospitals;

  /// No description provided for @noTreatments.
  ///
  /// In en, this message translates to:
  /// **'No treatments added yet'**
  String get noTreatments;

  /// No description provided for @noHospitals.
  ///
  /// In en, this message translates to:
  /// **'No hospitals added yet'**
  String get noHospitals;

  /// No description provided for @addTreatment.
  ///
  /// In en, this message translates to:
  /// **'Add Treatment'**
  String get addTreatment;

  /// No description provided for @addHospital.
  ///
  /// In en, this message translates to:
  /// **'Add Hospital'**
  String get addHospital;

  /// No description provided for @editHospital.
  ///
  /// In en, this message translates to:
  /// **'Edit Hospital'**
  String get editHospital;

  /// No description provided for @deleteHospital.
  ///
  /// In en, this message translates to:
  /// **'Delete Hospital'**
  String get deleteHospital;

  /// No description provided for @deleteHospitalConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this hospital?'**
  String get deleteHospitalConfirmation;

  /// No description provided for @hospitalName.
  ///
  /// In en, this message translates to:
  /// **'Hospital Name'**
  String get hospitalName;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @hospitalType.
  ///
  /// In en, this message translates to:
  /// **'Hospital Type'**
  String get hospitalType;

  /// No description provided for @hospitalTypeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., General Hospital, Specialty Hospital'**
  String get hospitalTypeHint;

  /// No description provided for @hospitalLevel.
  ///
  /// In en, this message translates to:
  /// **'Hospital Level'**
  String get hospitalLevel;

  /// No description provided for @hospitalLevelHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Class A Grade 3, Class B Grade 2'**
  String get hospitalLevelHint;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get fieldRequired;

  /// No description provided for @hospitalAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Hospital added successfully'**
  String get hospitalAddedSuccess;

  /// No description provided for @hospitalUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Hospital updated successfully'**
  String get hospitalUpdatedSuccess;

  /// No description provided for @hospitalDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Hospital deleted successfully'**
  String get hospitalDeletedSuccess;

  /// No description provided for @departmentAndDoctor.
  ///
  /// In en, this message translates to:
  /// **'Department & Doctor'**
  String get departmentAndDoctor;

  /// No description provided for @departmentAndDoctorTitle.
  ///
  /// In en, this message translates to:
  /// **'Department & Doctor Management'**
  String get departmentAndDoctorTitle;

  /// No description provided for @departments.
  ///
  /// In en, this message translates to:
  /// **'Departments'**
  String get departments;

  /// No description provided for @doctors.
  ///
  /// In en, this message translates to:
  /// **'Doctors'**
  String get doctors;

  /// No description provided for @addDepartment.
  ///
  /// In en, this message translates to:
  /// **'Add Department'**
  String get addDepartment;

  /// No description provided for @addDoctor.
  ///
  /// In en, this message translates to:
  /// **'Add Doctor'**
  String get addDoctor;

  /// No description provided for @departmentName.
  ///
  /// In en, this message translates to:
  /// **'Department Name'**
  String get departmentName;

  /// No description provided for @doctorName.
  ///
  /// In en, this message translates to:
  /// **'Doctor Name'**
  String get doctorName;

  /// No description provided for @departmentCategory.
  ///
  /// In en, this message translates to:
  /// **'Department Category'**
  String get departmentCategory;

  /// No description provided for @doctorTitle.
  ///
  /// In en, this message translates to:
  /// **'Doctor Title'**
  String get doctorTitle;

  /// No description provided for @manageDepartments.
  ///
  /// In en, this message translates to:
  /// **'Manage Departments'**
  String get manageDepartments;

  /// No description provided for @manageDoctors.
  ///
  /// In en, this message translates to:
  /// **'Manage Doctors'**
  String get manageDoctors;

  /// No description provided for @noDepartments.
  ///
  /// In en, this message translates to:
  /// **'No departments assigned yet'**
  String get noDepartments;

  /// No description provided for @noDoctors.
  ///
  /// In en, this message translates to:
  /// **'No doctors assigned yet'**
  String get noDoctors;

  /// No description provided for @departmentAssignedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Department assigned successfully'**
  String get departmentAssignedSuccess;

  /// No description provided for @departmentRemovedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Department removed successfully'**
  String get departmentRemovedSuccess;

  /// No description provided for @departmentAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Department added successfully'**
  String get departmentAddedSuccess;

  /// No description provided for @departmentUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Department updated successfully'**
  String get departmentUpdatedSuccess;

  /// No description provided for @doctorAssignedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Doctor assigned successfully'**
  String get doctorAssignedSuccess;

  /// No description provided for @doctorRemovedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Doctor removed successfully'**
  String get doctorRemovedSuccess;

  /// No description provided for @doctorAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Doctor added successfully'**
  String get doctorAddedSuccess;

  /// No description provided for @doctorUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Doctor updated successfully'**
  String get doctorUpdatedSuccess;

  /// No description provided for @treatmentTitle.
  ///
  /// In en, this message translates to:
  /// **'Treatment Title'**
  String get treatmentTitle;

  /// No description provided for @diagnosis.
  ///
  /// In en, this message translates to:
  /// **'Diagnosis'**
  String get diagnosis;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get startDate;

  /// No description provided for @endDate.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get endDate;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @editTreatment.
  ///
  /// In en, this message translates to:
  /// **'Edit Treatment'**
  String get editTreatment;

  /// No description provided for @deleteTreatment.
  ///
  /// In en, this message translates to:
  /// **'Delete Treatment'**
  String get deleteTreatment;

  /// No description provided for @deleteTreatmentConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this treatment?'**
  String get deleteTreatmentConfirmation;

  /// No description provided for @treatmentDetails.
  ///
  /// In en, this message translates to:
  /// **'Treatment Details'**
  String get treatmentDetails;

  /// No description provided for @treatmentAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Treatment added successfully'**
  String get treatmentAddedSuccess;

  /// No description provided for @treatmentUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Treatment updated successfully'**
  String get treatmentUpdatedSuccess;

  /// No description provided for @treatmentDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Treatment deleted successfully'**
  String get treatmentDeletedSuccess;

  /// No description provided for @visits.
  ///
  /// In en, this message translates to:
  /// **'Visits'**
  String get visits;

  /// No description provided for @noVisits.
  ///
  /// In en, this message translates to:
  /// **'No visits added yet'**
  String get noVisits;

  /// No description provided for @noVisitsForTreatment.
  ///
  /// In en, this message translates to:
  /// **'No visits for this treatment'**
  String get noVisitsForTreatment;

  /// No description provided for @addFirstVisit.
  ///
  /// In en, this message translates to:
  /// **'Add your first visit to track your progress'**
  String get addFirstVisit;

  /// No description provided for @addFirstVisitHint.
  ///
  /// In en, this message translates to:
  /// **'Add your first visit to get started'**
  String get addFirstVisitHint;

  /// No description provided for @addVisit.
  ///
  /// In en, this message translates to:
  /// **'Add Visit'**
  String get addVisit;

  /// No description provided for @visitCategory.
  ///
  /// In en, this message translates to:
  /// **'Visit Category'**
  String get visitCategory;

  /// No description provided for @outpatient.
  ///
  /// In en, this message translates to:
  /// **'Outpatient'**
  String get outpatient;

  /// No description provided for @inpatient.
  ///
  /// In en, this message translates to:
  /// **'Inpatient'**
  String get inpatient;

  /// No description provided for @visitDate.
  ///
  /// In en, this message translates to:
  /// **'Visit Date'**
  String get visitDate;

  /// No description provided for @visitDetails.
  ///
  /// In en, this message translates to:
  /// **'Visit Details'**
  String get visitDetails;

  /// No description provided for @selectHospital.
  ///
  /// In en, this message translates to:
  /// **'Select Hospital (Optional)'**
  String get selectHospital;

  /// No description provided for @selectDepartment.
  ///
  /// In en, this message translates to:
  /// **'Select Department (Optional)'**
  String get selectDepartment;

  /// No description provided for @selectDoctor.
  ///
  /// In en, this message translates to:
  /// **'Select Doctor (Optional)'**
  String get selectDoctor;

  /// No description provided for @additionalInfo.
  ///
  /// In en, this message translates to:
  /// **'Additional Information (Optional)'**
  String get additionalInfo;

  /// No description provided for @loadVisits.
  ///
  /// In en, this message translates to:
  /// **'Load Visits'**
  String get loadVisits;

  /// No description provided for @visitAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Visit added successfully'**
  String get visitAddedSuccess;

  /// No description provided for @visitUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Visit updated successfully'**
  String get visitUpdatedSuccess;

  /// No description provided for @visitDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Visit deleted successfully'**
  String get visitDeletedSuccess;

  /// No description provided for @editVisit.
  ///
  /// In en, this message translates to:
  /// **'Edit Visit'**
  String get editVisit;

  /// No description provided for @deleteVisit.
  ///
  /// In en, this message translates to:
  /// **'Delete Visit'**
  String get deleteVisit;

  /// No description provided for @deleteVisitConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this visit?'**
  String get deleteVisitConfirmation;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}

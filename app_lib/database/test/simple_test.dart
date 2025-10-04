import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:matcher/matcher.dart' as m;
import '../lib/src/database.dart';

void main() {
  group('Simple Database Tests', () {
    late AppDatabase database;

    setUp(() {
      database = AppDatabase.forTesting();
    });

    tearDown(() async {
      await database.close();
    });

    test('should create and retrieve a department', () async {
      // Arrange
      final department = DepartmentsCompanion.insert(
        name: 'Cardiology',
        category: Value('Clinical Department'),
      );

      // Act
      final id = await database.createDepartment(department);
      final retrievedDepartment = await database.getDepartmentById(id);

      // Assert
      expect(retrievedDepartment, m.isNotNull);
      expect(retrievedDepartment!.name, equals('Cardiology'));
      expect(retrievedDepartment.category, equals('Clinical Department'));
    });

    test('should create and retrieve a hospital', () async {
      // Arrange
      final hospital = HospitalsCompanion.insert(
        name: 'General Hospital',
        address: Value('123 Main St'),
        departmentIds: '',
      );

      // Act
      final id = await database.createHospital(hospital);
      final retrievedHospital = await database.getHospitalById(id);

      // Assert
      expect(retrievedHospital, m.isNotNull);
      expect(retrievedHospital!.name, equals('General Hospital'));
      expect(retrievedHospital.address, equals('123 Main St'));
      expect(retrievedHospital.departmentIds, equals(''));
    });

    
    test('should get all departments', () async {
      // Arrange
      await database.createDepartment(DepartmentsCompanion.insert(name: 'Cardiology'));
      await database.createDepartment(DepartmentsCompanion.insert(name: 'Neurology'));
      await database.createDepartment(DepartmentsCompanion.insert(name: 'Pediatrics'));

      // Act
      final departments = await database.getAllDepartments();

      // Assert
      expect(departments.length, equals(3));
      expect(departments.map((d) => d.name), contains('Cardiology'));
      expect(departments.map((d) => d.name), contains('Neurology'));
      expect(departments.map((d) => d.name), contains('Pediatrics'));
    });
  });
}
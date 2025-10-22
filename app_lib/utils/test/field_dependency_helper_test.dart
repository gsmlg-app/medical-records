import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_utils/field_dependency_helper.dart';

void main() {
  group('FieldDependencyHelper', () {
    late FieldDependencyHelper helper;

    setUp(() {
      helper = FieldDependencyHelper();
    });

    tearDown(() {
      helper.dispose();
    });

    test(
      'executeAfterFieldUpdate should execute callback after field update',
      () async {
        var callbackExecuted = false;
        var fieldUpdateCompleted = false;

        await helper.executeAfterFieldUpdate(
          () async {
            fieldUpdateCompleted = true;
          },
          () {
            callbackExecuted = true;
          },
        );

        expect(fieldUpdateCompleted, isTrue);
        expect(callbackExecuted, isTrue);
      },
    );

    test(
      'executeCascadingFieldUpdates should execute updates in sequence',
      () async {
        final executionOrder = <int>[];

        await helper.executeCascadingFieldUpdates([
          () async {
            executionOrder.add(1);
          },
          () async {
            executionOrder.add(2);
          },
          () async {
            executionOrder.add(3);
          },
        ]);

        expect(executionOrder, equals([1, 2, 3]));
      },
    );

    test('waitForCondition should return true when condition is met', () async {
      var conditionMet = false;

      // Simulate condition becoming true after a delay
      Timer(const Duration(milliseconds: 50), () {
        conditionMet = true;
      });

      final result = await helper.waitForCondition(
        () => conditionMet,
        timeout: const Duration(seconds: 1),
      );

      expect(result, isTrue);
    });

    test(
      'waitForCondition should return false when timeout is reached',
      () async {
        final result = await helper.waitForCondition(
          () => false, // Condition never becomes true
          timeout: const Duration(milliseconds: 100),
        );

        expect(result, isFalse);
      },
    );

    test(
      'createAutoDisposeSubscription should create and manage subscription',
      () async {
        final controller = StreamController<int>();
        final receivedValues = <int>[];

        helper.createAutoDisposeSubscription<int>(
          controller.stream,
          (value) => receivedValues.add(value),
        );

        controller.add(1);
        controller.add(2);
        await controller.close();

        // Wait for stream processing
        await Future.delayed(const Duration(milliseconds: 10));

        expect(receivedValues, equals([1, 2]));
      },
    );

    test('dispose should clean up all resources', () async {
      final controller = StreamController<int>();

      // Create a subscription that will be disposed
      helper.createAutoDisposeSubscription<int>(controller.stream, (value) {});

      helper.dispose();

      // After dispose, new subscriptions should still work but old ones are cancelled
      await controller.close();
    });
  });
}

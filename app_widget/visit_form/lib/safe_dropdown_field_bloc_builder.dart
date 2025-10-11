import 'package:flutter/material.dart';
import 'package:flutter_form_bloc/flutter_form_bloc.dart';
import 'package:form_bloc/form_bloc.dart';

/// A safe dropdown field bloc builder that avoids assertion errors
/// by ensuring valid state during widget initialization
class SafeDropdownFieldBlocBuilder<T> extends StatefulWidget {
  const SafeDropdownFieldBlocBuilder({
    super.key,
    required this.selectFieldBloc,
    this.decoration,
    required this.itemBuilder,
    this.isEnabled = true,
    this.nextFocusNode,
    this.onChanged,
  });

  final SelectFieldBloc<T, dynamic> selectFieldBloc;
  final InputDecoration? decoration;
  final Widget Function(BuildContext, T) itemBuilder;
  final bool isEnabled;
  final FocusNode? nextFocusNode;
  final void Function(T)? onChanged;

  @override
  State<SafeDropdownFieldBlocBuilder<T>> createState() =>
      _SafeDropdownFieldBlocBuilderState<T>();
}

class _SafeDropdownFieldBlocBuilderState<T>
    extends State<SafeDropdownFieldBlocBuilder<T>> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<
      SelectFieldBloc<T, dynamic>,
      SelectFieldBlocState<T, dynamic>
    >(
      bloc: widget.selectFieldBloc,
      builder: (context, state) {
        // Only render when we have valid items
        if (state.items.isEmpty) {
          return InputDecorator(
            decoration: widget.decoration ?? const InputDecoration(),
            child: const Text('Loading...'),
          );
        }

        // Ensure we have a valid value - this is the key fix
        T? currentValue;
        if (state.value != null && state.items.contains(state.value)) {
          currentValue = state.value;
        } else if (state.items.isNotEmpty) {
          currentValue = state.items.first;
        }

        return DropdownButtonFormField<T>(
          value: currentValue,
          decoration: widget.decoration,
          items: state.items.map((item) {
            return DropdownMenuItem<T>(
              value: item,
              child: widget.itemBuilder(context, item),
            );
          }).toList(),
          onChanged: widget.isEnabled
              ? (T? newValue) {
                  if (newValue != null) {
                    widget.selectFieldBloc.updateValue(newValue);
                    widget.onChanged?.call(newValue);
                  }
                }
              : null,
        );
      },
    );
  }
}

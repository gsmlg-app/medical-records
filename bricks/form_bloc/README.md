# {{name.pascalCase()}} Form BLoC

A Form BLoC for handling {{name.sentenceCase()}} form validation and submission using the `duskmoon_form` package.

## Features

- ✅ Field validation with built-in validators
- ✅ Form submission with loading states
- ✅ Error handling and success responses
- ✅ Form reset functionality
- ✅ Comprehensive test coverage

## Usage

### Basic Usage

```dart
BlocProvider(
  create: (context) => {{name.pascalCase()}}FormBloc(),
  child: {{name.pascalCase()}}FormScreen(),
)
```

### Form Fields

{% for field in field_names %}
- `{{field.pascalCase()}}`: {{field}} input field{% if has_validation %} with validation{% endif %}
{% endfor %}

### Form Submission

```dart
context.read<{{name.pascalCase()}}FormBloc>().add(
  const {{name.pascalCase()}}FormEventSubmitted(),
);
```

### Form Reset

```dart
context.read<{{name.pascalCase()}}FormBloc>().add(
  const {{name.pascalCase()}}FormEventReset(),
);
```

## Form Field Builders

Use the `DmTextFieldBlocBuilder` from `duskmoon_form` to build form fields:

```dart
DmTextFieldBlocBuilder(
  textFieldBloc: context.read<{{name.pascalCase()}}FormBloc>().{{field_names.first.camelCase()}}FieldBloc,
  decoration: const InputDecoration(
    labelText: '{{field_names.first.pascalCase()}}',
  ),
)
```

## Testing

Run the test suite:

```bash
flutter test
```

## Implementation Notes

1. **Customize Validation**: Modify field validators in the BLoC constructor
2. **Implement Submission**: Update the `_submitForm` method with your actual submission logic
3. **Add Fields**: Add new fields to the `field_names` variable and regenerate
4. **Custom Events**: Add custom events for specific form interactions

## Dependencies

- `duskmoon_form`: Form state management and adaptive form widgets
- `bloc`: State management
- `equatable`: Value equality
# FormBloc Usage Pattern

## 1. FormBloc Initialization

```dart
class MyFormBloc extends FormBloc<String, String> {
  final MyDatabase _database;
  
  MyFormBloc(this._database) : super() {
    // Add field blocs in constructor
    addFieldBloc(fieldBloc: nameFieldBloc);
    addFieldBloc(fieldBloc: categoryFieldBloc);
    
    // onLoading() is automatically called when FormBloc is created
  }

  // Field blocs with proper initialization
  late final nameFieldBloc = TextFieldBloc(
    name: 'name',
    validators: [FieldBlocValidators.required],
  );

  late final categoryFieldBloc = SelectFieldBloc<MyCategory, dynamic>(
    name: 'category',
    items: MyCategory.values, // Ensure items are unique
    initialValue: MyCategory.defaultOption,
    validators: [FieldBlocValidators.required],
  );

  @override
  void onLoading() async {
    try {
      // Load async data
      final data = await _database.getData();
      
      // Update SelectFieldBloc items after loading
      categoryFieldBloc.updateItems(data.categories);
      
      // Use emitLoaded() when data is ready
      emitLoaded();
    } catch (e) {
      emitFailure(failureResponse: 'Failed to load data: $e');
    }
  }

  @override
  void onSubmitting() async {
    try {
      // Process form submission
      await _database.saveData(
        name: nameFieldBloc.value,
        category: categoryFieldBloc.value,
      );
      
      // Use emitSuccess() after successful submission
      emitSuccess(successResponse: 'Data saved successfully!');
    } catch (e) {
      emitFailure(failureResponse: 'Failed to save data: $e');
    }
  }
}
```

## 2. UI Integration

```dart
class MyFormScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MyFormBloc(context.read<MyDatabase>()),
      child: BlocListener<MyFormBloc, FormBlocState<String, String>>(
        listener: (context, state) {
          if (state is FormBlocLoading) {
            // Show loading indicator
          } else if (state is FormBlocFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.failureResponse ?? 'Error')),
            );
          } else if (state is FormBlocSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.successResponse ?? 'Success')),
            );
            // Navigate or reset form
          }
        },
        child: Builder(
          builder: (context) {
            return Column(
              children: [
                // Text field
                TextFieldBlocBuilder(
                  textFieldBloc: context.read<MyFormBloc>().nameFieldBloc,
                  decoration: InputDecoration(labelText: 'Name'),
                ),
                
                // Dropdown field
                DropdownFieldBlocBuilder<MyCategory>(
                  selectFieldBloc: context.read<MyFormBloc>().categoryFieldBloc,
                  decoration: InputDecoration(labelText: 'Category'),
                  itemBuilder: (context, value) => FieldItem(
                    child: Text(value.toString()),
                  ),
                ),
                
                // Submit button
                BlocBuilder<MyFormBloc, FormBlocState<String, String>>(
                  builder: (context, state) {
                    return ElevatedButton(
                      onPressed: state.isValid() 
                          ? () => context.read<MyFormBloc>().submit()
                          : null,
                      child: Text('Submit'),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
```

## 3. Key Points

### onLoading() Trigger
- Automatically called when FormBloc is created (default `isLoading: true`)
- Also called when `reload()` is invoked
- Use for loading initial data from databases/APIs

### SelectFieldBloc Best Practices
- Ensure items list contains unique values
- Use `updateItems()` after loading async data
- For enum classes, ensure proper `operator ==` and `hashCode` implementation

### emitLoaded() vs emitSuccess()
- `emitLoaded()`: Call after loading initial data in `onLoading()`
- `emitSuccess()`: Call after successful form submission in `onSubmitting()`
- `emitFailure()`: Call when any operation fails

### Error Handling
- Always wrap async operations in try-catch blocks
- Use `emitFailure()` with descriptive error messages
- Handle FormBlocFailure states in UI with BlocListener

## 4. Common Issues & Solutions

### Dropdown Duplicate Value Error
```dart
// WRONG - May cause duplicate values
items: [category1, category1, category2]

// CORRECT - Ensure unique values
items: MyCategory.values.where((c) => c.value == expectedValue).toList()
```

### Form Not Loading
```dart
// Ensure FormBloc is created with BlocProvider
BlocProvider(
  create: (context) => MyFormBloc(database),
  child: MyFormWidget(),
)
```

### Field Updates Not Reflecting
```dart
// Use updateItems() for SelectFieldBloc after loading data
categoryFieldBloc.updateItems(newItems);

// Use updateValue() to change selected value
categoryFieldBloc.updateValue(newValue);
```
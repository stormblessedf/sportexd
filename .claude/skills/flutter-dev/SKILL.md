---
name: flutter-dev
description: Flutter development best practices, widget patterns, state management with Provider, and Material Design 3 guidelines. Use this skill when working on Flutter UI, widgets, or state management.
---

# Flutter Development Skill

## Widget Best Practices

### Stateless vs Stateful
- Prefer `StatelessWidget` when no internal state is needed
- Use `StatefulWidget` only when widget needs to manage its own state
- Extract reusable widgets into separate files

### Widget Structure
```dart
class MyWidget extends StatelessWidget {
  const MyWidget({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      // Widget tree
    );
  }
}
```

### Performance
- Use `const` constructors where possible
- Avoid rebuilding entire widget trees - extract smaller widgets
- Use `ListView.builder` for long lists instead of `ListView`
- Use `RepaintBoundary` for complex animations

## State Management with Provider

### Service Pattern
```dart
// Define service
class MyService extends ChangeNotifier {
  // State and methods
  void updateState() {
    // Update logic
    notifyListeners();
  }
}

// Provide service
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => MyService()),
  ],
  child: MyApp(),
)

// Consume service
final service = context.read<MyService>();
final value = context.watch<MyService>().value;
```

### Context Extensions
- `context.read<T>()` - Get value without listening
- `context.watch<T>()` - Get value and rebuild on changes
- `context.select<T, R>()` - Listen to specific property

## Material Design 3

### Theme Usage
```dart
// Colors
Theme.of(context).colorScheme.primary
Theme.of(context).colorScheme.surface
Theme.of(context).colorScheme.onSurface

// Text Styles
Theme.of(context).textTheme.headlineLarge
Theme.of(context).textTheme.bodyMedium
Theme.of(context).textTheme.labelSmall
```

### Common Widgets
- `FilledButton` - Primary actions
- `OutlinedButton` - Secondary actions
- `TextButton` - Tertiary actions
- `Card` - Container with elevation
- `ListTile` - List items

## Navigation with GoRouter

### Route Definition
```dart
GoRouter(
  initialLocation: '/home',
  routes: [
    GoRoute(
      path: '/home',
      name: 'home',
      builder: (context, state) => HomeScreen(),
    ),
    GoRoute(
      path: '/detail/:id',
      name: 'detail',
      builder: (context, state) {
        final id = state.pathParameters['id'];
        return DetailScreen(id: id!);
      },
    ),
  ],
)
```

### Navigation
```dart
// Named route
context.goNamed('detail', pathParameters: {'id': '123'});

// With extra data
context.go('/detail', extra: myObject);

// Go back
context.pop();
```

## Form Handling

### TextFormField Pattern
```dart
final _formKey = GlobalKey<FormState>();
final _controller = TextEditingController();

Form(
  key: _formKey,
  child: TextFormField(
    controller: _controller,
    decoration: InputDecoration(
      labelText: 'Label',
      hintText: 'Hint',
    ),
    validator: (value) {
      if (value == null || value.isEmpty) {
        return 'Required field';
      }
      return null;
    },
  ),
)

// Validate
if (_formKey.currentState!.validate()) {
  // Process form
}
```

## Async Patterns

### FutureBuilder
```dart
FutureBuilder<Data>(
  future: fetchData(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return CircularProgressIndicator();
    }
    if (snapshot.hasError) {
      return Text('Error: ${snapshot.error}');
    }
    return DataWidget(data: snapshot.data!);
  },
)
```

### StreamBuilder
```dart
StreamBuilder<List<Item>>(
  stream: itemStream,
  builder: (context, snapshot) {
    if (!snapshot.hasData) {
      return CircularProgressIndicator();
    }
    return ListView.builder(
      itemCount: snapshot.data!.length,
      itemBuilder: (context, index) => ItemWidget(item: snapshot.data![index]),
    );
  },
)
```

## Error Handling

### Try-Catch with User Feedback
```dart
try {
  await someAsyncOperation();
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Success')),
    );
  }
} catch (e) {
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  }
}
```

## Guidelines

- Always check `context.mounted` after async operations before using context
- Dispose controllers in `dispose()` method
- Use `late` for controllers initialized in `initState()`
- Prefer named parameters for better readability
- Add `const` to constructors and widgets where possible

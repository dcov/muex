# muex
A composable state management library for flutter

## Status
The features it has are relatively stable, but it has only been used for my personal hobby projects,
so there are no guarantees as to whether it's suitable for more serious projects.

To use it, reference it as a git package in your `pubspec.yaml`:
```yaml
dependencies:
    # The core library.
    muex:
        git:
            url: git://github.com/dcov/muex.git
            path: muex

    # Flutter specific Widgets and methods.
    muex_flutter:
        git:
            url: git://github.com/dcov/muex.git
            path: muex_flutter

dev_dependencies:
    # The Model API code generator
    muex_gen:
        git:
            url: git://github.com/dcov/muex.git
            path: muex_gen
```

## Types

### Model
The code-generated type that makes up the application's state.

It tracks every use of a mutable field (including the standard dart collection types which are internally mutable), so
that an application can 'react' to changes to those mutable values.

```dart
// state.dart
import 'package:muex/muex.dart';

// Import the generated code
part 'state.g.dart';

// The code generator only picks up classes that extend [Model].
abstract class CityWeather implements Model {

  // Refer to the generated class by prefixing the class name with '_$'.
  factory CityWeather({
    String cityName,
    double temperature,
    List<String> conditions,
  }) = _$Weather;

  // Fields without a setter are immutable, and thus their usage is not tracked.
  String get cityName;

  // Fields with a setter are mutable, and will be tracked for changes.
  double get temperature;
  set temperature(double value);

  // The standard collection types are automatically tracked for internal changes,
  // but they can also be tracked for external changes.
  List<String> get conditions;
  //set conditions(List<String> value);
}

abstract class AppState implements Model {

  factory AppState({
    Map<String, CityWeather?> cities,
  }) = _$AppState;
    
  // All of the standard collection types are supported i.e. List, Map, and Set
  Map<String, CityWeather?> get cities;
}
```

<br/>

##### Connection
The mechanism through which 'state' can be depended on.

It keeps track of any `Model` (and its mutable values) that is used, and notifies the owner every time one (or more)
of those values changes.

A connection cannot be created directly, it is instead created through a `Loop`.

```dart

// will be called any time the state that's depended on changes
void callback() { }

// Assuming you've created a Connection already, and used [callback] as the 'listener'.
// 
// Connection.capture takes a sync function, calls the function, and tracks any mutable values
// belonging to a [Model] that are used. Every time one (or more) of those values changes, [callback]
// is invoked.
//
// The paramater that is passed to the function is the 'root' state, which is explained later.
connection.capture((AppState state) {
    
    // This depends on [state.cities]' internal state.
    for (final city in state.cities.values) {
        // This uses all of [CityWeather]'s fields, but only [temperature] and [conditions] will be
        // 'tracked' (because [name] is immutable).
        print("""
          ${city.name}\n
              temp: ${city.temperature}\n
              conditions: ${city.conditions}\n
        """);
    }
});
```

<br/>

### Action
The base type for all of the currently supported units of logic:  `Update`, `Effect`, `Chained,` `Unchained`, and `None`.

<br/>

##### Update
Responsible for updating application state.

An `Update` is the only type allowed to mutate any `Model` state.

Any state that is mutated during a chain of `Update` actions is tracked, and any `Connnection` that depends on that
mutated state is notified.

```dart
// logic.dart
import 'package:muex/muex.dart';

class UpdateCityWeather implements Update {

  UpdateCityWeather({
    required this.cityName,
    required this.data,
  });

  final String cityName;

  final WeatherData data;
  
  // [Update] types must implement [update].
  //
  // Its signature is [Action update(covariant Object state)].
  //
  // The [state] param is the 'root' state.
  @override
  Action update(AppState state) {
    // Update the [AppState]
    state.cities[cityName] = CityWeather(
      cityName: cityName,
      temperature: data.temperature,
      conditions: data.conditions,
    );
    
    return None();
  }
}
```

`Update`'s can also be created like so:
```dart
Action updateCityWeather({ String cityName, WeatherData data }) {
    return Update((AppState state) {
        // update logic
        return None();
    });
}
```

However the recommend way is to implement `Update` with a new type for readbility purposes. `Update`s created in this
way are useful for small updates in the context of other actions, e.g. an `Effect` that needs to update a status value
after it's finished.

<br/>

##### Effect
Reponsible for performing side effects.

An `Effect` can be synchronous or asynchronous, and can do anything except mutate `Model` state.

```dart
class GetCityWeather implements Effect {
    
  GetCityWeather({
    required this.cityName,
  });

  final String cityName;

  // [Effect] types must implement [effect].
  //
  // Its signature is [FutureOr<Actionn> effect(covariant Object container)].
  //
  // The [container] param is a user-defined 'resource' container (i.e. API interface,
  // i/o client, etc.), and in this case it is defined as an imaginary [EffectContext]
  // type which contains an imaginary weather API handle.
  @override
  Future<Action> effect(EffectContext context) async {
    const result = await context.api.getCityWeather(cityName);
    return UpdateCityWeather(
      cityName: cityName,
      data: result,
    );
  }
}
```

Like `Update`'s, `Effect`'s can also be created like so:
```dart
Action getCityWeather({ String cityName }) {
    return Effect((EffectContext context) async {
        // effect logic
        return UpdateCityWeather(cityName, result);
    });
}
```

<br/>

##### Chained
Chains async actions.

This is useful when you have independent action sequences that need to be completed in order.

```dart
abstract class Counter implements Model {
    
    int get count;
    set count(int value);
}

Action resetCounter() {
  return Chained({
    // This will execute first
    Update((Counter state) {
      state.count = 0;
      return None();
    }),
    // This will execute fully.
    Effect((Api api) async {
      await api.somethingAsync();
      return Update((Counter state) {
        state.count += 1;
        return None();
      });
    }),
    // This will execute only after the Effect above and any actions that follow from it, are
    // completed, even though the Effect is async.
    Update((Counter state) {
      assert(state.count == 1);
      return None();
    }),
  });
}
```

<br/>

##### Unchained
Does not chain async actions.

This is useful when you don't care about the order of execution of action sequences.

```dart
Action resetCounter() {
  return Unchained({
    // This will execute
    Update((Counter state) {
      state.count = 0;
      return None();
    }),
    // Once an async effect is reached, it'll continue onto the next action in the set
    Effect((Api api) async {
      await api.somethingAsync();
      return Update((Counter state) {
        assert(state.count == 1);
        return None();
      });
    }),
    // This will execute before the Effect above and it's resulting Update are executed.
    Update((Counter state) {
      state.count += 1;
      return None();
    }),
  });
}
```

Note: This example was predictable in its behavior hence why we can assert how it'll execute, but real world uses will
not be, so it's usually the case that you'll need `Chained` instead.

<br/>

##### None
Represents the 'finished' action.

When an Action sequence is complete it should return this.

<br/>

### Loop
Ties the functionality of the `Connection`, `Model`, and `Action` types  together.

It contains the 'root' state of the application (mentioned previously), which it passes to every `Update`, and
`Connection`.

It also contains the 'container' which it passes to `Effect` types.

Note: Currently there can only be one active instance for the whole life of an application, i.e. it should be created once
at the start of the application. This is due to how the  `Model` functionality is implemented, but it may change in the
future.

```dart
void main() {
    const initial_cities = <String>{ 'San Francisco', 'New York', 'Tokyo' };
    final loop = Loop(
      // The 'root' state
      state: AppState(),
      // The effect 'container'
      container: EffectContext(),
      // The very first Action to process
      initial: Chained(
        initial_cities.map((name) {
          return GetCityWeather(cityName: name);
        }).toSet()
      ),
    );

    // this creates a Connection that calls the provided function every time the state
    // it depends on changes.
    final connection = loop.connect(() {
        print('state changed');
    });

    // capture any state to depend on.
    connection.capture((AppState state) {
        for (final city in state.cities.values) {
            print('${city.name}: ${city.temperature}');
        }
    });

    // process the Unchained action
    loop.then(Unchained({
        GetCityWeather(cityName: 'Los Angeles'),
        GetCityWeather(cityName: 'Berlin'),
    });
}
```

<br/>

## Flutter
If you're using `muex` to develop with Flutter, then you don't need to bother with manually creating a `Loop`, and 
managing `Connection`s, as `muex_flutter` provides several helpers.

#### runLoop
This function creates a `Loop`, calls `runApp`, and makes the `Loop` available to all `Widget`s in the app.

It should be used in place of `runApp`.

```dart
runLoop(
  // These values are used to create the Loop
  state: AppState(),
  container: ApiContainer(),
  initial: InitApp(),
  // This is the Widget that you would normally pass to runApp, i.e. the root Widget.
  view: MaterialApp(),
);
```

<br/>

#### BuildContext extensions
These are extensions for interacting with the `Loop` created by `runLoop`.

```dart
// The Loop.state value
final state = context.state;

// The loop.then function
context.then(None())
```

<br/>

#### Connector
A Widget that manages a `Connection`, and capturing used state for you.

```dart
return Connector(
  builder: (BuildContext context) {
    // Any state used in this 'builder' callback is captured, and it is called again
    // when that state changes.
    return Scaffold(
        body: Center(child: Text('count: ${model.count}')),
    );
  },
);
```

<br/>

## Conclusion
And that's it!

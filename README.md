# muex
A composable state management library for flutter

### Status
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

### Usage
In `muex`, state is decoupled from logic, and composed of `Model` types:

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

  // Fields without a setter are immutable.
  String get cityName;

  // Fields with a setter are mutable, and will be tracked for changes.
  double get temperature;
  set temperature(double value);

  // The standard collection types are automatically tracked for internal changes
  List<String> get conditions;
}

abstract class AppState implements Model {

  factory AppState({
    Map<String, CityWeather?> cities,
  }) = _$AppState;
    
  Map<String, CityWeather?> get cities;
}
```

Logic is separated into `Initial`, `Update` and `Effect` types:

```dart
// logic.dart
import 'package:muex/muex.dart';

import 'state.dart';

// An [Initial] type is ran once when the application is initialized.
class InitApp implements Initial {
    
  InitApp({
    required this.initialCities,
  });

  final List<String> initialCities;

  // [Initial] types must implement [init] and return an [Init] object.
  @override
  Init init() {
    // [Init] is just a data object that describes the initial state and optional additional
    // 'action(s)' to perform.
    return Init(
      state: AppState(
        cities: <String, CityWeather?>{},
      ),
      // [Then.all] takes a [Set] of action types ([Update] or [Effect])
      then: Then.all(initialCities.map((String cityName) {
        // GetCityWeather is an [Effect] type implemented below
        return GetCityWeather(
            cityName: cityName,
        );
      }).toSet())
    );
  }
}

// An [Effect] type performs side-effects such as network requests.
// It is not allowed to mutate any [Model]s.
class GetCityWeather implements Effect {
    
  GetCityWeather({
    required this.cityName,
  });

  final String cityName;

  // [Effect] types must implement [effect] which must return a [Future<Then>] or [Then] value.
  //
  // Its signature is [FutureOr<Then> effect(covariant Object container)].
  //
  // The [container] param is a user-defined 'resource' container (i.e. API interfaces,
  // file i/o handlers, etc.), and in this case it is defined as an imaginary [EffectContext]
  // type which contains an imaginary weather API handle.
  @override
  Future<Then> effect(EffectContext context) async {
    const result = await context.api.getCityWeather(cityName);
    // [UpdateCityWeather] is an [Update] type implemented below.
    // [Then]'s default constructor takes a single action.
    return Then(UpdateCityWeather(
      cityName: cityName,
      data: result,
    ));
  }
}

// An [Update] type updates any [Model] state, and is the only block of execution where [Model]
// state is allowed to be mutated.
class UpdateCityWeather implements Update {

  UpdateCityWeather({
    required this.cityName,
    required this.data,
  });

  final String cityName;

  final WeatherData data;
  
  // [Update] types must implement [update] which must return a [Then] value.
  //
  // Its signature is [Then update(covariant Object state)].
  //
  // The [state] param is the value returned in [Init.state] by the [Initial] type.
  @override
  Then update(AppState state) {
    // Update the [AppState]
    state.cities[cityName] = CityWeather(
      cityName: cityName,
      temperature: data.temperature,
      conditions: data.conditions,
    );
    
    // [Then.done] is the value that indicates that there are no more actions to execute.
    return Then.done();
  }
}
```

The Flutter layer provides a `Connector` `Widget` that listens to changes in state that you've
accessed (i.e. depend on), as well as several `BuildContext` extensions:

```dart
// main.dart
import 'package:muex_flutter/muex_flutter.dart';

class App extends StatelessWidget {

  App({
    Key? key,
    this.state,
  }) : super(key: key);

  final AppState? state;

  @override
  Widget build(BuildContext context) {
    // [context.state] allows you to access the root [Model] object of the application.
    final state = this.state ?? context.state;
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text("Weatheroony"),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: () {
                // [context.then] dispatches actions to the main loop to be processed.
                context.then(Then(RefreshWeather()));
              },
            ),
          ],
        ),
        // [Connector] tracks any of the state used within the [builder] closure.
        // (State in this case refers to mutable fields of a [Model])
        body: Connector(
          builder: (BuildContext _) {
            // whenever [state.cities] is internally mutated (i.e. whenever [UpdateCityWeather]
            // runs), [Connector] will rebuild this.
            final list_data = state.cities.values.toList();
            return ListView.builder(
              itemCount: list_data.length,
              itemBuilder: (_, index) {
                return CityWeatherTile(
                  cityWeather: list_data[index],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

void main() {
  // [runLoop] is a wrapper that initializes the action loop and calls [runApp]
  runLoop(
    initial: InitApp(
      initialCities: <String>[ "San Francisco", "New York" ],
    ),
    container: EffectContext(),
    view: App(
      state: null,
    ),
  );
}
```

And that's it!

`muex` was designed to be very minimal, although it does end up guiding the design of an
application to be composable both in its state and its logic.

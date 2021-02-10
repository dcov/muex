# muex
A composable state management solution for flutter

### Status
It is currently in development and isn't production ready.

### Usage
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

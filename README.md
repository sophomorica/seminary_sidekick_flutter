# Seminary Sidekick

[![Flutter CI](https://github.com/your-username/seminary-sidekick/actions/workflows/flutter-ci.yml/badge.svg)](https://github.com/your-username/seminary-sidekick/actions/workflows/flutter-ci.yml)
[![codecov](https://codecov.io/gh/your-username/seminary-sidekick/branch/main/graph/badge.svg)](https://codecov.io/gh/your-username/seminary-sidekick)

A gamified scripture memorization app for LDS Doctrinal Mastery passages. Master the scriptures through fun, addictive games!

## Features

- **Three Game Modes**: Matching, Word Builder, and Quiz games
- **Progress Tracking**: Persistent progress with Hive local storage
- **Multiple Difficulty Levels**: Beginner, Intermediate, Advanced, Master
- **Scripture Library**: 100+ Doctrinal Mastery passages
- **Audio Feedback**: Sound effects for correct/incorrect actions
- **Confetti Celebrations**: Visual rewards for achievements

## Getting Started

### Prerequisites

- Flutter 3.19.0 or later
- Dart SDK
- Android Studio / Xcode for mobile development

### Installation

1. Clone the repository:

   ```bash
   git clone <repository-url>
   cd seminary_sidekick
   ```

2. Install dependencies:

   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

## Development

### Testing

Run all tests:

```bash
flutter test
```

Run tests with coverage:

```bash
flutter test --coverage
```

Run local CI checks (same as GitHub Actions):

```bash
./scripts/ci.sh
```

Run specific test file:

```bash
flutter test test/providers/progress_provider_test.dart
```

### Code Quality

Run static analysis:

```bash
flutter analyze
```

Format code:

```bash
flutter format .
```

## CI/CD

This project uses GitHub Actions for continuous integration:

- **Automated Testing**: All tests run on every push and pull request
- **Code Analysis**: Flutter analyze runs to catch linting issues
- **Coverage Reports**: Test coverage uploaded to Codecov

### Branch Protection

The `main` branch is protected and requires:

- All tests to pass
- Code analysis to pass
- At least one approval for pull requests

See `.github/BRANCH_PROTECTION.md` for setup instructions.

## Architecture

- **State Management**: Riverpod for reactive state management
- **Local Storage**: Hive for persistent data storage
- **Navigation**: Go Router for declarative routing
- **UI Framework**: Flutter with custom theme system

## Contributing

1. Create a feature branch from `develop`
2. Make your changes
3. Add tests for new functionality
4. Ensure all tests pass: `flutter test`
5. Run code analysis: `flutter analyze`
6. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

# ScamShield architecture

ScamShield uses a **feature-first layered architecture**. The goal is to keep the
code easy to read today while still allowing the product to grow into a real
fraud-protection platform.

## Core principles

1. **Features own their own logic.** Scam checking, protection, recovery, radar,
   learning and reporting should not depend on each other's UI classes.
2. **UI does not own business logic.** Widgets render state and forward user
   actions to controllers/use cases.
3. **Dependencies are explicit.** Riverpod provides shared services and state so
   they can be tested or replaced without rewriting screens.
4. **Navigation is centralised.** go_router defines routes in one place and gives
   us a clean route to mobile deep links and web URLs.
5. **Comments explain intent.** We comment why a class, decision or workaround
   exists. We do not add noise by commenting obvious Dart syntax.
6. **Names should read like plain English.** Avoid unexplained abbreviations and
   one-letter business variables.
7. **Security-sensitive behaviour must be explainable.** Scam verdicts should
   expose reasons and recommended actions instead of returning a mysterious AI
   score.

## Target directory structure

```text
lib/
  app/
    scamshield_app.dart
    router.dart
    app_shell.dart

  core/
    errors/
    providers/
    security/
    theme/
    utils/
    widgets/

  features/
    home/
      data/
      domain/
      presentation/

    scam_check/
      data/
      domain/
      presentation/

    protection/
    recovery/
    radar/
    learn/
    reports/

  main.dart
```

## Layers inside a feature

### domain
Pure business concepts. This is where entities, repository contracts and use
cases belong. Domain code should know as little as possible about Flutter.

Example:

```text
domain/
  entities/scam_analysis.dart
  repositories/scam_repository.dart
  use_cases/analyse_message.dart
```

### data
Implements the domain contracts. This layer talks to local rules, device
storage, APIs, threat-intelligence services or machine-learning models.

Example:

```text
data/
  models/scam_analysis_model.dart
  data_sources/local_rules_data_source.dart
  repositories/scam_repository_impl.dart
```

### presentation
Screens, widgets and Riverpod controllers. Presentation code should ask a use
case to do work rather than embedding fraud rules directly in a button handler.

Example:

```text
presentation/
  controllers/scam_check_controller.dart
  screens/scam_check_screen.dart
  widgets/risk_score_card.dart
```

## State management

Riverpod is the default state-management and dependency-injection tool.

Use the simplest provider that fits the job:

- `Provider` for read-only services and dependencies.
- `StateProvider` for tiny UI state.
- `Notifier` / `AsyncNotifier` for real feature state and asynchronous work.

Do not place unrelated application state into one giant global controller.

## Navigation

`go_router` owns application routes. Screens should navigate by named/path
routes rather than constructing `MaterialPageRoute` throughout the codebase.

## Migration strategy

The original prototype remains functional while files are moved gradually.
This avoids a risky big-bang rewrite.

Migration order:

1. App bootstrap, routing and providers.
2. Home feature.
3. Scam-check domain/data/presentation layers.
4. Recovery feature.
5. Protection feature.
6. Radar and threat-intelligence services.
7. Learning/reporting features.
8. Backend and account/family services.

At each step, the app should continue to run before the next migration begins.

## Testing expectation

Business rules receive unit tests. Controllers receive state tests. Important
user journeys receive widget/integration tests. A visual feature is not complete
if its underlying scam decision logic is untested.

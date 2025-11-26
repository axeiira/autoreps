Project structure (starter)

This project uses a feature-first layout. The folders created by the starter script are:

- lib/core/           : App-wide utilities, theme, constants, and global widgets
  - theme/            : Theme definitions (e.g. `app_theme.dart`)
  - utils/            : Small helpers and constants
- lib/widgets/        : Reusable widgets used across features (e.g. `app_scaffold.dart`)
- lib/features/       : Feature modules grouped by functionality
  - example_feature/
    - presentation/   : Pages and widgets for the feature
    - data/           : (placeholder) models, datasources, repositories
- lib/routes/         : App routing (e.g. `app_router.dart`)

How to use
1. Open `lib/main.dart` and wire in `AppTheme` and `AppRouter` if you want to.
2. Add new features under `lib/features/<name>/` and keep presentation code (pages/widgets) separate from data logic.

Recommendations
- Pick a state-management solution (Provider, Riverpod, Bloc) and use it consistently.
- Keep files small and extract repeated UI into `lib/widgets/` or feature-scoped widgets.
- Add tests under `test/` mirroring `lib/` structure (e.g. `test/features/example_feature/`).

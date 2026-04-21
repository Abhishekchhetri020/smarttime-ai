# Contributing to SmartTime AI

Thanks for your interest in improving SmartTime AI.

This project is being built as a practical open-source timetable platform for schools. Contributions that improve reliability, usability, documentation, diagnostics, and educator workflows are especially welcome.

## Good ways to contribute

- report reproducible bugs
- improve documentation
- propose product ideas grounded in real school workflows
- improve solver quality or diagnostics
- strengthen Android usability and performance
- help with tests, validation, and developer tooling

## Before you start

1. Check existing issues and pull requests first.
2. Open an issue for significant changes before writing a large patch.
3. Keep proposals focused and easy to review.

## Development areas

- `android-app/flutter_app/` - Flutter Android client
- `solver/` - FastAPI timetable solver
- `backend/functions/` - backend services and orchestration
- `admin-web/` - Next.js admin interface
- `docs/` - project docs, rollout notes, and planning material

## Local setup

### Solver

```bash
cd solver
pip install -r requirements-dev.txt
pytest -q
uvicorn main:app --reload
```

### Backend functions

```bash
cd backend/functions
npm install
npm test
npm run build
```

### Admin web

```bash
cd admin-web
npm install
npm run dev
```

### Android app

```bash
cd android-app/flutter_app
flutter pub get
flutter test
flutter run
```

## Pull request guidelines

- keep PRs focused and small when possible
- explain the problem, not just the code change
- include screenshots for UI changes
- include test notes for behavior changes
- update docs when your change affects setup, workflows, or architecture

## Coding expectations

- prefer clear and maintainable solutions over clever ones
- avoid unrelated refactors in feature PRs
- keep user-facing workflows understandable for non-technical school staff
- preserve diagnostic clarity where possible, especially in solver-related changes

## Reporting bugs

When opening a bug report, include:
- what you expected to happen
- what actually happened
- steps to reproduce
- screenshots or logs if relevant
- device, OS, or runtime details when applicable

## Feature requests

Feature ideas are welcome, especially when they are tied to real timetable pain points in schools.

Useful requests usually explain:
- the school workflow problem
- who is affected
- what a successful outcome looks like
- any constraint or policy details that matter

## Community

Please be respectful and constructive. By participating, you agree to follow the [Code of Conduct](CODE_OF_CONDUCT.md).

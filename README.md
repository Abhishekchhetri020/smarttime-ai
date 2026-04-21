# SmartTime AI

[![CI](https://github.com/Abhishekchhetri020/smarttime-ai/actions/workflows/ci.yml/badge.svg)](https://github.com/Abhishekchhetri020/smarttime-ai/actions/workflows/ci.yml)
[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)
[![Status](https://img.shields.io/badge/status-active%20development-6aa84f.svg)](#project-status)

SmartTime AI is an open-source timetable generation platform built to help teachers and school coordinators create practical, conflict-aware school timetables faster.

The long-term goal is simple: make timetable generation more accessible, affordable, and transparent for schools worldwide, starting with a free Android-first workflow that real educators can actually use.

## Why this project exists

Manual timetable planning is slow, repetitive, and difficult to maintain. Even small changes, like teacher absences, room constraints, or subject load balancing, can cause a cascade of conflicts.

SmartTime AI aims to solve that by combining:
- a teacher-friendly Android experience
- a constraint-aware scheduling engine
- diagnostics that explain why scheduling conflicts happen
- import and export flows that fit real school workflows

## What SmartTime AI is building

SmartTime AI is being developed as a modular platform with these core parts:

- **Android app** for school setup, timetable generation, review, and sharing
- **Solver service** for conflict-aware timetable generation and diagnostics
- **Backend services** for orchestration, persistence, and publishing workflows
- **Admin web app** for future browser-based operations
- **Docs and planning artifacts** that keep the project transparent and auditable

## Project status

SmartTime AI is in **active development**.

Current repository state:
- core architecture is in place
- solver and diagnostics work is underway
- Android app development is active
- Excel/PDF import-export foundations exist
- backend and admin tooling are scaffolded and evolving

This repository is not yet production-stable, but it is being shaped into a real, usable open-source timetable platform for schools.

## Key goals

- Help teachers and coordinators generate timetables faster
- Reduce manual errors and scheduling conflicts
- Support real school constraints, not toy examples
- Keep the platform affordable and accessible
- Build in public with an open-source roadmap

## Repository structure

- `android-app/flutter_app/` - Flutter Android application
- `solver/` - FastAPI-based timetable solver service
- `backend/functions/` - backend API and orchestration layer
- `admin-web/` - Next.js admin interface
- `docs/` - plans, runbooks, validation notes, and rollout docs
- `infra/` - infrastructure and environment templates

## Technology stack

- **Android app:** Flutter, Dart, Drift, Firebase
- **Solver:** Python, FastAPI, pytest
- **Backend:** Node.js, TypeScript, Firebase Functions
- **Admin web:** Next.js, React

## Getting started

### 1. Clone the repository

```bash
git clone https://github.com/Abhishekchhetri020/smarttime-ai.git
cd smarttime-ai
```

### 2. Run the solver service

```bash
cd solver
pip install -r requirements-dev.txt
pytest -q
uvicorn main:app --reload
```

### 3. Run backend functions

```bash
cd backend/functions
npm install
npm test
npm run build
```

### 4. Run the admin web app

```bash
cd admin-web
npm install
npm run dev
```

### 5. Run the Android app

```bash
cd android-app/flutter_app
flutter pub get
flutter run
```

## Roadmap

Near-term priorities:
- strengthen the timetable solver and conflict diagnostics
- improve Android workflows for setup and timetable generation
- complete reliable import and export pipelines
- harden backend orchestration and validation
- prepare the project for external contributors

Long-term direction:
- support broader school deployment scenarios
- make timetable changes easier to explain and review
- expand educator-friendly workflows beyond initial timetable generation

## Open source direction

This project is intended to grow as a practical open-source tool for education.

If you care about:
- school operations
- timetable automation
- Flutter for education
- scheduling and optimization systems
- explainable workflow tooling

then contributions, feedback, and issue reports are welcome.

See [CONTRIBUTING.md](CONTRIBUTING.md) for contribution guidelines.

## Community standards

Please read:
- [CONTRIBUTING.md](CONTRIBUTING.md)
- [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)
- [SECURITY.md](SECURITY.md)
- [SUPPORT.md](SUPPORT.md)

## License

This project is licensed under the [Apache License 2.0](LICENSE).

## Maintainer note

SmartTime AI is being built with a real-world education use case in mind. The goal is not to create a demo scheduler, but a genuinely useful platform that can help teachers and school coordinators save time and reduce timetable friction.

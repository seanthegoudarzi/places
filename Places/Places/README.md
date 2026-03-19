# FranxPlaces

FranxPlaces is a SwiftUI-based iOS application that displays a list of locations fetched from a
remote source, allows users to open them in the Wikipedia app, and supports adding custom locations
with validated coordinates. The project is architected around the **MVI (Model-View-Intent)**
pattern, with a clear separation of concerns across every layer.

---

## Table of Contents

- [Architecture Overview](#architecture-overview)
  - [MVI Pattern](#mvi-pattern)
  - [Screen Anatomy](#screen-anatomy)
  - [Data Flow](#data-flow)
- [Project Structure](#project-structure)
- [Screens](#screens)
  - [Navigator](#navigator)
  - [Locations List](#locations-list)
  - [Custom Location](#custom-location)
- [Dependency Injection](#dependency-injection)
- [A Note on Over-Engineering](#a-note-on-over-engineering)
- [Testing Strategy](#testing-strategy)
  - [Unit Tests](#unit-tests)
  - [UI Tests](#ui-tests)
  - [The Testing Pyramid](#the-testing-pyramid)

---

## Architecture Overview

### MVI Pattern

The app follows the **Model-View-Intent** unidirectional data flow pattern. Each screen is composed
of five distinct pieces:

| Component        | Role                                                                 |
|------------------|----------------------------------------------------------------------|
| **Intent**       | An enum representing every action a user or the system can trigger.  |
| **State**        | A struct that fully describes the current state of the screen.       |
| **Effect**       | An enum for one-shot side effects (navigation, opening a URL, etc.). |
| **IntentHandler**| A stateless reducer that receives an intent, reads/mutates state via a context, and optionally emits effects. |
| **ViewModel**    | A generic class that owns the state, routes intents to the handler, and publishes effects via Combine. |

### Screen Anatomy

Every screen in the app follows the same template:

```
Screens/
└── SomeScreen/
    ├── SomeScreenIntent.swift
    ├── SomeScreenState.swift
    ├── SomeScreenEffect.swift
    ├── SomeScreenIntentHandler.swift
    └── SomeScreenView.swift
```

The view reads `viewModel.state` to render UI, sends user actions as intents via
`viewModel.handle(_:)`, and subscribes to `viewModel.effectPublisher` for one-off side effects
like navigation or opening external URLs.

### Data Flow

```
┌──────────────────────────────────────────────────────────────┐
│  Data Sources                                                │
│  • GithubLocationsDataSource  (remote JSON from GitHub)      │
│  • TemporaryInMemoryLocationDataSource  (for adding new      │
│    locations, stored in-memory)                               │
└──────────────────────────┬───────────────────────────────────┘
                           │
                           ▼
┌──────────────────────────────────────────────────────────────┐
│  Repository  (LocationsRepository protocol)                  │
│  DefaultLocationsRepository fetches from both sources in     │
│  parallel and merges the results. Writes go to in-memory.    │
└──────────────────────────┬───────────────────────────────────┘
                           │
                           ▼
┌──────────────────────────────────────────────────────────────┐
│  IntentHandler                                               │
│  Receives intents, calls repository methods, maps domain     │
│  models to display items, updates state, emits effects.      │
└──────────────────────────┬───────────────────────────────────┘
                           │
                           ▼
┌──────────────────────────────────────────────────────────────┐
│  ViewModel → View                                            │
│  ViewModel holds state and publishes effects.                │
│  View renders state and dispatches intents.                  │
└──────────────────────────────────────────────────────────────┘
```

---

## Locale-Aware Input

Coordinate handling distinguishes between **display** and **input**:

- **Display (read-only)** — Coordinates shown in the locations list always use a dot as the decimal
  separator (e.g., `52.3547, 4.8339`), regardless of the user's locale. This keeps the
  representation consistent and universally readable, which is the standard convention for
  geographic coordinates.

- **Input (keyboard entry)** — When a user types coordinates in the custom location form, the
  `CoordinateFormatter` parses the input using the device's current locale first, then falls back
  to the POSIX locale (`en_US_POSIX`). This means a user in the Netherlands can type `52,3676`
  (comma separator) and a user in the US can type `52.3676` (dot separator), and both will be
  parsed correctly. The POSIX fallback covers the common scenario where a user pastes a
  dot-formatted coordinate from an external source (e.g., Google Maps, Wikipedia) while their
  device is set to a comma-separator locale.

---

## Dependency Injection

A lightweight DI container (`DependencyContainer` + `DependencyModule`) registers all dependencies
at app launch. During UI tests, a different set of dependencies is registed which returns mock data without hitting the network.

---

## A Note on Over-Engineering

Some parts of this codebase may appear over-engineered for an app of this size, and that is
intentional. For example:

- **The Repository pattern** — For an app that simply fetches a JSON file, introducing a repository
  protocol with a default implementation and a UI-test stub might seem excessive. It is included to
  demonstrate how this layer makes it trivial
  to swap data sources, add caching, or test in isolation.

- **Offloading coordinate formatting to a background TaskGroup** — Formatting a handful of numbers
  is not a performance bottleneck at the current scale. However, the concurrent mapping demonstrates that when the
  operation *is* expensive (e.g., formatting thousands of items, or performing locale-sensitive
  number formatting that involves non-trivial work), the architecture already supports pushing that
  work off the main thread with no structural changes.

The goal is to show that this architecture scales. In a production codebase with a more realistic input,
complex business rules, and real performance constraints, these patterns pay for themselves. Here
they serve as a proof of concept.

---

## Testing Strategy

### Unit Tests

Because intent handlers are stateless reducers, unit tests are straightforward: construct the
handler with its (mocked) dependencies, call `handle` with an intent and an initial state, and
assert on the collected state snapshots and effects.

### UI Tests

UI tests live in `FranxPlacesUITests/` and use the **Page Object pattern** for readability:

- `LocationsListPage` — abstracts interactions with the locations list screen.
- `CustomLocationPage` — abstracts interactions with the add-location form.
- `FranxPlacesUITests` — the test cases themselves, covering navigation flows like adding a
  location and returning to the list.

The app detects a `UI_TESTING` launch argument and reads a `UI_TEST_SCENARIO` environment variable
(`loaded`, `empty`, `error`) to swap in `UITestLocationsRepository`, giving tests full control over
the data layer without touching the network.

### The Testing Pyramid

This architecture lends itself naturally to a well-balanced **testing pyramid**:

```
            ┌─────────┐
            │ UI Tests│   ← Few, high-level: navigation flows,
            │         │     end-to-end scenarios (mock or real env)
            └────┬────┘
                 │
          ┌──────┴──────┐
          │  Snapshot   │   ← Medium: views rendered in every
          │   Tests     │     meaningful state combination (doesn't exist in this project, but in a real world example it should be added)
          └──────┬──────┘
                 │
     ┌───────────┴───────────┐
     │      Unit Tests       │   ← Many, fast: intent handlers,
     │                       │     models, formatters, view models
     └───────────────────────┘
```

1. **Unit tests** form the base. Because intent handlers encapsulate virtually all business logic,
   thorough unit tests against them provide high coverage with fast execution.

2. **Snapshot tests** (not included in this project, but the architecture supports them well) would
   occupy the middle tier. Since mosts views are pure functions of their state, you can render a view
   with any `State` value and snapshot the result — covering loading, loaded, empty, and error
   states without any network calls or navigation setup.

3. **UI tests** sit at the top. This project includes UI tests that verify high-level navigation
   flows against a mock environment. In a real-world scenario, this layer could also run against a
   staging or production environment to validate end-to-end behavior. Because the lower layers
   already cover business logic and visual correctness, UI tests can remain few in number and
   focused on integration concerns.

This pyramid ensures fast feedback from the bottom (unit tests run in milliseconds), visual
confidence from the middle (snapshot tests catch unintended UI regressions), and integration
assurance from the top.

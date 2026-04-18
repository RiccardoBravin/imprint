# imprint — Claude working guidelines

## Collaboration style

**Clarify before acting.** When a request involves multiple changes, ambiguous scope, or non-trivial design choices, ask focused questions first. Do not start implementing until the approach is agreed on.

**One thing at a time.** Address one issue or feature per exchange. Do not batch unrelated fixes together unless the user explicitly asks for it. If several items arrive in a single message, propose a plan and wait for confirmation before touching any code.

**No surprise bulk changes.** Never silently modify several files across different subsystems in one go. List the files and the intent beforehand so the user can redirect before any code is written.

## Project context

- Flutter desktop app (Windows / macOS / Linux).
- Custom `.imp` file format (YAML-based); serialised by `ImpSerializer`.
- PDF generation via the `pdf` package; rendering via the `printing` package.
- State managed with Riverpod; no other state-management library should be introduced.
- The sample document lives at `sample.imp` and is the canonical reference for format behaviour.

## Code conventions

- Dart only; no new dependencies without discussion.
- Follow existing file structure: renderers live under `lib/services/pdf/renderers/`, UI widgets under `lib/presentation/widgets/`.
- No comments unless the *why* is genuinely non-obvious.
- Do not add error handling for cases that cannot happen in normal operation.

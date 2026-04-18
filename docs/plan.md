# Implementation Plan

## Guiding Principles

- Build from the inside out: data model → serialization → state → UI → PDF.
- Each phase produces something runnable before moving to the next.
- No speculative features. Each item below maps to a concrete, agreed requirement.

---

## Phase 1 — Foundation ✅

**Goal:** The app runs, can create/open/save `.imp` files, and renders a basic list of sections in the sidebar.

- Project cleanup & setup; dependencies added to `pubspec.yaml`
- All data model classes: `Document`, `DocumentSettings`, `FormatSettings`, `AppSettings`, `S3Config`
- Sealed `Section` base class and all five subclasses in a single `section.dart` (required for Dart exhaustive switch)
- Item types: `MenuItem`, `WineItem`, `EventItem`
- `Allergen` constants (14 EU entries)
- `ImpSerializer.fromYaml()` / `.toYaml()` with version field
- `DocumentRepository` and `SettingsRepository`
- `DocumentNotifier` / `SettingsNotifier` (Riverpod 3 `Notifier`, not `StateNotifier`)
- Home screen with recent files
- Editor screen shell: title bar, sidebar, bottom toolbar, unsaved changes warning

---

## Phase 2 — Section Editing ✅

**Goal:** All section types are fully editable. Files can be saved and reopened with all content intact.

- Sidebar: drag-to-reorder (`ReorderableListView.builder`), visibility indicator, hover actions
- Section context menu: Layout settings, Hide/Show, Duplicate, Delete (with confirmation)
- Five section editors: `RegularSectionEditor`, `SpecialSelectionEditor`, `WineSectionEditor`, `EventSectionEditor`, `CoverSectionEditor`
- Item rows with inline editing, drag handle, allergen chips
- Allergen selector dialog (14 EU allergens as toggle grid)
- Add section picker dialog
- Section settings popup (`SegmentedButton` for inline/full_page/flow)

---

## Phase 3 — Document Settings & App Settings ✅

**Goal:** All settings layers are exposed in the UI and persisted correctly.

- Settings popup with two tabs: Document and App
- **Document tab:** A4/A5 format toggle (SegmentedButton), font size, sections per page, primary color, show footer/fee toggles, fee field, footer note
- **App tab:** S3 endpoint, bucket, access key, secret key (obscured), test connection button
- `ColorPickerField`: hex input + swatch + 24-color preset dialog

---

## Phase 4 — PDF Engine ✅

**Goal:** The app can generate correct PDFs for A4 and A5, respecting all layout rules.

- `PdfService.render(Document, PdfFormat) → Future<Uint8List>`
- Pagination engine: visible sections only → `fullPage` → one `pw.Page` each; `inline` → grouped ≤ `sectionsPerPage` per `pw.Page`; `flow` → `pw.MultiPage`
- `pdf_theme.dart`: shared colors, fonts, price formatting
- Five renderer functions (not a class hierarchy): `buildCoverContent`, `buildRegularSection`, `buildSpecialSelectionContent`, `buildWineSectionContent`, `buildEventSectionContent`
- "Preview PDF" button → `PdfPreviewDialog` (fullscreen, A4/A5 toggle, built-in print)
- "Print" button → `PrintService` → `Printing.layoutPdf`

---

## Phase 5 — Live Preview ✅

**Goal:** The preview pane shows the real PDF output in real time as the user edits.

- `◧` button in title bar toggles preview pane (highlighted when active)
- `SplitView` widget: draggable horizontal divider, clamped 20–80%, resize cursor
- `PdfPreviewPane`: watches `documentProvider`, debounces 300ms, renders PDF async in main isolate
- Previous bytes stay visible while re-rendering; small spinner indicates pending render
- A4/A5 toggle in pane header; format switch triggers immediate re-render (no debounce)
- `PdfPreview` from `printing` package handles page display and navigation

---

## Phase 6 — Cloud Upload ✅

**Goal:** Users can upload a generated PDF to an S3-compatible bucket.

- `S3Service.testConnection(S3Config)` and `S3Service.upload(config, bytes, objectName)` backed by `minio_new`
- Endpoint URL parser handles `https://host`, `http://host:port`, and bare hostnames
- "Test connection" in Settings → App now calls real `S3Service`
- `UploadDialog`: format selector (defaults to `activeFormat`), editable object name, render → upload phases with spinner, selectable presigned URL on success

---

## Phase 7 — Polish ✅ / ⚠ Partial

Items completed during earlier phases:

- ✅ Keyboard shortcut `Ctrl+S` (save)
- ✅ Empty state in sidebar (prompt to add first section)
- ✅ Unsaved changes warning on window close and on navigate-home
- ✅ Missing logo handled gracefully in cover renderer (silently skipped)

Remaining / out of scope for now:
- ⬜ File association setup instructions (Windows / Linux)
- ⬜ Undo / redo
- ⬜ Very large document stress test

---

## Out of Scope

These are acknowledged but explicitly not planned for the current build:

- Localization / multilingual UI
- Auto-update system
- Custom DSL to replace YAML
- Additional paper formats (A3, Letter)
- User-created templates
- Multi-document tabs

---

## Dependency Order

```
Phase 1 (Foundation)
  └─ Phase 2 (Section editing)
       └─ Phase 3 (Settings)
            └─ Phase 4 (PDF engine)
                 ├─ Phase 5 (Preview)   ← depends on Phase 4
                 └─ Phase 6 (Cloud)     ← depends on Phase 4
                      └─ Phase 7 (Polish)
```

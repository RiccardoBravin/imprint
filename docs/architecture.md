# Architecture

## Overview

Imprint is a Flutter desktop application (Windows + Linux) for composing structured documents. The developer defines **section types** — their fields, validation rules, and rendering logic — in code. Users freely compose documents by combining any section types in any order.

There are no user-created templates. The document is simply an ordered list of typed sections.

---

## Technology Stack

| Concern | Package |
| --- | --- |
| State management | `flutter_riverpod` 3.x (`Notifier` / `NotifierProvider`) |
| YAML parsing | `yaml` (parsing only; serialization is hand-written in `ImpSerializer`) |
| PDF generation | `pdf` |
| PDF preview & printing | `printing` |
| File picker (open/save) | `file_picker` 11.x (static API: `FilePicker.pickFiles()`) |
| App settings persistence | `shared_preferences` |
| S3-compatible upload | `minio_new` |
| Window management | `window_manager` |
| Drag-to-reorder | Flutter built-in `ReorderableListView.builder` + `ReorderableDragStartListener` |

---

## Data Model

### Document

The root object. Serialized to/from `.imp` (YAML).

```text
Document
├── version: int                  # file format version, for future migrations
├── fee: double?                  # optional cover charge / service fee
├── footerNote: String?           # optional footer text
├── settings: DocumentSettings
└── sections: List<Section>
```

### DocumentSettings

Per-document layout settings. Contains one `FormatSettings` per export format and an `activeFormat` preference.

```text
DocumentSettings
├── a4: FormatSettings
├── a5: FormatSettings
└── activeFormat: PdfFormat       # default format for preview and export (a4 | a5)

FormatSettings
├── titleFontSize: double
├── primaryColor: int             # stored as ARGB int; Color getter available
├── sectionsPerPage: int          # used for `inline` layout sections
├── showFooter: bool
└── showFee: bool
```

### Section (sealed base class)

All section types are defined in a single `section.dart` file. This is required for Dart's compile-time exhaustive switch on sealed classes without `part`/`part of` directives.

```text
Section (sealed)
├── name: String
├── hidden: bool
└── layout: SectionLayout         # fullPage | inline | flow
```

**SectionLayout values:**

- `fullPage` — section occupies an entire page alone
- `inline` — grouped with adjacent inline sections, up to `sectionsPerPage` per page
- `flow` — rendered continuously with automatic page breaks (`pw.MultiPage`)

### Section Types

```text
RegularSection extends Section
└── items: List<MenuItem>

SpecialSelection extends Section
├── sharedPrice: double
├── note: String
└── items: List<MenuItem>

WineSection extends Section
└── items: List<WineItem>

EventSection extends Section
└── items: List<EventItem>

CoverSection extends Section
├── venueName: String
├── logoPath: String?             # absolute path to image file
└── tagline: String
```

### Item Types

```text
MenuItem
├── name: String
├── description: String
├── price: double
└── allergens: List<int>          # EU allergen indices (0-based, see file-format.md)

WineItem
├── name: String
└── price: double

EventItem
├── name: String
├── time: String?                 # free-form, e.g. "19:00"
└── price: double?
```

### AppSettings

Global application settings. **Not** stored in `.imp` files. Persisted via `shared_preferences`.

```text
AppSettings
└── s3Config: S3Config?

S3Config
├── endpoint: String              # full URL, e.g. https://s3.example.com:9000
├── bucket: String
├── accessKey: String
└── secretKey: String
```

---

## Settings Layers

| Level | Scope | Stored in | Editable via |
| --- | --- | --- | --- |
| **App settings** | Global | System preferences | Settings popup → App tab |
| **Document settings** | Per `.imp` file | Inside `.imp` | Settings popup → Document tab |
| **Section settings** | Per section | Inside `.imp` | Section context menu → Layout settings |

---

## State Management

All providers use Riverpod 3.x `Notifier` / `NotifierProvider`. The older `StateNotifier` pattern is not used.

```text
documentProvider      NotifierProvider<DocumentNotifier, DocumentState>
settingsProvider      NotifierProvider<SettingsNotifier, AppSettings>
recentFilesProvider   FutureProvider<List<String>>
```

`DocumentState` holds the current `Document?`, the file path, and a dirty flag. All section mutations go through `DocumentNotifier` (addSection, removeSection, updateSection, reorderSections, etc.) and set `isDirty = true`.

---

## PDF Engine

The PDF engine runs entirely in memory and produces a `Uint8List` which is then either saved, printed, or displayed in the preview pane.

### Rendering Pipeline

```text
Document
  │
  ▼
PdfService.render(document, PdfFormat) → Future<Uint8List>
  │
  ├── select FormatSettings for the chosen format (a4 / a5)
  ├── collect visible sections (hidden == false)
  └── iterate sections:
        fullPage  → pw.Page       (one per section)
        inline    → pw.Page       (batches of up to sectionsPerPage)
        flow      → pw.MultiPage  (auto-overflow)
```

### Section Renderers

Renderers are standalone top-level functions, not a class hierarchy. Each receives the typed section and returns a `pw.Widget`:

| Function | File |
| --- | --- |
| `buildCoverContent` | `renderers/cover_renderer.dart` |
| `buildRegularSection` | `renderers/regular_renderer.dart` |
| `buildSpecialSelectionContent` | `renderers/special_selection_renderer.dart` |
| `buildWineSectionContent` | `renderers/wine_renderer.dart` |
| `buildEventSectionContent` | `renderers/event_renderer.dart` |

`pdf_theme.dart` contains shared styles: color conversion, font helpers, price formatter.

Adding a new section type requires: a new model class in `section.dart`, a new renderer function, a new editor widget, and a YAML serialization entry.

### Preview

`PdfPreviewPane` watches `documentProvider`, debounces 300ms, then calls `PdfService.render()` asynchronously in the main isolate. The previous `Uint8List` stays displayed while the new one is rendering; a small spinner in the pane header indicates a pending re-render. Format switches bypass the debounce and render immediately.

---

## Cloud Upload

Upload is S3-compatible (Cloudflare R2, MinIO, Backblaze B2, AWS S3, etc.).

Flow:

1. User opens `UploadDialog` via the Upload button
2. Selects format (A4/A5, defaults to `activeFormat`) and edits the object name
3. `PdfService.render()` generates the PDF in memory
4. `S3Service.upload()` streams the bytes via `minio_new`
5. On success, a presigned URL (1 hour) is shown as selectable text

`S3Service._parseEndpoint()` normalises the endpoint URL, extracting host, port, and SSL flag so the `Minio` client receives the individual parameters it expects.

---

## File I/O

- Open: `FilePicker.pickFiles()` → `ImpSerializer.fromYaml(String)`
- Save: `ImpSerializer.toYaml(Document)` → `FilePicker.saveFile()` (or direct write if path known)
- Unsaved changes: dirty flag in `DocumentState`; modal on close/home with Save / Discard / Cancel

---

## Project Structure

```text
lib/
├── main.dart
├── app.dart
│
├── core/
│   ├── allergens.dart              # EU 14 allergen constants
│   ├── constants.dart              # kAppName, kFileExtension, kPreviewDebounceMs, …
│   └── pdf_format.dart             # PdfFormat enum (a4 | a5)
│
├── data/
│   ├── models/
│   │   ├── document.dart
│   │   ├── document_settings.dart  # includes activeFormat: PdfFormat
│   │   ├── format_settings.dart
│   │   ├── app_settings.dart
│   │   ├── s3_config.dart
│   │   ├── section.dart            # sealed Section + all 5 subclasses (one file)
│   │   └── items/
│   │       ├── menu_item.dart
│   │       ├── wine_item.dart
│   │       └── event_item.dart
│   │
│   ├── serialization/
│   │   └── imp_serializer.dart
│   │
│   └── repositories/
│       ├── document_repository.dart
│       └── settings_repository.dart
│
├── services/
│   ├── pdf/
│   │   ├── pdf_service.dart        # pagination orchestrator → Uint8List
│   │   ├── pdf_theme.dart          # shared styles, color helpers, price formatter
│   │   └── renderers/
│   │       ├── cover_renderer.dart
│   │       ├── regular_renderer.dart
│   │       ├── special_selection_renderer.dart
│   │       ├── wine_renderer.dart
│   │       └── event_renderer.dart
│   ├── print_service.dart          # wraps Printing.layoutPdf
│   └── s3_service.dart             # testConnection + upload via minio_new
│
└── presentation/
    ├── screens/
    │   ├── home_screen.dart
    │   └── editor_screen.dart      # SplitView, preview toggle, _Sidebar, _BottomToolbar
    ├── widgets/
    │   ├── editors/
    │   │   ├── section_editor.dart
    │   │   ├── regular_section_editor.dart
    │   │   ├── special_selection_editor.dart
    │   │   ├── wine_section_editor.dart
    │   │   ├── event_section_editor.dart
    │   │   └── cover_section_editor.dart
    │   ├── items/
    │   │   ├── menu_item_row.dart
    │   │   ├── wine_item_row.dart
    │   │   └── event_item_row.dart
    │   ├── allergen_chips.dart
    │   ├── color_picker_field.dart
    │   ├── add_section_dialog.dart
    │   ├── section_settings_popup.dart
    │   ├── settings_popup.dart
    │   ├── pdf_preview_pane.dart
    │   ├── pdf_preview_dialog.dart
    │   ├── split_view.dart
    │   └── upload_dialog.dart
    └── providers/
        ├── document_provider.dart
        └── settings_provider.dart
```

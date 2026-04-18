# UX & Interface Design

## Principles

1. **Assume zero technical skill** — every action must be immediately understandable without a manual.
2. **Nothing is hidden unless it needs to be** — common actions (add item, add section, save, export) are always visible. Advanced settings are one level deeper.
3. **One document at a time** — no tabs, no multi-window complexity.
4. **Immediate feedback** — the preview pane shows the real output in real time so users always know what they are producing.

---

## Home Screen

Shown on launch when no document is open.

```text
┌──────────────────────────────────────────────────────┐
│                                                      │
│              🍴  imprint                             │
│                                                      │
│          [ + New Document ]   [ Open File ]          │
│                                                      │
└──────────────────────────────────────────────────────┘
```

- The logo (fork-and-knife icon + wordmark) is centered on the screen.
- Only two actions are presented: **New Document** (filled/primary button) and **Open File** (outlined button).
- No recent files list is shown in the current implementation.

---

## Editor Screen — Default (no preview)

```text
┌─────────────────────────────────────────────────────────────────┐
│  🍴  menu_ristorante.imp *                          [⚙]  [⊞]   │
├────────────────┬────────────────────────────────────────────────┤
│  ≡ Section 1   │                                                 │
│     regular    │   Proposta del giorno                          │
│  ≡ Proposta    │   special_selection  ·  full_page              │
│     special.. ●│                                                 │
│                │   Shared price  [ 55.00 ]                      │
│                │   Note  [ Non si fanno variazioni... ]         │
│                │                                                 │
│                │   ≡  Lonzino e radicchio marinato        ×     │
│                │      Description (optional)                     │
│                │      1  2  3  4  5  6  7  8  9 10 11 12 13 14 │
│                │                                                 │
│                │   [+ Add Item]                                  │
│                │                                                 │
├── Add Section ─┴────────────────────────────────────────────────┤
│  [Preview PDF]   [Print]   [Upload]                  [💾 Save]  │
└─────────────────────────────────────────────────────────────────┘
```

### Title bar

- App icon on the left; clicking it navigates home (prompts save if dirty).
- `*` suffix on filename = unsaved changes.
- `[⚙]` opens the settings popup.
- `[⊞]` (panel icon) toggles the preview pane.

### Sidebar

- Lists all sections in order; each tile shows the section name and type beneath it.
- `≡` on the left = drag handle for reordering.
- `●` = section is currently hidden (not exported).
- Clicking a section selects it and loads its contents in the main area.
- `⋮` button on hover opens the section context menu.
- **Add Section** button is pinned at the bottom of the sidebar.

### Main area

- Shows the content of the selected section.
- Type and layout shown as a subtitle under the section name (`regular · inline`, `special_selection · full_page`, etc.).
- Items are displayed as rows, each with a `≡` drag handle on the left and `×` remove button on the right.
- All 14 EU allergen numbers are shown as toggle chips on each item row; active allergens are highlighted.
- `[+ Add Item]` appends a new empty item row at the bottom of the list.
- When no sections exist, the sidebar shows "No sections yet." and the main area shows "Add a section to get started."

### Bottom toolbar

Always visible. Contains:

- **Preview PDF** — opens a fullscreen PDF preview screen (see below). Disabled when no document is open.
- **Print** — renders PDF in memory, then opens the system print dialog. Disabled when no document is open.
- **Upload** — opens the upload dialog. Disabled when no document is open.
- **Save** — saves to the current file path; if new document, opens a save-as dialog. Greyed out when no unsaved changes.

---

## Editor Screen — With Preview Pane

```text
┌────────────────────────────────────────────────────────────────────────────┐
│  🍴  menu_ristorante.imp *                                    [⚙]  [⊞]    │
├─────────────┬───────────────────────────┬──────────────────────────────────┤
│  ≡ Section 1│  Section 1                │  Preview              [A4] [A5]  │
│     regular │  regular · inline         │  ──────────────────────────────  │
│  ≡ Proposta │                           │  ┌────────────────────────────┐  │
│     special.│  ≡ Item 1          1.00 × │  │                            │  │
│             │  ≡ Item 2          2.00 × │  │   Section 1                │  │
│             │  ≡ Item 3          3.00 × │  │   Item 1             €1.00 │  │
│             │                           │  │   Item 2             €2.00 │  │
│             │  [+ Add Item]             │  │   Item 3             €3.00 │  │
│             │                           │  └────────────────────────────┘  │
├─ Add Section┴───────────────────────────┤                                  │
│  [Preview PDF]  [Print]  [Upload]                              [💾 Save]   │
└────────────────────────────────────────────────────────────────────────────┘
```

- `[A4]` / `[A5]` toggle in the preview header re-renders immediately using the corresponding format settings.
- A small spinner next to "Preview" indicates a render in progress; the previous page stays visible.
- Preview re-renders automatically ~300ms after any content change (debounced).
- Page navigation is provided by the `printing` package's `PdfPreview` widget.
- The preview pane is resizable by dragging the divider (clamped to 20–80% of the main area width).

---

## PDF Preview Screen

Opened by clicking **Preview PDF** in the bottom toolbar. Replaces the editor with a fullscreen view.

```text
┌──────────────────────────────────────────────────────────────┐
│  [✕]  PDF Preview                          [A4] [A5]  🔍 100% 🔍 │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│           ┌──────────────────────────────────┐              │
│           │                                  │              │
│           │   Section 1                      │              │
│           │   Item 1                  €1.00  │              │
│           │   Item 2                  €2.00  │              │
│           │   Item 3                  €3.00  │              │
│           │                                  │              │
│           └──────────────────────────────────┘              │
│                                                              │
├──────────────────────────────────────────────────────────────┤
│                        [🖨 Print]                            │
└──────────────────────────────────────────────────────────────┘
```

- `[✕]` closes the preview and returns to the editor.
- `[A4]` / `[A5]` toggle re-renders the PDF in the selected format.
- Zoom controls (magnifier icons + percentage) adjust the view scale.
- **Print** button at the bottom opens the system print dialog.

---

## Section Context Menu

Triggered by the `⋮` button on hover in the sidebar.

```text
  ┌───────────────────┐
  │  Layout settings  │
  │  Hide / Show      │
  │  Duplicate        │
  │  ─────────────    │
  │  Delete           │
  └───────────────────┘
```

- **Layout settings** opens the section settings popup (inline/full_page/flow).
- **Hide / Show** toggles the `hidden` flag (hidden sections are excluded from exports).
- **Duplicate** appends a copy of the section at the bottom.
- **Delete** asks for confirmation before removing.

Note: renaming is done by editing the section name directly in the main editor area, not through the context menu.

---

## Add Section

Clicking `[+ Add Section]` in the sidebar opens a small picker:

```text
  ┌──────────────────────────────────────────────┐
  │  Add a section                               │
  │                                              │
  │  [Regular]          Items with prices        │
  │  [Special proposal] One price, shared items  │
  │  [Wine list]        Wines and prices         │
  │  [Event program]    Items with times         │
  │  [Cover page]       Full-page intro page     │
  └──────────────────────────────────────────────┘
```

The new section is appended at the bottom of the sidebar and immediately selected.

---

## Settings Popup (⚙)

A centered modal dialog. Two tabs: **Document** and **App**.

### Document tab

```text
┌──────────────────────────────────────────────────┐
│  Settings                                   [✕]  │
│  [Document]  [App]                               │
├──────────────────────────────────────────────────┤
│  Format settings                                 │
│  Editing   [A4]  [A5]                            │
│                                                  │
│  Title                                           │
│  Font size [ 40 ]  Sections/p [ 2 ]  Color [██] │
│                                                  │
│  Items                                           │
│  Font size [ 13 ]  Color [██] #000000            │
│                                                  │
│  Descriptions                                    │
│  Font size [8.5]  Color [██] #555555             │
│                                                  │
│  Footer & Logo                                   │
│  Font size [9.0]  Color [██] #444444  Logo [ 65] │
│  [○] Show footer note    [●] Show cover charge   │
│                                                  │
│  Document                                        │
│  Cover charge [ 3.00 ]  Price symbol [€ Euro ▾]  │
│  Footer note  [________________________]         │
│                                                  │
└──────────────────────────────────────────────────┘
```

- **Editing** toggle (A4 / A5) switches which format's settings are displayed; each format has independent typography and color settings.
- **Title** group: font size, sections per page, and primary color (hex + color picker).
- **Items** group: font size and color for item names.
- **Descriptions** group: font size and color for item description text.
- **Footer & Logo** group: font size, color, logo size, and two toggles — "Show footer note" and "Show cover charge".
- **Document** section (below the fold): cover charge amount, price symbol (currency dropdown), and footer note text.
- All format settings are per-format (A4/A5) and applied immediately to the live preview.

### App tab

```text
┌──────────────────────────────────────────────────┐
│  Settings                                   [✕]  │
│  [Document]  [App]                               │
├──────────────────────────────────────────────────┤
│  Interface                                       │
│  Text scale  [────●──────────────]  125%         │
│  Theme  [System]  [Light]  [Dark]                │
│                                                  │
│  Cloud Storage (S3-compatible)                   │
│  Endpoint      [                          ]      │
│  Bucket        [                          ]      │
│  Access key    [                          ]      │
│  Secret key    [                     ] [👁]      │
│                                                  │
│  [ Test connection ]                             │
│                                                  │
└──────────────────────────────────────────────────┘
```

- **Text scale** slider adjusts the editor UI font size globally.
- **Theme** segmented button: System / Light / Dark.
- **Cloud Storage** fields: Endpoint, Bucket, Access key, Secret key (with reveal toggle).
- "Test connection" calls `S3Service.testConnection()` and shows success/failure inline.
- Credentials are saved to system preferences immediately on each keystroke, never to `.imp` files.

---

## Section Settings Popup

Opened via the section context menu → "Layout settings". Smaller modal.

```text
┌──────────────────────────────────────┐
│  Section settings               [✕] │
├──────────────────────────────────────┤
│  Layout                              │
│  [Full page] [Inline] [Flow]         │
│                                      │
│  Full page   — section alone on page │
│  Inline      — grouped with others  │
│  Flow        — spans pages as needed │
│                                      │
└──────────────────────────────────────┘
```

---

## Allergen Chips

Allergens are displayed as compact number chips throughout the editor.

```text
  allergens:   1   3   5
```

- Hovering over a chip shows a tooltip: e.g. `3 — Eggs`
- Clicking the chip area on an item row opens the allergen selector.
- The allergen selector shows all 14 EU allergens as a toggle grid (number + name).

---

## Upload Dialog

```text
┌──────────────────────────────────────────┐
│  Upload PDF                         [✕] │
├──────────────────────────────────────────┤
│  Format     [A4]  [A5]                   │
│  Object name  [ menu_ristorante-a4.pdf ] │
│  Destination: my-bucket @ https://...    │
│                                          │
│  ⟳ Uploading…                            │
│                                          │
│  ✓ https://…/menu_ristorante-a4.pdf?...  │
│                              [ Upload ]  │
│                      [ Upload again ]    │
└──────────────────────────────────────────┘
```

- Format selector defaults to the document's `activeFormat`.
- Changing the format updates the filename suffix automatically.
- Two phases are shown in sequence: "Rendering PDF…" → "Uploading…".
- On success, the presigned URL is shown as selectable text (valid for 1 hour).
- If no S3 config is set, a warning banner is shown and the Upload button is disabled.

---

## Unsaved Changes Warning

Triggered when closing the window or navigating to home with a dirty document.

```text
┌──────────────────────────────────────────┐
│  Unsaved changes                         │
│                                          │
│  menu_ristorante.imp has unsaved changes.│
│  Do you want to save before closing?     │
│                                          │
│  [Discard]  [Cancel]  [Save]             │
└──────────────────────────────────────────┘
```

- **Save** → saves file, then proceeds.
- **Discard** → discards changes, then proceeds.
- **Cancel** → returns to the editor, nothing happens.

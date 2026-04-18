# File Format — `.imp`

## Overview

Imprint documents are stored as `.imp` files. The format is YAML — human-readable, compact, and editable by hand during development. A future migration to a custom DSL is possible without breaking existing files, since the format is versioned.

The file encodes:

- Document-level metadata (fee, footer note)
- Per-format layout settings (A4, A5) and the active format preference
- An ordered list of sections

---

## Top-level Structure

```yaml
version: 1
fee: 3.0              # optional; omit or set to 0 to disable
footer_note: ""       # optional; empty string or omit

settings:
  active_format: a4   # optional; default a4; values: a4 | a5
  a4:
    title_font_size: 40
    primary_color: "#8E6B46"
    sections_per_page: 3
    show_footer: true
    show_fee: true
  a5:
    title_font_size: 32
    primary_color: "#000000"
    sections_per_page: 2
    show_footer: false
    show_fee: true

sections:
  - ...
  - ...
```

---

## Section Types

Every section has these common fields:

```yaml
- type: <section_type>    # required, see types below
  name: "Section name"    # required
  hidden: false           # optional, default false
  layout: inline          # optional, default inline; values: full_page | inline | flow
```

### `regular`

Standard section with individually priced items.

```yaml
- type: regular
  name: Antipasti
  hidden: false
  layout: inline
  items:
    - name: Speck di Ragogna "Molinaro"
      price: 12.00
      allergens: [3]
      description: ""           # optional
    - name: Flan agli spinaci
      price: 12.00
      allergens: [3, 4]
```

### `special_selection`

A fixed-price proposal where all items are included at one shared price.

```yaml
- type: special_selection
  name: Proposta del giorno
  hidden: false
  layout: full_page
  shared_price: 55.00
  note: "Non si fanno variazioni sulle proposte."
  items:
    - name: Lonzino e radicchio marinato
      allergens: [1, 3, 5]
    - name: Tagliatelle al ragù di faraona
      allergens: [6]
    - name: Guancialetto di vitello brasato
      allergens: [3, 9, 10]
    - name: Crostata alle pere e cioccolato
      allergens: []
```

Items in a special selection do not have individual prices.

### `wine_list`

A section for wines and other beverages. No allergens.

```yaml
- type: wine_list
  name: Bollicine
  hidden: false
  layout: flow
  items:
    - name: Prosecco superiore Brut "Col Funer"
      price: 22.00
    - name: Franciacorta Animante "Barone Pizzini"
      price: 45.00
```

### `event_program`

A section listing events or courses with optional times and prices.

```yaml
- type: event_program
  name: Serata di degustazione
  hidden: false
  layout: full_page
  items:
    - name: Aperitivo di benvenuto
      time: "19:00"
      price: 0.00
    - name: Degustazione vini
      time: "20:00"
      price: 35.00
    - name: Cena a buffet
      time: "21:30"
```

`time` and `price` are both optional on event items.

### `cover`

A full-page cover/header section.

```yaml
- type: cover
  layout: full_page
  venue_name: "Ristorante Al Fogolâr"
  logo: "/absolute/path/to/logo.png"   # optional; absolute path
  tagline: ""                           # optional subtitle
```

A document may contain at most one cover section, typically placed first.

---

## Allergens

Allergens are stored as integer indices (0-based) matching the EU regulation list.

```yaml
allergens: [1, 3, 5]
```

### EU Allergen Index

| Index | Allergen |
| --- | --- |
| 0 | Celery |
| 1 | Gluten-containing cereals |
| 2 | Crustaceans |
| 3 | Eggs |
| 4 | Fish |
| 5 | Lupin |
| 6 | Milk |
| 7 | Molluscs |
| 8 | Mustard |
| 9 | Tree nuts |
| 10 | Peanuts |
| 11 | Sesame seeds |
| 12 | Soybeans |
| 13 | Sulphur dioxide / Sulphites |

If the EU regulation adds allergens in the future, new indices are appended. Existing indices never change.

---

## Layout Values

| Value | Behaviour |
| --- | --- |
| `full_page` | Section occupies an entire page alone. Page breaks forced before and after. |
| `inline` | Section is grouped with adjacent inline sections. Number of sections per page is controlled by `settings.a4.sections_per_page` (or `a5`). |
| `flow` | Section renders continuously and breaks across as many pages as content requires. |

---

## Settings Reference

### FormatSettings (per export format)

| Field | Type | Default | Description |
| --- | --- | --- | --- |
| `title_font_size` | float | — | Section title font size in pt |
| `primary_color` | string | `"#000000"` | Hex color for titles and accents |
| `sections_per_page` | int | `2` | Max inline sections per page |
| `show_footer` | bool | `true` | Whether to render the footer note |
| `show_fee` | bool | `true` | Whether to display the cover charge |

---

## Versioning

The `version` field enables future migrations. When the serializer reads a file, it checks the version and applies any necessary transformations before constructing the in-memory model.

Current version: **1**

---

## Complete Example

```yaml
version: 1
fee: 3.00
footer_note: ""

settings:
  active_format: a4
  a4:
    title_font_size: 40
    primary_color: "#8E6B46"
    sections_per_page: 3
    show_footer: true
    show_fee: true
  a5:
    title_font_size: 32
    primary_color: "#000000"
    sections_per_page: 2
    show_footer: false
    show_fee: true

sections:
  - type: cover
    layout: full_page
    venue_name: "Ristorante Al Fogolâr"
    logo: "/home/user/menus/logo.png"
    tagline: ""

  - type: special_selection
    name: Proposta del giorno
    layout: full_page
    shared_price: 55.00
    note: "Non si fanno variazioni sulle proposte e vengono servite per l'intero tavolo."
    items:
      - name: Lonzino e radicchio marinato
        allergens: [1, 3, 5]
      - name: Tagliatelle al ragù di faraona e castagne
        allergens: [6]
      - name: Guancialetto di vitello brasato e tortino di patate
        allergens: [3, 9, 10]
      - name: Crostata alle pere e cioccolato
        allergens: []

  - type: regular
    name: Antipasti
    layout: inline
    items:
      - name: Speck di Ragogna "Molinaro"
        price: 12.00
        allergens: [3]
      - name: Flan agli spinaci, speck croccante e fonduta
        price: 12.00
        allergens: [3, 4]

  - type: regular
    name: Primi Piatti
    layout: inline
    items:
      - name: Risotto al radicchio e arancia
        price: 16.00
        allergens: []
      - name: Gnocchi di spinaci e pane su vellutata di ricotta
        price: 16.00
        allergens: []

  - type: wine_list
    name: Vini al calice
    layout: flow
    items:
      - name: Prosecco "Col Funer"
        price: 4.00
      - name: Sauvignon "Visintini"
        price: 4.50
```

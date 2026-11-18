# Type Filter Dropdown Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A type dropdown at the right of the panel's search field (All types, Folders, Documents, Images, Code, Video, Audio, Archives, Fonts, Apps), opened with ⌘P, that narrows name-search results and recents.

**Architecture:** A `TypeFilter` enum in FSearchKit owns the titles, the daemon token (`kind:dir`, `type:image`) and the recents match. `SearchModel` gains `typeFilter` and appends its token to the name query it sends, unless the query already has a typed `type:`/`kind:`. The app shows the pick as a button and pops a native `NSMenu`, following `ActionsMenu`'s pattern, so ↑/↓/↵/Esc and type-select come free.

**Tech Stack:** Swift 6, SwiftUI + AppKit, swift-testing, UniformTypeIdentifiers.

**Spec:** `docs/superpowers/specs/2026-11-17-type-filter-design.md`

## Global Constraints

- No daemon changes. The only new text sent is one token: `kind:dir` or `type:<doc|image|code|video|audio|archive|font|app>`.
- Name search only. The dropdown is hidden in Inside files and Definitions, and the token is never sent there.
- A typed `type:` or `kind:` word with a value wins: the token is not added and the button reads "Typed filter".
- ⌘P opens the menu. ⌘0 to ⌘9 stay as they are.
- `make test` and `make apptest` pass, and app unit coverage stays at or above 90% (ADR 0011).

## Review Focus

1. A pick changed while the old results are still shown, then ↵ pressed fast: ↵ must wait for the new results, never open a row from the old type.
2. A pick changed while the last word is a half-typed filter (`foo ext:`): the search must still run with the new type, not keep the old rows.
3. A query that already holds `kind:dir` plus a Folders pick: the token is sent once, never as `kind:dir kind:dir`.
4. Reopening within 60 seconds keeps the pick; after 60 seconds it is gone along with the query.
5. A quoted `"type:x"` word in name search reaches the daemon unquoted as a filter, so it counts as a typed filter and the pick steps aside.

---

### Task 1: `TypeFilter` in FSearchKit

**Files:**
- Create: `Packages/FSearchKit/Sources/FSearchKit/TypeFilter.swift`
- Test: `Packages/FSearchKit/Tests/FSearchKitTests/TypeFilterTests.swift`

**Interfaces:**
- Produces: `public enum TypeFilter: String, CaseIterable, Sendable { folders, documents, images, code, video, audio, archives, fonts, apps }` with `public var title: String` ("Folders", "Documents", …), `public var token: String`, `public static func query(_ q: String, with f: TypeFilter?) -> String`, `public static func typedFilter(in q: String) -> Bool`, `public func matches(path: String, isDirectory: Bool) -> Bool`.

- [ ] **Step 1: Write the failing tests** in `TypeFilterTests`:
  - tokens: `.folders.token == "kind:dir"`, `.documents.token == "type:doc"`, `.archives.token == "type:archive"`, `.apps.token == "type:app"`.
  - `query("invoice", with: .images) == "invoice type:image"`; `query("invoice", with: nil) == "invoice"`; `query("", with: .folders) == "kind:dir"`.
  - typed wins: `query("a kind:dir", with: .folders) == "a kind:dir"`, `query("a type:code", with: .images) == "a type:code"`.
  - quoted counts (the daemon unquotes in name search): `typedFilter(in: "\"type:code\"") == true`.
  - bare key is not a filter: `typedFilter(in: "type:") == false`.
  - matches: `.folders.matches(path: "/a/b", isDirectory: true)`; not `"/a/b.txt", false`. `.images` matches `x.jpg`, `x.HEIC`; `.code` matches `x.swift`; `.documents` matches `x.pdf`, `x.docx`, `x.txt` and not `x.swift`; `.video` matches `x.mov`; `.audio` matches `x.mp3`; `.archives` matches `x.zip`; `.fonts` matches `x.ttf`; `.apps` matches `/A/Safari.app` with `isDirectory: true`.
- [ ] **Step 2: Run** `cd Packages/FSearchKit && swift test --filter TypeFilterTests`: fails, no `TypeFilter`.
- [ ] **Step 3: Implement.** `typedFilter` uses QuerySplit's word splitting: a word that, unquoted, starts with `type:` or `kind:` with a non-empty value. `matches` uses `UTType(filenameExtension:)?.conforms(to:)`; documents = pdf, text, rtf, presentation, spreadsheet, plus OOXML/iWork identifiers if the tests need them, excluding sourceCode. Add a `shortcut:` comment: the UTType lists can differ from the daemon's extension lists, which only matters for recents.
- [ ] **Step 4: Run** the same filter: pass.
- [ ] **Step 5: Commit** `Add TypeFilter`.

### Task 2: Model, panel state and ⌘P key

**Files:**
- Modify: `Packages/FSearchKit/Sources/FSearchKit/SearchModel.swift` (state, `resultsAreCurrent`, `refresh`, `run`)
- Modify: `Packages/FSearchKit/Sources/FSearchKit/PanelKeys.swift` (`PanelKey.typeMenu`, `commandLetter`, `letterKeyCodes`, `actsOnResults`, `reduce`, `PanelState.typeFilter`)
- Test: `Packages/FSearchKit/Tests/FSearchKitTests/SearchModelTests.swift`, the existing PanelKeys tests file

**Interfaces:**
- Consumes: `TypeFilter.query(_:with:)`.
- Produces: `SearchModel.typeFilter: TypeFilter?` (public var), `SearchModel.answeredType: TypeFilter?` (public private(set)), `PanelKey.typeMenu`, `PanelState.typeFilter: TypeFilter?` (init parameter defaulted to nil).

- [ ] **Step 1: Write the failing tests** (RecordingBackend):
  - names mode, query `invoice`, `typeFilter = .folders`, `refresh()`: calls == `["search invoice kind:dir"]`.
  - content mode with `typeFilter = .images`: the grep call has no `type:image`.
  - after a settled search, setting `typeFilter` makes `resultsAreCurrent == false`; after `refresh()` it is true and `answeredType == typeFilter`.
  - half-typed: search `foo`, then query `foo ext:` and `typeFilter = .code`, `refresh()`: does not return early; `answered` reflects the new pick (cleared rows, phase idle), and once `ext:md` is finished the call carries `type:code`.
  - `PanelKey.commandLetter("p", shift: false) == .typeMenu`; `.typeMenu.actsOnResults == false`; reducing `.typeMenu` returns `.none` and leaves the state unchanged.
  - `PanelSession` round trip keeps `typeFilter`.
- [ ] **Step 2: Run** `swift test`: those fail.
- [ ] **Step 3: Implement.** `refresh` captures `typeFilter` with `q` and `mode`, records `requestedType`, and the half-typed early return also needs `typeFilter == requestedType`. Every place that sets `answered` also sets `answeredType`. `run` applies `TypeFilter.query` only on the plain names path (not the `contentSearch` branch) (the debug log keeps the typed query). Map key code `0x23` to `"p"`.
- [ ] **Step 4: Run** `make test`: all pass.
- [ ] **Step 5: Commit** `Model and keys for the type filter`.

### Task 3: Dropdown, menu and recents in the app

**Files:**
- Create: `App/Panel/TypeMenu.swift`
- Modify: `App/Panel/SearchView.swift` (button, ⌘P, onChange, recents filter, section title), `App/Panel/PanelInput.swift` (`firstKey` passes ⌘P via `commandLetter`; `rowsAreCurrent` half-typed branch also requires `model.answeredType == model.typeFilter`), `App/Panel/PanelController.swift` (resume and hide carry `typeFilter`)
- Test: `AppTests/PanelInputTests.swift`, `AppTests/AppMenuTests.swift` (or a new `AppTests/TypeMenuTests.swift`)

**Interfaces:**
- Consumes: Tasks 1 and 2.
- Produces: `enum TypeMenu { static func build(model: SearchModel) -> NSMenu; static var popUp: @MainActor (NSMenu, NSPoint, NSView) -> Void; static func show(model: SearchModel, in view: NSView?, at: CGRect) }`.

- [ ] **Step 1: Write the failing tests:**
  - `TypeMenu.build` has 10 items titled "All types", then each `TypeFilter.title` in case order; the item for the current pick has state `.on`; running item 2's action sets `model.typeFilter = .folders`, and item 0 sets nil.
  - `PanelInput.key(for: ⌘P press)` == `.typeMenu`; ⌘⌃P is nil.
  - `rowsAreCurrent` is false after the pick changes on a half-typed query.
- [ ] **Step 2: Run** `make apptest`: those fail.
- [ ] **Step 3: Implement.**
  - `TypeMenu` copies `ActionsMenu`'s `popUp` seam (inert in the test host) and target pattern.
  - SearchView, names mode only: a button at the right of the field reads `"Typed filter"` when `TypeFilter.typedFilter(in: query)`, else `typeFilter?.title ?? "All types"`, with a ▾ chevron. It is tinted with the accent colour when a pick applies, has accessibility identifier `typeFilter`, and clicking it calls `TypeMenu.show` anchored at the button's frame.
  - `handle`: `.typeMenu` in names mode opens the menu before `gate`; in other modes it is swallowed.
  - `.onChange(of: model.typeFilter)`: selection to 0, cancel the held key, refresh.
  - `shown`: recents filtered by `typeFilter?.matches(path:isDirectory:)`.
  - Section title: `typeFilter?.title` instead of "Files" when a pick applies.
- [ ] **Step 4: Run** `make apptest`: pass, coverage ≥ 90%.
- [ ] **Step 5: Commit** `Type filter dropdown in the panel`.

### Task 4: Docs and full check

**Files:** `docs/reference/keyboard-shortcuts.md` (⌘P row), `docs/reference/query-syntax.md` (one paragraph on the dropdown under Filters), `CHANGELOG.md` (Unreleased line).

- [ ] **Step 1:** Write the doc lines.
- [ ] **Step 2: Run** `make lint type test apptest build`: all pass.
- [ ] **Step 3:** Launch the Debug app against the bundled daemon and check by hand: ⌘P opens the menu, Folders narrows `invoice` to folders, an empty query shows recent folders, `kind:file` typed shows "Typed filter".
- [ ] **Step 4: Commit** `Docs for the type filter`.

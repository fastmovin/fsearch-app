# Type filter dropdown: design

Date: 2026-11-17. Status: proposed. Mockups: `docs/superpowers/mockups/type-filter.html` (option A).

## Why

The daemon already filters by type (`type:image`, `kind:dir`), but the only way to learn that is the `?` cheat sheet. A visible picker makes "only folders" or "only images" one keystroke away and shows when a filter is on. It's for Brian's own copy first. An upstream pull request may come later.

## Goals

- A dropdown at the right of the search field: All types, Folders, Documents, Images, Code, Video, Audio, Archives, Fonts, Apps.
- ⌘P opens it. ↑/↓ and ↵ pick, Esc closes. Clicking works too.
- While a type is picked, the dropdown is highlighted, the section header names the type ("Folders"), and the results narrow.
- With an empty query, the recents list is filtered by the picked type.

## Non-goals

- No daemon changes. The picker only adds `kind:dir` or `type:<value>` to what is sent.
- No picker in Inside files or Definitions: content search only reads text and code, so the type picker adds little there. The dropdown is hidden in those modes.
- No tabs, no suggestion rows, no completion for typed `type:` values (options B and C).

## Anti-goals

- Breaking typed filters. Anything you can type today works as before.
- Clashing with existing keys. ⌘1 to ⌘9 already act on result rows, so the mockup's ⌘0 to ⌘4 shortcuts are dropped. ⌘P is free (`PanelKeys.commandLetter` binds only Y, K and ⇧C).

## Approaches

| Option | Tradeoff | Outcome |
|---|---|---|
| A. Dropdown in the search bar | Shows the filter, works on an empty query, costs no space. Most work, in the key handling. | Chosen (Brian, 2026-11-17) |
| B. Suggestion rows plus completion | Smallest, teaches syntax. Filter stays hidden in text, needs a query. | Not chosen |
| C. Tabs above results | Clear, but uses a row of a fixed 460-pt panel. | Not chosen |

## Behaviour (calls made by Claude, accepted by Brian's "go with your recommendations")

- **Where it applies:** name search only.
- **Typed filter wins:** if the query already has a `type:` or `kind:` word, the picker's token is not added and the dropdown reads "Typed filter" until that word is gone.
- **How long it sticks:** it follows the query. The 60-second resume window that keeps the query also keeps the pick, and a cleared query on a later open also clears the pick.
- **Clearing it:** pick All types. Backspace in an empty field still only drops a mode chip, as today.
- **Recents filter:** Folders keeps entries with `isDirectory`. Other types match the file's UTType (`UniformTypeIdentifiers`: image, movie, audio, archive, font, application, source code, and documents as PDF, text, and Office/iWork types). This can disagree with the daemon's extension lists at the edges; that's acceptable for recents and gets a `shortcut:` comment.
- **Fresh results:** the pick is part of what the model counts as "the query answered", so ↵ pressed right after changing the pick waits for the new results, the same as after typing.

## Constraints

- Keep the repo's test gates green: FSearchKit tests, and the app unit-test coverage gate at 90% (ADR 0011).
- Build needs `xcodegen` and `cargo` (for `make daemon`), neither installed on zod yet.

## Left to the builder

- The exact model shape for the pick in `SearchModel` and how it joins the sent query.
- Whether the popup is a SwiftUI `Menu` or a custom overlay like `AppMenuOverlay`. A custom overlay is likely, so ↑/↓/↵ stay inside the panel's key handling.
- The test split between FSearchKit and AppTests.

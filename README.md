# omarchy-yoyo-ui

Shared QML components for my [Omarchy](https://omarchy.org) shell plugins
(Throttle, System Tidy, Notification Center), so the panels look and behave the
same and the code lives in one place.

Plugins **vendor** a pinned copy into `vendor/yoyo-ui/` (no submodules:
`omarchy plugin add` does a plain clone, and the plugin has to work straight
from that). Every colour, size and font comes from `qs.Commons`
(`Color` + `Style`): the library has no colours of its own.

![preview](docs/preview.png)

## Components

| Type | What it is |
| --- | --- |
| `Theme` (singleton) | Colour roles (`fg`, `dim`, `faint`, `accent`, `urgent`, `background`, `line`, `hoverFill`, `normalFill`, `selectedFill`, `tint(c, a)`), metrics (`edge`, `gap`, `rowHeight`, `dataRowHeight`, `smallRowHeight`) and type sizes (`caption`, `body`, `title`, `heading`). Writable: `foreground`, `fontFamily`. |
| `ChipRow` | Tab / filter chips. `chips: [{ key, label }]`, `selectedKey`, `compact`, `cursorIndex` + `cursorActive` (keyboard cursor), optional `foreground` / `fontFamily`. Signals `selected(key)`, `chipHovered(index)`. |
| `HeaderChip` | Small action chip. `text`, `tooltipText`, `on`, `enabled`, `danger` (urgent fill when on), optional `foreground` / `fontFamily`; `hovered`. Signal `clicked()`. |
| `ActionRow` | `CursorSurface` row: `title`, `subtitle` and a chip. `confirm: true` makes it two-step: first `activate()` arms (`confirmText`, urgent, `confirmTooltip`) for `armMs` (3000), the second fires `triggered()`. Afterwards the chip shows `doneText` for `doneMs` (1500) if `doneText` is set. Leaving the row (`hasCursor` false) disarms. Signal `rowHovered()`. |
| `EmptyState` | Centred "nothing here yet": `title` (dim, body) + optional `subtitle` (faint, caption). |
| `KeyHints` | Footer hints, `hints: [["Tab", "tabs"], ["j k", "rows"]]`. |
| `StatusFooter` | Footer bar (height `Style.space(18)`): `hints`, replaced by `statusText` while set (`statusKind`: `""`, `"progress"`, `"done"` = accent, `"error"` = urgent), optional `rightText`. `flash(text, kind)` sets a status that clears itself (errors after `errorMs` 6000, others after `doneMs` 2500, `"progress"` stays); `clear()`. |

All of them read `Theme` from their own copy, so they follow whatever the
plugin's `Panel.qml` binds into it.

## Using it in a plugin

### 1. Vendor it

Copy [`tools/sync-ui.sh`](tools/sync-ui.sh) into the plugin as
`tools/sync-ui.sh` (it works on its parent directory, the plugin root), then:

```sh
tools/sync-ui.sh v0.1.0      # or any tag / commit
git add tools/sync-ui.sh vendor/yoyo-ui
```

That clones this repo, checks the ref out and replaces `vendor/yoyo-ui/` with
the contents of `ui/`, plus:

- `vendor/yoyo-ui/VERSION`: `ref`, the full `commit` hash, `repo`;
- `vendor/yoyo-ui/MANIFEST`: sha256 of every vendored file.

`YOYO_UI_REPO=/path/or/url tools/sync-ui.sh <ref>` uses another source (a local
checkout while developing the library). Update = run it again with the new tag
and commit the result.

### 2. Keep it untouched

```sh
tools/sync-ui.sh --check            # fails if any vendored file was edited, added or removed
tools/sync-ui.sh --check-upstream   # also re-fetches the pinned commit and compares (network)
```

Add `tools/sync-ui.sh --check` to the plugin's test script (`tests/unit.sh`).
Fixes go here first, get a tag, then get synced; never edit `vendor/yoyo-ui/`.

### 3. Import it

It is a plain **directory import** with a `qmldir` (no `module` line):

```qml
// Panel.qml, BarWidget.qml … (plugin root)
import qs.Commons
import "vendor/yoyo-ui"

// components/*.qml (one level down)
import "../vendor/yoyo-ui"

// or qualified, if a name would clash
import "../vendor/yoyo-ui" as Yoyo   // Yoyo.Theme.fg, Yoyo.ChipRow { … }
```

Then bind the theme to the bar once, in `Panel.qml`:

```qml
Binding { target: Theme; property: "foreground"; value: root.contentForeground }
Binding { target: Theme; property: "fontFamily"; value: root.contentFontFamily }
```

### Import gotchas (verified with quickshell, offscreen, see `tests/run.sh`)

- **Use the relative path import.** `import Yoyo.Ui` does **not** resolve:
  quickshell reports `module "Yoyo.Ui" is not installed`, and a plugin cannot
  add import paths. Only `qs.*` (the shell's own dirs) and relative paths work.
- **One `Theme` per vendored copy.** The singleton is keyed by the directory, so
  `Panel.qml` (`"vendor/yoyo-ui"`), `components/` (`"../vendor/yoyo-ui"`) and
  qualified imports all get the *same* instance: the test retargets
  `Theme.foreground` from `Panel.qml` and checks all three see it. Two plugins
  each have their own copy, so their themes never interfere and they can pin
  different versions.
- **Delete the plugin's old `theme/`** (and stop importing `"theme"`). With both
  imported, `Theme` means two different singletons and the bar bindings only
  reach one of them.
- **Unqualified import beats same-folder files.** If `components/HeaderChip.qml`
  still exists and `components/X.qml` imports `"../vendor/yoyo-ui"`
  unqualified, `HeaderChip` in `X.qml` is the *library* one, silently. Delete
  the local duplicate, or rename it, or import the library qualified.
- **No `module` line in `qmldir`**: keep it a directory qmldir, otherwise every
  plugin's copy would claim the same module URI.
- Needs Omarchy's shell: `qs.Commons` (`Color`, `Style`) and `qs.Ui`
  (`CursorSurface`, `PanelToolTip`).
- qmllint: run it the usual way (`qmllint -I /usr/share/omarchy/shell -I .`);
  the vendored dir needs no extra `-I`. `qs.*` import / unqualified warnings
  are the same baseline as for any plugin.

## Versioning

Semver tags (`v0.1.0`, …). Patch: fixes with no visual or API change. Minor:
new components / properties, defaults unchanged. Major (or minor while 0.x):
anything that changes how an existing plugin looks or what it must pass.
Plugins pin a tag through `vendor/yoyo-ui/VERSION` and update deliberately.
See [CHANGELOG.md](CHANGELOG.md).

## Tests

```sh
tests/run.sh [OUT_DIR]   # default tests/out
```

Runs qmllint on `ui/`, round-trips `tools/sync-ui.sh` against a throwaway repo
(clean `--check`, edited / added / removed file and forged `MANIFEST` all
caught, bad ref fails), then renders `tests/fixture/` (a fake plugin with the
library vendored by the script) offscreen with quickshell, twice (normal and
with `Theme.foreground` retargeted), checking for QML warnings and that every
import site shares one `Theme`. Needs `qs` and `/usr/share/omarchy/shell`.

## License

MIT

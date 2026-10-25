# Changelog

## v0.2.0

New:

- `ConfirmController`: shared two-step confirm (`arm` / `confirm` / `disarm`,
  stable `armedKey`, `timeout` default 4 s).
- `ActionRow`: `actionStyle: "button"` (fixed `actionWidth`, default 72, disabled
  opacity 0.45, urgent row tint while armed), which matches System Tidy's
  `ActionListRow` pixel for pixel. Also `badge` + `badgeVariant`
  (`normal` / `warn` / `danger`), `actionVisible`, `actionEnabled`, `danger`,
  `armedText` (subtitle while armed), writable `armed`, a shared `controller` +
  `confirmKey`, `disarmOnLeave`, `activateOnClick`, and signals
  `actionClicked()` / `triggered()`.
- `HeaderChip`: confirm mode (`confirm`, `confirmText` "Confirm?",
  `confirmTooltip`, `armMs` 4 s, `controller` / `confirmKey`, `armed`,
  `activate()`, `disarm()`, `triggered()`). Disabling the chip disarms it.
- `EmptyState`: `fitContent` for whole-pixel centring like
  `Text { anchors.centerIn }`; padding documented (`topPadding`,
  `bottomPadding`, `spacing`).
- Tests: `tests/fixture/logic.qml` (behaviour checks), with new fixture rows
  for the button style, badges and confirm chips.
- README: confirm pattern, multi-monitor `Theme` limitation, and the test-script
  wording for `--check`.

Breaking / migration:

- `ActionRow.chip` is now `actionLabel`: rename `chip:` to `actionLabel:`.
  Nothing else changes for the default chip style (Throttle renders identically).
- `HeaderChip` no longer redeclares `property bool enabled` (qmllint
  `[property-override]`). `enabled: …` still works, but it is now the real
  `Item.enabled`, so it also disables the chip's children and focus. Visuals are
  unchanged (opacity 0.4, no hover or tooltip while disabled). Code that read
  `chip.enabled` expecting the old shadow property gets the inherited one, which
  has the same value.
- If you are moving from a plugin-local `theme/`: its `contentForeground` /
  `contentFontFamily` map to `Theme.foreground` / `Theme.fontFamily`, and
  component overrides are `foreground` / `fontFamily`.
- `ActionRow.danger` defaults to `false`, as before for the chip style. Tidy's
  old `ActionListRow` defaulted to `true`, so set it explicitly when you port
  button rows.

## v0.1.0

First release: `Theme`, `ChipRow`, `HeaderChip`, `ActionRow`, `EmptyState`,
`KeyHints`, `StatusFooter`; `tools/sync-ui.sh` (vendor a pinned ref, `--check`,
`--check-upstream`); offscreen render test. Extracted from Throttle 1.2.1 and
System Tidy 1.4.0 without visual changes.

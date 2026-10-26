# Changelog

## v0.3.0

New (all additive; nothing existing changes how it looks or what it takes):

- `Theme` tokens: `hairline` (divider / border thickness, `Style.spacing.hairline`),
  `icon` / `iconSmall` (`Style.font.icon*`), `buttonFill` (`tint(fg, 0.06)`, idle
  small buttons), `separator` (`tint(fg, 0.08)`), panel widths `panelNarrow` /
  `panelWidth` / `panelWide` (`Style.space(480 / 520 / 560)`). Every token is a
  typed property, so plugins can use `Theme.hairline` / `Theme.icon` instead of
  `Style.spacing.hairline` / `Style.font.icon` and drop their
  `// qmllint disable missing-property` comments. `tint()` is typed
  (`color`, `real`) → `color`.
- `StatusFooter`: `separator` (off by default), `separatorGap` (`Theme.edge`),
  `separatorStrength` (0.08): the faint rule above the footer that Throttle and
  System Tidy drew with a `PanelSeparator`. It sits outside the footer's box.
- `RowHover`: the row `MouseArea` from Throttle (hover → `hovered(rowIndex)`,
  `clickable`, `pointer`).
- `TitleText` / `CaptionText`: `ActionRow`'s title and subtitle text styles.
- `tests/run.sh`: qmllint resolves `qs.Commons` / `qs.Ui` through a temp `qs/`
  root and fails on any warning (before, the imports did not resolve and
  warnings never failed); ShellCheck when installed; logic tests for the new
  pieces; the preview shows them.

Fixed:

- `ui/` is qmllint-clean with real imports: `ChipRow` / `KeyHints` use
  `pragma ComponentBehavior: Bound` and qualified delegate ids; `ChipRow` /
  `HeaderChip` read `Theme.hairline` / `Theme.caption` / `Theme.body` (same
  values as before). Renders are pixel-identical to v0.2.0.
- `tools/sync-ui.sh`: SC2015 in `--check` (`[ ] && [ ] || die` is now an
  `if`). Re-copy it into plugins when you sync.

Breaking: none.

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

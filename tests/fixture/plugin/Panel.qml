import QtQuick
import Quickshell
import qs.Commons
import qs.Commons as Commons
import "vendor/yoyo-ui"
import "components" as Local

// Stand-in for a plugin's Panel.qml: unqualified vendored import, the
// Theme bindings every plugin does, and one of each component.
Rectangle {
  id: root
  // YOYO_TINT=1 retargets Theme.foreground to prove every import site shares
  // one singleton instance per vendored copy.
  readonly property color expected: Quickshell.env("YOYO_TINT") === "1" ? Commons.Color.accent : Commons.Color.foreground
  readonly property color seenRoot: Theme.fg
  readonly property color seenComponent: probe.seen
  readonly property color seenQualified: qprobe.seen

  Binding { target: Theme; property: "foreground"; value: root.expected }
  Binding { target: Theme; property: "fontFamily"; value: Style.font.family }

  color: Theme.background
  height: col.implicitHeight + 2 * Theme.edge

  Column {
    id: col
    x: 0; y: Theme.edge
    width: parent.width
    spacing: Theme.edge

    ChipRow {
      x: Theme.edge
      chips: [{ key: "a", label: "Apps" }, { key: "b", label: "Traffic" }, { key: "c", label: "Settings" }]
      selectedKey: "a"; cursorActive: true; cursorIndex: 2
    }
    ChipRow {
      x: Theme.edge; compact: true
      chips: [{ key: "live", label: "Live" }, { key: "week", label: "Week" }, { key: "month", label: "Month" }]
      selectedKey: "week"
    }
    Row {
      x: Theme.edge; spacing: Style.space(6)
      HeaderChip { text: "Idle" }
      HeaderChip { text: "On"; on: true }
      HeaderChip { text: "Remove"; on: true; danger: true }
      HeaderChip { text: "Disabled"; enabled: false }
    }
    ActionRow { width: parent.width; title: "Copy diagnostics"; subtitle: "Plain-text report to the clipboard"; chip: "Copy" }
    ActionRow { width: parent.width; title: "Clear history"; subtitle: "Two-step confirm (armed)"; chip: "Clear"; confirm: true; armed: true; hasCursor: true }
    EmptyState { width: parent.width; title: "Nothing here yet"; subtitle: "Rows show up when there is something to show" }
    Local.Probe { id: probe; x: Theme.edge }
    Local.QualifiedProbe { id: qprobe; x: Theme.edge }
    KeyHints { x: Theme.edge; hints: [["Tab", "tabs"], ["j k", "rows"], ["Enter", "open"]] }
    StatusFooter { width: parent.width; hints: [["Tab", "tabs"]]; rightText: "≈ 1.2 GiB reclaimable" }
    StatusFooter { width: parent.width; statusText: "Removing 3 packages…"; statusKind: "progress"; rightText: "≈ 1.2 GiB" }
    StatusFooter { width: parent.width; statusText: "pacman failed: exit 1"; statusKind: "error" }
  }
}

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

  ConfirmController { id: confirmCtl }
  Component.onCompleted: confirmCtl.arm("pkg:ruby")

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
    ActionRow { width: parent.width; title: "Copy diagnostics"; subtitle: "Plain-text report to the clipboard"; actionLabel: "Copy" }
    ActionRow { width: parent.width; title: "Clear history"; subtitle: "Two-step confirm (armed)"; actionLabel: "Clear"; confirm: true; armed: true; hasCursor: true }
    // Button style, sharing one ConfirmController (armed row 2 by key)
    ActionRow { width: parent.width; actionStyle: "button"; controller: confirmCtl; confirmKey: "pkg:cmake"; confirm: true; danger: true
      title: "cmake"; subtitle: "112 MiB · installed 2026-03-02"; actionLabel: "Remove"; badge: "protected" }
    ActionRow { width: parent.width; actionStyle: "button"; controller: confirmCtl; confirmKey: "pkg:ruby"; confirm: true; danger: true
      title: "ruby"; subtitle: "48 MiB"; actionLabel: "Remove"; badge: "irreversible"; badgeVariant: "warn"; armedText: "pacman -Rns ruby — again to confirm" }
    ActionRow { width: parent.width; actionStyle: "button"; title: "keyring"; subtitle: "disabled · ~/.config/autostart"; actionLabel: "Enable"
      badge: "system"; badgeVariant: "danger"; actionEnabled: false }
    Row {
      x: Theme.edge; spacing: Style.space(6)
      HeaderChip { text: "Empty trash"; confirm: true; danger: true; controller: confirmCtl; confirmKey: "trash" }
      HeaderChip { text: "Armed elsewhere"; confirm: true; controller: confirmCtl; confirmKey: "pkg:ruby" }
    }
    EmptyState { width: parent.width; title: "Nothing here yet"; subtitle: "Rows show up when there is something to show" }
    EmptyState { width: parent.width; fitContent: true; topPadding: 0; bottomPadding: Style.space(8); title: "fitContent: centred like anchors.centerIn" }
    Local.Probe { id: probe; x: Theme.edge }
    Local.QualifiedProbe { id: qprobe; x: Theme.edge }
    KeyHints { x: Theme.edge; hints: [["Tab", "tabs"], ["j k", "rows"], ["Enter", "open"]] }
    Item {
      width: parent.width; height: Theme.smallRowHeight
      Rectangle { anchors.fill: parent; color: hover.containsMouse ? Theme.hoverFill : "transparent" }
      Row {
        x: Theme.edge; anchors.verticalCenter: parent.verticalCenter; spacing: Theme.gap
        Rectangle {
          width: Theme.icon + Theme.edge; height: width; radius: Style.cornerRadius
          color: Theme.buttonFill; border.width: Theme.hairline; border.color: Theme.line
          Text { anchors.centerIn: parent; text: "×"; color: Theme.dim; font.family: Theme.fontFamily; font.pixelSize: Theme.icon }
        }
        Column {
          anchors.verticalCenter: parent.verticalCenter
          TitleText { text: "TitleText + CaptionText" }
          CaptionText { text: "RowHover row · Theme.icon in a Theme.buttonFill box" }
        }
      }
      RowHover { id: hover; clickable: true }
    }
    Item { width: parent.width; height: Theme.edge }
    StatusFooter { width: parent.width; separator: true; hints: [["Tab", "tabs"]]; rightText: "separator: true · ≈ 1.2 GiB reclaimable" }
    StatusFooter { width: parent.width; statusText: "Removing 3 packages…"; statusKind: "progress"; rightText: "≈ 1.2 GiB" }
    StatusFooter { width: parent.width; statusText: "pacman failed: exit 1"; statusKind: "error" }
  }
}

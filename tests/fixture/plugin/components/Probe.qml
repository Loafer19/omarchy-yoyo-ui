import QtQuick
import "../vendor/yoyo-ui"

// components/ imports the same copy with "../vendor/yoyo-ui".
Row {
  readonly property color seen: Theme.fg
  spacing: 8
  HeaderChip { text: "components/ import"; on: true }
  Text { text: "Theme.fg seen here"; color: Theme.fg; font.family: Theme.fontFamily; font.pixelSize: Theme.caption; anchors.verticalCenter: parent.verticalCenter }
}

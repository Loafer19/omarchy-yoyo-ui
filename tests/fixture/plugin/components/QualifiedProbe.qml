import QtQuick
import qs.Ui
import "../vendor/yoyo-ui" as Yoyo

// Qualified import next to qs.Ui (which has its own types): no clash.
Row {
  readonly property color seen: Yoyo.Theme.fg
  spacing: 8
  Yoyo.HeaderChip { text: "qualified import"; tooltipText: "uses PanelToolTip from qs.Ui" }
  Text { text: "Yoyo.Theme.fg"; color: Yoyo.Theme.fg; font.family: Yoyo.Theme.fontFamily; font.pixelSize: Yoyo.Theme.caption; anchors.verticalCenter: parent.verticalCenter }
}

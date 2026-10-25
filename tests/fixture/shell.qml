import QtQuick
import Quickshell
import qs.Commons as Commons
import "plugin" as P

// Offscreen preview: loads plugin/Panel.qml the way a plugin is laid out
// (vendor/yoyo-ui next to Panel.qml, components/ one level down), grabs it to
// YOYO_OUT and prints which colour each import site sees for Theme.fg.
ShellRoot {
  id: shell
  property string out: Quickshell.env("YOYO_OUT") || "/tmp/yoyo-ui-preview.png"
  FloatingWindow {
    implicitWidth: 460; implicitHeight: 700
    color: Commons.Color.background
    P.Panel { id: panel; width: 460 }
  }
  Timer {
    interval: 1200; running: true
    onTriggered: panel.grabToImage(function(r) {
      r.saveToFile(shell.out)
      console.log("probe expected=" + panel.expected + " root=" + panel.seenRoot + " components=" + panel.seenComponent + " qualified=" + panel.seenQualified)
      console.log("saved " + shell.out + " " + panel.width + "x" + panel.height)
      Qt.quit()
    })
  }
}

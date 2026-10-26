import QtQuick
import Quickshell
import qs.Commons
import "plugin/vendor/yoyo-ui"

// Behaviour tests for ConfirmController, ActionRow, HeaderChip,
// EmptyState.fitContent, Theme tokens, StatusFooter.separator, RowHover and
// the text styles. Prints PASS/FAIL lines, then "logic done N M".
ShellRoot {
  id: shell
  property int pass: 0
  property int fail: 0
  // The enabled button MouseArea with a pointing-hand cursor.
  function findMouse(item) {
    for (var i = 0; i < item.children.length; i++) {
      var c = item.children[i]
      if (c.cursorShape === Qt.PointingHandCursor && c.visible && c.parent.visible) return c
      var f = shell.findMouse(c)
      if (f) return f
    }
    return null
  }

  // Colours as #aarrggbb strings: colour properties round, so compare what renders.
  function sameColor(a, b) { return String(Qt.color(a)) === String(Qt.color(b)) && Qt.color(a).a.toFixed(2) === Qt.color(b).a.toFixed(2) }

  function check(name, cond) {
    if (cond) { pass++; console.log("PASS " + name) } else { fail++; console.log("FAIL " + name) }
  }

  ConfirmController { id: ctl }
  ConfirmController { id: fast; timeout: 100 }

  FloatingWindow {
    implicitWidth: 600; implicitHeight: 400
    Item {
      anchors.fill: parent
      ActionRow { id: own; width: 400; title: "t"; subtitle: "s"; actionLabel: "Clear"; confirm: true; doneText: "Cleared"
        property int fired: 0; onTriggered: fired++ }
      ActionRow { id: r1; width: 400; actionStyle: "button"; controller: ctl; confirmKey: "k1"; confirm: true; actionLabel: "Remove"; armedText: "again"
        property int fired: 0; onTriggered: fired++ }
      ActionRow { id: r2; width: 400; actionStyle: "button"; controller: ctl; confirmKey: "k2"; confirm: true; actionLabel: "Remove"
        property int fired: 0; onTriggered: fired++ }
      ActionRow { id: plain; width: 400; actionStyle: "button"; controller: ctl; confirmKey: "k3"; actionLabel: "Enable"
        property int fired: 0; onTriggered: fired++ }
      ActionRow { id: off; width: 400; actionLabel: "Nope"; actionEnabled: false
        property int fired: 0; onTriggered: fired++ }
      ActionRow { id: routed; width: 400; actionStyle: "button"; controller: ctl; confirmKey: "k4"; confirm: true
        activateOnClick: false; actionLabel: "Remove"
        property int fired: 0; property int clicks: 0; onTriggered: fired++; onActionClicked: clicks++ }
      HeaderChip { id: chip; text: "Empty trash"; confirm: true; danger: true
        property int fired: 0; property int clicks: 0; onTriggered: fired++; onClicked: clicks++ }
      HeaderChip { id: simple; text: "DND"
        property int fired: 0; onTriggered: fired++ }
      Item { id: boxA; width: 333; height: 41; Text { id: refText; anchors.centerIn: parent; text: "Trash is empty"; color: Theme.dim; font.family: Theme.fontFamily; font.pixelSize: Theme.body } }
      Item { id: boxB; width: 333; height: 41
        EmptyState { id: fit; anchors.centerIn: parent; width: parent.width; topPadding: 0; bottomPadding: 0; fitContent: true; title: "Trash is empty" } }
      StatusFooter { id: plainFooter; width: 300 }
      StatusFooter { id: ruledFooter; width: 300; separator: true }
      StatusFooter { id: gapFooter; width: 300; separator: true; separatorGap: 4; separatorStrength: 0.2 }
      Item { width: 200; height: 30
        RowHover { id: hoverPlain; rowIndex: 3
          property int seen: -1; onHovered: (i) => seen = i } }
      Item { width: 200; height: 30; RowHover { id: hoverClick; clickable: true } }
      Item { width: 200; height: 30; RowHover { id: hoverArrow; clickable: true; pointer: false } }
      TitleText { id: titleText; text: "t" }
      CaptionText { id: captionText; text: "c" }
    }
  }

  Timer { id: wait; interval: 250; property var then: null; onTriggered: then() }

  Component.onCompleted: {
    // ConfirmController
    check("controller starts disarmed", !ctl.armed && ctl.armedKey === "")
    check("confirm(a) arms, returns false", ctl.confirm("a") === false && ctl.armedKey === "a" && ctl.armed)
    check("confirm(b) re-arms b", ctl.confirm("b") === false && ctl.armedKey === "b" && !ctl.isArmed("a"))
    check("confirm(b) again returns true and disarms", ctl.confirm("b") === true && !ctl.armed)
    check("empty key never arms", ctl.confirm("") === false && !ctl.armed && !ctl.isArmed(""))
    ctl.arm("x"); ctl.disarm()
    check("disarm()", !ctl.armed)
    check("default timeout 4000", ctl.timeout === 4000)

    // ActionRow, own controller (Throttle style)
    own.activate()
    check("own row: first activate arms", own.armed && own.fired === 0 && own.actionText === "Confirm")
    own.activate()
    check("own row: second activate triggers + done text", !own.armed && own.fired === 1 && own.actionText === "Cleared")
    own.activate(); own.hasCursor = true; own.hasCursor = false
    check("own row: leaving the row disarms", !own.armed)

    // ActionRow with a shared controller
    r1.activate()
    check("shared: r1 armed, r2 not", r1.armed && !r2.armed && ctl.armedKey === "k1")
    r2.activate()
    check("shared: arming r2 disarms r1", r2.armed && !r1.armed && r1.fired === 0 && r2.fired === 0)
    r2.activate()
    check("shared: r2 confirms", r2.fired === 1 && !ctl.armed)
    r1.activate(); plain.activate()
    check("shared: non-confirm action runs at once and disarms others", plain.fired === 1 && !ctl.armed)
    r1.activate()
    check("shared: keyboard path via controller.confirm(key)", ctl.confirm("k1") === true && r1.fired === 0 && !r1.armed)
    off.activate()
    check("disabled action does nothing", off.fired === 0)

    // activateOnClick: false -> a click only reports, the owner arms
    var ma = shell.findMouse(routed)
    if (ma) ma.clicked(null)
    check("activateOnClick false: click only emits actionClicked", ma !== null && routed.clicks === 1 && routed.fired === 0 && !routed.armed)
    ctl.confirm("k4")
    check("activateOnClick false: armed via the shared controller", routed.armed && routed.actionText === "Confirm")
    ctl.disarm()

    // HeaderChip
    simple.activate()
    check("plain chip triggers on first click", simple.fired === 1)
    chip.activate()
    check("confirm chip: first click arms, shows Confirm?", chip.armed && chip.fired === 0 && chip.clicks === 1)
    chip.activate()
    check("confirm chip: second click triggers", !chip.armed && chip.fired === 1 && chip.clicks === 2)
    chip.activate(); chip.disarm()
    check("confirm chip: disarm() (Esc)", !chip.armed)
    chip.activate(); chip.enabled = false
    check("confirm chip: disabling disarms", !chip.armed)
    chip.enabled = true

    // EmptyState.fitContent rounds like anchors.centerIn
    var a = refText.mapToItem(null, 0, 0), b = fit.children[0].mapToItem(null, 0, 0)
    var a0 = boxA.mapToItem(null, 0, 0), b0 = boxB.mapToItem(null, 0, 0)
    check("fitContent: same x/y as Text { anchors.centerIn } (" + (a.x - a0.x) + "," + (a.y - a0.y) + " vs " + (b.x - b0.x) + "," + (b.y - b0.y) + ")",
      a.x - a0.x === b.x - b0.x && a.y - a0.y === b.y - b0.y)

    // Theme tokens (typed copies of Style's grouped tokens)
    check("Theme.hairline is Style.spacing.hairline", Theme.hairline === Style.spacing.hairline && Theme.hairline >= 1)
    check("Theme.icon / iconSmall follow Style.font", Theme.icon === Style.font.icon && Theme.iconSmall === Style.font.iconSmall)
    check("Theme.buttonFill is tint(fg, 0.06)", shell.sameColor(Theme.buttonFill, Theme.tint(Theme.fg, 0.06)))
    check("Theme.separator is tint(fg, 0.08)", shell.sameColor(Theme.separator, Theme.tint(Theme.fg, 0.08)))
    check("panel widths 480 / 520 / 560", Theme.panelNarrow === Style.space(480) && Theme.panelWidth === Style.space(520) && Theme.panelWide === Style.space(560))

    // StatusFooter.separator: a rule above the box, the box itself unchanged
    var rule = function(f) { for (var i = 0; i < f.children.length; i++) if (f.children[i].height === Theme.hairline && f.children[i].color !== undefined && f.children[i].width === f.width && !(f.children[i] instanceof Text)) return f.children[i]; return null }
    var r0 = rule(plainFooter), rr = rule(ruledFooter), rg = rule(gapFooter)
    check("separator off by default", r0 !== null && !r0.visible)
    check("separator: Theme.edge above, hairline, footer width", rr && rr.visible && rr.y === -(Theme.edge + Theme.hairline) && rr.width === 300)
    check("separator colour = Theme.separator", rr && shell.sameColor(rr.color, Theme.separator))
    check("separatorGap / separatorStrength", rg && rg.y === -(4 + Theme.hairline) && shell.sameColor(rg.color, Theme.tint(Theme.fg, 0.2)))
    check("separator leaves the footer height alone", ruledFooter.height === plainFooter.height)

    // RowHover
    check("RowHover fills its row", hoverPlain.width === 200 && hoverPlain.height === 30)
    check("RowHover: hover only by default", hoverPlain.acceptedButtons === Qt.NoButton && hoverPlain.cursorShape === Qt.ArrowCursor && hoverPlain.hoverEnabled)
    check("RowHover clickable: left button + pointing hand", hoverClick.acceptedButtons === Qt.LeftButton && hoverClick.cursorShape === Qt.PointingHandCursor)
    check("RowHover pointer: false keeps the arrow", hoverArrow.acceptedButtons === Qt.LeftButton && hoverArrow.cursorShape === Qt.ArrowCursor)
    hoverPlain.hovered(hoverPlain.rowIndex)
    check("RowHover hovered(rowIndex)", hoverPlain.seen === 3)

    // Text styles = ActionRow's title / subtitle look
    check("TitleText: fg, body, bold", shell.sameColor(titleText.color, Theme.fg) && titleText.font.pixelSize === Theme.body && titleText.font.bold && titleText.elide === Text.ElideRight)
    check("CaptionText: dim, caption", shell.sameColor(captionText.color, Theme.dim) && captionText.font.pixelSize === Theme.caption && !captionText.font.bold)

    // timeouts
    fast.arm("t")
    wait.then = function() {
      check("controller disarms after timeout", !fast.armed)
      console.log("logic done " + shell.pass + " " + shell.fail)
      Qt.quit()
    }
    wait.start()
  }
}

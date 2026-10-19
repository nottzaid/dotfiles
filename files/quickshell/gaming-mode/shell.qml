// The panel gaming mode opens after leaving (files/bin/gaming-mode,
// panel_open): how the desktop came back from its sleep, and what can be
// done about anything that did not, fed by `gaming-mode-review --watch`.
// It never takes the keyboard: Hyprland focuses a layer that asks for focus
// on demand the moment it maps. Its buttons run `gaming-mode act` through
// systemd-run, outside this process (going back to the game closes it). A
// calm review closes itself after a while unless the pointer rests on it;
// one with something to do stays until that is done or it is dismissed.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
    id: root

    readonly property string bin: (Quickshell.env("HOME") || "") + "/.local/bin/"
    property var review: null
    property bool expanded: false
    readonly property string severity: review ? review.severity : "ok"
    readonly property bool calm: severity === "ok" || severity === "info"
    readonly property int lifetime: severity === "ok" ? 12000 : 30000

    // Catppuccin Mocha; the accent is the light the backdrop kept on.
    readonly property color base: "#11111b"
    readonly property color line: "#313244"
    readonly property color text: "#cdd6f4"
    readonly property color subtext: "#a6adc8"
    readonly property color muted: "#7f849c"
    readonly property color light: review && review.light ? review.light : "#f9e2af"
    readonly property color accent: calm || severity === "wait" ? light : tone(severity)
    readonly property string font: "FantasqueSansM Nerd Font"

    function tone(sev) {
        return ({ ok: "#a6e3a1", info: "#89b4fa", wait: "#b4befe", warn: "#fab387", error: "#f38ba8" })[sev] || root.text;
    }
    function glyph(code) { return String.fromCodePoint(code); }
    function stateGlyph(sev) {
        return glyph(({ ok: 0xf012c, info: 0xf02fd, wait: 0xf051f, warn: 0xf0026, error: 0xf0159 })[sev] || 0xf02fd);
    }
    function kindGlyph(kind, sev) {
        if (kind === "app") return glyph(sev === "ok" ? 0xf0599 : 0xf0717); // awake: a sun; asleep: a snowflake
        return glyph(({ shell: 0xf011, screen: 0xf0379, terminal: 0xf018d })[kind] || 0xf02fd);
    }
    function act(a) {
        if (!review || !review.session) return;
        // (Its own unit, outside this one, kept until everything it started
        // in the background has ended: a retry in 10 s, say.)
        Quickshell.execDetached(["systemd-run", "--user", "--quiet", "--collect", "--slice=session.slice",
                                 "-p", "ExitType=cgroup", "--",
                                 bin + "gaming-mode", "act", review.session, a.id, a.arg || ""]);
    }
    function close() { card.leaving = true; }

    onCalmChanged: life.left = 1

    Process {
        running: true
        command: [root.bin + "gaming-mode-review", "--watch", "2"]
        stdout: SplitParser {
            onRead: data => {
                try { root.review = JSON.parse(data); } catch (e) {}
            }
        }
        onExited: Qt.quit()
    }

    // A calm review goes by itself; resting the pointer on it holds it.
    Timer {
        id: life
        property real left: 1
        interval: 100
        repeat: true
        running: win.visible && root.calm && !hover.hovered && !root.expanded && !card.leaving
        onTriggered: {
            left -= interval / root.lifetime;
            if (left <= 0) root.close();
        }
    }

    // A button: one click acts; one that asks first is armed by the first
    // click and acts on the second within four seconds.
    component Button: Rectangle {
        id: b
        property var action
        property bool armed: false
        property bool sent: false
        readonly property bool primary: action.style === "primary"
        readonly property bool danger: action.style === "danger"
        implicitWidth: label.implicitWidth + 22
        implicitHeight: 26
        color: armed ? root.tone("error")
             : primary ? (mouse.containsMouse ? Qt.lighter(root.accent, 1.12) : root.accent)
             : mouse.containsMouse ? root.line : "transparent"
        border.width: 1
        border.color: danger || armed ? root.tone("error") : primary ? root.accent : root.muted
        opacity: sent ? 0.55 : 1
        Text {
            textFormat: Text.PlainText
            id: label
            anchors.centerIn: parent
            text: b.sent ? "…" : b.armed ? b.action.confirm : b.action.label
            color: b.armed || b.primary ? root.base : b.danger ? root.tone("error") : root.text
            font.family: root.font
            font.pixelSize: 13
        }
        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (b.sent) return;
                if (b.action.confirm && !b.armed) {
                    b.armed = true;
                    disarm.restart();
                    return;
                }
                b.armed = false;
                b.sent = true;
                settle.restart();
                root.act(b.action);
            }
        }
        Timer { id: disarm; interval: 4000; onTriggered: b.armed = false }
        Timer { id: settle; interval: 3000; onTriggered: b.sent = false }
    }

    component Actions: Flow {
        property var actions: []
        spacing: 8
        visible: actions.length > 0
        Repeater {
            model: parent.actions
            Button { action: modelData }
        }
    }

    PanelWindow {
        id: win
        screen: {
            const want = Quickshell.env("GAMING_MODE_OUTPUT");
            const screens = Quickshell.screens;
            for (let i = 0; i < screens.length; i++)
                if (screens[i].name === want) return screens[i];
            return screens.length ? screens[0] : null;
        }
        visible: root.review !== null && root.review.session !== null
        anchors { top: true; right: true }
        margins { top: 14; right: 14 }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "gaming-mode-panel"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        color: "transparent"
        implicitWidth: card.width + 20
        implicitHeight: card.height
        mask: Region { item: card }
        onVisibleChanged: if (visible) arrive.start()

        Rectangle {
            id: card
            property bool leaving: false
            width: 470
            height: body.y + body.implicitHeight + 20
            anchors.right: parent.right
            color: Qt.rgba(0.067, 0.067, 0.106, 0.88)
            border.width: 1
            border.color: root.accent
            opacity: 0
            transform: Translate { id: shift; x: 20 }
            Behavior on border.color { ColorAnimation { duration: 300 } }

            HoverHandler { id: hover }

            ParallelAnimation {
                id: arrive
                NumberAnimation { target: card; property: "opacity"; to: 1; duration: 220; easing.type: Easing.OutCubic }
                NumberAnimation { target: shift; property: "x"; to: 0; duration: 300; easing.type: Easing.OutCubic }
            }
            onLeavingChanged: if (leaving) go.start()
            SequentialAnimation {
                id: go
                ParallelAnimation {
                    NumberAnimation { target: card; property: "opacity"; to: 0; duration: 160 }
                    NumberAnimation { target: shift; property: "x"; to: 20; duration: 160; easing.type: Easing.InCubic }
                }
                ScriptAction { script: Qt.quit() }
            }

            // The night the backdrop showed, above the title.
            Item {
                id: band
                x: 1
                y: 1
                width: parent.width - 2
                height: 128
                clip: true
                visible: art.status === Image.Ready
                Image {
                    id: art
                    anchors.fill: parent
                    source: root.review && root.review.art ? "file://" + root.review.art : ""
                    fillMode: Image.PreserveAspectCrop
                    sourceSize.width: 940
                    asynchronous: true
                    smooth: true
                }
                Rectangle {
                    anchors.fill: parent
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.rgba(0.067, 0.067, 0.106, 0.15) }
                        GradientStop { position: 0.55; color: Qt.rgba(0.067, 0.067, 0.106, 0.55) }
                        GradientStop { position: 1.0; color: Qt.rgba(0.067, 0.067, 0.106, 0.88) }
                    }
                }
            }

            Column {
                id: body
                x: 20
                y: band.visible ? 76 : 20
                width: parent.width - 40
                spacing: 16

                // The title, in the light, with the backdrop's block cursor.
                Item {
                    width: parent.width
                    height: heading.implicitHeight
                    Column {
                        id: heading
                        spacing: 3
                        Row {
                            spacing: 6
                            Text {
                                textFormat: Text.PlainText
                                id: title
                                text: root.review ? root.review.title : ""
                                color: root.accent
                                font.family: root.font
                                font.pixelSize: 25
                                font.bold: true
                            }
                            Rectangle {
                                width: 11
                                height: title.font.pixelSize * 0.62
                                y: title.baselineOffset - height
                                color: root.accent
                            }
                        }
                        Text {
                            textFormat: Text.PlainText
                            text: root.review ? `${root.review.subtitle}  ·  since ${root.review.since}` : ""
                            color: root.subtext
                            font.family: root.font
                            font.pixelSize: 13
                        }
                    }
                }

                // The numbers.
                Row {
                    width: parent.width
                    visible: root.review !== null && root.review.stats.length > 0
                    Repeater {
                        model: root.review ? root.review.stats : []
                        Column {
                            width: body.width / Math.max(1, root.review.stats.length)
                            spacing: 1
                            Text {
                                textFormat: Text.PlainText
                                text: modelData.value
                                color: root.text
                                font.family: root.font
                                font.pixelSize: 20
                                font.bold: true
                            }
                            Text {
                                textFormat: Text.PlainText
                                text: modelData.label
                                color: root.muted
                                font.family: root.font
                                font.pixelSize: 11
                            }
                        }
                    }
                }

                // What concerns the stay as a whole: the game, retries, a pause.
                Repeater {
                    model: root.review ? root.review.findings : []
                    Row {
                        width: body.width
                        spacing: 12
                        Rectangle {
                            width: 2
                            height: finding.implicitHeight
                            color: root.tone(modelData.severity)
                        }
                        Column {
                            id: finding
                            width: parent.width - 14
                            spacing: 9
                            Column {
                                width: parent.width
                                spacing: 2
                                Text {
                                    textFormat: Text.PlainText
                                    width: parent.width
                                    text: modelData.text
                                    color: root.text
                                    wrapMode: Text.Wrap
                                    font.family: root.font
                                    font.pixelSize: 14
                                }
                                Text {
                                    textFormat: Text.PlainText
                                    width: parent.width
                                    visible: !!modelData.detail
                                    text: modelData.detail || ""
                                    color: root.subtext
                                    wrapMode: Text.Wrap
                                    font.family: root.font
                                    font.pixelSize: 12
                                }
                            }
                            Actions { width: parent.width; actions: modelData.actions }
                        }
                    }
                }

                // What slept, and how it woke. A calm review folds it into a line.
                Column {
                    width: parent.width
                    spacing: 7
                    visible: root.review !== null && root.review.items.length > 0
                    readonly property bool open: root.expanded || !root.calm
                    Rectangle { width: parent.width; height: 1; color: root.line }
                    Item {
                        width: parent.width
                        height: fold.implicitHeight + 4
                        Text {
                            textFormat: Text.PlainText
                            id: fold
                            y: 4
                            text: {
                                if (!root.review) return "";
                                const items = root.review.items;
                                const ok = items.filter(i => i.severity === "ok").length;
                                const head = parent.parent.open ? root.glyph(0xf0140) : root.glyph(0xf0142);
                                return `${head}  what slept  ·  ${ok === items.length ? "all " + items.length + " back" : ok + " of " + items.length + " back"}`;
                            }
                            color: foldMouse.containsMouse ? root.text : root.muted
                            font.family: root.font
                            font.pixelSize: 12
                        }
                        MouseArea {
                            id: foldMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: root.calm
                            cursorShape: root.calm ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: root.expanded = !root.expanded
                        }
                    }
                    Repeater {
                        model: parent.open && root.review ? root.review.items : []
                        Column {
                            width: body.width
                            spacing: 6
                            Item {
                                width: parent.width
                                height: 22
                                Text {
                                    textFormat: Text.PlainText
                                    id: kindIcon
                                    width: 22
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: root.kindGlyph(modelData.kind, modelData.severity)
                                    color: modelData.severity === "ok" ? root.light : root.subtext
                                    font.family: root.font
                                    font.pixelSize: 15
                                }
                                Text {
                                    textFormat: Text.PlainText
                                    anchors.left: kindIcon.right
                                    anchors.right: stateText.left
                                    anchors.rightMargin: 10
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.name
                                    elide: Text.ElideRight
                                    color: root.text
                                    font.family: root.font
                                    font.pixelSize: 14
                                }
                                Text {
                                    textFormat: Text.PlainText
                                    id: stateText
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: `${modelData.text}  ${root.stateGlyph(modelData.severity)}`
                                    color: modelData.severity === "ok" ? root.subtext : root.tone(modelData.severity)
                                    font.family: root.font
                                    font.pixelSize: 13
                                }
                            }
                            Actions {
                                x: 22
                                width: parent.width - 22
                                actions: modelData.actions
                            }
                        }
                    }
                }
            }

            // Dismiss.
            Text {
                textFormat: Text.PlainText
                x: parent.width - width - 14
                y: 10
                text: root.glyph(0xf0156)
                color: dismiss.containsMouse ? root.text : root.muted
                font.family: root.font
                font.pixelSize: 18
                MouseArea {
                    id: dismiss
                    anchors.fill: parent
                    anchors.margins: -6
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.close()
                }
            }

            // How long a calm review stays.
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.margins: 1
                height: 2
                width: (parent.width - 2) * life.left
                color: root.accent
                opacity: hover.hovered || root.expanded ? 0.35 : 0.8
                visible: root.calm
            }
        }
    }
}

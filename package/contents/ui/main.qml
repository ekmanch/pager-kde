import QtQuick
import QtQuick.Layouts
import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.plasma.workspace.dbus as DBus
import org.kde.taskmanager as TaskManager

PlasmoidItem {
    id: root

    // Style values, matching the order of the drop-down in the settings.
    readonly property int stylePills: 0
    readonly property int styleDots: 1
    readonly property int styleNumbers: 2

    readonly property int style: Plasmoid.configuration.style
    readonly property bool vertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical

    readonly property int dotSize: Math.max(2, Plasmoid.configuration.size)
    readonly property int pillLength: Math.max(dotSize, Plasmoid.configuration.pillLength)
    readonly property int pillThickness: Math.max(2, Math.round(dotSize * 0.6))
    // How strongly inactive pills and dots are filled, on top of the inactive
    // colour's own alpha. Translucent rather than a fixed grey, so it stays soft
    // over any panel or wallpaper and the active desktop stands out the most.
    readonly property real inactiveFillAlpha: 0.5
    readonly property int spacing: Math.max(0, Plasmoid.configuration.spacing)
    readonly property int margin: Math.max(0, Plasmoid.configuration.margin)

    // Pills mark the active desktop by shape already, so they default to white;
    // the other styles need the accent colour to tell it apart.
    readonly property color activeColor: Plasmoid.configuration.activeColor !== ""
        ? Plasmoid.configuration.activeColor
        : style === stylePills ? "#ffffff" : Kirigami.Theme.highlightColor
    readonly property color inactiveColor: Plasmoid.configuration.inactiveColor !== ""
        ? Plasmoid.configuration.inactiveColor : "#ffffff"
    readonly property real activeOpacity: Plasmoid.configuration.activeOpacity / 100
    readonly property real inactiveOpacity: Plasmoid.configuration.inactiveOpacity / 100

    readonly property int desktopCount: desktopInfo.numberOfDesktops
    readonly property int currentIndex: desktopInfo.desktopIds.indexOf(desktopInfo.currentDesktop)

    // The desktop we have asked KWin to switch to but that it has not reported
    // yet. The pager shows it right away, and fast scrolling steps from it, so
    // quick wheel flicks neither lag nor drop steps.
    property int pendingIndex: -1
    readonly property int shownIndex: pendingIndex >= 0 ? pendingIndex : currentIndex

    onCurrentIndexChanged: {
        if (currentIndex === pendingIndex) {
            pendingIndex = -1;
        }
    }
    onDesktopCountChanged: pendingIndex = -1

    preferredRepresentation: fullRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    function switchTo(index) {
        if (index < 0 || index >= desktopCount || index === shownIndex) {
            return;
        }
        pendingIndex = index;
        pendingTimeout.restart();
        DBus.SessionBus.asyncCall({
            service: "org.kde.KWin",
            path: "/KWin",
            iface: "org.kde.KWin",
            member: "setCurrentDesktop",
            arguments: [new DBus.int32(index + 1)]
        });
    }

    function callDesktopManager(member, args) {
        DBus.SessionBus.asyncCall({
            service: "org.kde.KWin",
            path: "/VirtualDesktopManager",
            iface: "org.kde.KWin.VirtualDesktopManager",
            member: member,
            arguments: args
        });
    }

    // Adds a desktop after the last one.
    function addDesktop() {
        callDesktopManager("createDesktop", [
            new DBus.uint32(desktopCount),
            new DBus.string(i18n("Desktop %1", desktopCount + 1))
        ]);
    }

    // Removes the last desktop; KWin moves its windows to the one before it.
    function removeDesktop() {
        if (desktopCount < 2) {
            return;
        }
        callDesktopManager("removeDesktop", [
            new DBus.string(String(desktopInfo.desktopIds[desktopCount - 1]))
        ]);
    }

    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: i18n("Add Virtual Desktop")
            icon.name: "list-add"
            onTriggered: root.addDesktop()
        },
        PlasmaCore.Action {
            text: i18n("Remove Virtual Desktop")
            icon.name: "list-remove"
            enabled: root.desktopCount > 1
            onTriggered: root.removeDesktop()
        },
        PlasmaCore.Action {
            text: i18n("Configure Virtual Desktops…")
            onTriggered: KCM.KCMLauncher.openSystemSettings("kcm_kwin_virtualdesktops")
        }
    ]

    function step(delta) {
        const n = desktopCount;
        if (n < 2 || shownIndex < 0) {
            return;
        }
        let next = shownIndex + delta;
        if (Plasmoid.configuration.wrapAround) {
            next = ((next % n) + n) % n;
        } else {
            next = Math.max(0, Math.min(n - 1, next));
        }
        switchTo(next);
    }

    function mix(a, b, t) {
        return Qt.rgba(a.r + (b.r - a.r) * t,
                       a.g + (b.g - a.g) * t,
                       a.b + (b.b - a.b) * t,
                       a.a + (b.a - a.a) * t);
    }

    TaskManager.VirtualDesktopInfo {
        id: desktopInfo
    }

    // Safety net: if KWin never confirms a switch, fall back to what it reports.
    Timer {
        id: pendingTimeout
        interval: 600
        onTriggered: root.pendingIndex = -1
    }

    fullRepresentation: Item {
        id: full

        readonly property real contentLength: {
            const n = root.desktopCount;
            if (n < 1) {
                return 0;
            }
            if (root.style === root.stylePills) {
                // Fixed, so the panel layout does not jitter while the pill animates.
                return (n - 1) * (root.dotSize + root.spacing) + root.pillLength;
            }
            return root.vertical ? grid.implicitHeight : grid.implicitWidth;
        }
        readonly property real totalLength: contentLength + 2 * root.margin

        Layout.fillWidth: root.vertical
        Layout.fillHeight: !root.vertical
        Layout.minimumWidth: root.vertical ? -1 : totalLength
        Layout.preferredWidth: root.vertical ? -1 : totalLength
        Layout.maximumWidth: root.vertical ? Infinity : totalLength
        Layout.minimumHeight: root.vertical ? totalLength : -1
        Layout.preferredHeight: root.vertical ? totalLength : -1
        Layout.maximumHeight: root.vertical ? totalLength : Infinity

        Grid {
            id: grid

            anchors.centerIn: parent
            columns: root.vertical ? 1 : Math.max(1, root.desktopCount)
            spacing: root.spacing
            horizontalItemAlignment: Grid.AlignHCenter
            verticalItemAlignment: Grid.AlignVCenter

            Repeater {
                id: repeater

                model: root.desktopCount

                Item {
                    id: cell

                    required property int index

                    // 0 = inactive, 1 = active; everything visual is derived from it.
                    property real activeness: index === root.shownIndex ? 1 : 0
                    Behavior on activeness {
                        NumberAnimation {
                            duration: 150
                            easing.type: Easing.OutCubic
                        }
                    }

                    readonly property bool isNumber: root.style === root.styleNumbers
                    readonly property real mainLength: {
                        if (isNumber) {
                            return root.vertical ? label.implicitHeight : label.implicitWidth;
                        }
                        if (root.style === root.stylePills) {
                            return root.dotSize + (root.pillLength - root.dotSize) * activeness;
                        }
                        return root.dotSize;
                    }
                    readonly property real crossLength: {
                        if (isNumber) {
                            return root.vertical ? label.implicitWidth : label.implicitHeight;
                        }
                        return root.dotSize;
                    }
                    readonly property color blendedColor: root.mix(root.inactiveColor, root.activeColor, activeness)

                    width: root.vertical ? crossLength : mainLength
                    height: root.vertical ? mainLength : crossLength
                    opacity: root.inactiveOpacity + (root.activeOpacity - root.inactiveOpacity) * activeness

                    Rectangle {
                        readonly property real thickness: root.style === root.stylePills
                            ? root.dotSize + (root.pillThickness - root.dotSize) * cell.activeness
                            : root.dotSize

                        anchors.centerIn: parent
                        visible: !cell.isNumber
                        width: root.vertical ? thickness : cell.mainLength
                        height: root.vertical ? cell.mainLength : thickness
                        radius: Math.min(width, height) / 2
                        antialiasing: true

                        // Inactive pills and dots get a translucent fill that turns
                        // solid when active.
                        color: root.mix(Qt.rgba(root.inactiveColor.r, root.inactiveColor.g, root.inactiveColor.b,
                                                root.inactiveColor.a * root.inactiveFillAlpha),
                                        root.activeColor, cell.activeness)
                    }

                    Text {
                        id: label

                        anchors.centerIn: parent
                        visible: cell.isNumber
                        text: cell.index + 1
                        color: cell.blendedColor
                        // Panel recolouring widgets (e.g. Panel Colorizer) assign a
                        // colour to every Text in the panel, which silently drops the
                        // binding above. Take the colour back whenever that happens.
                        onColorChanged: {
                            if (!Qt.colorEqual(color, cell.blendedColor)) {
                                color = Qt.binding(() => cell.blendedColor);
                            }
                        }
                        font.family: Kirigami.Theme.defaultFont.family
                        font.pixelSize: root.dotSize
                        textFormat: Text.PlainText
                    }
                }
            }
        }

        // One area for both clicking and scrolling. It covers the whole applet:
        // the full panel thickness plus the margins, so neither needs precision.
        MouseArea {
            id: mouseArea

            property int wheelAccumulator: 0

            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            cursorShape: Qt.PointingHandCursor

            function indexAt(x, y) {
                const reach = Math.max(root.spacing / 2, 2);
                for (let i = 0; i < repeater.count; ++i) {
                    const item = repeater.itemAt(i);
                    if (!item) {
                        continue;
                    }
                    const p = mapToItem(item, x, y);
                    const pos = root.vertical ? p.y : p.x;
                    const length = root.vertical ? item.height : item.width;
                    if (pos >= -reach && pos < length + reach) {
                        return i;
                    }
                }
                return -1;
            }

            onClicked: mouse => root.switchTo(indexAt(mouse.x, mouse.y))

            onWheel: wheel => {
                if (!Plasmoid.configuration.scrollEnabled) {
                    wheel.accepted = false;
                    return;
                }
                const delta = wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : wheel.angleDelta.x;
                if (delta === 0) {
                    return;
                }
                // Accumulate so that one wheel notch (120) is exactly one desktop,
                // also for high-resolution wheels and touchpads.
                if (wheelAccumulator !== 0 && (delta > 0) !== (wheelAccumulator > 0)) {
                    wheelAccumulator = 0;
                }
                wheelAccumulator += delta;
                if (Math.abs(wheelAccumulator) >= 120) {
                    // Scrolling down goes to the next desktop.
                    root.step(wheelAccumulator > 0 ? -1 : 1);
                    wheelAccumulator %= 120;
                }
            }
        }
    }
}

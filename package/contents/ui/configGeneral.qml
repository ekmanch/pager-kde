import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami
import org.kde.kquickcontrols as KQuickControls

KCM.SimpleKCM {
    id: page

    property alias cfg_style: styleCombo.currentIndex
    property alias cfg_scrollEnabled: scrollCheck.checked
    property alias cfg_wrapAround: wrapCheck.checked
    property string cfg_activeColor
    property string cfg_inactiveColor
    property alias cfg_activeOpacity: activeOpacity.value
    property alias cfg_inactiveOpacity: inactiveOpacity.value
    property alias cfg_pillLength: pillLengthSpin.value

    // Size, spacing and margin are stored per style; the spin boxes below show
    // and edit the ones of the selected style.
    property int cfg_pillsSize
    property int cfg_pillsSpacing
    property int cfg_pillsMargin
    property int cfg_dotsSize
    property int cfg_dotsSpacing
    property int cfg_dotsMargin
    property int cfg_numbersSize
    property int cfg_numbersSpacing
    property int cfg_numbersMargin

    // Filled in by Plasma with the defaults from main.xml.
    property int cfg_styleDefault
    property bool cfg_scrollEnabledDefault
    property bool cfg_wrapAroundDefault
    property string cfg_activeColorDefault
    property string cfg_inactiveColorDefault
    property int cfg_activeOpacityDefault
    property int cfg_inactiveOpacityDefault
    property int cfg_pillLengthDefault
    property int cfg_pillsSizeDefault
    property int cfg_pillsSpacingDefault
    property int cfg_pillsMarginDefault
    property int cfg_dotsSizeDefault
    property int cfg_dotsSpacingDefault
    property int cfg_dotsMarginDefault
    property int cfg_numbersSizeDefault
    property int cfg_numbersSpacingDefault
    property int cfg_numbersMarginDefault

    // Config key prefix of the selected style.
    readonly property string stylePrefix: ["pills", "dots", "numbers"][styleCombo.currentIndex] ?? "pills"

    function styleValue(name) {
        return page["cfg_" + stylePrefix + name];
    }

    function setStyleValue(name, value) {
        page["cfg_" + stylePrefix + name] = value;
    }

    // Resets everything except the style, and only the selected style's
    // size, spacing and margin.
    function restoreDefaults() {
        cfg_scrollEnabled = cfg_scrollEnabledDefault;
        cfg_wrapAround = cfg_wrapAroundDefault;
        cfg_activeColor = cfg_activeColorDefault;
        cfg_inactiveColor = cfg_inactiveColorDefault;
        cfg_activeOpacity = cfg_activeOpacityDefault;
        cfg_inactiveOpacity = cfg_inactiveOpacityDefault;
        if (cfg_style === 0) {
            cfg_pillLength = cfg_pillLengthDefault;
        }
        for (const name of ["Size", "Spacing", "Margin"]) {
            setStyleValue(name, page["cfg_" + stylePrefix + name + "Default"]);
        }
    }

    // A colour button plus a way back to the default. An empty string in the
    // config means "use the default", so the accent colour keeps following
    // the system until a custom colour is picked.
    component ColorRow: RowLayout {
        id: row

        property string value
        property color defaultColor

        signal picked(string color)

        spacing: Kirigami.Units.smallSpacing

        KQuickControls.ColorButton {
            id: button
            showAlphaChannel: false
            onAccepted: color => row.picked(color.toString())
        }
        Binding {
            target: button
            property: "color"
            value: row.value !== "" ? row.value : row.defaultColor
        }
        QQC2.Button {
            icon.name: "edit-undo"
            text: i18n("Use default")
            enabled: row.value !== ""
            onClicked: row.picked("")
        }
    }

    component OpacitySlider: RowLayout {
        property alias value: slider.value

        spacing: Kirigami.Units.smallSpacing

        QQC2.Slider {
            id: slider
            Layout.preferredWidth: Kirigami.Units.gridUnit * 12
            from: 0
            to: 100
            stepSize: 5
            snapMode: QQC2.Slider.SnapAlways
        }
        QQC2.Label {
            text: i18n("%1%", Math.round(slider.value))
            horizontalAlignment: Text.AlignRight
            Layout.minimumWidth: Kirigami.Units.gridUnit * 2
        }
    }

    Kirigami.FormLayout {
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("General")
        }

        QQC2.ComboBox {
            id: styleCombo
            Kirigami.FormData.label: i18n("Style:")
            model: [
                i18n("Pills — dots with active pill"),
                i18n("Dots — dots with solid active dot"),
                i18n("Numbers")
            ]
        }

        QQC2.CheckBox {
            id: scrollCheck
            Kirigami.FormData.label: i18n("Scroll:")
            text: i18n("Change desktops on scroll")
        }

        QQC2.CheckBox {
            id: wrapCheck
            Kirigami.FormData.label: i18n("Cyclic:")
            text: i18n("Wrap around on scroll")
            enabled: scrollCheck.checked
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Appearance")
        }

        QQC2.SpinBox {
            id: sizeSpin
            Kirigami.FormData.label: styleCombo.currentIndex === 2 ? i18n("Font size:") : i18n("Dot size:")
            from: 4
            to: 64
            value: page.styleValue("Size")
            onValueModified: page.setStyleValue("Size", value)
        }

        QQC2.SpinBox {
            id: pillLengthSpin
            Kirigami.FormData.label: i18n("Pill length:")
            visible: styleCombo.currentIndex === 0
            from: 4
            to: 128
        }

        QQC2.SpinBox {
            id: spacingSpin
            Kirigami.FormData.label: i18n("Spacing:")
            from: 0
            to: 64
            value: page.styleValue("Spacing")
            onValueModified: page.setStyleValue("Spacing", value)
        }

        QQC2.SpinBox {
            id: marginSpin
            Kirigami.FormData.label: i18n("Margin:")
            from: 0
            to: 64
            value: page.styleValue("Margin")
            onValueModified: page.setStyleValue("Margin", value)
        }

        ColorRow {
            Kirigami.FormData.label: i18n("Active color:")
            value: page.cfg_activeColor
            // Matches main.qml: white for pills, the accent colour otherwise.
            defaultColor: styleCombo.currentIndex === 0 ? "#ffffff" : Kirigami.Theme.highlightColor
            onPicked: color => page.cfg_activeColor = color
        }

        ColorRow {
            Kirigami.FormData.label: i18n("Inactive color:")
            value: page.cfg_inactiveColor
            defaultColor: "#ffffff"
            onPicked: color => page.cfg_inactiveColor = color
        }

        OpacitySlider {
            id: activeOpacity
            Kirigami.FormData.label: i18n("Active opacity:")
        }

        OpacitySlider {
            id: inactiveOpacity
            Kirigami.FormData.label: i18n("Inactive opacity:")
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Reset")
        }

        QQC2.Button {
            icon.name: "edit-undo"
            text: i18n("Restore Defaults")
            onClicked: page.restoreDefaults()
        }
    }
}

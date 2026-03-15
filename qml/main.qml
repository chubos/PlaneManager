import QtQuick
import QtQuick.Controls

ApplicationWindow {
    width: 1024
    height: 768
    visible: true
    title: qsTr("Plane Manager - Fleet & Logistics")

    header: ToolBar {
        Row {
            Button { text: "Flota"; onClicked: console.log("Widok Floty") }
            Button { text: "Mapa"; onClicked: console.log("Widok Mapy") }
            Button { text: "Statystyki"; onClicked: console.log("Statystyki") }
        }
    }

    Text {
        anchors.centerIn: parent
        text: "System gotowy."
        font.pixelSize: 24
    }
}
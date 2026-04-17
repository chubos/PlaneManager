import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material

ApplicationWindow {
    id: window
    width: 1280
    height: 800
    visible: true
    title: "Plane Manager"

    Material.theme: Material.Light
    Material.accent: Material.Blue
    Material.primary: Material.BlueGrey

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // Panel boczny (Sidebar)
        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 220
            color: "#F8F9FA"

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 15
                spacing: 10

                Label {
                    text: "NAWIGACJA"
                    font.pixelSize: 20
                    font.letterSpacing: 1.5
                    font.bold: true
                    color: "#6C757D"
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 20
                    Layout.bottomMargin: 20
                }

                // Trzy przyciski
                Button {
                    text: "Samoloty"
                    Layout.fillWidth: true
                    Material.elevation: 0
                    flat: stackView.currentItem && stackView.currentItem.objectName !== "planeView"
                    font.pixelSize: 15
                    onClicked: stackView.replace("PlaneList.qml")
                }

                Button {
                    text: "Lotniska"
                    Layout.fillWidth: true
                    Material.elevation: 0
                    flat: stackView.currentItem && stackView.currentItem.objectName !== "airportView"
                    font.pixelSize: 15
                    onClicked: stackView.replace("AirportList.qml")
                }

                Button {
                    text: "Loty"
                    Layout.fillWidth: true
                    Material.elevation: 0
                    flat: stackView.currentItem && stackView.currentItem.objectName !== "flightView"
                    font.pixelSize: 15
                    onClicked: stackView.replace("FlightList.qml")
                }

                Button {
                    text: "Mapa"
                    Layout.fillWidth: true
                    Material.elevation: 0
                    flat: stackView.currentItem && stackView.currentItem.objectName !== "mapView"
                    font.pixelSize: 15
                    onClicked: stackView.replace("MapView.qml")
                }

                Item { Layout.fillHeight: true } // Zapelniacz spychajacy do gory
            }

            // Subtelna, cienka linia oddzielajaca panel od reszty
            Rectangle {
                anchors.right: parent.right
                width: 1
                height: parent.height
                color: "#E9ECEF" 
            }
        }

        // Glowny obszar wyswietlania
        StackView {
            id: stackView
            Layout.fillWidth: true
            Layout.fillHeight: true
            initialItem: "PlaneList.qml"
            
            // Plynne przejscie miedzy oknami
            replaceEnter: Transition { PropertyAnimation { property: "opacity"; from: 0; to: 1; duration: 200 } }
            replaceExit: Transition { PropertyAnimation { property: "opacity"; from: 1; to: 0; duration: 200 } }
        }
    }
}
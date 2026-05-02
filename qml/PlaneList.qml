pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material

import "."

Item {
    id: root
    objectName: "planeView"

    // qmllint disable unqualified
    readonly property var service: planeService 
    // qmllint enable unqualified

    PlaneEditDialog {
        id: editDialog
        service: root.service
        onSaved: root.refreshPlanes()
    }

    // Funkcja pobiera liste z C++ i wrzuca BEZPOSREDNIO do widoku
    function refreshPlanes() {
        listView.model = root.service.getAllPlanes();
    }

    Component.onCompleted: root.refreshPlanes()

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: root.refreshPlanes()
    }

    Rectangle {
        anchors.fill: parent
        color: "#FFFFFF"
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 40
        spacing: 30

        // --- Naglowek ---
        RowLayout {
            Layout.fillWidth: true
            spacing: 40
            
            ColumnLayout {
                spacing: 5
                Label {
                    text: "Flota Samolotów"
                    font.pixelSize: 32; font.bold: true; color: "#212529"
                }
                Label {
                    text: "Zarządzaj swoimi maszynami i ich statusem"
                    font.pixelSize: 15; color: "#6C757D"
                }
            }

            Item {
                Layout.fillWidth: true
            }

            Button {
                text: "+ Dodaj Samolot"
                Material.background: Material.accent
                Material.foreground: "white"
                Material.elevation: 0
                font.bold: true; font.pixelSize: 14
                Layout.preferredHeight: 45
                onClicked: addDialog.open()
            }
        }

        // --- Lista Samolotow ---
        ListView {
            id: listView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 15

            delegate: Pane {
                id: planeDelegate
                required property var modelData
                readonly property string brandLower: modelData.brand ? modelData.brand.toLowerCase() : ""
                readonly property url logoSource: {
                    if (brandLower.indexOf("airbus") !== -1) return "qrc:/qt/qml/PlaneManager/assets/airbus.png";
                    if (brandLower.indexOf("boeing") !== -1) return "qrc:/qt/qml/PlaneManager/assets/boeing.png";
                    if (brandLower.indexOf("embraer") !== -1) return "qrc:/qt/qml/PlaneManager/assets/embraer.png";
                    if (brandLower.indexOf("bombardier") !== -1) return "qrc:/qt/qml/PlaneManager/assets/bombardier.png";
                    if (brandLower.indexOf("atr") !== -1) return "qrc:/qt/qml/PlaneManager/assets/atr.png";
                    if (brandLower.indexOf("cessna") !== -1) return "qrc:/qt/qml/PlaneManager/assets/cessna.png";
                    if (brandLower.indexOf("gulfstream") !== -1) return "qrc:/qt/qml/PlaneManager/assets/gulfstream.png";
                    if (brandLower.indexOf("dassault") !== -1) return "qrc:/qt/qml/PlaneManager/assets/dassault.png";
                    if (brandLower.indexOf("antonov") !== -1) return "qrc:/qt/qml/PlaneManager/assets/antonov.png";
                    if (brandLower.indexOf("sukhoi") !== -1) return "qrc:/qt/qml/PlaneManager/assets/sukhoi.png";
                    return "";
                }
                width: listView.width - 10 
                x: (listView.width - width) / 2
                Material.background: "#FAFAFA" 
                padding: 20

                RowLayout {
                    anchors.fill: parent
                    spacing: 25

                    Item {
                        Layout.preferredWidth: 190
                        Layout.preferredHeight: 140

                        Image {
                            anchors.centerIn: parent
                            width: 150
                            height: 120
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                            mipmap: false
                            source: planeDelegate.logoSource
                            visible: planeDelegate.logoSource !== ""
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        Label {
                            text: planeDelegate.modelData.brand + " " + planeDelegate.modelData.model
                            font.pixelSize: 18; font.bold: true; color: "#212529"
                        }
                        Label {
                            text: "ID Maszyny: #" + planeDelegate.modelData.id
                            font.pixelSize: 12; color: "#ADB5BD"
                        }
                    }

                    Item { Layout.preferredWidth: 20 } 

                    Rectangle {
                        width: 110; height: 32; radius: 16
                        color: planeDelegate.modelData.status === "Dostepny" ? "#E8F5E9" : (planeDelegate.modelData.status === "W locie" ? "#FFF3E0" : "#FFEBEE")
                        
                        Label {
                            anchors.centerIn: parent
                            text: planeDelegate.modelData.status
                            font.pixelSize: 14; font.bold: true
                            color: planeDelegate.modelData.status === "Dostepny" ? "#2E7D32" : (planeDelegate.modelData.status === "W locie" ? "#EF6C00" : "#C62828")
                        }
                    }

                    Item { Layout.fillWidth: true } 

                    Button {
                        text: "Szczegóły"
                        flat: true
                        Material.foreground: "#059669"
                        Material.background: "#ECFDF5"
                        Material.elevation: 0
                        onClicked: {
                            var view = root.StackView.view
                            if (!view) {
                                console.warn("PlaneList: StackView.view is null; cannot navigate to details")
                                return
                            }
                            view.push(Qt.resolvedUrl("PlaneDetail.qml"), { planeId: planeDelegate.modelData.id })
                        }
                    }
                    Button {
                        text: "Usuń"
                        flat: true
                        Material.foreground: "#DC3545" 
                        Material.background: "#FFEBEE"
                        Material.elevation: 0
                        onClicked: {
                            if (root.service.deletePlane(planeDelegate.modelData.id)) {
                                root.refreshPlanes();
                            }
                        }
                    }
                    Button {
                        text: "Edytuj"
                        flat: true
                        Material.foreground: "#1976D2" 
                        Material.background: "#E3F2FD"
                        Material.elevation: 0
                        onClicked: {
                            editDialog.openWithData(planeDelegate.modelData)
                        }
                    }
                }
            }
        }
    }

    // --- Dialog Dodawania ---
    Dialog {
        id: addDialog
        title: "Rejestracja Nowego Samolotu"
        standardButtons: Dialog.Ok | Dialog.Cancel
        anchors.centerIn: parent
        modal: true
        width: 360

        ScrollView {
            anchors.fill: parent
            contentWidth: addColumn.width
            
            ColumnLayout {
                id: addColumn
                width: addDialog.width - 30
                spacing: 10
                
                Label { text: "Podstawowe dane"; font.bold: true; font.pixelSize: 12; color: "#212529" }
                TextField {
                    id: brandInput
                    placeholderText: "Marka (np. Airbus)"
                    Layout.fillWidth: true
                    font.pixelSize: 12
                }
                TextField {
                    id: modelInput
                    placeholderText: "Model (np. A320)"
                    Layout.fillWidth: true
                    font.pixelSize: 12
                }
                ComboBox {
                    id: statusInput
                    model: ["Dostepny", "W serwisie"]
                    Layout.fillWidth: true
                    font.pixelSize: 12
                }
                
                Label { text: "Parametry techniczne"; font.bold: true; font.pixelSize: 12; color: "#212529"; Layout.topMargin: 8 }
                
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Label { text: "Siła ciągu (kN)"; font.pixelSize: 10 }
                        TextField {
                            id: thrustInput
                            text: "0"
                            inputMethodHints: Qt.ImhDigitsOnly
                            Layout.fillWidth: true
                            font.pixelSize: 11
                        }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Label { text: "Długość (m)"; font.pixelSize: 10 }
                        TextField {
                            id: lengthInput
                            text: "0.00"
                            inputMethodHints: Qt.ImhFormattedNumbersOnly
                            Layout.fillWidth: true
                            font.pixelSize: 11
                        }
                    }
                }
                
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Label { text: "Liczba silników"; font.pixelSize: 10 }
                        TextField {
                            id: numberOfEnginesInput
                            text: "1"
                            inputMethodHints: Qt.ImhDigitsOnly
                            Layout.fillWidth: true
                            font.pixelSize: 11
                        }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Label { text: "Pasażerowie"; font.pixelSize: 10 }
                        TextField {
                            id: passengersInput
                            text: "0"
                            inputMethodHints: Qt.ImhDigitsOnly
                            Layout.fillWidth: true
                            font.pixelSize: 11
                        }
                    }
                }
                
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Label { text: "Max prędkość (km/h)"; font.pixelSize: 10 }
                        TextField {
                            id: maxSpeedInput
                            text: "0.00"
                            inputMethodHints: Qt.ImhFormattedNumbersOnly
                            Layout.fillWidth: true
                            font.pixelSize: 11
                        }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Label { text: "Max wysokość (km)"; font.pixelSize: 10 }
                        TextField {
                            id: maxAltitudeInput
                            text: "0.00"
                            inputMethodHints: Qt.ImhFormattedNumbersOnly
                            Layout.fillWidth: true
                            font.pixelSize: 11
                        }
                    }
                }
            }
        }

        onAccepted: {
            var thrustVal = parseInt(thrustInput.text) || 0
            var lengthVal = parseFloat(lengthInput.text) || 0
            var enginesVal = parseInt(numberOfEnginesInput.text) || 1
            var passengersVal = parseInt(passengersInput.text) || 0
            var speedVal = parseFloat(maxSpeedInput.text) || 0
            var altitudeVal = parseFloat(maxAltitudeInput.text) || 0

            if (root.service.addPlane(brandInput.text, modelInput.text, statusInput.currentText,
                                       thrustVal, lengthVal, enginesVal, passengersVal, speedVal, altitudeVal)) {
                root.refreshPlanes();
                brandInput.clear();
                modelInput.clear();
                thrustInput.text = "0"
                lengthInput.text = "0.00"
                numberOfEnginesInput.text = "1"
                passengersInput.text = "0"
                maxSpeedInput.text = "0.00"
                maxAltitudeInput.text = "0.00"
            }
        }
    }

}
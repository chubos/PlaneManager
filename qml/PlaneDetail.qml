pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material

Item {
    id: root
    objectName: "planeDetail"
    
    required property int planeId
    property var planeData: null
    property string editBrandValue: ""
    property string editModelValue: ""
    property string editStatusValue: ""
    property int editThrustValue: 0
    property double editLengthValue: 0
    property int editNumberOfEnginesValue: 1
    property int editPassengersValue: 0
    property double editMaxSpeedValue: 0
    property double editMaxAltitudeValue: 0

    // qmllint disable unqualified
    readonly property var service: planeService 
    readonly property var stackView: parent
    // qmllint enable unqualified

    function loadPlaneData() {
        var allPlanes = root.service.getAllPlanes()
        for (var i = 0; i < allPlanes.length; i++) {
            if (allPlanes[i].id === root.planeId) {
                root.planeData = allPlanes[i]
                return
            }
        }
    }

    Component.onCompleted: loadPlaneData()

    Rectangle {
        anchors.fill: parent
        color: "#FFFFFF"
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 40
        spacing: 30

        // --- Nagłówek z przyciskiem wróć ---
        RowLayout {
            Layout.fillWidth: true
            spacing: 20

            Button {
                text: "← Wróć"
                flat: true
                Material.foreground: Material.accent
                font.pixelSize: 14
                onClicked: {
                    stackView.pop()
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 5
                Label {
                    text: planeData ? (planeData.brand + " " + planeData.model) : "Samolot"
                    font.pixelSize: 32
                    font.bold: true
                    color: "#212529"
                }
                Label {
                    text: "Szczegóły techniczne i operacyjne"
                    font.pixelSize: 15
                    color: "#6C757D"
                }
            }

            Item { Layout.fillWidth: true }

            Button {
                text: "Edytuj"
                Material.background: Material.accent
                Material.foreground: "white"
                Material.elevation: 0
                font.bold: true
                font.pixelSize: 14
                onClicked: {
                    editDialog.open()
                }
            }
        }

        // --- Główna zawartość ---
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: detailColumn.width

            ColumnLayout {
                id: detailColumn
                width: root.width - 80
                spacing: 25

                // --- Sekcja: Podstawowe dane ---
                Pane {
                    Layout.fillWidth: true
                    Material.background: "#F8FAFC"
                    padding: 25

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 20

                        Label {
                            text: "Podstawowe dane"
                            font.pixelSize: 18
                            font.bold: true
                            color: "#212529"
                        }

                        GridLayout {
                            columns: 2
                            columnSpacing: 40
                            rowSpacing: 20
                            Layout.fillWidth: true

                            // Marka
                            ColumnLayout {
                                spacing: 5
                                Label {
                                    text: "Marka"
                                    font.pixelSize: 12
                                    color: "#6C757D"
                                    font.bold: true
                                }
                                Label {
                                    text: planeData ? planeData.brand : "-"
                                    font.pixelSize: 16
                                    color: "#212529"
                                }
                            }

                            // Model
                            ColumnLayout {
                                spacing: 5
                                Label {
                                    text: "Model"
                                    font.pixelSize: 12
                                    color: "#6C757D"
                                    font.bold: true
                                }
                                Label {
                                    text: planeData ? planeData.model : "-"
                                    font.pixelSize: 16
                                    color: "#212529"
                                }
                            }

                            // ID
                            ColumnLayout {
                                spacing: 5
                                Label {
                                    text: "ID Maszyny"
                                    font.pixelSize: 12
                                    color: "#6C757D"
                                    font.bold: true
                                }
                                Label {
                                    text: planeData ? ("#" + planeData.id) : "-"
                                    font.pixelSize: 16
                                    color: "#212529"
                                }
                            }

                            // Status
                            ColumnLayout {
                                spacing: 5
                                Label {
                                    text: "Status"
                                    font.pixelSize: 12
                                    color: "#6C757D"
                                    font.bold: true
                                }
                                Rectangle {
                                    implicitHeight: 32
                                    implicitWidth: 120
                                    radius: 16
                                    color: planeData && planeData.status === "Dostepny" ? "#E8F5E9" : 
                                           (planeData && planeData.status === "W locie" ? "#FFF3E0" : "#FFEBEE")
                                    
                                    Label {
                                        anchors.centerIn: parent
                                        text: planeData ? planeData.status : "-"
                                        font.pixelSize: 14
                                        font.bold: true
                                        color: planeData && planeData.status === "Dostepny" ? "#2E7D32" : 
                                               (planeData && planeData.status === "W locie" ? "#EF6C00" : "#C62828")
                                    }
                                }
                            }
                        }
                    }
                }

                // --- Sekcja: Parametry techniczne ---
                Pane {
                    Layout.fillWidth: true
                    Material.background: "#F8FAFC"
                    padding: 25

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 20

                        Label {
                            text: "Parametry techniczne"
                            font.pixelSize: 18
                            font.bold: true
                            color: "#212529"
                        }

                        GridLayout {
                            columns: 2
                            columnSpacing: 40
                            rowSpacing: 20
                            Layout.fillWidth: true

                            // Siła ciągu
                            ColumnLayout {
                                spacing: 5
                                Label {
                                    text: "Siła ciągu (kN)"
                                    font.pixelSize: 12
                                    color: "#6C757D"
                                    font.bold: true
                                }
                                Label {
                                    text: planeData && planeData.thrust ? planeData.thrust.toLocaleString() : "-"
                                    font.pixelSize: 16
                                    color: "#212529"
                                }
                            }

                            // Długość
                            ColumnLayout {
                                spacing: 5
                                Label {
                                    text: "Długość (m)"
                                    font.pixelSize: 12
                                    color: "#6C757D"
                                    font.bold: true
                                }
                                Label {
                                    text: planeData && planeData.length ? planeData.length.toFixed(2) : "-"
                                    font.pixelSize: 16
                                    color: "#212529"
                                }
                            }

                            // Liczba silników
                            ColumnLayout {
                                spacing: 5
                                Label {
                                    text: "Liczba silników"
                                    font.pixelSize: 12
                                    color: "#6C757D"
                                    font.bold: true
                                }
                                Label {
                                    text: planeData && planeData.numberOfEngines ? planeData.numberOfEngines : "-"
                                    font.pixelSize: 16
                                    color: "#212529"
                                }
                            }

                            // Pasażerowie
                            ColumnLayout {
                                spacing: 5
                                Label {
                                    text: "Liczba pasażerów"
                                    font.pixelSize: 12
                                    color: "#6C757D"
                                    font.bold: true
                                }
                                Label {
                                    text: planeData && planeData.passengers ? planeData.passengers : "-"
                                    font.pixelSize: 16
                                    color: "#212529"
                                }
                            }

                            // Max prędkość
                            ColumnLayout {
                                spacing: 5
                                Label {
                                    text: "Maksymalna prędkość (km/h)"
                                    font.pixelSize: 12
                                    color: "#6C757D"
                                    font.bold: true
                                }
                                Label {
                                    text: planeData && planeData.maxSpeed ? planeData.maxSpeed.toFixed(2) : "-"
                                    font.pixelSize: 16
                                    color: "#212529"
                                }
                            }

                            // Max wysokość
                            ColumnLayout {
                                spacing: 5
                                Label {
                                    text: "Maksymalna wysokość (km)"
                                    font.pixelSize: 12
                                    color: "#6C757D"
                                    font.bold: true
                                }
                                Label {
                                    text: planeData && planeData.maxAltitude ? planeData.maxAltitude.toFixed(2) : "-"
                                    font.pixelSize: 16
                                    color: "#212529"
                                }
                            }
                        }
                    }
                }

                Item { Layout.fillHeight: true }
            }
        }
    }

    // --- Dialog Edycji ---
    Dialog {
        id: editDialog
        title: "Edycja Samolotu"
        standardButtons: Dialog.Ok | Dialog.Cancel
        anchors.centerIn: parent
        modal: true
        width: 360

        ScrollView {
            anchors.fill: parent
            contentWidth: editColumn.width

            ColumnLayout {
                id: editColumn
                width: editDialog.width - 30
                spacing: 10

                Label { text: "Podstawowe dane"; font.bold: true; font.pixelSize: 12; color: "#212529" }
                
                TextField {
                    id: editBrandInput
                    placeholderText: root.editBrandValue
                    Layout.fillWidth: true
                    font.pixelSize: 12
                }

                TextField {
                    id: editModelInput
                    placeholderText: root.editModelValue
                    Layout.fillWidth: true
                    font.pixelSize: 12
                }

                ComboBox {
                    id: editStatusInput
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
                            id: editThrustInput
                            text: root.editThrustValue
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
                            id: editLengthInput
                            text: root.editLengthValue.toFixed(2)
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
                            id: editNumberOfEnginesInput
                            text: root.editNumberOfEnginesValue
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
                            id: editPassengersInput
                            text: root.editPassengersValue
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
                            id: editMaxSpeedInput
                            text: root.editMaxSpeedValue.toFixed(2)
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
                            id: editMaxAltitudeInput
                            text: root.editMaxAltitudeValue.toFixed(2)
                            inputMethodHints: Qt.ImhFormattedNumbersOnly
                            Layout.fillWidth: true
                            font.pixelSize: 11
                        }
                    }
                }
            }
        }

        onAboutToHide: {
            // Czyść wartości
            editBrandInput.clear()
            editModelInput.clear()
            editThrustInput.clear()
            editLengthInput.clear()
            editNumberOfEnginesInput.clear()
            editPassengersInput.clear()
            editMaxSpeedInput.clear()
            editMaxAltitudeInput.clear()
        }

        onAccepted: {
            var brandToSave = editBrandInput.text.length > 0 ? editBrandInput.text : root.editBrandValue
            var modelToSave = editModelInput.text.length > 0 ? editModelInput.text : root.editModelValue
            var thrustValue = parseInt(editThrustInput.text) || 0
            var lengthValue = parseFloat(editLengthInput.text) || 0
            var enginesValue = parseInt(editNumberOfEnginesInput.text) || 1
            var passengersValue = parseInt(editPassengersInput.text) || 0
            var speedValue = parseFloat(editMaxSpeedInput.text) || 0
            var altitudeValue = parseFloat(editMaxAltitudeInput.text) || 0

            if (root.service.updatePlane(root.planeId, brandToSave, modelToSave, editStatusInput.currentText,
                                          thrustValue, lengthValue, enginesValue, passengersValue, speedValue, altitudeValue)) {
                root.loadPlaneData()
                editDialog.close()
            }
        }
    }
}

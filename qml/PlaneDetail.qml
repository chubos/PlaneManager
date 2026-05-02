pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material

import "."

// qmllint disable unqualified

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
    // qmllint enable unqualified

    PlaneEditDialog {
        id: editDialog
        service: root.service
        onSaved: root.loadPlaneData()
    }

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
                    var view = root.StackView.view
                    if (!view) {
                        console.warn("PlaneDetail: StackView.view is null; cannot pop")
                        return
                    }
                    view.pop()
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 5
                Label {
                    text: root.planeData ? (root.planeData.brand + " " + root.planeData.model) : "Samolot"
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
                    editDialog.openWithData(root.planeData)
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
                                    text: root.planeData ? root.planeData.brand : "-"
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
                                    text: root.planeData ? root.planeData.model : "-"
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
                                    text: root.planeData ? ("#" + root.planeData.id) : "-"
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
                                     color: root.planeData && root.planeData.status === "Dostepny" ? "#E8F5E9" : 
                                         (root.planeData && root.planeData.status === "W locie" ? "#FFF3E0" : "#FFEBEE")
                                    
                                    Label {
                                        anchors.centerIn: parent
                                         text: root.planeData ? root.planeData.status : "-"
                                        font.pixelSize: 14
                                        font.bold: true
                                         color: root.planeData && root.planeData.status === "Dostepny" ? "#2E7D32" : 
                                             (root.planeData && root.planeData.status === "W locie" ? "#EF6C00" : "#C62828")
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
                                    text: root.planeData && root.planeData.thrust ? root.planeData.thrust.toLocaleString() : "-"
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
                                    text: root.planeData && root.planeData.length ? root.planeData.length.toFixed(2) : "-"
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
                                    text: root.planeData && root.planeData.numberOfEngines ? root.planeData.numberOfEngines : "-"
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
                                    text: root.planeData && root.planeData.passengers ? root.planeData.passengers : "-"
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
                                    text: root.planeData && root.planeData.maxSpeed ? root.planeData.maxSpeed.toFixed(2) : "-"
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
                                    text: root.planeData && root.planeData.maxAltitude ? root.planeData.maxAltitude.toFixed(2) : "-"
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

}

// qmllint enable unqualified

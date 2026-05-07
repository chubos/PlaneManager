pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material

Item {
    id: root
    objectName: "statisticsView"
    
    property var stats: null
    property var extremes: null
    
    // qmllint disable unqualified
    readonly property var service: planeService 
    // qmllint enable unqualified
    
    function loadStatistics() {
        root.stats = root.service.getStatistics()
        root.extremes = root.service.getExtremeAircrafts()
        if (pieChart) {
            pieChart.requestPaint()
        }
    }
    
    Component.onCompleted: loadStatistics()
    
    Rectangle {
        anchors.fill: parent
        color: "#FFFFFF"
    }
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 30
        spacing: 25

        // --- Nagłówek ---
        Label {
            text: "Statystyka Samolotów"
            font.pixelSize: 32
            font.bold: true
            color: "#1a1a1a"
            Layout.alignment: Qt.AlignHCenter
        }

        // --- Główna zawartość ---
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: mainContent.width

            ColumnLayout {
                id: mainContent
                width: Math.min(parent.parent.width - 60, 1000)
                spacing: 30
                Layout.alignment: Qt.AlignHCenter

                // --- Sekcja 1: Ogólne statystyki ---
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    Layout.alignment: Qt.AlignHCenter

                    Label {
                        text: "Ogólne Informacje"
                        font.pixelSize: 16
                        font.bold: true
                        color: "#333"
                        Layout.alignment: Qt.AlignHCenter
                    }

                    GridLayout {
                        columns: 4
                        columnSpacing: 20
                        rowSpacing: 15
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignHCenter

                        // Wszystkie samoloty
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 80
                            radius: 12
                            color: "#E3F2FD"
                            Layout.preferredWidth: (parent.width - 60) / 4

                            ColumnLayout {
                                anchors.centerIn: parent
                                anchors.margins: 12
                                spacing: 8
                                width: parent.width - 24

                                Label {
                                    text: root.stats ? root.stats.totalPlanes : "0"
                                    font.pixelSize: 36
                                    font.bold: true
                                    color: "#1976D2"
                                    Layout.alignment: Qt.AlignHCenter
                                }
                                Label {
                                    text: "Razem"
                                    font.pixelSize: 14
                                    color: "#1976D2"
                                    Layout.alignment: Qt.AlignHCenter
                                }
                            }
                        }

                        // Dostępne
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 80
                            radius: 12
                            color: "#E8F5E9"
                            Layout.preferredWidth: (parent.width - 60) / 4

                            ColumnLayout {
                                anchors.centerIn: parent
                                anchors.margins: 12
                                spacing: 8
                                width: parent.width - 24

                                Label {
                                    text: root.stats ? root.stats.availablePlanes : "0"
                                    font.pixelSize: 36
                                    font.bold: true
                                    color: "#388E3C"
                                    Layout.alignment: Qt.AlignHCenter
                                }
                                Label {
                                    text: "Dostępne"
                                    font.pixelSize: 14
                                    color: "#388E3C"
                                    Layout.alignment: Qt.AlignHCenter
                                }
                            }
                        }

                        // W locie
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 80
                            radius: 12
                            color: "#FFF3E0"
                            Layout.preferredWidth: (parent.width - 60) / 4

                            ColumnLayout {
                                anchors.centerIn: parent
                                anchors.margins: 12
                                spacing: 8
                                width: parent.width - 24

                                Label {
                                    text: root.stats ? root.stats.inFlightPlanes : "0"
                                    font.pixelSize: 36
                                    font.bold: true
                                    color: "#F57C00"
                                    Layout.alignment: Qt.AlignHCenter
                                }
                                Label {
                                    text: "W locie"
                                    font.pixelSize: 14
                                    color: "#F57C00"
                                    Layout.alignment: Qt.AlignHCenter
                                }
                            }
                        }

                        // W serwisie
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 80
                            radius: 12
                            color: "#FFEBEE"
                            Layout.preferredWidth: (parent.width - 60) / 4

                            ColumnLayout {
                                anchors.centerIn: parent
                                anchors.margins: 12
                                spacing: 8
                                width: parent.width - 24

                                Label {
                                    text: root.stats ? root.stats.inServicePlanes : "0"
                                    font.pixelSize: 36
                                    font.bold: true
                                    color: "#C62828"
                                    Layout.alignment: Qt.AlignHCenter
                                }
                                Label {
                                    text: "W serwisie"
                                    font.pixelSize: 14
                                    color: "#C62828"
                                    Layout.alignment: Qt.AlignHCenter
                                }
                            }
                        }
                    }
                }

                // --- Sekcja 2: Wykres kołowy ---
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    Layout.alignment: Qt.AlignHCenter

                    Label {
                        text: "Rozkład Statusów Samolotów"
                        font.pixelSize: 16
                        font.bold: true
                        color: "#333"
                        Layout.alignment: Qt.AlignHCenter
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 280
                        spacing: 30
                        Layout.alignment: Qt.AlignHCenter

                        Rectangle {
                            Layout.preferredWidth: 280
                            Layout.preferredHeight: 280
                            color: "transparent"

                            Canvas {
                                id: pieChart
                                anchors.fill: parent

                                onPaint: {
                                    var ctx = getContext("2d")
                                    ctx.clearRect(0, 0, width, height)

                                    var total = root.stats ? root.stats.totalPlanes : 1
                                    var available = root.stats ? root.stats.availablePlanes : 0
                                    var inFlight = root.stats ? root.stats.inFlightPlanes : 0
                                    var inService = root.stats ? root.stats.inServicePlanes : 0

                                    var centerX = width / 2
                                    var centerY = height / 2
                                    var radius = Math.min(width, height) / 2 - 20

                                    var startAngle = -Math.PI / 2
                                    var colors = ["#4CAF50", "#FF9800", "#F44336"]
                                    var values = [available, inFlight, inService]

                                    for (var i = 0; i < values.length; i++) {
                                        var sliceAngle = (values[i] / Math.max(total, 1)) * 2 * Math.PI

                                        ctx.fillStyle = colors[i]
                                        ctx.beginPath()
                                        ctx.moveTo(centerX, centerY)
                                        ctx.arc(centerX, centerY, radius, startAngle, startAngle + sliceAngle)
                                        ctx.closePath()
                                        ctx.fill()

                                        startAngle += sliceAngle
                                    }
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillHeight: true
                            Layout.fillWidth: true
                            spacing: 14

                            RowLayout {
                                spacing: 10
                                Rectangle { Layout.preferredWidth: 16; Layout.preferredHeight: 16; color: "#4CAF50"; radius: 2 }
                                ColumnLayout {
                                    spacing: 2
                                    Label { text: "Dostępne"; font.pixelSize: 14; font.bold: true }
                                    Label { text: root.stats ? root.stats.availablePlanes : "0"; font.pixelSize: 13; color: "#666" }
                                }
                            }

                            RowLayout {
                                spacing: 10
                                Rectangle { Layout.preferredWidth: 16; Layout.preferredHeight: 16; color: "#FF9800"; radius: 2 }
                                ColumnLayout {
                                    spacing: 2
                                    Label { text: "W locie"; font.pixelSize: 14; font.bold: true }
                                    Label { text: root.stats ? root.stats.inFlightPlanes : "0"; font.pixelSize: 13; color: "#666" }
                                }
                            }

                            RowLayout {
                                spacing: 10
                                Rectangle { Layout.preferredWidth: 16; Layout.preferredHeight: 16; color: "#F44336"; radius: 2 }
                                ColumnLayout {
                                    spacing: 2
                                    Label { text: "W serwisie"; font.pixelSize: 14; font.bold: true }
                                    Label { text: root.stats ? root.stats.inServicePlanes : "0"; font.pixelSize: 13; color: "#666" }
                                }
                            }

                            Item { Layout.fillHeight: true }
                        }
                    }
                }

                // --- Sekcja 3: Wymiary i pojemność ---
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    Layout.alignment: Qt.AlignHCenter

                    Label {
                        text: "Charakterystyka Floty"
                        font.pixelSize: 16
                        font.bold: true
                        color: "#333"
                        Layout.alignment: Qt.AlignHCenter
                    }

                    GridLayout {
                        columns: 2
                        columnSpacing: 30
                        rowSpacing: 15
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignHCenter

                        ColumnLayout {
                            spacing: 10

                            Label { text: "Długość Samolotów"; font.pixelSize: 15; font.bold: true; color: "#333" }

                            GridLayout {
                                columns: 2
                                columnSpacing: 15
                                rowSpacing: 8
                                Layout.fillWidth: true

                                Label { text: "Średnia:"; font.pixelSize: 13; color: "#000" }
                                Label { text: root.stats ? root.stats.avgLength.toFixed(2) + " m" : "0 m"; font.pixelSize: 12; font.bold: true; color: "#1976D2" }

                                Label { text: "Maksymalna:"; font.pixelSize: 13; color: "#000" }
                                ColumnLayout {
                                    spacing: 2
                                    Label { text: root.extremes ? Number(root.extremes.maxLengthValue).toFixed(2) + " m" : "0 m"; font.pixelSize: 12; font.bold: true; color: "#4CAF50" }
                                    Label { text: root.extremes ? (root.extremes.maxLengthBrand + " " + root.extremes.maxLengthModel) : ""; font.pixelSize: 10; color: "#999" }
                                }

                                Label { text: "Minimalna:"; font.pixelSize: 13; color: "#000" }
                                ColumnLayout {
                                    spacing: 2
                                    Label { text: root.extremes ? Number(root.extremes.minLengthValue).toFixed(2) + " m" : "0 m"; font.pixelSize: 12; font.bold: true; color: "#F57C00" }
                                    Label { text: root.extremes ? (root.extremes.minLengthBrand + " " + root.extremes.minLengthModel) : ""; font.pixelSize: 10; color: "#999" }
                                }
                            }
                        }

                        ColumnLayout {
                            spacing: 10

                            Label { text: "Pojemność Samolotów"; font.pixelSize: 15; font.bold: true; color: "#333" }

                            GridLayout {
                                columns: 2
                                columnSpacing: 15
                                rowSpacing: 8
                                Layout.fillWidth: true

                                Label { text: "Średnia:"; font.pixelSize: 13; color: "#000" }
                                Label { text: root.stats ? Math.round(root.stats.avgPassengers) + " pax" : "0 pax"; font.pixelSize: 12; font.bold: true; color: "#1976D2" }

                                Label { text: "Maksymalna:"; font.pixelSize: 13; color: "#000" }
                                ColumnLayout {
                                    spacing: 2
                                    Label { text: root.extremes ? root.extremes.maxPassengersValue + " pax" : "0 pax"; font.pixelSize: 12; font.bold: true; color: "#4CAF50" }
                                    Label { text: root.extremes ? (root.extremes.maxPassengersBrand + " " + root.extremes.maxPassengersModel) : ""; font.pixelSize: 10; color: "#999" }
                                }

                                Label { text: "Minimalna:"; font.pixelSize: 13; color: "#000" }
                                ColumnLayout {
                                    spacing: 2
                                    Label { text: root.extremes ? root.extremes.minPassengersValue + " pax" : "0 pax"; font.pixelSize: 12; font.bold: true; color: "#F57C00" }
                                    Label { text: root.extremes ? (root.extremes.minPassengersBrand + " " + root.extremes.minPassengersModel) : ""; font.pixelSize: 10; color: "#999" }
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


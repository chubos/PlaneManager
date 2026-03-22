pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material

Item {
    id: root
    objectName: "airportView"

    // qmllint disable unqualified
    readonly property var service: airportService 
    // qmllint enable unqualified

    // Bezposrednie ladowanie danych do modelu
    function refreshAirports() {
        listView.model = root.service.getAllAirports();
    }

    Component.onCompleted: root.refreshAirports()

    // Jasne tlo
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
            
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 5
                Label {
                    text: "Baza Lotnisk"
                    font.pixelSize: 32; font.bold: true; color: "#212529"
                }
                Label {
                    text: "Zarzadzaj lokalizacjami i kodami ICAO"
                    font.pixelSize: 15; color: "#6C757D"
                }
            }

            Button {
                text: "+ Dodaj Lotnisko"
                Material.background: Material.accent
                Material.foreground: "white"
                Material.elevation: 0
                font.bold: true; font.pixelSize: 14
                Layout.preferredHeight: 45
                onClicked: addDialog.open()
            }
        }

        // --- Lista Lotnisk ---
        ListView {
            id: listView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 15

            delegate: Pane {
                id: airportDelegate
                required property var modelData
                width: listView.width - 10 
                anchors.horizontalCenter: parent.horizontalCenter
                Material.background: "#FAFAFA" 
                padding: 20

                RowLayout {
                    anchors.fill: parent
                    spacing: 25

                    // Ozdobna ikona z pierwsza litera kodu ICAO
                    Rectangle {
                        width: 46; height: 46; radius: 23
                        color: "#E8EAF6" // Lekki fioletowo-niebieski
                        Label {
                            anchors.centerIn: parent
                            text: airportDelegate.modelData.icaoCode ? airportDelegate.modelData.icaoCode.charAt(0) : "A"
                            font.pixelSize: 20; font.bold: true; color: "#3F51B5"
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        Label {
                            text: airportDelegate.modelData.name
                            font.pixelSize: 18; font.bold: true; color: "#212529"
                        }
                        Label {
                            text: "Kod ICAO: " + airportDelegate.modelData.icaoCode
                            font.pixelSize: 14; font.bold: true; color: Material.accent
                        }
                        Label {
                            text: "Wspolrzedne: Lat " + Number(airportDelegate.modelData.latitude).toFixed(4) + ", Lon " + Number(airportDelegate.modelData.longitude).toFixed(4)
                            font.pixelSize: 12; color: "#ADB5BD"
                        }
                    }

                    Item { Layout.preferredWidth: 20 } 

                    Button {
                        text: "Usun"
                        flat: true
                        Material.foreground: "#DC3545" 
                        Material.elevation: 0
                        onClicked: {
                            if (root.service.deleteAirport(airportDelegate.modelData.id)) {
                                root.refreshAirports();
                            }
                        }
                    }
                }
            }
        }
    }

    // --- Dialog Dodawania ---
    Dialog {
        id: addDialog
        title: "Rejestracja Nowego Lotniska"
        standardButtons: Dialog.Ok | Dialog.Cancel
        anchors.centerIn: parent
        modal: true
        width: 450

        ColumnLayout {
            anchors.fill: parent
            spacing: 20
            
            TextField {
                id: icaoInput
                placeholderText: "Kod ICAO (np. EPWA)"
                Layout.fillWidth: true; font.pixelSize: 16
                maximumLength: 4 // ICAO ma zawsze 4 znaki
            }
            TextField {
                id: nameInput
                placeholderText: "Pelna nazwa lotniska"
                Layout.fillWidth: true; font.pixelSize: 16
            }
            
            // Pola na wspolrzedne ukladamy obok siebie
            RowLayout {
                Layout.fillWidth: true
                spacing: 15
                TextField {
                    id: latInput
                    placeholderText: "Szerokosc (Lat)"
                    Layout.fillWidth: true; font.pixelSize: 16
                    inputMethodHints: Qt.ImhFormattedNumbersOnly
                }
                TextField {
                    id: lonInput
                    placeholderText: "Dlugosc (Lon)"
                    Layout.fillWidth: true; font.pixelSize: 16
                    inputMethodHints: Qt.ImhFormattedNumbersOnly
                }
            }
        }

        onAccepted: {
            // Konwersja tekstu z pol na liczby zmiennoprzecinkowe (float/double)
            var lat = parseFloat(latInput.text.replace(",", "."));
            var lon = parseFloat(lonInput.text.replace(",", "."));
            
            if (root.service.addAirport(icaoInput.text.toUpperCase(), nameInput.text, lat, lon)) {
                root.refreshAirports();
                icaoInput.clear();
                nameInput.clear();
                latInput.clear();
                lonInput.clear();
            }
        }
    }
}
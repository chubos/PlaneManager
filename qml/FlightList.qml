pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material

Item {
    id: root
    objectName: "flightView"

    // qmllint disable unqualified
    readonly property var service: flightService 
    // qmllint enable unqualified

    // Funkcja odswiezajaca glowna liste lotow
    function refreshFlights() {
        listView.model = root.service.getAllFlights();
    }

    // Funkcja ladujaca dane do list rozwijanych w formularzu
    function loadDropdowns() {
        // Samoloty
        // qmllint disable unqualified
        var pData = planeService.getAllPlanes();
        // qmllint enable unqualified
        var pModel = [];
        for (var i = 0; i < pData.length; i++) {
            pModel.push({ text: pData[i].brand + " " + pData[i].model, value: pData[i].id });
        }
        planeCombo.model = pModel;

        // Lotniska
        // qmllint disable unqualified
        var aData = airportService.getAllAirports();
        // qmllint enable unqualified
        var aModel = [];
        for (var j = 0; j < aData.length; j++) {
            aModel.push({ text: aData[j].icaoCode + " - " + aData[j].name, value: aData[j].id });
        }
        depCombo.model = aModel;
        arrCombo.model = aModel;
    }

    Component.onCompleted: {
        root.refreshFlights();
        root.loadDropdowns();
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
            
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 5
                Label {
                    text: "Harmonogram Lotow"
                    font.pixelSize: 32; font.bold: true; color: "#212529"
                }
                Label {
                    text: "Planuj trasy i zarzadzaj rezerwacjami floty"
                    font.pixelSize: 15; color: "#6C757D"
                }
            }

            Button {
                text: "+ Zaplanuj Lot"
                Material.background: Material.accent
                Material.foreground: "white"
                Material.elevation: 0
                font.bold: true; font.pixelSize: 14
                Layout.preferredHeight: 45
                onClicked: {
                    root.loadDropdowns(); // Odswiezamy listy przed otwarciem
                    addDialog.open();
                }
            }
        }

        // --- Lista Lotow ---
        ListView {
            id: listView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 15

            delegate: Pane {
                id: flightDelegate
                required property var modelData
                width: listView.width - 10 
                anchors.horizontalCenter: parent.horizontalCenter
                Material.background: "#FAFAFA" 
                padding: 20

                RowLayout {
                    anchors.fill: parent
                    spacing: 25

                    // Ozdobna ikona samolociku
                    Rectangle {
                        width: 46; height: 46; radius: 23
                        color: "#E0F2F1" // Jasny morski
                        Label {
                            anchors.centerIn: parent
                            text: "✈" 
                            font.pixelSize: 20; color: "#009688"
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        Label {
                            text: flightDelegate.modelData.planeName
                            font.pixelSize: 18; font.bold: true; color: "#212529"
                        }
                        Label {
                            text: "Trasa: " + flightDelegate.modelData.depIcao + " ➔ " + flightDelegate.modelData.arrIcao
                            font.pixelSize: 14; font.bold: true; color: Material.accent
                        }
                        Label {
                            text: "Start: " + flightDelegate.modelData.startTime + " | Ladowanie: " + flightDelegate.modelData.endTime
                            font.pixelSize: 12; color: "#6C757D"
                        }
                    }

                    Item { Layout.preferredWidth: 20 } 

                    Button {
                        text: "Anuluj Lot"
                        flat: true
                        Material.foreground: "#DC3545" 
                        Material.elevation: 0
                        onClicked: {
                            if (root.service.deleteFlight(flightDelegate.modelData.id)) {
                                root.refreshFlights();
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
        title: "Kreator Nowego Lotu"
        standardButtons: Dialog.Ok | Dialog.Cancel
        anchors.centerIn: parent
        modal: true
        width: 500

        ColumnLayout {
            anchors.fill: parent
            spacing: 15
            
            Label { text: "Wybierz maszyne:"; color: "#6C757D"; font.bold: true }
            ComboBox {
                id: planeCombo
                Layout.fillWidth: true; font.pixelSize: 16
                textRole: "text"
                valueRole: "value"
            }

            Label { text: "Wybierz lotniska (Start -> Cel):"; color: "#6C757D"; font.bold: true; Layout.topMargin: 10 }
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                ComboBox {
                    id: depCombo
                    Layout.fillWidth: true; font.pixelSize: 14
                    textRole: "text"
                    valueRole: "value"
                }
                Label { text: "➔"; font.pixelSize: 20; color: Material.accent }
                ComboBox {
                    id: arrCombo
                    Layout.fillWidth: true; font.pixelSize: 14
                    textRole: "text"
                    valueRole: "value"
                }
            }

            Label { text: "Daty i godziny (Format: YYYY-MM-DD HH:MM):"; color: "#6C757D"; font.bold: true; Layout.topMargin: 10 }
            RowLayout {
                Layout.fillWidth: true
                spacing: 15
                TextField {
                    id: startInput
                    placeholderText: "Start np. 2026-06-15 14:30"
                    Layout.fillWidth: true; font.pixelSize: 14
                }
                TextField {
                    id: endInput
                    placeholderText: "Koniec np. 2026-06-15 17:00"
                    Layout.fillWidth: true; font.pixelSize: 14
                }
            }
        }

        onAccepted: {
            // Poniewaz QDateTime w C++ lubi format ISO, formatujemy tekst z pol (zamieniamy spacje na T i dodajemy sekundy)
            var startIso = startInput.text.replace(" ", "T") + ":00";
            var endIso = endInput.text.replace(" ", "T") + ":00";

            // planeCombo.currentValue zwroci nam bezposrednio ID samolotu!
            if (root.service.addFlight(planeCombo.currentValue, depCombo.currentValue, arrCombo.currentValue, startIso, endIso)) {
                root.refreshFlights();
                startInput.clear();
                endInput.clear();
            }
        }
    }
}
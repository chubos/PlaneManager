pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material

Item {
    id: root
    objectName: "planeView"

    // qmllint disable unqualified
    readonly property var service: planeService 
    // qmllint enable unqualified

    // Funkcja pobiera liste z C++ i wrzuca BEZPOSREDNIO do widoku
    function refreshPlanes() {
        listView.model = root.service.getAllPlanes();
    }

    Component.onCompleted: root.refreshPlanes()

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
            spacing: 25
            
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 5
                Label {
                    text: "Flota Samolotow"
                    font.pixelSize: 32; font.bold: true; color: "#212529"
                }
                Label {
                    text: "Zarzadzaj swoimi maszynami i ich statusem"
                    font.pixelSize: 15; color: "#6C757D"
                }
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
                width: listView.width - 10 
                anchors.horizontalCenter: parent.horizontalCenter
                Material.background: "#FAFAFA" 
                padding: 20

                RowLayout {
                    anchors.fill: parent
                    spacing: 25

                    Rectangle {
                        width: 46; height: 46; radius: 23
                        color: "#E3F2FD" 
                        Label {
                            anchors.centerIn: parent
                            // Uzywamy modelData i sprawdzamy czy istnieje
                            text: planeDelegate.modelData.brand ? planeDelegate.modelData.brand.charAt(0) : "?" 
                            font.pixelSize: 20; font.bold: true; color: Material.accent
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        Label {
                            // Wszedzie zmieniamy 'model' na 'modelData'
                            text: planeDelegate.modelData.brand + " " + planeDelegate.modelData.model
                            font.pixelSize: 18; font.bold: true; color: "#212529"
                        }
                        Label {
                            text: "ID Maszyny: #" + planeDelegate.modelData.id
                            font.pixelSize: 12; color: "#ADB5BD"
                        }
                    }

                    Rectangle {
                        width: 110; height: 32; radius: 16
                        color: planeDelegate.modelData.status === "Dostepny" ? "#E8F5E9" : (planeDelegate.modelData.status === "W locie" ? "#FFF3E0" : "#FFEBEE")
                        
                        Label {
                            anchors.centerIn: parent
                            text: planeDelegate.modelData.status
                            font.pixelSize: 12; font.bold: true
                            color: planeDelegate.modelData.status === "Dostepny" ? "#2E7D32" : (planeDelegate.modelData.status === "W locie" ? "#EF6C00" : "#C62828")
                        }
                    }

                    Item { Layout.preferredWidth: 20 } 

                    Button {
                        text: "Usun"
                        flat: true
                        Material.foreground: "#DC3545" 
                        Material.elevation: 0
                        onClicked: {
                            if (root.service.deletePlane(planeDelegate.modelData.id)) {
                                root.refreshPlanes();
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
        title: "Rejestracja Nowego Samolotu"
        standardButtons: Dialog.Ok | Dialog.Cancel
        anchors.centerIn: parent
        modal: true
        width: 400

        ColumnLayout {
            anchors.fill: parent
            spacing: 20
            
            TextField {
                id: brandInput
                placeholderText: "Marka (np. Airbus)"
                Layout.fillWidth: true; font.pixelSize: 16
            }
            TextField {
                id: modelInput
                placeholderText: "Model (np. A320)"
                Layout.fillWidth: true; font.pixelSize: 16
            }
            ComboBox {
                id: statusInput
                model: ["Dostepny", "W serwisie", "W locie"]
                Layout.fillWidth: true; font.pixelSize: 16
            }
        }

        onAccepted: {
            if (root.service.addPlane(brandInput.text, modelInput.text, statusInput.currentText)) {
                root.refreshPlanes();
                brandInput.clear();
                modelInput.clear();
            }
        }
    }
}
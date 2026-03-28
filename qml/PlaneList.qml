pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material

Item {
    id: root
    objectName: "planeView"
    property int editPlaneId: -1
    property string editBrandValue: ""
    property string editModelValue: ""
    property string editStatusValue: ""

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
                            root.editPlaneId = planeDelegate.modelData.id
                            root.editBrandValue = planeDelegate.modelData.brand ? planeDelegate.modelData.brand : ""
                            root.editModelValue = planeDelegate.modelData.model ? planeDelegate.modelData.model : ""
                            root.editStatusValue = planeDelegate.modelData.status ? planeDelegate.modelData.status : "Dostepny"
                            editBrandInput.clear()
                            editModelInput.clear()
                            var statusIndex = editStatusInput.model.indexOf(root.editStatusValue)
                            editStatusInput.currentIndex = statusIndex >= 0 ? statusIndex : 0
                            editDialog.open();
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

    // --- Dialog Edycji ---
    Dialog {
        id: editDialog
        title: "Edycja Samolotu"
        standardButtons: Dialog.Ok | Dialog.Cancel
        anchors.centerIn: parent
        modal: true
        width: 400

        ColumnLayout {
            anchors.fill: parent
            spacing: 20

            TextField {
                id: editBrandInput
                placeholderText: root.editBrandValue
                Layout.fillWidth: true; font.pixelSize: 16
            }
            TextField {
                id: editModelInput
                placeholderText: root.editModelValue
                Layout.fillWidth: true; font.pixelSize: 16
            }
            ComboBox {
                id: editStatusInput
                model: ["Dostepny", "W serwisie", "W locie"]
                Layout.fillWidth: true; font.pixelSize: 16
            }
        }

        onAccepted: {
            var brandToSave = editBrandInput.text.length > 0 ? editBrandInput.text : root.editBrandValue
            var modelToSave = editModelInput.text.length > 0 ? editModelInput.text : root.editModelValue
            if (root.service.updatePlane(root.editPlaneId, brandToSave, modelToSave, editStatusInput.currentText)) {
                root.refreshPlanes();
                editBrandInput.clear();
                editModelInput.clear();
            }
        }
    }

}
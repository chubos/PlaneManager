pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material
import QtQuick.Dialogs

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

    FileDialog {
        id: imageFileDialog
        title: "Wybierz zdjęcie samolotu"
        nameFilters: ["Pliki obrazów (*.jpg *.jpeg *.png *.bmp)"]
        onAccepted: {
            var path = imageFileDialog.selectedFile.toString().substring(8)
            root.service.uploadImage(root.planeId, path)
            infoLabel.text = "Przesyłanie..."
        }
    }

    Connections {
        target: root.service
        function onImageUploadFinished(planeId, success, msg) {
            if (planeId === root.planeId) {
                infoLabel.text = msg;
                if (success) root.loadPlaneData();
            }
        }
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
        anchors.margins: 30
        spacing: 25

        // --- Nagłówek ---
        RowLayout {
            Layout.fillWidth: true
            spacing: 20

            Button {
                text: "← Wróć"
                flat: true
                Material.foreground: Material.accent
                font.pixelSize: 13
                onClicked: root.StackView.view ? root.StackView.view.pop() : null
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3
                Label {
                    text: root.planeData ? (root.planeData.brand + " " + root.planeData.model) : "Samolot"
                    font.pixelSize: 28
                    font.bold: true
                    color: "#1a1a1a"
                }
                Label {
                    text: "ID: " + (root.planeData ? root.planeData.id : "-")
                    font.pixelSize: 12
                    color: "#888888"
                }
            }

            Item { Layout.fillWidth: true }

            Button {
                text: "Edytuj"
                Material.background: Material.accent
                Material.foreground: "white"
                padding: 12
                font.bold: true
                font.pixelSize: 12
                onClicked: editDialog.openWithData(root.planeData)
            }
        }

        // --- Główna zawartość: Zdjęcie + Dane ---
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 25

            // --- Lewa strona: Zdjęcie ---
            Pane {
                Layout.preferredWidth: 380
                Layout.alignment: Qt.AlignTop
                Material.background: "#FFFFFF"
                padding: 0

                ColumnLayout {
                    width: 380
                    spacing: 12

                    Rectangle {
                        Layout.preferredWidth: 380
                        Layout.preferredHeight: 350
                        color: "#FFFFFF"
                        radius: 12

                        Image {
                            id: planeImage
                            anchors.fill: parent
                            anchors.margins: 12
                            fillMode: Image.PreserveAspectFit
                            source: root.planeData && root.planeData.imagePath ? (root.planeData.imagePath + "?t=" + new Date().getTime()) : ""
                            smooth: true
                            mipmap: true
                            cache: false
                            asynchronous: true
                            onSourceChanged: console.log("Image source changed to:", source)
                            onStatusChanged: console.log("Image status:", status, "- source:", source)
                        }

                        Label {
                            anchors.centerIn: parent
                            text: "Brak zdjęcia"
                            font.pixelSize: 14
                            color: "#999999"
                            visible: !planeImage.source || planeImage.source === ""
                        }
                    }

                    Button {
                        text: "Zmień zdjęcie"
                        Layout.fillWidth: true
                        Material.background: Material.accent
                        Material.foreground: "white"
                        font.bold: true
                        font.pixelSize: 12
                        onClicked: imageFileDialog.open()
                    }

                    Label {
                        id: infoLabel
                        text: ""
                        color: "#666666"
                        font.pixelSize: 11
                        visible: text !== ""
                        wrapMode: Text.Wrap
                    }
                }
            }

            // --- Prawa strona: Dane techniczne ---
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentWidth: dataColumn.width

                ColumnLayout {
                    id: dataColumn
                    width: parent.parent.width - 420
                    spacing: 20

                    // Sekcja 1: Status
                    ColumnLayout {
                        spacing: 10
                        Layout.fillWidth: true

                        Label {
                            text: "Status"
                            font.pixelSize: 12
                            font.bold: true
                            color: "#666666"
                            font.capitalization: Font.AllUppercase
                        }

                        Rectangle {
                            Layout.preferredHeight: 40
                            Layout.fillWidth: true
                            radius: 8
                            color: root.planeData && root.planeData.status === "Dostepny" ? "#E8F5E9" : 
                                   (root.planeData && root.planeData.status === "W locie" ? "#FFF3E0" : "#FFEBEE")

                            Label {
                                anchors.centerIn: parent
                                text: root.planeData ? root.planeData.status : "-"
                                font.pixelSize: 14
                                font.bold: true
                                color: root.planeData && root.planeData.status === "Dostepny" ? "#2E7D32" : 
                                       (root.planeData && root.planeData.status === "W locie" ? "#F57C00" : "#C62828")
                            }
                        }
                    }

                    // Sekcja 2: Wymiary i silniki
                    GridLayout {
                        columns: 2
                        columnSpacing: 15
                        rowSpacing: 15
                        Layout.fillWidth: true

                        // Długość
                        ColumnLayout {
                            spacing: 5
                            Label {
                                text: "Długość"
                                font.pixelSize: 11
                                color: "#999999"
                                font.bold: true
                            }
                            Label {
                                text: root.planeData ? root.planeData.length.toFixed(2) + " m" : "-"
                                font.pixelSize: 16
                                color: "#1a1a1a"
                                font.bold: true
                            }
                        }

                        // Liczba silników
                        ColumnLayout {
                            spacing: 5
                            Label {
                                text: "Silniki"
                                font.pixelSize: 11
                                color: "#999999"
                                font.bold: true
                            }
                            Label {
                                text: root.planeData ? root.planeData.numberOfEngines + " szt" : "-"
                                font.pixelSize: 16
                                color: "#1a1a1a"
                                font.bold: true
                            }
                        }

                        // Moc
                        ColumnLayout {
                            spacing: 5
                            Label {
                                text: "Moc"
                                font.pixelSize: 11
                                color: "#999999"
                                font.bold: true
                            }
                            Label {
                                text: root.planeData ? root.planeData.thrust + " kN" : "-"
                                font.pixelSize: 16
                                color: "#1a1a1a"
                                font.bold: true
                            }
                        }

                        // Pasażerowie
                        ColumnLayout {
                            spacing: 5
                            Label {
                                text: "Pasażerowie"
                                font.pixelSize: 11
                                color: "#999999"
                                font.bold: true
                            }
                            Label {
                                text: root.planeData ? root.planeData.passengers + " os" : "-"
                                font.pixelSize: 16
                                color: "#1a1a1a"
                                font.bold: true
                            }
                        }
                    }

                    // Sekcja 3: Osiągi
                    ColumnLayout {
                        spacing: 10
                        Layout.fillWidth: true

                        Label {
                            text: "Osiągi"
                            font.pixelSize: 12
                            font.bold: true
                            color: "#666666"
                            font.capitalization: Font.AllUppercase
                        }

                        GridLayout {
                            columns: 2
                            columnSpacing: 15
                            rowSpacing: 10
                            Layout.fillWidth: true

                            ColumnLayout {
                                spacing: 5
                                Label {
                                    text: "Max. prędkość"
                                    font.pixelSize: 11
                                    color: "#999999"
                                }
                                Label {
                                    text: root.planeData ? root.planeData.maxSpeed.toFixed(1) + " km/h" : "-"
                                    font.pixelSize: 15
                                    color: "#1a1a1a"
                                    font.bold: true
                                }
                            }

                            ColumnLayout {
                                spacing: 5
                                Label {
                                    text: "Max. wysokość"
                                    font.pixelSize: 11
                                    color: "#999999"
                                }
                                Label {
                                    text: root.planeData ? root.planeData.maxAltitude.toFixed(0) + " m" : "-"
                                    font.pixelSize: 15
                                    color: "#1a1a1a"
                                    font.bold: true
                                }
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }
                }
            }
        }
    }
}

// qmllint enable unqualified
